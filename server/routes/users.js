const express = require("express");
const router = express.Router();
const { getFirestore } = require("firebase-admin/firestore");
const auth = require("../middleware/auth");

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


