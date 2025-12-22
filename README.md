# <img src="client/assets/icons/logo.png" alt="EventEase Logo" width="32" height="32" style="vertical-align:middle; margin-right:8px;"> EventEase App

A mobile application that allows users to discover, plan, and manage events. Import events from social media, generate AI-powered event plans, and keep track of your schedule.

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

**Purpose:** This app is designed for event enthusiasts, planners, and anyone looking to discover and manage events. It leverages AI to help plan events and provides a platform for importing, organizing, and tracking events from various sources.

## Core Features

### A. AI-Powered Event Planning

- Generate personalized event plans using AI
- Customize event details, timing, and activities
- Smart suggestions based on event type and preferences

### B. Event Management

- CRUD operations for personal event collections
- Categorization and organization of events
- Calendar integration and scheduling
- Search and filter functionality

### C. Social Media Event Import

- Deep linking to handle shared event content
- Parsing engine to extract event details from social media posts
- Import from Instagram, TikTok, YouTube, and web URLs
- Validation and editing of imported event data

## Technology Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Node.js with Express
- **Database:** In-memory storage (for demo purposes)
- **AI Integration:** External AI service (e.g., OpenAI)
- **State Management:** Provider
- **External APIs:** RocketAPI for Instagram content

## Getting Started

To get started with the EventEase App, follow these steps:

1. Clone the repository:

   ```bash
   git clone https://github.com/louisbrent1992/flutter-events-app.git
   cd flutter-events-app
   ```

2. Navigate to the client directory and install dependencies:

   ```bash
   cd client
   flutter pub get
   ```

3. Run the app:

   ```bash
   flutter run
   ```

4. For the backend, navigate to the server directory and install dependencies:

   ```bash
   cd server
   npm install
   ```

5. Set up environment variables:

   In the `server/` folder, copy `env.example` to `.env` and fill in the required API keys.

6. Start the server:

   ```bash
   npm run dev
   ```

## Social Media Integration

This app integrates with Instagram, TikTok, and YouTube to extract event information. To set up the integration:

1. Sign up for a RapidAPI key at [RapidAPI](https://rapidapi.com/)
2. Subscribe to the [RocketAPI for Developers](https://rapidapi.com/rocketapi-rocketapi-default/api/rocketapi-for-developers/)
3. Add your API key to the `.env` file as `RAPID_API_KEY`

The integration allows the app to:

- Extract event details from social media posts
- Retrieve images and metadata from posts
- Process content with AI to identify event information
- Create event entries with metadata from social media

## Screenshots

![Home Screen](client/assets/screenshots/home_screen.png)

---

![AI Planner Screen](client/assets/screenshots/ai_recipe_screen.png)

---

![Event List Screen](client/assets/screenshots/recipe_list_screen.png)

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

The app uses Firebase for authentication and data storage:

### Setup Instructions
1. Create a Firebase project at https://console.firebase.google.com/
2. Enable Authentication (Email/Password and Google sign-in)
3. Enable Cloud Firestore
4. Deploy security rules: `firebase deploy --only firestore`

### Troubleshooting
If you encounter permissions issues:
- Ensure Firestore security rules are deployed
- Verify collection paths match between code and rules
- Confirm user authentication before accessing protected data

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
