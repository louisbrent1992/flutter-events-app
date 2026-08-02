/**
 * Test Notification Script
 *
 * Sends a test push notification to a user's device (EventEase).
 *
 * Usage:
 *   node scripts/send-test-notification.js --userId <userId>
 *   node scripts/send-test-notification.js --token <fcmToken>
 *   node scripts/send-test-notification.js --userId <userId> --title "Custom Title" --body "Custom Body"
 *   node scripts/send-test-notification.js --userId <userId> --type upcomingEvents
 *
 * Options:
 *   --userId <userId>        User ID to send notification to (looks up FCM token)
 *   --token <fcmToken>        FCM token to send notification to directly
 *   --title <title>           Custom notification title (optional)
 *   --body <body>             Custom notification body (optional)
 *   --route <route>           Route to navigate to (default: /home)
 *   --eventId <eventId>       Event ID for event detail route (optional)
 *   --type <type>             Notification type: upcomingEvents, aiPlanner
 */

const admin = require('firebase-admin');
require('dotenv').config();

// Initialize Firebase Admin
const { initFirebase } = require('../config/firebase.js');
initFirebase();

const { getMessaging } = require('firebase-admin/messaging');
const { getFirestore } = require('firebase-admin/firestore');
const db = getFirestore();

// Notification type configurations
const NOTIFICATION_TYPES = {
  upcomingEvents: {
    title: 'What’s coming up 📅',
    body: 'See your upcoming events and set reminders.',
    route: '/myEvents',
    args: {},
  },
  aiPlanner: {
    title: 'Plan your next outing ✨',
    body: 'Try the AI planner to generate an itinerary.',
    route: '/planner',
    args: {},
  },
};

// Parse command line arguments
function parseArgs() {
  const args = {};
  for (let i = 0; i < process.argv.length; i++) {
    if (process.argv[i].startsWith('--')) {
      const key = process.argv[i].substring(2);
      const value = process.argv[i + 1];
      if (value && !value.startsWith('--')) {
        args[key] = value;
        i++;
      } else {
        args[key] = true;
      }
    }
  }
  return args;
}

async function getFcmToken(userId) {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new Error(`User ${userId} not found`);
    }
    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;
    if (!fcmToken) {
      throw new Error(`No FCM token found for user ${userId}`);
    }
    return fcmToken;
  } catch (error) {
    console.error(`❌ Error getting FCM token:`, error.message);
    throw error;
  }
}

async function sendNotification(args) {
  try {
    // Get FCM token
    let fcmToken;
    if (args.token) {
      fcmToken = args.token;
      console.log(`📱 Using provided FCM token: ${fcmToken.substring(0, 20)}...`);
    } else if (args.userId) {
      console.log(`👤 Looking up FCM token for user: ${args.userId}`);
      fcmToken = await getFcmToken(args.userId);
      console.log(`✅ Found FCM token: ${fcmToken.substring(0, 20)}...`);
    } else {
      throw new Error('Either --userId or --token must be provided');
    }

    // Determine notification content
    let title, body, route, notificationData = {};

    if (args.type && NOTIFICATION_TYPES[args.type]) {
      // Use predefined notification type
      const typeConfig = NOTIFICATION_TYPES[args.type];
      title = typeConfig.title;
      body = typeConfig.body;
      route = typeConfig.route;
      notificationData = { ...typeConfig.args };
    } else {
      // Use custom or default values
      title = args.title || 'Test Notification 🔔';
      body = args.body || 'This is a test notification from the terminal';
      route = args.route || '/home';
      if (args.eventId) {
        notificationData.eventId = args.eventId;
      }
    }

    // Build data payload
    const data = {
      route: route,
      ...notificationData,
    };

    // Convert data values to strings (FCM requirement)
    const stringData = {};
    for (const [key, value] of Object.entries(data)) {
      stringData[key] = String(value);
    }

    // Create notification message
    const message = {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data: stringData,
      android: {
        notification: {
          channelId: 'eventease_general',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: 'default',
            alert: {
              title,
              body,
            },
          },
        },
      },
    };

    console.log(`\n📤 Sending notification...`);
    console.log(`   Title: ${title}`);
    console.log(`   Body: ${body}`);
    console.log(`   Route: ${route}`);
    if (Object.keys(notificationData).length > 0) {
      console.log(`   Data: ${JSON.stringify(notificationData)}`);
    }

    const response = await getMessaging().send(message);
    console.log(`\n✅ Notification sent successfully!`);
    console.log(`   Message ID: ${response}\n`);

  } catch (error) {
    console.error(`\n❌ Error sending notification:`, error.message || error);
    if (error.code === 'messaging/invalid-registration-token') {
      console.error(`   The FCM token is invalid. Make sure the app is running and has registered for notifications.`);
    } else if (error.code === 'messaging/registration-token-not-registered') {
      console.error(`   The FCM token is not registered. The user may have uninstalled the app.`);
    }
    process.exit(1);
  }
}

// Main execution
async function main() {
  const args = parseArgs();

  if (args.help || (!args.userId && !args.token)) {
    console.log(`
Usage:
  node scripts/send-test-notification.js --userId <userId>
  node scripts/send-test-notification.js --token <fcmToken>
  node scripts/send-test-notification.js --userId <userId> --title "Custom Title" --body "Custom Body"
  node scripts/send-test-notification.js --userId <userId> --type upcomingEvents
  node scripts/send-test-notification.js --userId <userId> --route /eventDetail --eventId <eventId>

Options:
  --userId <userId>        User ID to send notification to (looks up FCM token)
  --token <fcmToken>       FCM token to send notification to directly
  --title <title>          Custom notification title (optional)
  --body <body>            Custom notification body (optional)
  --route <route>          Route to navigate to (default: /home)
  --eventId <eventId>      Event ID for event detail route (optional)
  --type <type>            Notification type: upcomingEvents, aiPlanner
  --help                   Show this help message

Examples:
  # Send to user by ID
  node scripts/send-test-notification.js --userId abc123

  # Send custom notification
  node scripts/send-test-notification.js --userId abc123 --title "Hello" --body "World"

  # Send an upcoming events notification
  node scripts/send-test-notification.js --userId abc123 --type upcomingEvents

  # Send to event detail
  node scripts/send-test-notification.js --userId abc123 --route /eventDetail --eventId event123

  # Send directly to FCM token
  node scripts/send-test-notification.js --token "your-fcm-token-here"
`);
    process.exit(0);
  }

  await sendNotification(args);
}

main();
