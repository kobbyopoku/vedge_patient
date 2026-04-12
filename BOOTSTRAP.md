# Bootstrap — vedge_patient

This directory was authored by W5.5 inside the Claude Agent SDK sandbox, which
cannot run `flutter create` / `flutter pub get` / `flutter analyze`. The Dart
source, `pubspec.yaml`, `analysis_options.yaml`, `.metadata`, `.gitignore`, and
`test/widget_test.dart` are all checked in by hand. The native iOS / Android
platform shells are NOT — they must be generated locally with `flutter create`
(which is non-destructive for an existing project and will only fill in the
missing platform directories).

## Post-handoff orchestrator command

Run this once to fill in the platform shells and verify the project:

```bash
cd /Users/kobbyopoku/ROAM/CascadeProjects/vedge/vedge_patient && \
  flutter create --org health.vedge --platforms=ios,android --project-name vedge_patient . && \
  flutter pub get && \
  flutter analyze
```

Expected outcomes:
- `flutter create` adds `ios/`, `android/`, and overwrites `.metadata` — this
  is fine. The hand-authored `lib/`, `pubspec.yaml`, and
  `analysis_options.yaml` are preserved because they already exist.
- `flutter pub get` resolves the locked package versions.
- `flutter analyze` should print `No issues found!`. If it reports any, they
  are bugs introduced during W5.5 — file them back on the W5.5 agent.

## Dev run

```bash
# backend must be running on :8050 (vedge-app profile=dev)
flutter run --dart-define=API_BASE_URL=http://localhost:8050
```

On iOS Simulator / Android Emulator running against a Mac host, you may need
`http://10.0.2.2:8050` (Android) or `http://localhost:8050` (iOS).

## Notes

- Uses Flutter 3.32.8 / Dart 3.8.1, same as `vedge_staff`.
- Shares package versions with `vedge_staff` so a future shared-code package
  extraction is clean.
- Secure-storage keys are all prefixed `vedge_patient.` so they never collide
  with `vedge_staff` if both apps are installed on the same device.
