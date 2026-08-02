const express = require("express");
const router = express.Router();
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const auth = require("../middleware/auth");
const { checkAndSendMilestoneNotification } = require("../utils/notifications");

// Firestore
const db = getFirestore();

// Get user profile
router.get("/profile", auth, async (req, res) => {
	try {
		const userDoc = await db.collection("users").doc(req.user.uid).get();
		if (!userDoc.exists) {
			return res.status(404).json({ error: "User not found" });
		}
		res.json(userDoc.data());
	} catch (error) {
		console.error("Error fetching user profile:", error);
		const errorHandler = require("../utils/errorHandler");
		errorHandler.serverError(
			res,
			"We couldn't load your profile right now. Please try again shortly."
		);
	}
});

// Update user profile
router.put("/profile", auth, async (req, res) => {
	try {
		const { displayName, email, photoURL } = req.body || {};
		await db.collection("users").doc(req.user.uid).set(
			{
				displayName: displayName ?? null,
				email: email ?? null,
				photoURL: photoURL ?? null,
				updatedAt: new Date().toISOString(),
			},
			{ merge: true }
		);
		res.json({ message: "Profile updated successfully" });
	} catch (error) {
		console.error("Error updating user profile:", error);
		const errorHandler = require("../utils/errorHandler");
		errorHandler.serverError(
			res,
			"We couldn't update your profile right now. Please try again shortly."
		);
	}
});

// Register FCM token for push notifications
router.post("/notifications/token", auth, async (req, res) => {
	try {
		const { token } = req.body;
		if (!token) {
			return res.status(400).json({ error: "FCM token is required" });
		}

		await db.collection("users").doc(req.user.uid).set(
			{
				fcmToken: token,
				fcmTokenUpdatedAt: new Date().toISOString(),
			},
			{ merge: true }
		);

		res.json({ success: true, message: "FCM token registered" });
	} catch (error) {
		console.error("Error registering FCM token:", error);
		const errorHandler = require("../utils/errorHandler");
		errorHandler.serverError(res, "Failed to register notification token");
	}
});

// Get user notification preferences
router.get("/preferences", auth, async (req, res) => {
	try {
		const userDoc = await db.collection("users").doc(req.user.uid).get();
		const data = userDoc.exists ? userDoc.data() : {};

		// Return preferences with defaults
		res.json({
			preferences: {
				pushNotifications: data.pushNotifications ?? true,
				eventReminders: data.eventReminders ?? true,
				communityUpdates: data.communityUpdates ?? true,
				milestoneAlerts: data.milestoneAlerts ?? true,
			},
		});
	} catch (error) {
		console.error("Error fetching preferences:", error);
		const errorHandler = require("../utils/errorHandler");
		errorHandler.serverError(res, "Failed to fetch preferences");
	}
});

// Save user notification preferences
router.post("/preferences", auth, async (req, res) => {
	try {
		const { pushNotifications, eventReminders, communityUpdates, milestoneAlerts } = req.body;

		const updates = {
			updatedAt: new Date().toISOString(),
		};

		if (pushNotifications !== undefined) updates.pushNotifications = pushNotifications;
		if (eventReminders !== undefined) updates.eventReminders = eventReminders;
		if (communityUpdates !== undefined) updates.communityUpdates = communityUpdates;
		if (milestoneAlerts !== undefined) updates.milestoneAlerts = milestoneAlerts;

		await db.collection("users").doc(req.user.uid).set(updates, { merge: true });

		res.json({ success: true, message: "Preferences updated" });
	} catch (error) {
		console.error("Error saving preferences:", error);
		const errorHandler = require("../utils/errorHandler");
		errorHandler.serverError(res, "Failed to save preferences");
	}
});

// Get all events for a user with pagination
router.get("/events", auth, async (req, res) => {
	try {
		const userId = req.user.uid;
		const page = parseInt(req.query.page) || 1;
		const limit = parseInt(req.query.limit) || 10;
		const startAt = (page - 1) * limit;

		const eventsRef = db.collection("events");
		const snapshot = await eventsRef
			.where("userId", "==", userId)
			.orderBy("createdAt", "desc")
			.limit(limit)
			.offset(startAt)
			.get();

		const events = [];
		snapshot.forEach((doc) => {
			events.push({
				id: doc.id,
				...doc.data(),
			});
		});

		// Get total count for pagination
		let totalEvents = 0;
		let totalPages = 0;
		let hasNextPage = false;
		let hasPrevPage = page > 1;

		if (page === 1 || events.length === limit) {
			const totalQuery = await eventsRef
				.where("userId", "==", userId)
				.count()
				.get();
			totalEvents = totalQuery.data().count;
			totalPages = Math.ceil(totalEvents / limit);
			hasNextPage = page * limit < totalEvents;
		}

		res.json({
			events,
			pagination: {
				total: totalEvents,
				page,
				limit,
				totalPages,
				hasNextPage,
				hasPrevPage,
			},
		});
	} catch (error) {
		console.error("Error getting user events:", error);
		const errorHandler = require("../utils/errorHandler");
		errorHandler.serverError(
			res,
			"We couldn't load your events right now. Please try again shortly."
		);
	}
});

// Get a specific user event by ID
router.get("/events/:id", auth, async (req, res) => {
	try {
		const userId = req.user.uid;
		const eventId = req.params.id;

		const eventDoc = await db.collection("events").doc(eventId).get();

		if (!eventDoc.exists) {
			return res.status(404).json({ error: "Event not found" });
		}

		const eventData = eventDoc.data();

		if (eventData.userId !== userId) {
			return res
				.status(403)
				.json({ error: "Not authorized to access this event" });
		}

		res.json({
			id: eventDoc.id,
			...eventData,
		});
	} catch (error) {
		console.error("Error getting event:", error);
		const errorHandler = require("../utils/errorHandler");
		errorHandler.serverError(
			res,
			"We couldn't load that event right now. Please try again shortly."
		);
	}
});

// Create a new user event
router.post("/events", auth, async (req, res) => {
	try {
		const userId = req.user.uid;
		const {
			title,
			description = "",
			startAt = null,
			endAt = null,
			venueName = null,
			address = null,
			city = null,
			region = null,
			country = null,
			latitude = null,
			longitude = null,
			ticketUrl = null,
			ticketPrice = null,
			imageUrl = null,
			categories = [],
			sourceUrl = null,
			sourcePlatform = null,
			isDiscoverable = false,
			originalEventId = null,
		} = req.body;

		if (!title) {
			return res.status(400).json({ error: "Title is required" });
		}

		// Check for duplicates by sourceUrl first
		if (sourceUrl) {
			const urlDuplicateQuery = await db.collection("events")
				.where("userId", "==", userId)
				.where("sourceUrl", "==", sourceUrl)
				.limit(1)
				.get();

			if (!urlDuplicateQuery.empty) {
				return res.status(409).json({
					error: true,
					message: "This event already exists in your collection",
					existingEventId: urlDuplicateQuery.docs[0].id
				});
			}
		}

		// Check for duplicates by title
		const duplicateQuery = await db.collection("events")
			.where("userId", "==", userId)
			.where("title", "==", title)
			.limit(1)
			.get();

		if (!duplicateQuery.empty) {
			return res.status(409).json({
				error: true,
				message: "An event with this title already exists",
				existingEventId: duplicateQuery.docs[0].id
			});
		}

		// Generate searchable fields
		const searchableFields = [
			title.toLowerCase(),
			...(categories || []).map((c) => c.toLowerCase()),
			city ? city.toLowerCase() : null,
			venueName ? venueName.toLowerCase() : null,
		].filter((field) => field && field.length > 0);

		const newEvent = {
			userId,
			title,
			description,
			startAt,
			endAt,
			venueName,
			address,
			city,
			region,
			country,
			latitude,
			longitude,
			ticketUrl,
			ticketPrice,
			imageUrl,
			categories: Array.isArray(categories) ? categories : [],
			sourceUrl,
			sourcePlatform,
			isDiscoverable,
			searchableFields,
			createdAt: new Date().toISOString(),
			updatedAt: new Date().toISOString(),
			saveCount: 0,
			shareCount: 0,
			commentCount: 0,
		};

		const docRef = await db.collection("events").add(newEvent);

		// If saving from a community event, track and increment saveCount
		if (originalEventId && originalEventId !== docRef.id) {
			try {
				const originalEventRef = db.collection("events").doc(originalEventId);
				const originalEventDoc = await originalEventRef.get();

				if (originalEventDoc.exists) {
					const originalEventData = originalEventDoc.data();

					// Only increment for community events from other users
					if (originalEventData.isDiscoverable && originalEventData.userId !== userId) {
						const saveRef = db.collection("eventSaves").doc(`${originalEventId}_${userId}`);
						const saveDoc = await saveRef.get();

						if (!saveDoc.exists) {
							let newSaveCount = 0;
							await db.runTransaction(async (transaction) => {
								const currentEvent = await transaction.get(originalEventRef);
								if (!currentEvent.exists) return;

								const currentSaveCount = currentEvent.data().saveCount || 0;
								newSaveCount = currentSaveCount + 1;

								transaction.set(saveRef, {
									eventId: originalEventId,
									userId: userId,
									createdAt: FieldValue.serverTimestamp(),
								});

								transaction.update(originalEventRef, {
									saveCount: newSaveCount,
									updatedAt: FieldValue.serverTimestamp(),
								});
							});

							// Send milestone notification
							checkAndSendMilestoneNotification(
								originalEventData.userId,
								originalEventId,
								originalEventData.title,
								'saves',
								newSaveCount
							);
						}
					}
				}
			} catch (error) {
				console.error("Error tracking event save:", error);
			}
		}

		res.status(201).json({
			id: docRef.id,
			...newEvent,
		});
	} catch (error) {
		console.error("Error creating event:", error);
		const errorHandler = require("../utils/errorHandler");
		errorHandler.serverError(
			res,
			"We couldn't save your event right now. Please try again shortly."
		);
	}
});

// Update a user event
router.put("/events/:id", auth, async (req, res) => {
	try {
		const userId = req.user.uid;
		const eventId = req.params.id;

		const eventRef = db.collection("events").doc(eventId);
		const eventDoc = await eventRef.get();

		if (!eventDoc.exists) {
			return res.status(404).json({ error: "Event not found" });
		}

		const eventData = eventDoc.data();

		if (eventData.userId !== userId) {
			return res
				.status(403)
				.json({ error: "Not authorized to update this event" });
		}

		// Regenerate searchable fields
		const title = req.body.title || eventData.title;
		const categories = req.body.categories || eventData.categories || [];
		const city = req.body.city || eventData.city;
		const venueName = req.body.venueName || eventData.venueName;

		const searchableFields = [
			title.toLowerCase(),
			...categories.map((c) => c.toLowerCase()),
			city ? city.toLowerCase() : null,
			venueName ? venueName.toLowerCase() : null,
		].filter((field) => field && field.length > 0);

		const updates = {
			...req.body,
			userId: eventData.userId,
			searchableFields,
			updatedAt: new Date().toISOString(),
		};

		await eventRef.update(updates);

		const updatedDoc = await eventRef.get();
		res.json({
			id: updatedDoc.id,
			...updatedDoc.data(),
		});
	} catch (error) {
		console.error("Error updating event:", error);
		const errorHandler = require("../utils/errorHandler");
		errorHandler.serverError(
			res,
			"We couldn't update your event right now. Please try again shortly."
		);
	}
});

// Delete a user event
router.delete("/events/:id", auth, async (req, res) => {
	try {
		const userId = req.user.uid;
		const eventId = req.params.id;

		const eventRef = db.collection("events").doc(eventId);
		const eventDoc = await eventRef.get();

		if (!eventDoc.exists) {
			return res.status(404).json({ error: "Event not found" });
		}

		const eventData = eventDoc.data();

		if (eventData.userId !== userId) {
			return res
				.status(403)
				.json({ error: "Not authorized to delete this event" });
		}

		await eventRef.delete();

		res.json({ success: true, message: "Event deleted successfully" });
	} catch (error) {
		console.error("Error deleting event:", error);
		const errorHandler = require("../utils/errorHandler");
		errorHandler.serverError(
			res,
			"We couldn't delete your event right now. Please try again shortly."
		);
	}
});

// Delete user account data (Firestore user doc). Auth deletion is handled client-side.
router.delete("/account", auth, async (req, res) => {
	try {
		const userId = req.user.uid;
		await db.collection("users").doc(userId).delete();
		res.json({ success: true, message: "Account deleted successfully" });
	} catch (error) {
		const errorHandler = require("../utils/errorHandler");
		errorHandler.serverError(
			res,
			"We couldn't delete your account data right now. Please try again shortly."
		);
	}
});

module.exports = router;
