# Bethel Prayer House – mobile app (v2 redesign)

Flutter app for Bethel Prayer House, Naperville, IL. Warm & modern redesign with
new features: live stream, verse of the day, Bible reading plan, prayer wall,
events with RSVP, and giving.

## Run it

```bash
flutter pub get
flutter run                     # demo mode: built-in sample content
```

Connect the real backend (`bethel_app_backend`):

```bash
flutter run --dart-define=API_BASE_URL=https://YOUR-API-HOST
```

Other build-time settings (all optional):

| Define | Purpose |
|---|---|
| `API_BASE_URL` | Base URL of the ASP.NET API. Empty = demo mode. |
| `CHURCH_ID` | Church id for album/song endpoints (default `1`). |
| `GIVING_URL` | Public giving page, e.g. a Stripe Payment Link (`https://buy.stripe.com/...`). |
| `YOUTUBE_URL` | Church YouTube channel. |

## Structure

```
lib/
  app/        config, theme (cream / navy / gold), app state
  data/       models, repository interface, mock + API implementations
  screens/    welcome, shell (bottom nav), home, watch, prayer, music,
              events, bible, give, more (ministries, gallery, books)
  widgets/    shared UI pieces
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
