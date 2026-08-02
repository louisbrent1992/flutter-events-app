/**
 * Places Cache Routes (EventEase)
 *
 * Server-side caching for Google Places API to reduce costs.
 *
 * Strategy:
 * - Cache place autocomplete results for popular searches
 * - Cache place details for venues
 * - Cron job refreshes cache periodically
 * - Client queries server first, only falls back to live API if needed
 *
 * Cost savings:
 * - Places Autocomplete: $2.83/1000 sessions → cached = near zero
 * - Place Details: $17/1000 requests → cached = near zero
 */

const express = require("express");
const router = express.Router();
const axios = require("axios");
const { getFirestore } = require("firebase-admin/firestore");
const errorHandler = require("../utils/errorHandler");

const db = getFirestore();

// Google Maps API key from environment
const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY;

// Cache TTL settings
const AUTOCOMPLETE_CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours
const PLACE_DETAILS_CACHE_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 days
const VENUE_CACHE_TTL_MS = 30 * 24 * 60 * 60 * 1000; // 30 days

/**
 * GET /api/places/autocomplete
 *
 * Search for places with caching.
 * Checks Firestore cache first, then falls back to Google API.
 */
router.get("/autocomplete", async (req, res) => {
    try {
        const input = (req.query.input || req.query.q || "").toString().trim();

        if (!input || input.length < 2) {
            return res.json({ predictions: [], cached: false });
        }

        const cacheKey = input.toLowerCase();

        // 1. Check cache first
        const cacheRef = db.collection("placesCache").doc(`autocomplete_${cacheKey.replace(/[/\\]/g, "_")}`);
        const cacheDoc = await cacheRef.get();

        if (cacheDoc.exists) {
            const cached = cacheDoc.data();
            const age = Date.now() - (cached.cachedAt?.toMillis?.() || 0);

            if (age < AUTOCOMPLETE_CACHE_TTL_MS) {
                // Cache hit - return cached data
                return res.json({
                    predictions: cached.predictions || [],
                    cached: true,
                    cacheAge: Math.round(age / 1000 / 60), // minutes
                });
            }
        }

        // 2. Cache miss or expired - call Google API
        if (!GOOGLE_MAPS_API_KEY) {
            console.warn("GOOGLE_MAPS_API_KEY not configured");
            return res.json({ predictions: [], cached: false, error: "API not configured" });
        }

        const response = await axios.get(
            "https://maps.googleapis.com/maps/api/place/autocomplete/json",
            {
                params: {
                    input,
                    key: GOOGLE_MAPS_API_KEY,
                    types: "establishment|geocode",
                },
            }
        );

        if (response.data.status !== "OK" && response.data.status !== "ZERO_RESULTS") {
            console.error("Places API error:", response.data.status);
            return res.json({ predictions: [], cached: false });
        }

        const predictions = (response.data.predictions || []).map((p) => ({
            placeId: p.place_id,
            description: p.description,
            mainText: p.structured_formatting?.main_text || "",
            secondaryText: p.structured_formatting?.secondary_text || "",
            types: p.types || [],
        }));

        // 3. Cache the result
        await cacheRef.set({
            query: input,
            predictions,
            cachedAt: new Date(),
            source: "google_places_api",
        });

        return res.json({
            predictions,
            cached: false,
        });
    } catch (e) {
        console.error("Places autocomplete error:", e.message);
        return errorHandler.serverError(res, "Failed to search places.");
    }
});

/**
 * GET /api/places/details/:placeId
 *
 * Get place details with caching.
 */
router.get("/details/:placeId", async (req, res) => {
    try {
        const { placeId } = req.params;

        if (!placeId) {
            return errorHandler.badRequest(res, "Place ID required");
        }

        // 1. Check cache first
        const cacheRef = db.collection("placesCache").doc(`details_${placeId}`);
        const cacheDoc = await cacheRef.get();

        if (cacheDoc.exists) {
            const cached = cacheDoc.data();
            const age = Date.now() - (cached.cachedAt?.toMillis?.() || 0);

            if (age < PLACE_DETAILS_CACHE_TTL_MS) {
                return res.json({
                    place: cached.place,
                    cached: true,
                    cacheAge: Math.round(age / 1000 / 60 / 60), // hours
                });
            }
        }

        // 2. Cache miss - call Google API
        if (!GOOGLE_MAPS_API_KEY) {
            return res.json({ place: null, cached: false, error: "API not configured" });
        }

        const response = await axios.get(
            "https://maps.googleapis.com/maps/api/place/details/json",
            {
                params: {
                    place_id: placeId,
                    key: GOOGLE_MAPS_API_KEY,
                    fields: "name,formatted_address,geometry,types,rating,photos,opening_hours",
                },
            }
        );

        if (response.data.status !== "OK") {
            console.error("Place details API error:", response.data.status);
            return res.json({ place: null, cached: false });
        }

        const result = response.data.result;
        const place = {
            placeId,
            name: result.name,
            formattedAddress: result.formatted_address,
            latitude: result.geometry?.location?.lat,
            longitude: result.geometry?.location?.lng,
            rating: result.rating,
            types: result.types || [],
            photoReferences: (result.photos || []).slice(0, 3).map((p) => p.photo_reference),
        };

        // 3. Cache the result
        await cacheRef.set({
            place,
            cachedAt: new Date(),
            source: "google_places_api",
        });

        return res.json({
            place,
            cached: false,
        });
    } catch (e) {
        console.error("Place details error:", e.message);
        return errorHandler.serverError(res, "Failed to get place details.");
    }
});

/**
 * GET /api/places/venues
 *
 * Get cached venue data for known event venues.
 * This is pre-populated by the cron job from event data.
 */
router.get("/venues", async (req, res) => {
    try {
        const city = (req.query.city || "").toString().trim().toLowerCase();
        const limit = Math.min(100, Math.max(1, parseInt(req.query.limit || "50", 10)));

        let query = db.collection("venueCache").orderBy("popularity", "desc").limit(limit);

        if (city) {
            query = db
                .collection("venueCache")
                .where("cityLower", "==", city)
                .orderBy("popularity", "desc")
                .limit(limit);
        }

        const snap = await query.get();
        const venues = snap.docs.map((doc) => ({
            id: doc.id,
            ...doc.data(),
        }));

        return res.json({
            venues,
            total: venues.length,
        });
    } catch (e) {
        console.error("Venues fetch error:", e.message);
        return errorHandler.serverError(res, "Failed to get venues.");
    }
});

/**
 * POST /api/places/geocode
 *
 * Geocode an address with caching.
 * Only used for events that don't have coordinates.
 */
router.post("/geocode", async (req, res) => {
    try {
        const { address } = req.body;

        if (!address || address.trim().length < 5) {
            return errorHandler.badRequest(res, "Address required");
        }

        const cacheKey = address.toLowerCase().trim().replace(/\s+/g, "_").substring(0, 100);

        // 1. Check cache
        const cacheRef = db.collection("geocodeCache").doc(cacheKey);
        const cacheDoc = await cacheRef.get();

        if (cacheDoc.exists) {
            const cached = cacheDoc.data();
            return res.json({
                latitude: cached.latitude,
                longitude: cached.longitude,
                formattedAddress: cached.formattedAddress,
                cached: true,
            });
        }

        // 2. Cache miss - call Google API
        if (!GOOGLE_MAPS_API_KEY) {
            return res.json({ latitude: null, longitude: null, cached: false, error: "API not configured" });
        }

        const response = await axios.get(
            "https://maps.googleapis.com/maps/api/geocode/json",
            {
                params: {
                    address,
                    key: GOOGLE_MAPS_API_KEY,
                },
            }
        );

        if (response.data.status !== "OK" || !response.data.results?.length) {
            return res.json({ latitude: null, longitude: null, cached: false });
        }

        const result = response.data.results[0];
        const location = {
            latitude: result.geometry.location.lat,
            longitude: result.geometry.location.lng,
            formattedAddress: result.formatted_address,
        };

        // 3. Cache the result
        await cacheRef.set({
            ...location,
            originalAddress: address,
            cachedAt: new Date(),
        });

        return res.json({
            ...location,
            cached: false,
        });
    } catch (e) {
        console.error("Geocode error:", e.message);
        return errorHandler.serverError(res, "Failed to geocode address.");
    }
});

/**
 * GET /api/places/stats
 *
 * Get cache statistics for monitoring.
 */
router.get("/stats", async (req, res) => {
    try {
        const [autocomplete, details, geocode, venues] = await Promise.all([
            db.collection("placesCache").where("query", "!=", "").count().get(),
            db.collection("placesCache").where("place", "!=", null).count().get(),
            db.collection("geocodeCache").count().get(),
            db.collection("venueCache").count().get(),
        ]);

        return res.json({
            cache: {
                autocompleteEntries: autocomplete.data().count,
                placeDetailsEntries: details.data().count,
                geocodeEntries: geocode.data().count,
                venueEntries: venues.data().count,
            },
            ttl: {
                autocompleteHours: AUTOCOMPLETE_CACHE_TTL_MS / 1000 / 60 / 60,
                placeDetailsDays: PLACE_DETAILS_CACHE_TTL_MS / 1000 / 60 / 60 / 24,
                venueDays: VENUE_CACHE_TTL_MS / 1000 / 60 / 60 / 24,
            },
        });
    } catch (e) {
        console.error("Stats error:", e.message);
        return res.json({ cache: {}, error: "Failed to get stats" });
    }
});

/**
 * POST /api/places/refresh
 *
 * Manually trigger cache refresh (for admin/testing).
 */
router.post("/refresh", async (req, res) => {
    try {
        const { runManualRefresh } = require("../utils/placesCacheCron");
        const results = await runManualRefresh();
        return res.json({ success: true, results });
    } catch (e) {
        console.error("Manual refresh error:", e.message);
        return errorHandler.serverError(res, "Failed to refresh cache.");
    }
});

module.exports = router;
