# Bethel Prayer House – Firebase backend

Everything the app needs runs on Firebase (Google Cloud):

| Piece | What it does |
|---|---|
| **Firestore** | Church content: song books and songs, events, services, ministries, verses, prayer wall, sermon comments |
| **Firebase Auth** | Email/password, Google and guest (anonymous) sign-in |
| **Cloud Functions** | `syncYouTube` every 10 minutes, `syncYouTubeFull` nightly, `syncYouTubeNow` for admins, and counters for "I prayed" and verse likes |
| **Secret Manager** | The YouTube Data API key |
| **Storage** | Church images, song recordings and book PDFs (under `public/`) |

## What the YouTube sync does

| On YouTube | In the app |
|---|---|
| A live stream that is on air | **LIVE** banner on Home and Watch, plays inside the app |
| A scheduled stream | "Starts Sun at 10:30 AM" banner |
| A finished live stream or a normal upload | **Sermon** |
| A video in a playlist | Sermon in that **series** (e.g. "Romans Series") |
| A video in a playlist whose name contains "Testimon" | **Testimony** |
| A video in a playlist whose name contains "Interview" | **Interview** |
| A video up to 60 seconds, or up to 3 minutes with #shorts | **Short** |
| A video made private or deleted | Removed from the app |

Admins can hide a video or change its type or preacher in Firestore (`hidden`,
`typeOverride`, `preacher`, `seriesOverride`); the sync never overwrites those fields.
With five playlists it uses about 1,500 of the 10,000 free YouTube API units per day.

## Set up the live project (one time)

You need a Google account. Steps 1–3 happen in the browser.

1. **Create the Firebase project.** Go to <https://console.firebase.google.com>, choose
   *Create a project*, and name it (for example `bethel-prayer-house`). Note the project ID.
2. **Switch to the Blaze plan** (*Upgrade* in the console). Cloud Functions, scheduled jobs
   and Secret Manager need it. A church this size normally stays inside the free allowance;
   set a budget alert (e.g. $10/month) under *Usage and billing*.
3. **Turn on what the app uses:**
   - *Build → Authentication → Sign-in method*: enable **Email/Password**, **Google** and **Anonymous**.
   - *Build → Firestore Database*: create the database (production mode, region `us-central1`).
   - *Build → Storage*: get started (same region).
   - In the Google Cloud console for the same project, open
     <https://console.cloud.google.com/apis/library/youtube.googleapis.com>, click **Enable**,
     then *APIs & Services → Credentials → Create credentials → API key*. Restrict the key to
     **YouTube Data API v3**.
4. **Deploy from a computer** with Node.js 22 installed:

   ```bash
   npm install -g firebase-tools
   firebase login
   cd backend
   firebase use --add            # pick the project, alias "default"
   cd functions && npm install && cd ..
   firebase functions:secrets:set YOUTUBE_API_KEY   # paste the API key
   firebase deploy               # asks for YOUTUBE_CHANNEL: paste the channel link or @handle
   ```

5. **Load the starting content** (song books, hymns, services, ministries, events, verses),
   including the full Songs of Zion book from `assets/songs/songs_of_zion.json`
   (kept out of git; see `assets/songs/README.md`):

   ```bash
   gcloud auth application-default login
   cd backend/functions
   GOOGLE_CLOUD_PROJECT=<project-id> npm run seed -- --production --songs ../../assets/songs/songs_of_zion.json
   ```

6. **Make yourself an admin** after signing in to the app once:

   ```bash
   GOOGLE_CLOUD_PROJECT=<project-id> npm run make-admin -- you@example.com
   ```

7. **Connect the app:**

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<project-id>   # writes lib/firebase_options.dart
   flutter run --dart-define=BACKEND=firebase
   ```

The first sync runs within 10 minutes of deploying. Check *Functions → Logs* for
"YouTube sync finished".

## Develop locally with the emulators

No Google account needed. From `backend/functions`:

```bash
npm install
npm test                    # unit tests for the YouTube rules
npm run test:emulator       # sync, seed, triggers and security rules against the emulators
```

Run the app against local data:

```bash
cd backend && npx --prefix functions firebase emulators:start --only firestore,auth --project demo-bethel
# in another terminal
cd backend/functions && FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm run seed
cd ../.. && flutter run --dart-define=BACKEND=firebase --dart-define=USE_FIREBASE_EMULATOR=true
```

On an Android emulator add `--dart-define=EMULATOR_HOST=10.0.2.2`.

## Data model

| Collection | Fields |
|---|---|
| `church/info` | name, address, country, phone, email |
| `church/live` | status (`live`/`upcoming`/`none`), videoId, title, thumbnail, scheduledStart, viewers |
| `church/youtube` | channelId, channelTitle, lastSync, series |
| `videos/{youtubeId}` | kind, type, title, description, thumbnail, publishedAt, durationSec, series, hidden, removed, typeOverride, preacher, seriesOverride |
| `videos/{id}/comments` | uid, name, text, createdAt |
| `songBooks/{id}` | title, language, image, order, songCount |
| `songs/{bookId}-{number}` | bookId, number, title, artist, lyricist, lyrics {language: text}, chordKey, chords, audioUrl, trendingScore |
| `events/{id}` | title, date, time, venue, description, image, speakers, category |
| `events/{id}/rsvps/{uid}` | one per person |
| `services/{id}` | name, schedule, description, image, icon, order |
| `serviceRequests/{id}` | uid, serviceId, name, phone, note, createdAt (admins only) |
| `ministries/{id}` | name, info, image, meets, order |
| `verses/{id}` | date, text, reference, image, likes, shares, views |
| `prayerRequests/{id}` | uid, name, request, category, public, createdAt, prayedCount |
| `prayerContacts/{id}` | uid, email, phone (admins only) |
| `books`, `pictures`, `readingPlan` | as in `seed/content.json` |
| `users/{uid}` | name, email, saved songs (owner only) |

Security rules are in `firestore.rules` and covered by `functions/test/rules.emulator.test.ts`.
