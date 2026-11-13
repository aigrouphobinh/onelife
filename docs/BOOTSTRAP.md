# Run locally

## Prerequisites
Flutter stable, Android SDK, Android Studio or VS Code. iOS builds require macOS and Xcode.

This repository currently includes Dart source and pubspec but does **not** include generated android/ios platform folders. To generate them without replacing tracked Dart files, from the repo root run:

```bash
flutter create --platforms=android,ios --project-name onelife .
flutter pub get
flutter analyze
flutter test
flutter run
```

Commit generated platform files after checking Android application ID, iOS bundle identifier, signing, and supported SDK targets. Do not commit signing credentials.

## Known gaps
Tasks, reminders, share-sheet integration, export, FTS5, iOS verification and store publishing are not implemented. The first vertical slice is offline notes create/search/delete with SQLite.
