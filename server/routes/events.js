/**
 * Events Routes (EventEase)
 *
 * Auth required.
 * Stores per-user events in Firestore collection: "events"
 */

const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const { getFirestore } = require("firebase-admin/firestore");
const errorHandler = require("../utils/errorHandler");

const db = getFirestore();

function toIsoOrNull(v) {
	if (!v) return null;
	if (typeof v === "string") return v;
	try {
		return new Date(v).toISOString();
	} catch (_) {
		return null;
	}
}

// List user events (paginated)
router.get("/", auth, async (req, res) => {
	try {
		const userId = req.user.uid;
		const page = Math.max(1, Number.parseInt(req.query.page || "1", 10));
		const limit = Math.min(50, Math.max(1, Number.parseInt(req.query.limit || "20", 10)));

		// Firestore pagination: use offset for simplicity (ok for small lists)
		const offset = (page - 1) * limit;

		const baseQuery = db.collection("events").where("userId", "==", userId);

		const totalSnap = await baseQuery.get();
		const total = totalSnap.size;
		const totalPages = Math.max(1, Math.ceil(total / limit));

		const snap = await baseQuery
			.orderBy("startAt", "desc")
			.orderBy("createdAt", "desc")
			.offset(offset)
			.limit(limit)
			.get();

		const events = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
		return res.json({
			events,
			pagination: {
				page,
				limit,
				total,
				totalPages,
				hasNextPage: page < totalPages,
				hasPrevPage: page > 1,
			},
		});
	} catch (e) {
		console.error("Error listing events:", e);
		return errorHandler.serverError(res, "Failed to load events.");
	}
});

// Get single event
router.get("/:id", auth, async (req, res) => {
	try {
		const userId = req.user.uid;
		const id = req.params.id;
		const ref = db.collection("events").doc(id);
		const doc = await ref.get();
		if (!doc.exists) return errorHandler.notFound(res, "Event not found");
		const data = doc.data();
		if (!data || data.userId !== userId) {
			return errorHandler.forbidden(res, "You do not have access to this event");
		}
		return res.json({ id: doc.id, ...data });
	} catch (e) {
		console.error("Error fetching event:", e);
		return errorHandler.serverError(res, "Failed to load event.");
	}
});

// Create event
router.post("/", auth, async (req, res) => {
	try {
		const userId = req.user.uid;
		const body = req.body || {};

		const event = {
			userId,
			title: (body.title || "Untitled Event").toString(),
			description: (body.description || "").toString(),
			startAt: toIsoOrNull(body.startAt),
			endAt: toIsoOrNull(body.endAt),
			venueName: body.venueName ? body.venueName.toString() : null,
			address: body.address ? body.address.toString() : null,
			city: body.city ? body.city.toString() : null,
			region: body.region ? body.region.toString() : null,
			country: body.country ? body.country.toString() : null,
			latitude:
				body.latitude === null || body.latitude === undefined
					? null
					: Number(body.latitude),
			longitude:
				body.longitude === null || body.longitude === undefined
					? null
					: Number(body.longitude),
			ticketUrl: body.ticketUrl ? body.ticketUrl.toString() : null,
			ticketPrice: body.ticketPrice ? body.ticketPrice.toString() : null,
			imageUrl: body.imageUrl ? body.imageUrl.toString() : null,
			sourceUrl: body.sourceUrl ? body.sourceUrl.toString() : null,
			sourcePlatform: body.sourcePlatform ? body.sourcePlatform.toString() : null,
			categories: Array.isArray(body.categories)
				? body.categories.map((c) => c.toString()).filter(Boolean)
				: [],
			createdAt: new Date().toISOString(),
			updatedAt: new Date().toISOString(),
		};

		const docRef = await db.collection("events").add(event);
		return res.status(201).json({ id: docRef.id, ...event });
	} catch (e) {
		console.error("Error creating event:", e);
		return errorHandler.serverError(res, "Failed to create event.");
	}
});

// Update event
router.put("/:id", auth, async (req, res) => {
	try {
		const userId = req.user.uid;
		const id = req.params.id;
		const ref = db.collection("events").doc(id);
		const doc = await ref.get();
		if (!doc.exists) return errorHandler.notFound(res, "Event not found");
		const existing = doc.data();
		if (!existing || existing.userId !== userId) {
			return errorHandler.forbidden(res, "You do not have access to this event");
		}

		const body = req.body || {};
		const patch = {
			title: body.title !== undefined ? body.title.toString() : existing.title,
			description:
				body.description !== undefined ? body.description.toString() : existing.description,
			startAt: body.startAt !== undefined ? toIsoOrNull(body.startAt) : existing.startAt ?? null,
			endAt: body.endAt !== undefined ? toIsoOrNull(body.endAt) : existing.endAt ?? null,
			venueName: body.venueName !== undefined ? (body.venueName ? body.venueName.toString() : null) : existing.venueName ?? null,
			address: body.address !== undefined ? (body.address ? body.address.toString() : null) : existing.address ?? null,
			city: body.city !== undefined ? (body.city ? body.city.toString() : null) : existing.city ?? null,
			region: body.region !== undefined ? (body.region ? body.region.toString() : null) : existing.region ?? null,
			country: body.country !== undefined ? (body.country ? body.country.toString() : null) : existing.country ?? null,
			latitude:
				body.latitude !== undefined
					? body.latitude === null
						? null
						: Number(body.latitude)
					: existing.latitude ?? null,
			longitude:
				body.longitude !== undefined
					? body.longitude === null
						? null
						: Number(body.longitude)
					: existing.longitude ?? null,
			ticketUrl: body.ticketUrl !== undefined ? (body.ticketUrl ? body.ticketUrl.toString() : null) : existing.ticketUrl ?? null,
			ticketPrice: body.ticketPrice !== undefined ? (body.ticketPrice ? body.ticketPrice.toString() : null) : existing.ticketPrice ?? null,
			imageUrl: body.imageUrl !== undefined ? (body.imageUrl ? body.imageUrl.toString() : null) : existing.imageUrl ?? null,
			sourceUrl: body.sourceUrl !== undefined ? (body.sourceUrl ? body.sourceUrl.toString() : null) : existing.sourceUrl ?? null,
			sourcePlatform: body.sourcePlatform !== undefined ? (body.sourcePlatform ? body.sourcePlatform.toString() : null) : existing.sourcePlatform ?? null,
			categories: Array.isArray(body.categories)
				? body.categories.map((c) => c.toString()).filter(Boolean)
				: existing.categories ?? [],
			updatedAt: new Date().toISOString(),
		};

		await ref.update(patch);
		return res.json({ id, ...existing, ...patch });
	} catch (e) {
		console.error("Error updating event:", e);
		return errorHandler.serverError(res, "Failed to update event.");
	}
});

// Delete event
router.delete("/:id", auth, async (req, res) => {
	try {
		const userId = req.user.uid;
		const id = req.params.id;
		const ref = db.collection("events").doc(id);
		const doc = await ref.get();
		if (!doc.exists) return errorHandler.notFound(res, "Event not found");
		const existing = doc.data();
		if (!existing || existing.userId !== userId) {
			return errorHandler.forbidden(res, "You do not have access to this event");
		}
		await ref.delete();
		return res.json({ success: true });
	} catch (e) {
		console.error("Error deleting event:", e);
		return errorHandler.serverError(res, "Failed to delete event.");
	}
});

module.exports = router;


