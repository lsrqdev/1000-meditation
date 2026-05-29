# 1000

A quiet 1000-day progressive meditation app built with Flutter.

The program starts at 3 minutes per day and gradually builds to 30 minutes per day across 9 phases.

## Program

| Phase | Days | Daily target |
| --- | ---: | ---: |
| 1 | 1-30 | 3 min |
| 2 | 31-90 | 5 min |
| 3 | 91-180 | 7 min |
| 4 | 181-300 | 10 min |
| 5 | 301-450 | 12 min |
| 6 | 451-650 | 15 min |
| 7 | 651-800 | 20 min |
| 8 | 801-900 | 25 min |
| 9 | 901-1000 | 30 min |

## Features

- Animated meditation timer with an orb interface
- 1000-day phase progression
- Week-to-date progress and streak tracking
- Local history saved on device/browser
- Completion bell and haptic cues where supported
- Optional ambient soundscapes
- Data export from the statistics screen
- Web deployment support through Vercel

## Run Locally

Install dependencies:

```bash
flutter pub get
```

Run in Chrome:

```bash
flutter run -d chrome
```

Run on macOS:

```bash
flutter run -d macos
```

Run tests:

```bash
flutter test
```

Build for web:

```bash
flutter build web
```

Serve the web build locally:

```bash
python3 -m http.server 8080 --directory build/web
```

Then open:

```text
http://localhost:8080
```

## Deploy To Vercel

This repo includes:

- `vercel.json`
- `vercel_build.sh`

Vercel uses those files to install Flutter, build the web app, and publish `build/web`.

Deploy steps:

1. Push the repo to GitHub.
2. Import the repo in Vercel.
3. Use the free Hobby plan.
4. Deploy.

After deployment, use the production `.vercel.app` URL for daily practice. Avoid preview URLs for daily use because browser storage is tied to the exact domain.

## iPhone Safari

Open the production Vercel URL in Safari, then use Share -> Add to Home Screen.

Progress is saved locally on that iPhone/Safari install. It survives normal refreshes and redeploys, but can be lost if Safari site data is cleared.

## Data Storage

The app stores progress locally with `shared_preferences`.

On web, that means browser storage:

- Same browser and same domain keeps history.
- Different devices do not automatically sync.
- Preview and production Vercel URLs have separate storage.
- Clearing site data can remove history.

Use the statistics screen export as a backup.
