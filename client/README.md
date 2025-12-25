# EventEase Flutter Client

**Version 1.0.0**

Flutter mobile application for EventEase - a smart event management platform with AI-powered planning and social media integration.

## 📱 Overview

This is the Flutter client application for EventEase, providing a cross-platform mobile experience for iOS and Android. The app features a modern Material Design 3 UI, real-time Firebase synchronization, and seamless social media event importing.

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.7.0 or higher
- **Dart SDK**: 3.7.0 or higher
- **iOS Development**: 
  - Xcode 14.0+
  - CocoaPods
  - macOS (for iOS builds)
- **Android Development**:
  - Android Studio
  - Android SDK (API 24+)
  - Java 17

### Initial Setup

1. **Install Flutter dependencies:**
   ```bash
   cd client
   flutter pub get
   ```

2. **Configure Firebase:**
   - Firebase configuration is set up via `lib/firebase_options.dart`
   - Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in place
   - Verify Firebase project settings match your environment

3. **iOS Setup (macOS only):**
   ```bash
   cd ios
   pod install
   cd ..
   ```

4. **Run the app:**
   ```bash
   # Run on connected device/emulator
   flutter run
   
   # Run on specific device
   flutter devices
   flutter run -d <device-id>
   
   # Build for release
   flutter build apk --release  # Android
   flutter build ios --release  # iOS
   ```

## 📁 Project Structure

```
client/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── firebase_options.dart     # Firebase configuration
│   ├── screens/                   # UI screens
│   │   ├── home_screen.dart
│   │   ├── my_events_screen.dart
│   │   ├── ai_planner_screen.dart
│   │   ├── discover_events_screen.dart
│   │   ├── event_collections_screen.dart
│   │   └── auth/                 # Authentication screens
│   ├── components/               # Reusable UI components
│   │   ├── custom_app_bar.dart
│   │   ├── credits_badge.dart
│   │   ├── button.dart
│   │   └── ...
│   ├── providers/                # State management (Provider)
│   │   ├── auth_provider.dart
│   │   ├── event_provider.dart
│   │   ├── subscription_provider.dart
│   │   └── ...
│   ├── services/                 # Business logic and API services
│   │   ├── api_client.dart
│   │   ├── event_service.dart
│   │   ├── event_ai_service.dart
│   │   └── ...
│   ├── models/                   # Data models
│   │   ├── event.dart
│   │   ├── generated_plan.dart
│   │   └── ...
│   ├── theme/                    # App theming
│   │   └── theme.dart
│   └── utils/                    # Utility functions
│       ├── snackbar_helper.dart
│       └── ...
├── android/                      # Android-specific files
├── ios/                          # iOS-specific files
├── assets/                       # Images, icons, fonts
│   ├── icons/
│   └── images/
└── pubspec.yaml                  # Flutter dependencies
```

## 🛠️ Development

### Code Organization

- **Screens**: Full-page UI components that represent app routes
- **Components**: Reusable widgets used across multiple screens
- **Providers**: State management using Provider pattern
- **Services**: API clients and business logic layer
- **Models**: Data classes representing app entities

### State Management

The app uses the **Provider** pattern for state management:
- `AuthService`: User authentication state
- `EventProvider`: Event CRUD operations
- `SubscriptionProvider`: Credits and subscription management
- `CollectionProvider`: Event collections management
- `DiscoverProvider`: Event discovery and search

### Key Dependencies

- **firebase_core**: Firebase initialization
- **firebase_auth**: User authentication
- **cloud_firestore**: Cloud database
- **provider**: State management
- **google_fonts**: Typography
- **cached_network_image**: Image caching
- **share_handler**: Share extension support
- **in_app_purchase**: Subscription management

### Building & Deployment

**Android:**
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# App bundle for Play Store
flutter build appbundle --release
```

**iOS:**
```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release

# Archive for App Store
# Use Xcode: Product > Archive
```

### Icon & Splash Generation

The app uses automated icon and splash screen generation:

```bash
# Generate launcher icons
dart run flutter_launcher_icons

# Generate splash screens
dart run flutter_native_splash:create
```

Configuration is in `pubspec.yaml`:
- `flutter_launcher_icons`: Icon generation settings
- `flutter_native_splash`: Splash screen settings

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run with coverage
flutter test --coverage
```

## 🔍 Code Analysis

```bash
# Analyze code for issues
flutter analyze

# Format code
dart format .

# Fix auto-fixable issues
dart fix --apply
```

## 📱 Platform-Specific Notes

### Android

- **Min SDK**: 24 (Android 7.0)
- **Target SDK**: 35
- **Package**: `com.eventease.com`
- **Adaptive Icons**: Configured in `android/app/src/main/res/`

### iOS

- **Min Version**: iOS 12.0
- **Bundle ID**: `com.eventease.app`
- **App Icons**: Generated in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Share Extension**: Configured in `ios/ShareExtension/`

## 🔧 Configuration

### Environment Variables

The app uses Firebase configuration files:
- **Android**: `android/app/google-services.json`
- **iOS**: `ios/Runner/GoogleService-Info.plist`

### API Configuration

API endpoints are configured in `lib/config/app_config.dart`:
- Production and staging API URLs
- Feature flags
- App configuration constants

## 🐛 Troubleshooting

**Build Issues:**
```bash
# Clean build cache
flutter clean
flutter pub get

# iOS: Reinstall pods
cd ios && pod deintegrate && pod install && cd ..
```

**Firebase Issues:**
- Verify `firebase_options.dart` matches your Firebase project
- Check that `google-services.json` and `GoogleService-Info.plist` are up to date
- Ensure Firebase services are enabled in Firebase Console

**Dependency Issues:**
```bash
# Update dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

## 📚 Additional Resources

- Main project documentation: [../README.md](../README.md)
- Release notes: [../RELEASE_NOTES.md](../RELEASE_NOTES.md)
- Flutter documentation: https://flutter.dev/docs
- Firebase Flutter docs: https://firebase.flutter.dev/

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.
