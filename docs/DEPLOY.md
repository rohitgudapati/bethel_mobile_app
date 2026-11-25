# Deploy checklist: Bethel Prayer House backend (Windows)

For a Claude session running on the church's Windows computer. Work through the steps in
order, check each result, and stop to ask the person whenever a step needs them (signing in,
pasting the YouTube key, choosing files). Never print or commit the YouTube key.

**Already done in the browser:** Firebase project `bethel-prayer-house-eb47e` on the Blaze plan
(free trial until 24 Feb 2027), Email/Password + Google + Anonymous sign-in, Firestore and
Storage in `us-central1`, YouTube Data API v3 enabled, API key "YouTube sync" restricted to it.
Google account: the church account (bethelph7@gmail.com). Note: that account also has an older
project `bethel-prayer-house` (no `-eb47e`). **Do not use or change it.**

## 1. Tools (PowerShell)

Install what is missing (`winget` is built into Windows 10/11). Open a new PowerShell window
after installing so the new commands are found.

```powershell
winget install --id Git.Git -e
winget install --id OpenJS.NodeJS.LTS -e          # Node 22 or newer
winget install --id Python.Python.3.12 -e
winget install --id Google.CloudSDK -e
npm install -g firebase-tools
py -m pip install python-docx
```

Check: `git --version`, `node -v` (v22+), `firebase --version`, `gcloud --version`, `py --version`.

## 2. Get the code

```powershell
mkdir C:\Bethel; cd C:\Bethel
git clone -b claude/redesign-demo https://github.com/rohitgudapati/bethel_mobile_app.git
cd bethel_mobile_app
```

## 3. Rebuild the song books (lyrics are kept out of GitHub)

Ask the person for the three Word files and copy them to `C:\Bethel\songbooks\`:
`SOZ_Master_English_1.docx`, `SOZ_Master_Telugu_1.docx`, `Bethel_Songs.docx`.

```powershell
cd C:\Bethel\bethel_mobile_app\tools\songbooks
py build_songbooks.py zion --english C:\Bethel\songbooks\SOZ_Master_English_1.docx --telugu C:\Bethel\songbooks\SOZ_Master_Telugu_1.docx
py build_songbooks.py bethel --docx C:\Bethel\songbooks\Bethel_Songs.docx
```

Expected: `songs_of_zion.json: 866 songs, numbers 1-867, missing [677]` and
`bethel_english.json: 60 songs`. The files land in `assets\songs\` and are git-ignored.

## 4. Sign in to Google (the person does this in the browser that opens)

```powershell
firebase login                                    # church account
gcloud auth login                                 # church account
gcloud config set project bethel-prayer-house-eb47e
gcloud auth application-default login             # church account (used by the seed tool)
gcloud auth application-default set-quota-project bethel-prayer-house-eb47e
firebase projects:list                            # must list bethel-prayer-house-eb47e
```

## 5. Store the YouTube key in Secret Manager

```powershell
cd C:\Bethel\bethel_mobile_app\backend\functions
npm ci
cd ..
firebase functions:secrets:set YOUTUBE_API_KEY --project bethel-prayer-house-eb47e
```

The person pastes the "YouTube sync" key at the prompt (Google Cloud → APIs & Services →
Credentials → YouTube sync → Show key). Don't echo it.

## 6. Deploy rules, indexes and functions

From `C:\Bethel\bethel_mobile_app\backend`:

```powershell
firebase deploy --only firestore,storage,functions --project bethel-prayer-house-eb47e
```

- If asked for `YOUTUBE_CHANNEL`, accept the default `@bethelprayerhousenaperville`.
- The first deploy enables several Google APIs and can take 5–10 minutes.
- If the first deploy fails on the Firestore/Eventarc triggers with a permissions or
  "service agent" error, wait 3–5 minutes and run the same command again (Google is still
  setting up its service accounts). This is normal on a new project.
- Expected functions: `syncYouTube`, `syncYouTubeSunday`, `syncYouTubeFull`, `syncYouTubeNow`,
  `onPrayed`, `onVerseLiked`, `onVerseUnliked`.

## 7. Load the church content

From `C:\Bethel\bethel_mobile_app\backend\functions`:

```powershell
$env:GOOGLE_CLOUD_PROJECT = "bethel-prayer-house-eb47e"
npm run seed -- --production --book songs-of-zion=..\..\assets\songs\songs_of_zion.json --book bethel-english=..\..\assets\songs\bethel_english.json
```

Expected: `Seeded about 980 documents.` Check in the Firebase console → Firestore that
`songs` has 926 documents and `songBooks` has Songs of Zion (866) and Bethel English Songs (60).

## 8. Run the first YouTube sync now (instead of waiting 10 minutes)

```powershell
gcloud scheduler jobs list --location us-central1
gcloud scheduler jobs run firebase-schedule-syncYouTubeFull-us-central1 --location us-central1
firebase functions:log --only syncYouTubeFull --project bethel-prayer-house-eb47e
```

Look for `YouTube sync finished` with a `written` count. Then Firestore → `videos` lists the
channel's sermons, Shorts and playlists, and `church/live` says `live`, `upcoming` or `none`.
If the log says the channel was not found, check the handle with the person and redeploy with
the right `YOUTUBE_CHANNEL`.

## 9. Connect the web app and try it

Needs Flutter (`winget install --id Google.Flutter -e` or https://docs.flutter.dev/get-started/install/windows),
then from `C:\Bethel\bethel_mobile_app`:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure --project=bethel-prayer-house-eb47e --platforms=web --yes
flutter pub get
flutter run -d chrome --dart-define=BACKEND=firebase
```

`flutterfire configure` rewrites `lib/firebase_options.dart` with the project's web settings
(these are public by design, safe to commit). In the app: the song book shows both books,
Watch shows YouTube videos, and a prayer request appears in Firestore → `prayerRequests`.

## 10. Make the church admin an admin

Sign up in the app once with the admin's email, then from `backend\functions`:

```powershell
npm run make-admin -- <admin-email>
```

## 11. Save the work

```powershell
cd C:\Bethel\bethel_mobile_app
git add lib/firebase_options.dart
git commit -m "Connect the app to Firebase project bethel-prayer-house-eb47e"
git push
```

Never commit `assets/songs/*.json`, `backend/functions/.secret.local` or any key.

## Not in this checklist (next step: publishing the phone apps)

- Choose the real app ID (e.g. `org.bethelprayerhouse.app`; `com.example…` is rejected by
  the stores), update the Android build (Gradle/Kotlin are from an old Flutter template),
  then `flutterfire configure --platforms=android,ios`.
- Apple Developer ($99/yr) and Google Play ($25 once) accounts.
- Before **24 Feb 2027**: Firebase console → Usage and billing → **Upgrade** the free-trial
  billing account so the project keeps running.
