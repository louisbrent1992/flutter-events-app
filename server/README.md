# EventEase Server

**Version 1.0.1**

Node.js/Express backend server for EventEase, providing REST API endpoints for event management, AI-powered planning, social media integration, and Firebase data operations.

## 🚀 Overview

The EventEase server handles:
- Event CRUD operations via Firebase Firestore
- AI-powered event planning using OpenAI
- Social media content extraction (Instagram, TikTok, YouTube)
- User authentication and authorization
- Event discovery and search
- Data deletion requests (GDPR compliance)

## 📋 Prerequisites

- **Node.js**: 16.0.0 or higher
- **npm**: Comes with Node.js
- **Firebase Project**: With Firestore enabled
- **Firebase Service Account**: JSON key file for admin SDK
- **OpenAI API Key**: For AI-powered features
- **RapidAPI Key** (optional): For Instagram/TikTok integration
- **YouTube API Key** (optional): For YouTube integration

## 🛠️ Setup

### 1. Install Dependencies

```bash
cd server
npm install
```

### 2. Configure Environment Variables

Copy the example environment file and fill in your values:

```bash
cp env.example .env
```

Edit `.env` with your configuration:

```env
# Runtime
NODE_ENV=production
PORT=8080

# Firebase Admin (required)
FIREBASE_SERVICE_ACCOUNT=<your-service-account-json-or-base64>

# OpenAI (required for AI features)
OPENAI_API_KEY=<your-openai-api-key>

# Optional: Social Media APIs
RAPID_API_KEY=<your-rapidapi-key>
YOUTUBE_API_KEY=<your-youtube-api-key>

# Optional: Email (for data deletion requests)
SMTP_USER=<your-smtp-username>
SMTP_PASS=<your-smtp-password>
```

### 3. Firebase Service Account

You can provide the Firebase service account in two ways:

**Option 1: JSON String**
```env
FIREBASE_SERVICE_ACCOUNT='{"type":"service_account","project_id":"..."}'
```

**Option 2: Base64 Encoded**
```env
FIREBASE_SERVICE_ACCOUNT=<base64-encoded-json>
```

**Option 3: File Path** (for local development)
Place your service account JSON file at:
```
server/config/firebase-service-account.json
```

### 4. Run the Server

**Development mode** (with auto-reload):
```bash
npm run dev
```

**Production mode**:
```bash
npm start
```

The server will start on `http://localhost:8080` (or the port specified in `.env`).

## 📁 Project Structure

```
server/
├── index.js                 # Main server entry point
├── config/
│   └── firebase.js         # Firebase Admin initialization
├── middleware/
│   └── auth.js             # Firebase Auth middleware
├── routes/
│   ├── events.js           # Event CRUD endpoints
│   ├── collections.js      # Event collections
│   ├── discover.js         # Event discovery/search
│   ├── generatedEvents.js  # AI-generated events
│   ├── generatedHistory.js # AI plan history
│   ├── random.js           # Random event endpoint
│   ├── users.js            # User management
│   ├── ui.js               # UI configuration
│   └── data-deletion.js    # GDPR data deletion
├── utils/
│   ├── errorHandler.js     # Error handling middleware
│   ├── instagramAPI.js     # Instagram content extraction
│   ├── tiktokAPI.js        # TikTok content extraction
│   └── youtubeAPI.js       # YouTube content extraction
├── scripts/
│   └── send-test-notification.js  # Test notification script
├── public/
│   ├── index.html          # Server info page
│   ├── data-deletion.html  # GDPR data deletion form
│   └── logo.png            # Server logo
└── package.json            # Dependencies and scripts
```

## 🔌 API Endpoints

### Events

- `GET /api/events` - List user events
- `POST /api/events` - Create new event
- `GET /api/events/:id` - Get event by ID
- `PUT /api/events/:id` - Update event
- `DELETE /api/events/:id` - Delete event

### Collections

- `GET /api/collections` - List user collections
- `POST /api/collections` - Create collection
- `GET /api/collections/:id` - Get collection details
- `PUT /api/collections/:id` - Update collection
- `DELETE /api/collections/:id` - Delete collection

### Discovery

- `GET /api/discover` - Discover events with filters
- `GET /api/random` - Get random event

### AI Planning

- `POST /api/generatedEvents` - Generate AI event plan
- `GET /api/generatedHistory` - Get AI plan history
- `GET /api/generatedHistory/:id` - Get specific plan

### Users

- `GET /api/users/me` - Get current user profile
- `PUT /api/users/me` - Update user profile

### UI Configuration

- `GET /api/ui` - Get UI configuration and feature flags

### Data Deletion (GDPR)

- `POST /api/data-deletion` - Request data deletion

## 🔐 Authentication

All protected endpoints require Firebase Authentication. Include the Firebase ID token in the `Authorization` header:

```
Authorization: Bearer <firebase-id-token>
```

The server validates tokens using Firebase Admin SDK.

## 🧪 Testing

### Send Test Notification

```bash
npm run send-notification
```

This script sends a test push notification to verify Firebase Cloud Messaging setup.

## 🔧 Configuration

### Environment Variables

See `env.example` for all available configuration options:

- **Firebase**: Service account credentials
- **OpenAI**: API key and model configuration
- **Social Media**: RapidAPI, YouTube API keys
- **Email**: SMTP configuration for notifications
- **Server**: Port, environment, public URLs

### Rate Limiting

The server includes rate limiting middleware to prevent abuse. Default limits:
- 100 requests per 15 minutes per IP

### Caching

In-memory caching is implemented for frequently accessed endpoints:
- Cache TTL: 5 minutes
- Automatic cache cleanup

## 🚀 Deployment

### Google Cloud Run

1. Build container:
   ```bash
   gcloud builds submit --tag gcr.io/<project-id>/eventease-server
   ```

2. Deploy:
   ```bash
   gcloud run deploy eventease-server \
     --image gcr.io/<project-id>/eventease-server \
     --platform managed \
     --region us-central1 \
     --set-env-vars NODE_ENV=production
   ```

3. Set secrets:
   ```bash
   gcloud run services update eventease-server \
     --update-secrets FIREBASE_SERVICE_ACCOUNT=firebase-sa:latest,OPENAI_API_KEY=openai-key:latest
   ```

### Docker

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 8080
CMD ["npm", "start"]
```

Build and run:
```bash
docker build -t eventease-server .
docker run -p 8080:8080 --env-file .env eventease-server
```

## 🐛 Troubleshooting

**Firebase Connection Issues:**
- Verify `FIREBASE_SERVICE_ACCOUNT` is correctly formatted
- Check Firebase project permissions
- Ensure Firestore is enabled in Firebase Console

**OpenAI API Errors:**
- Verify `OPENAI_API_KEY` is valid
- Check API rate limits and quotas
- Review model configuration in `.env`

**Port Already in Use:**
```bash
# Change PORT in .env or use different port
PORT=3000 npm start
```

**Module Not Found:**
```bash
# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

## 📚 Dependencies

### Core
- **express**: Web framework
- **firebase-admin**: Firebase Admin SDK
- **openai**: OpenAI API client
- **axios**: HTTP client for external APIs

### Middleware
- **cors**: Cross-origin resource sharing
- **body-parser**: Request body parsing
- **express-rate-limit**: Rate limiting

### Utilities
- **dotenv**: Environment variable management
- **uuid**: Unique ID generation
- **zod**: Schema validation
- **node-cron**: Scheduled tasks
- **nodemailer**: Email sending

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## 🔗 Related Documentation

- Main project README: [../README.md](../README.md)
- Client README: [../client/README.md](../client/README.md)
- Release notes: [../RELEASE_NOTES.md](../RELEASE_NOTES.md)

