/**
 * Comments Routes (EventEase)
 *
 * Comments system for events, adapted from RecipEase's comments.js
 *
 * Firestore collection: "comments"
 */

const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const errorHandler = require("../utils/errorHandler");

const db = getFirestore();

// Get all comments posted by the current user
// NOTE: This route MUST be defined before /:eventId to avoid "user" being interpreted as an eventId
router.get("/user", auth, async (req, res) => {
    try {
        const userId = req.user.uid;

        const commentsRef = db.collection("comments");
        const snapshot = await commentsRef
            .where("userId", "==", userId)
            .orderBy("createdAt", "desc")
            .limit(100)
            .get();

        const comments = [];
        for (const doc of snapshot.docs) {
            const data = doc.data();

            // Try to fetch event title and image for context
            let eventTitle = null;
            let eventImageUrl = null;
            if (data.eventId) {
                try {
                    const eventDoc = await db.collection("events").doc(data.eventId).get();
                    if (eventDoc.exists) {
                        const eventData = eventDoc.data();
                        eventTitle = eventData.title || null;
                        eventImageUrl = eventData.imageUrl || null;
                    }
                } catch (e) {
                    // Ignore errors fetching event data
                }
            }

            comments.push({
                id: doc.id,
                ...data,
                eventTitle,
                eventImageUrl,
                createdAt: data.createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
            });
        }

        res.json({
            success: true,
            data: comments,
        });
    } catch (error) {
        console.error("Error fetching user comments:", error);
        errorHandler.serverError(res, "Failed to fetch user comments");
    }
});

// Get comments for a specific event (public - guests can view)
router.get("/:eventId", async (req, res) => {
    try {
        const { eventId } = req.params;
        const { limit } = req.query;
        const limitVal = parseInt(limit) || 50;

        const commentsRef = db.collection("comments");
        const snapshot = await commentsRef
            .where("eventId", "==", eventId)
            .orderBy("createdAt", "desc")
            .limit(limitVal)
            .get();

        const comments = [];
        snapshot.forEach((doc) => {
            const data = doc.data();
            comments.push({
                id: doc.id,
                ...data,
                createdAt: data.createdAt?.toDate?.()?.toISOString() || new Date().toISOString(),
            });
        });

        res.json({
            success: true,
            data: comments,
        });
    } catch (error) {
        console.error("Error fetching comments:", error);
        errorHandler.serverError(res, "Failed to fetch comments");
    }
});

// Add a new comment
router.post("/", auth, async (req, res) => {
    try {
        const { eventId, text } = req.body;
        const user = req.user;

        if (!eventId || !text) {
            return res.status(400).json({
                success: false,
                message: "Event ID and text are required",
            });
        }

        // Get user details (avatar might have changed since token issuance)
        const userDoc = await db.collection("users").doc(user.uid).get();
        const userData = userDoc.exists ? userDoc.data() : {};

        const newComment = {
            eventId,
            userId: user.uid,
            username: userData.displayName || user.name || "User",
            userAvatarUrl: userData.photoURL || user.picture || null,
            text: text.trim(),
            createdAt: FieldValue.serverTimestamp(),
        };

        const batch = db.batch();
        const commentRef = db.collection("comments").doc();
        const eventRef = db.collection("events").doc(eventId);

        batch.set(commentRef, newComment);
        batch.update(eventRef, {
            commentCount: FieldValue.increment(1),
        });

        await batch.commit();

        // Return the created comment
        res.status(201).json({
            success: true,
            data: {
                id: commentRef.id,
                ...newComment,
                createdAt: new Date().toISOString(),
            },
        });
    } catch (error) {
        console.error("Error adding comment:", error);
        errorHandler.serverError(res, "Failed to add comment");
    }
});

// Delete a comment (owner only)
router.delete("/:commentId", auth, async (req, res) => {
    try {
        const { commentId } = req.params;
        const userId = req.user.uid;

        const commentRef = db.collection("comments").doc(commentId);
        const commentDoc = await commentRef.get();

        if (!commentDoc.exists) {
            return errorHandler.notFound(res, "Comment not found");
        }

        const commentData = commentDoc.data();

        // Check if user owns the comment
        if (commentData.userId !== userId) {
            return errorHandler.forbidden(res, "You can only delete your own comments");
        }

        const batch = db.batch();
        batch.delete(commentRef);

        // Decrement comment count on the event
        if (commentData.eventId) {
            const eventRef = db.collection("events").doc(commentData.eventId);
            batch.update(eventRef, {
                commentCount: FieldValue.increment(-1),
            });
        }

        await batch.commit();

        res.json({
            success: true,
            message: "Comment deleted successfully",
        });
    } catch (error) {
        console.error("Error deleting comment:", error);
        errorHandler.serverError(res, "Failed to delete comment");
    }
});

module.exports = router;
