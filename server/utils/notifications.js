/**
 * Notifications Utility (EventEase)
 *
 * FCM push notification utilities adapted from RecipEase's notifications.js
 *
 * Sends milestone notifications when events reach certain engagement thresholds.
 */

const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore } = require("firebase-admin/firestore");

const db = getFirestore();

// Milestone thresholds for different metrics
const MILESTONES = {
    saves: [10, 50, 100, 500, 1000, 5000, 10000],
    shares: [10, 50, 100, 500, 1000],
    comments: [10, 50, 100, 500, 1000],
};

/**
 * Check if a count matches a milestone threshold
 * @param {number} count - The current count
 * @param {string} metricType - 'saves', 'shares', or 'comments'
 * @returns {boolean} - Whether the count matches a milestone
 */
function isMilestone(count, metricType) {
    const thresholds = MILESTONES[metricType];
    if (!thresholds) return false;
    return thresholds.includes(count);
}

/**
 * Get the notification message for a milestone
 * @param {string} eventTitle - Title of the event
 * @param {string} metricType - 'saves', 'shares', or 'comments'
 * @param {number} count - The milestone count
 * @returns {object} - { title, body } for the notification
 */
function getMilestoneMessage(eventTitle, metricType, count) {
    const truncatedTitle = eventTitle.length > 30
        ? eventTitle.substring(0, 27) + '...'
        : eventTitle;

    switch (metricType) {
        case 'saves':
            return {
                title: '📥 People are saving your event!',
                body: `${count} people saved your "${truncatedTitle}" event!`,
            };
        case 'shares':
            return {
                title: '🔗 Your event is being shared!',
                body: `Your "${truncatedTitle}" event was shared ${count} times!`,
            };
        case 'comments':
            return {
                title: '💬 Your event is getting attention!',
                body: `Your "${truncatedTitle}" event has ${count} comments!`,
            };
        default:
            return {
                title: '🎉 Event milestone reached!',
                body: `Your "${truncatedTitle}" event reached ${count} ${metricType}!`,
            };
    }
}

/**
 * Check if a milestone was reached and send a push notification to the event owner
 * @param {string} eventOwnerId - The user ID of the event owner
 * @param {string} eventId - The event ID
 * @param {string} eventTitle - The event title
 * @param {string} metricType - 'saves', 'shares', or 'comments'
 * @param {number} newCount - The new count after increment
 */
async function checkAndSendMilestoneNotification(
    eventOwnerId,
    eventId,
    eventTitle,
    metricType,
    newCount
) {
    try {
        // Check if this count is a milestone
        if (!isMilestone(newCount, metricType)) {
            return;
        }

        console.log(`🎯 Milestone reached: ${eventTitle} hit ${newCount} ${metricType}`);

        // Get the event owner's FCM token
        const userDoc = await db.collection("users").doc(eventOwnerId).get();
        if (!userDoc.exists) {
            console.log(`⚠️ User ${eventOwnerId} not found, skipping notification`);
            return;
        }

        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        if (!fcmToken) {
            console.log(`⚠️ No FCM token for user ${eventOwnerId}, skipping notification`);
            return;
        }

        // Get the notification message
        const { title, body } = getMilestoneMessage(eventTitle, metricType, newCount);

        // Send the push notification
        const message = {
            token: fcmToken,
            notification: {
                title,
                body,
            },
            data: {
                route: '/eventDetail',
                eventId: eventId,
                type: 'milestone',
                metricType: metricType,
                count: String(newCount),
            },
            android: {
                notification: {
                    channelId: 'event_milestones',
                    priority: 'high',
                    icon: 'ic_notification',
                },
            },
            apns: {
                payload: {
                    aps: {
                        badge: 1,
                        sound: 'default',
                    },
                },
            },
        };

        const response = await getMessaging().send(message);
        console.log(`✅ Milestone notification sent: ${response}`);

    } catch (error) {
        // Log error but don't throw - notification failures shouldn't break the main flow
        console.error(`❌ Error sending milestone notification:`, error.message || error);
    }
}

module.exports = {
    checkAndSendMilestoneNotification,
    isMilestone,
    getMilestoneMessage,
    MILESTONES,
};
