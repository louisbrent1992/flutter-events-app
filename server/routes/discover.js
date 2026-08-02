/**
 * Discover Routes (EventEase)
 *
 * Public endpoint (no auth) to support guest mode Discover.
 *
 * Backing store:
 * - Firestore collection: "discoverEvents"
 *
 * Notes:
 * - Firestore has limited full-text search. This MVP fetches a bounded set of
 *   recent docs and performs filtering in-memory for query/category/date/city.
 * - Later phases can replace this with Algolia/Meilisearch or Firestore
 *   composite indexes + prefix search.
 */

const express = require("express");
const router = express.Router();
const { getFirestore } = require("firebase-admin/firestore");
const errorHandler = require("../utils/errorHandler");

const db = getFirestore();

function safeLower(v) {
  return (v || "").toString().toLowerCase();
}

function toIsoOrNull(v) {
  if (!v) return null;
  if (typeof v === "string") return v;
  try {
    return new Date(v).toISOString();
  } catch (_) {
    return null;
  }
}

function parseDateQuery(v) {
  if (!v) return null;
  const d = new Date(v);
  if (Number.isNaN(d.getTime())) return null;
  return d;
}

const { fetchSeatgeekEvents } = require("../utils/seatgeekAPI");

// GET /api/discover
router.get("/discover", async (req, res) => {
  try {
    const page = Math.max(1, Number.parseInt(req.query.page || "1", 10));
    const limit = Math.min(50, Math.max(1, Number.parseInt(req.query.limit || "20", 10)));

    const q = (req.query.q || req.query.query || "").toString().trim();
    const category = (req.query.category || "").toString().trim();
    const city = (req.query.city || "").toString().trim();
    const region = (req.query.region || "").toString().trim();
    const from = parseDateQuery(req.query.from);
    const to = parseDateQuery(req.query.to);

    // 1. Fetch internal events from Firestore
    // Fetch a bounded set of recent discover events (MVP).
    // Keep this reasonably small to avoid expensive scans.
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

    const rawInternal = snap.docs.map((d) => ({
      id: d.id,
      source: "internal",
      ...d.data()
    }));

    // 2. Fetch external events from SeatGeek
    const sgEvents = await fetchSeatgeekEvents({
      keyword: q,
      city: city,
      category: category


    });

    // 3. Filter Internal Events
    const qLower = safeLower(q);
    const categoryLower = safeLower(category);
    const cityLower = safeLower(city);
    const regionLower = safeLower(region);

    const filteredInternal = rawInternal.filter((e) => {
      // Allow soft-disable.
      if (e && e.isDiscoverable === false) return false;

      // Date window.
      const startAt = e?.startAt ? new Date(e.startAt) : null;
      if (from && startAt && startAt < from) return false;
      if (to && startAt && startAt > to) return false;

      // Category filter.
      if (categoryLower) {
        const categories = Array.isArray(e?.categories) ? e.categories : [];
        const hasCategory = categories.some((c) => safeLower(c) === categoryLower);
        if (!hasCategory) return false;
      }

      // Location filters.
      if (cityLower && safeLower(e?.city) !== cityLower) return false;
      if (regionLower && safeLower(e?.region) !== regionLower) return false;

      // Query filter (substring search across a few fields).
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

    // 4. Combine and Sort
    // We combine: filtered internal + external API results

    let allEvents = [
      ...filteredInternal,
      ...sgEvents
    ];

    // Deduplicate logic
    const seenIds = new Set();
    allEvents = allEvents.filter(e => {
      if (seenIds.has(e.id)) return false;
      seenIds.add(e.id);
      return true;
    });

    // Sort by Date (Ascending: soonest first)
    allEvents.sort((a, b) => {
      const dateA = a.startAt ? new Date(a.startAt).getTime() : 0;
      const dateB = b.startAt ? new Date(b.startAt).getTime() : 0;
      // If date is missing/invalid, push to end
      if (!dateA) return 1;
      if (!dateB) return -1;
      return dateA - dateB;
    });

    const total = allEvents.length;
    const totalPages = Math.max(1, Math.ceil(total / limit));
    const hasNextPage = page < totalPages;
    const hasPrevPage = page > 1;

    const offset = (page - 1) * limit;
    const events = allEvents.slice(offset, offset + limit).map((e) => ({
      ...e,
      startAt: toIsoOrNull(e.startAt),
      endAt: toIsoOrNull(e.endAt),
      createdAt: toIsoOrNull(e.createdAt),
      updatedAt: toIsoOrNull(e.updatedAt),
    }));

    return res.json({
      events,
      pagination: {
        page,
        limit,
        total,
        totalPages,
        hasNextPage,
        hasPrevPage,
        sources: {
          internal: filteredInternal.length,
          seatgeek: sgEvents.length
        }
      },
    });
  } catch (e) {
    console.error("Error listing discover events:", e);
    return errorHandler.serverError(res, "Failed to load discover events.");
  }
});

module.exports = router;

