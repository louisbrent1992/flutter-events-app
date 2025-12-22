# EventEase Client

Flutter mobile application for the EventEase platform.

## Getting Started

This is the Flutter client application for EventEase, an event discovery and planning app.

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- iOS development: Xcode and CocoaPods
- Android development: Android Studio and Android SDK

### Setup

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Configure Firebase:
   - Firebase configuration is already set up via `firebase_options.dart`
   - Ensure you have the correct Firebase project selected

3. Run the app:
   ```bash
   flutter run
   ```

### Project Structure

- `lib/` - Main application code
- `lib/screens/` - UI screens
- `lib/components/` - Reusable UI components
- `lib/providers/` - State management (Provider)
- `lib/services/` - Business logic and API services
- `lib/models/` - Data models

For more information, see the main [README.md](../README.md) in the project root.
