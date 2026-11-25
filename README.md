# Bethel Prayer House – mobile app (v2 redesign)

Flutter app for Bethel Prayer House, Naperville, IL. Warm & modern redesign with
new features: live stream, verse of the day, Bible reading plan, prayer wall,
events with RSVP, and giving.

## Run it

```bash
flutter pub get
flutter run                     # demo mode: built-in sample content
```

Connect the Firebase backend (see [backend/README.md](backend/README.md) for setup and the YouTube sync):

```bash
flutter run --dart-define=BACKEND=firebase
```

The older .NET API (`bethel_app_backend`) is still supported:

```bash
flutter run --dart-define=API_BASE_URL=https://YOUR-API-HOST
```

Other build-time settings (all optional):

| Define | Purpose |
|---|---|
| `BACKEND` | `firebase` to use Firebase. Otherwise demo mode, or the .NET API when `API_BASE_URL` is set. |
| `USE_FIREBASE_EMULATOR` | `true` to use the local Firebase emulators. |
| `API_BASE_URL` | Base URL of the old ASP.NET API. |
| `CHURCH_ID` | Church id for album/song endpoints (default `1`). |
| `GIVING_URL` | Public giving page, e.g. a Stripe Payment Link (`https://buy.stripe.com/...`). |
| `YOUTUBE_URL` | Church YouTube channel. |

## Structure

```
lib/
  app/        config, theme (cream / navy / gold), app state
  data/       models, repository interface; mock, Firebase and .NET API implementations
  screens/    welcome, shell (bottom nav), home, songs, watch, prayer,
              events, bible, give, church (services, verses, ministries), more
  widgets/    shared UI pieces
backend/      Firebase: Firestore rules, Cloud Functions (YouTube sync), seed content
```

## Screens → API endpoints

| Screen | Endpoint(s) |
|---|---|
| Sign in / up | `UserApi/SignIn`, `UserApi/SignUp` |
| Verse of the day | `DailyVerseAPI/GetTodayVerse`, `LikeDailyVerse` |
| Watch | `LiveStreamApi/GetAllLiveStreamings`, `SermonApi/GetAllSermons` |
| Events | `EventApi/GetAllEvents` |
| Prayer | `PrayerRequestAPI/SavePrayerRequest` (wall needs a new list endpoint) |
| Music | `AlbumApi/GetAlbumsByChurchId`, `GetTrendingSongsByChurchId`, `GetSongsByAlbumId` |
| Ministries / Books / Gallery | `MinistryApi/GetAllMinistries`, `BookApi/GetBooksListForMobiles`, `PictureApi/GetAllPictures` |

Not yet in the API: prayer wall listing and "I prayed" counts, event RSVPs, Bible text
(the reading plan ships KJV passages in the app).
