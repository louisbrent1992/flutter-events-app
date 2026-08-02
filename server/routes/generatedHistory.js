/**
 * Generated History Routes (EventEase)
 *
 * Stores AI planner outputs per user so users can revisit/regenerate.
 *
 * Auth required.
 *
 * Firestore:
 * - generatedPlans/{id}
 *   - userId, kind, title, input, output, createdAt, updatedAt
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

// List generated plans (paged)
router.get("/plans", auth, async (req, res) => {
  try {
    const userId = req.user.uid;
    const page = Math.max(1, Number.parseInt(req.query.page || "1", 10));
    const limit = Math.min(50, Math.max(1, Number.parseInt(req.query.limit || "20", 10)));

    const snap = await db
      .collection("generatedPlans")
      .where("userId", "==", userId)
      .orderBy("createdAt", "desc")
      .limit(500)
      .get();

    const all = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const total = all.length;
    const totalPages = Math.max(1, Math.ceil(total / limit));
    const offset = (page - 1) * limit;

    const items = all.slice(offset, offset + limit).map((p) => ({
      id: p.id,
      kind: p.kind || "itinerary",
      title: p.title || "AI Plan",
      createdAt: p.createdAt || null,
      updatedAt: p.updatedAt || null,
      input: p.input || null,
    }));

    return res.json({
      plans: items,
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
    console.error("Error listing generated plans:", e);
    return errorHandler.serverError(res, "Failed to load generated history.");
  }
});

// Create (persist) a generated plan
router.post("/plans", auth, async (req, res) => {
  try {
    const userId = req.user.uid;
    const body = req.body || {};
    const kind = (body.kind || "itinerary").toString();
    const input = body.input || {};
    const output = body.output || {};

    const title =
      (body.title || output?.title || "AI Plan").toString().trim() || "AI Plan";

    const createdAt = nowIso();
    const updatedAt = createdAt;
    const doc = await db.collection("generatedPlans").add({
      userId,
      kind,
      title,
      input,
      output,
      createdAt,
      updatedAt,
    });

    return res.json({
      plan: { id: doc.id, userId, kind, title, input, output, createdAt, updatedAt },
    });
  } catch (e) {
    console.error("Error creating generated plan:", e);
    return errorHandler.serverError(res, "Failed to save generated plan.");
  }
});

// Get detail
router.get("/plans/:id", auth, async (req, res) => {
  try {
    const userId = req.user.uid;
    const id = req.params.id;
    const ref = db.collection("generatedPlans").doc(id);
    const doc = await ref.get();
    if (!doc.exists) return errorHandler.notFound(res, "Plan not found");
    const data = doc.data() || {};
    if (data.userId !== userId) return errorHandler.forbidden(res, "Access denied");
    return res.json({ plan: { id: doc.id, ...data } });
  } catch (e) {
    console.error("Error fetching generated plan:", e);
    return errorHandler.serverError(res, "Failed to load plan.");
  }
});

// Delete (optional)
router.delete("/plans/:id", auth, async (req, res) => {
  try {
    const userId = req.user.uid;
    const id = req.params.id;
    const ref = db.collection("generatedPlans").doc(id);
    const doc = await ref.get();
    if (!doc.exists) return errorHandler.notFound(res, "Plan not found");
    const data = doc.data() || {};
    if (data.userId !== userId) return errorHandler.forbidden(res, "Access denied");
    await ref.delete();
    return res.json({ success: true });
  } catch (e) {
    console.error("Error deleting generated plan:", e);
    return errorHandler.serverError(res, "Failed to delete plan.");
  }
});

module.exports = router;

