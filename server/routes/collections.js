/**
 * Collections Routes (EventEase)
 *
 * Auth required.
 *
 * Firestore:
 * - collections/{collectionId}
 *   - userId, name, description, createdAt, updatedAt
 * - collections/{collectionId}/items/{eventId}
 *   - eventId, addedAt
 */

const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const { getFirestore } = require("firebase-admin/firestore");
const errorHandler = require("../utils/errorHandler");

const db = getFirestore();

function nowIso() {
  return new Date().toISOString();
}

async function ensureOwnCollection(userId, collectionId) {
  const ref = db.collection("collections").doc(collectionId);
  const doc = await ref.get();
  if (!doc.exists) return { ok: false, status: 404, message: "Collection not found" };
  const data = doc.data();
  if (!data || data.userId !== userId) {
    return { ok: false, status: 403, message: "You do not have access to this collection" };
  }
  return { ok: true, ref, data };
}

// List collections for user
router.get("/", auth, async (req, res) => {
  try {
    const userId = req.user.uid;
    const snap = await db
      .collection("collections")
      .where("userId", "==", userId)
      .orderBy("updatedAt", "desc")
      .get();

    const collections = await Promise.all(
      snap.docs.map(async (d) => {
        const data = d.data() || {};
        let itemCount = 0;
        try {
          const itemsSnap = await db
            .collection("collections")
            .doc(d.id)
            .collection("items")
            .get();
          itemCount = itemsSnap.size;
        } catch (_) {}
        return { id: d.id, ...data, itemCount };
      })
    );

    return res.json({ collections });
  } catch (e) {
    console.error("Error listing collections:", e);
    return errorHandler.serverError(res, "Failed to load collections.");
  }
});

// Create collection
router.post("/", auth, async (req, res) => {
  try {
    const userId = req.user.uid;
    const body = req.body || {};
    const name = (body.name || "Untitled").toString().trim();
    const description = (body.description || "").toString().trim();

    const doc = await db.collection("collections").add({
      userId,
      name,
      description,
      createdAt: nowIso(),
      updatedAt: nowIso(),
    });

    return res.json({
      collection: { id: doc.id, userId, name, description, createdAt: nowIso(), updatedAt: nowIso(), itemCount: 0 },
    });
  } catch (e) {
    console.error("Error creating collection:", e);
    return errorHandler.serverError(res, "Failed to create collection.");
  }
});

// Get collection + items (events)
router.get("/:id", auth, async (req, res) => {
  try {
    const userId = req.user.uid;
    const collectionId = req.params.id;
    const own = await ensureOwnCollection(userId, collectionId);
    if (!own.ok) {
      if (own.status === 404) return errorHandler.notFound(res, own.message);
      return errorHandler.forbidden(res, own.message);
    }

    const itemsSnap = await own.ref.collection("items").orderBy("addedAt", "desc").get();
    const eventIds = itemsSnap.docs.map((d) => d.id);

    const events = [];
    for (const eventId of eventIds) {
      const evDoc = await db.collection("events").doc(eventId).get();
      if (!evDoc.exists) continue;
      const ev = evDoc.data();
      if (!ev || ev.userId !== userId) continue;
      events.push({ id: evDoc.id, ...ev });
    }

    return res.json({
      collection: { id: collectionId, ...own.data, itemCount: eventIds.length },
      events,
    });
  } catch (e) {
    console.error("Error fetching collection:", e);
    return errorHandler.serverError(res, "Failed to load collection.");
  }
});

// Update collection
router.put("/:id", auth, async (req, res) => {
  try {
    const userId = req.user.uid;
    const collectionId = req.params.id;
    const own = await ensureOwnCollection(userId, collectionId);
    if (!own.ok) {
      if (own.status === 404) return errorHandler.notFound(res, own.message);
      return errorHandler.forbidden(res, own.message);
    }

    const body = req.body || {};
    const patch = {};
    if (body.name !== undefined) patch.name = body.name.toString().trim();
    if (body.description !== undefined) patch.description = body.description.toString().trim();
    patch.updatedAt = nowIso();

    await own.ref.update(patch);
    const updated = { ...own.data, ...patch };

    return res.json({ collection: { id: collectionId, ...updated } });
  } catch (e) {
    console.error("Error updating collection:", e);
    return errorHandler.serverError(res, "Failed to update collection.");
  }
});

// Delete collection
router.delete("/:id", auth, async (req, res) => {
  try {
    const userId = req.user.uid;
    const collectionId = req.params.id;
    const own = await ensureOwnCollection(userId, collectionId);
    if (!own.ok) {
      if (own.status === 404) return errorHandler.notFound(res, own.message);
      return errorHandler.forbidden(res, own.message);
    }

    // Delete items subcollection docs
    const itemsSnap = await own.ref.collection("items").get();
    await Promise.all(itemsSnap.docs.map((d) => d.ref.delete()));
    await own.ref.delete();

    return res.json({ success: true });
  } catch (e) {
    console.error("Error deleting collection:", e);
    return errorHandler.serverError(res, "Failed to delete collection.");
  }
});

// Add event to collection
router.post("/:id/items", auth, async (req, res) => {
  try {
    const userId = req.user.uid;
    const collectionId = req.params.id;
    const own = await ensureOwnCollection(userId, collectionId);
    if (!own.ok) {
      if (own.status === 404) return errorHandler.notFound(res, own.message);
      return errorHandler.forbidden(res, own.message);
    }

    const body = req.body || {};
    const eventId = (body.eventId || "").toString().trim();
    if (!eventId) return errorHandler.badRequest(res, "eventId is required");

    // Ensure the event belongs to the user
    const evDoc = await db.collection("events").doc(eventId).get();
    if (!evDoc.exists) return errorHandler.notFound(res, "Event not found");
    const ev = evDoc.data();
    if (!ev || ev.userId !== userId) {
      return errorHandler.forbidden(res, "You do not have access to this event");
    }

    await own.ref.collection("items").doc(eventId).set({
      eventId,
      addedAt: nowIso(),
    });
    await own.ref.update({ updatedAt: nowIso() });

    return res.json({ success: true });
  } catch (e) {
    console.error("Error adding event to collection:", e);
    return errorHandler.serverError(res, "Failed to add event to collection.");
  }
});

// Remove event from collection
router.delete("/:id/items/:eventId", auth, async (req, res) => {
  try {
    const userId = req.user.uid;
    const collectionId = req.params.id;
    const eventId = req.params.eventId;
    const own = await ensureOwnCollection(userId, collectionId);
    if (!own.ok) {
      if (own.status === 404) return errorHandler.notFound(res, own.message);
      return errorHandler.forbidden(res, own.message);
    }

    await own.ref.collection("items").doc(eventId).delete();
    await own.ref.update({ updatedAt: nowIso() });
    return res.json({ success: true });
  } catch (e) {
    console.error("Error removing event from collection:", e);
    return errorHandler.serverError(res, "Failed to remove event from collection.");
  }
});

module.exports = router;

