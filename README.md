# <img src="client/assets/icons/logo.png" alt="EventEase Logo" width="32" height="32" style="vertical-align:middle; margin-right:8px;"> EventEase

**Version 1.0.0**

EventEase is a smart event management app that helps you discover, plan, and organize events with the power of AI. Import events from social media, generate personalized event plans, and keep track of your schedule—all in one place.

## Table of Contents

- [Project Overview](#project-overview)
- [Core Features](#core-features)
- [Technology Stack](#technology-stack)
- [Getting Started](#getting-started)
- [Instagram Integration](#instagram-integration)
- [Social Sharing Integration](#social-sharing-integration)
- [Firebase Integration](#firebase-integration)
- [Screenshots](#screenshots)
- [License](#license)

## Project Overview

**EventEase** is designed for event enthusiasts, planners, and anyone looking to discover and manage events effortlessly. The app combines AI-powered planning with seamless social media integration to create a comprehensive event management solution.

**Key Highlights:**
- 🎯 **AI-Powered Planning**: Generate personalized event itineraries with intelligent suggestions
- 📱 **Social Media Integration**: Import events directly from Instagram, TikTok, YouTube, and web URLs
- 📅 **Smart Organization**: Create custom collections, categorize events, and set reminders
- 🔄 **Cloud Sync**: All your events sync across devices using Firebase
- 🎨 **Modern UI**: Beautiful, responsive design with dark mode support

## Core Features

### 🤖 AI-Powered Event Planning

- Generate personalized event plans and itineraries using AI
- Customize event details, timing, budget, and activities
- Smart suggestions based on event type, location, and preferences
- Save and regenerate event plans
- Export AI-generated plans as individual events

### 📋 Event Management

- **Create & Edit**: Full CRUD operations for personal events
- **Collections**: Organize events into custom collections
- **Categorization**: Tag and categorize events for easy discovery
- **Search & Filter**: Advanced search with category and time window filters
- **Event Details**: Rich event information including venue, dates, descriptions, and images

### 📱 Social Media Event Import

- **Deep Linking**: Handle shared event content seamlessly
- **Multi-Platform**: Import from Instagram, TikTok, YouTube, and web URLs
- **Smart Parsing**: Automatic extraction of event details from social media posts
- **Validation**: Review and edit imported event data before saving
- **Share Extension**: Native iOS and Android share extensions for easy importing

### 🔐 Authentication & Sync

- **Multiple Sign-In Options**: Email/Password, Google Sign-In, Apple Sign-In, Facebook Login
- **Cloud Storage**: Firebase Cloud Firestore for secure data storage
- **Real-Time Sync**: Automatic synchronization across all your devices
- **User Profiles**: Personalized user profiles and preferences

### 🔔 Notifications & Reminders

- **Push Notifications**: Firebase Cloud Messaging for event reminders
- **Smart Scheduling**: Timezone-aware notification scheduling
- **Local Notifications**: Reliable reminders even when the app is closed

## Technology Stack

### Frontend
- **Framework:** Flutter (Dart 3.7+)
- **State Management:** Provider
- **UI Components:** Material Design 3
- **Local Storage:** Hive for offline caching
- **Image Caching:** Cached Network Image with Flutter Cache Manager

### Backend
- **Runtime:** Node.js with Express
- **Database:** Firebase Cloud Firestore (NoSQL)
- **Authentication:** Firebase Authentication
- **Storage:** Firebase Storage for media files
- **Notifications:** Firebase Cloud Messaging

### Services & APIs
- **AI Integration:** External AI service for event planning
- **Social Media:** RocketAPI for Instagram, TikTok, YouTube content extraction
- **Analytics:** Firebase App Check for app integrity
- **Monetization:** Google Mobile Ads (AdMob)

### Development Tools
- **Icon Generation:** flutter_launcher_icons
- **Splash Screens:** flutter_native_splash
- **Linting:** flutter_lints
- **Testing:** Flutter Test Framework

## Getting Started

To get started with the EventEase App, follow these steps:

1. **Clone the repository:**

   ```bash
   git clone https://github.com/louisbrent1992/flutter-events-app.git
   cd flutter-events-app
   ```

2. **Set up the Flutter client:**

   ```bash
   cd client
   flutter pub get
   flutter run
   ```

   For detailed Flutter setup instructions, see [client/README.md](client/README.md).

3. **Set up the backend server:**

   ```bash
   cd server
   npm install
   cp env.example .env
   # Edit .env with your API keys
   npm run dev
   ```

   For detailed server setup instructions, see [server/README.md](server/README.md).

4. **Configure Firebase:**

   - Set up Firebase project and download configuration files
   - See [Firebase Integration](#firebase-integration) section below

## 📖 Additional Documentation

- **[Client README](client/README.md)**: Detailed Flutter client setup, development, and deployment
- **[Server README](server/README.md)**: Backend API documentation, endpoints, and deployment
- **[Release Notes](RELEASE_NOTES.md)**: Version history and changelog

## Social Media Integration

EventEase integrates with Instagram, TikTok, and YouTube to extract event information from social media posts.

### Setup Instructions

1. Sign up for a RapidAPI account at [RapidAPI](https://rapidapi.com/)
2. Subscribe to the [RocketAPI for Developers](https://rapidapi.com/rocketapi-rocketapi-default/api/rocketapi-for-developers/)
3. Copy your API key from the RapidAPI dashboard
4. Add your API key to the `server/.env` file as `RAPID_API_KEY`

### Features

- **Content Extraction**: Automatically extract event details from social media posts
- **Media Retrieval**: Download images and metadata from posts
- **AI Processing**: Intelligent content analysis to identify event information
- **Event Creation**: Automatically create event entries with extracted metadata
- **URL Parsing**: Support for various URL formats and platforms

## Screenshots

![Home Screen](client/assets/screenshots/home_screen.png)
*Home screen with quick access to key features*

---

![AI Planner Screen](client/assets/screenshots/ai_recipe_screen.png)
*AI-powered event planner for generating personalized itineraries*

---

![Event List Screen](client/assets/screenshots/recipe_list_screen.png)
*Event management with collections and search functionality*

## Social Sharing Integration

The app supports seamless event sharing through iOS and Android share extensions:

### Share Handler Integration
- **Enhanced Sharing**: Uses the `share_handler` package for robust sharing functionality
- **Multiple Content Types**: Supports URLs, text, images, videos, and various file types
- **Share Suggestions**: Provides intelligent share suggestions for better user experience
- **Cross-Platform**: Works consistently across iOS and Android platforms

### How It Works
1. Users can share event URLs from any app (Safari, Instagram, etc.)
2. The share extension captures the shared content automatically
3. The app processes the shared URL and extracts event information
4. Users can review and save the imported event to their collection

## Firebase Integration

EventEase uses Firebase for authentication, data storage, and cloud services.

### Required Firebase Services

1. **Firebase Authentication**
   - Email/Password authentication
   - Google Sign-In
   - Apple Sign-In
   - Facebook Login

2. **Cloud Firestore**
   - User profiles and preferences
   - Event data storage
   - Collections and metadata
   - Generated plans history

3. **Firebase Storage**
   - Event images and media files

4. **Firebase Cloud Messaging**
   - Push notifications for event reminders

5. **Firebase App Check**
   - App integrity verification

### Setup Instructions

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android and iOS apps to your Firebase project
3. Download configuration files:
   - `google-services.json` → `client/android/app/`
   - `GoogleService-Info.plist` → `client/ios/Runner/`
4. Enable required services in Firebase Console:
   - Authentication (Email/Password, Google, Apple, Facebook)
   - Cloud Firestore
   - Firebase Storage
   - Cloud Messaging
5. Deploy Firestore security rules:
   ```bash
   cd client
   firebase deploy --only firestore:rules
   ```

### Configuration Files

- **Android**: `client/android/app/google-services.json`
- **iOS**: `client/ios/Runner/GoogleService-Info.plist`
- **Flutter**: `client/lib/firebase_options.dart` (auto-generated)

### Troubleshooting

**Permission Issues:**
- Ensure Firestore security rules are deployed
- Verify collection paths match between code and rules
- Confirm user authentication before accessing protected data

**Build Errors:**
- Verify `google-services.json` and `GoogleService-Info.plist` are in correct locations
- Check that package names/bundle IDs match Firebase project configuration
- Run `flutter clean` and rebuild after updating Firebase config

## Platform Support

- ✅ **Android** (API 24+)
- ✅ **iOS** (iOS 12.0+)
- ✅ **Responsive Design** (Mobile, Tablet, Desktop)

## Requirements

- Flutter SDK 3.7.0 or higher
- Dart 3.7.0 or higher
- Node.js 18+ (for backend server)
- Firebase project with required services enabled
- RapidAPI account (for social media integration)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Version History

See [RELEASE_NOTES.md](RELEASE_NOTES.md) for detailed version history and changelog.
