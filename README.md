# Speakly

Professional Flutter application for practising English writing across
mobile, web and Windows desktop.

## Overview

Speakly is designed to help users build a daily English writing habit using
guided prompts, lessons, vocabulary training and an offline dictionary. The
app focuses on simplicity, persistence and measurable progress.

## Key features

- Daily writing prompts (curated by topic and level)
- Distraction-free editor with live word count, timers and save guards
- Local storage for all entries (no account required)
- Lessons covering grammar, punctuation and style with practical examples
- Vocabulary trainer and flashcards with bundled common words
- Offline dictionary with caching and audio pronunciation
- Progress tracking: streaks, milestones and activity charts

## Tech stack

- Flutter (Material 3) - single codebase for mobile, web and desktop
- State management: `provider`
- Local persistence: `shared_preferences`
- Network: `http` (dictionary lookups) with on-device caching
- Audio: `audioplayers`

## Prerequisites

- Flutter SDK (stable channel)
- For Windows desktop builds: Visual Studio with C++ build tools

## Getting started

1. Clone the repository:

   git clone <repo-url>
   cd Speakly

2. Install dependencies:

   flutter pub get

3. Run the app (example targets):

   flutter run -d chrome
   flutter run -d windows

For mobile devices, ensure an emulator or device is connected and available.

## Build (release)

Web:

```bash
flutter build web
```

Android APK:

```bash
flutter build apk
```

Windows:

```bash
flutter build windows
```

## Tests & static analysis

Run static analysis and unit/widget tests:

```bash
flutter analyze
flutter test
```

## Project layout

Top-level structure (relevant folders):

```
lib/
  main.dart
  models/
  screens/
  services/
  state/
  theme/
  widgets/
assets/
  data/
  words/
```

All editable content (prompts, lessons, vocab) lives under `assets/data/`.

## Contributing

Contributions are welcome. A suggested workflow:

1. Create a feature branch from `main`.
2. Add tests for new features where applicable.
3. Open a pull request with a clear description of changes.

Please follow the existing code style and keep changes focused.

## Troubleshooting

- If you see build errors on Windows, ensure the Visual C++ build tools are
  installed and `flutter doctor` reports no issues.
- If network dictionary lookups fail, the app will fall back to cached data
  when available.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE)
file in this repository for the full terms.

## Contact

For questions or support, open an issue or contact the maintainer via the
project repository.

---

If you want a Swedish translation of this README or a shorter one-page
variant for app stores, say the word and I will prepare it.
