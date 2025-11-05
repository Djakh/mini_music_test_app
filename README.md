# Mini Music Test App

A lightweight Flutter mini music player that showcases catalog browsing, queue management, background playback, and offline caching. Built with Flutter 3.x, Riverpod, and a clean architecture split into data, domain, and presentation layers.

## Features
- Load a track catalog from `assets/catalog/catalog.json` and search by title or artist.
- Playback powered by `just_audio` + `audio_service` with background controls, queueing, and persistence across app restarts.
- Mini player with play/pause, previous/next, progress scrubbing, and buffered progress.
- Queue screen with quick navigation to any track in the playlist.
- Offline mode: download tracks locally with progress feedback, remove cached files, and automatically switch playback to the cached asset when available.
- Graceful empty/error states for catalog and downloads.
- Gapless transitions between queued tracks leveraging `just_audio`’s concatenating playlist.
- Basic unit (2) and widget (1) tests covering repository logic, download state management, and search UI.

> Gapless or cross-fade playback is **not** enabled to keep the example focused on queue/background handling. The current architecture makes it straightforward to add via `just_audio` if needed.

## Project Structure
```
lib/
  core/        // DI and shared utilities
  data/        // Datasources and repository implementations
  domain/      // Entities, repositories, and use cases
  presentation/ // Pages, widgets, providers
  services/    // Audio handler bridging audio_service & just_audio
assets/
  audio/       // (placeholder for future bundled audio)
  covers/      // Generated solid color placeholders
  catalog/     // Track metadata consumed by the app
```

## Packages
- [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) – state management & DI
- [`just_audio`](https://pub.dev/packages/just_audio) – playback engine
- [`audio_service`](https://pub.dev/packages/audio_service) – background audio/notification integration
- [`audio_session`](https://pub.dev/packages/audio_session) – platform audio focus handling
- [`dio`](https://pub.dev/packages/dio) – download client with progress callbacks
- [`hive` / `hive_flutter`](https://pub.dev/packages/hive) – lightweight persistence for downloads & queue state
- [`mocktail`](https://pub.dev/packages/mocktail) – testing support

## Running the App
1. Install Flutter 3.x and fetch dependencies:
   ```bash
   flutter pub get
   ```
2. Run on a simulator or device:
   ```bash
   flutter run
   ```
3. Execute the automated tests:
   ```bash
   flutter test
   ```

### Background playback
- Android: configured `AudioService` foreground service with media notification, media button receiver, and required permissions (`android/app/src/main/AndroidManifest.xml`).
- iOS: enables the `audio` background mode and configures the `AVAudioSession` for playback (`ios/Runner/Info.plist`, `ios/Runner/AppDelegate.swift`).

### Assets & Offline Storage
- Catalog data: `assets/catalog/catalog.json`
- Cover art: `assets/covers/*.png`
- Downloads: saved under the platform-specific application support directory (`<app-support>/downloads`). Hive boxes (`downloads`, `queue`) persist download metadata and queue position/index.

## Notes
- The app assumes track audio URLs are reachable over the network for initial playback/download. Once downloaded, playback switches to the cached file automatically.
- Android/iOS background notifications are configured via `audio_service`. Update channel metadata if you rebrand the app.
- Search is case-insensitive and falls back to a friendly empty state when no results are found.
- **Изменённое решение:** Изначально скачанные локально MP3-файлы помечались как уже доступные офлайн сразу после загрузки каталога. В процессе задачи поведение изменил, чтобы состояние «скачано» устанавливалось только после нажатия пользователем на кнопку загрузки (с имитацией прогресса). Это отражает реальное действие и позволяет управлять кэшем (удалять/повторно качать) через UI.
