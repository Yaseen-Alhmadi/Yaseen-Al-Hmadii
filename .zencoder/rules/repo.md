# Repository Overview

## Project

- **Name**: Water Management System (Flutter)
- **Description**: Cross-platform Flutter application for managing customers, meter readings, invoices, and authentication using Firebase services.

## Tech Stack

- **Framework**: Flutter
- **Languages**: Dart, Kotlin (Android), Swift (iOS), C++ (desktop embeddings)
- **Backend/Services**: Firebase (Authentication, Firestore, Core)

## Key Paths

- **lib/main.dart**: Entry point bootstrapping Firebase and routing.
- **lib/screens/**: UI screens (login, signup, dashboard, customers, invoices, etc.).
- **lib/services/**: Application services and Firebase interactions.
- **lib/models/**: Data models (e.g., invoices).
- **android/app/google-services.json**: Firebase Android configuration (package name must match applicationId).
- **ios/Runner/GoogleService-Info.plist**: Firebase iOS configuration (not yet confirmed in repo).

## Build & Run

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```
2. **Run on Android**:
   ```bash
   flutter run -d <device_id>
   ```
3. **Build APK**:
   ```bash
   flutter build apk
   ```

## Common Tasks

- **Update Firebase options**: Regenerate via `flutterfire configure` and update `lib/firebase_options.dart` plus platform configs.
- **Add routes**: Register in `MaterialApp.routes` inside `WaterManagementApp`.
- **State management**: Uses `provider` for dependency injection of services.

## Notes

- Ensure `google-services.json` matches the Android `applicationId` defined in `android/app/build.gradle`.
- Fonts include Cairo; make sure assets declared in `pubspec.yaml` remain in sync.
- Codebase contains Arabic localization text; maintain RTL considerations when editing UI.
