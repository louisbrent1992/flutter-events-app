/**
 * Random suggestion (EventEase)
 *
 * Public endpoint that returns a random discoverable event.
 * Backed by Firestore collection: "discoverEvents"
 *
 * GET /api/random
 * Optional query params: q, category, city, region, from, to
 */

const express = require("express");
const router = express.Router();
const { getFirestore } = require("firebase-admin/firestore");
const errorHandler = require("../utils/errorHandler");

const db = getFirestore();

function safeLower(v) {
  return (v || "").toString().toLowerCase();
}

function parseDateQuery(v) {
  if (!v) return null;
  const d = new Date(v);
  if (Number.isNaN(d.getTime())) return null;
  return d;
}

// GET /api/random
router.get("/random", async (req, res) => {
  try {
    const q = (req.query.q || req.query.query || "").toString().trim();
    const category = (req.query.category || "").toString().trim();
    const city = (req.query.city || "").toString().trim();
    const region = (req.query.region || "").toString().trim();
    const from = parseDateQuery(req.query.from);
    const to = parseDateQuery(req.query.to);

    const MAX_SCAN = 400;

    let snap;
    try {
      snap = await db
        .collection("discoverEvents")
        .orderBy("startAt", "desc")
        .limit(MAX_SCAN)
        .get();
    } catch (_) {
      snap = await db
        .collection("discoverEvents")
        .orderBy("createdAt", "desc")
        .limit(MAX_SCAN)
        .get();
    }

    const raw = snap.docs.map((d) => ({ id: d.id, ...d.data() }));

    const qLower = safeLower(q);
    const categoryLower = safeLower(category);
    const cityLower = safeLower(city);
    const regionLower = safeLower(region);

    const filtered = raw.filter((e) => {
      if (e && e.isDiscoverable === false) return false;
      const startAt = e?.startAt ? new Date(e.startAt) : null;
      if (from && startAt && startAt < from) return false;
      if (to && startAt && startAt > to) return false;
      if (categoryLower) {
        const categories = Array.isArray(e?.categories) ? e.categories : [];
        const hasCategory = categories.some((c) => safeLower(c) === categoryLower);
        if (!hasCategory) return false;
      }
      if (cityLower && safeLower(e?.city) !== cityLower) return false;
      if (regionLower && safeLower(e?.region) !== regionLower) return false;
      if (qLower) {
        const hay = [
          e?.title,
          e?.description,
          e?.venueName,
          e?.city,
          e?.region,
          e?.address,
        ]
          .map(safeLower)
          .join(" ");
        if (!hay.includes(qLower)) return false;
      }
      return true;
    });

    if (!filtered.length) {
      return res.json({ event: null });
    }

    const picked = filtered[Math.floor(Math.random() * filtered.length)];
    return res.json({ event: picked });
  } catch (e) {
    console.error("Error generating random event:", e);
    return errorHandler.serverError(res, "Failed to load random suggestion.");
  }
});

module.exports = router;

