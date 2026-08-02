/**
 * Places Cache Cron Jobs (EventEase)
 *
 * Scheduled tasks to maintain the Places cache:
 * 1. Extract venues from events and cache their details
 * 2. Pre-populate popular search terms
 * 3. Clean up stale cache entries
 *
 * Schedule: Runs daily at 3 AM
 */

const cron = require("node-cron");
const axios = require("axios");
const { getFirestore } = require("firebase-admin/firestore");

const db = getFirestore();
const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY;

// Popular search terms to pre-cache
const POPULAR_SEARCHES = [
    "concert hall",
    "stadium",
    "theater",
    "arena",
    "convention center",
    "music venue",
    "nightclub",
    "bar",
    "park",
    "amphitheater",
];

/**
 * Extract unique venues from events and cache their geocoded data
 */
async function cacheVenuesFromEvents() {
    console.log("🗺️  [Cron] Starting venue cache refresh...");

    try {
        // Get all discover events with venue info
        const eventsSnap = await db
            .collection("discoverEvents")
            .where("venueName", "!=", "")
            .limit(500)
            .get();

        const venueMap = new Map();

        // Group events by venue
        eventsSnap.docs.forEach((doc) => {
            const event = doc.data();
            const venueName = event.venueName?.trim();
            if (!venueName) return;

            const key = `${venueName}|${event.city || ""}`.toLowerCase();

            if (!venueMap.has(key)) {
                venueMap.set(key, {
                    name: venueName,
                    city: event.city || "",
                    region: event.region || "",
                    address: event.address || "",
                    latitude: event.latitude,
                    longitude: event.longitude,
                    eventCount: 1,
                });
            } else {
                venueMap.get(key).eventCount++;
                // Prefer coordinates from events that have them
                if (event.latitude && event.longitude && !venueMap.get(key).latitude) {
                    venueMap.get(key).latitude = event.latitude;
                    venueMap.get(key).longitude = event.longitude;
                }
            }
        });

        console.log(`🗺️  [Cron] Found ${venueMap.size} unique venues`);

        // Cache each venue
        let cached = 0;
        let geocoded = 0;

        for (const [key, venue] of venueMap) {
            const docId = key.replace(/[/\\#[\]*]/g, "_").substring(0, 100);
            const venueRef = db.collection("venueCache").doc(docId);

            // Check if venue needs geocoding
            if (!venue.latitude || !venue.longitude) {
                if (GOOGLE_MAPS_API_KEY && venue.address) {
                    try {
                        const address = `${venue.name}, ${venue.address}, ${venue.city}`;
                        const response = await axios.get(
                            "https://maps.googleapis.com/maps/api/geocode/json",
                            {
                                params: { address, key: GOOGLE_MAPS_API_KEY },
                            }
                        );

                        if (response.data.status === "OK" && response.data.results?.length) {
                            const loc = response.data.results[0].geometry.location;
                            venue.latitude = loc.lat;
                            venue.longitude = loc.lng;
                            geocoded++;
                        }

                        // Rate limit: wait 100ms between geocode requests
                        await new Promise((r) => setTimeout(r, 100));
                    } catch (e) {
                        console.warn(`Geocode failed for ${venue.name}:`, e.message);
                    }
                }
            }

            // Save to cache
            await venueRef.set({
                ...venue,
                cityLower: venue.city.toLowerCase(),
                popularity: venue.eventCount,
                cachedAt: new Date(),
            });
            cached++;
        }

        console.log(`✅ [Cron] Cached ${cached} venues, geocoded ${geocoded} new locations`);
        return { cached, geocoded };
    } catch (e) {
        console.error("❌ [Cron] Venue cache error:", e.message);
        return { error: e.message };
    }
}

/**
 * Pre-cache popular search terms
 */
async function preCachePopularSearches() {
    if (!GOOGLE_MAPS_API_KEY) {
        console.log("⚠️  [Cron] Skipping search pre-cache: No API key");
        return { skipped: true };
    }

    console.log("🔍 [Cron] Pre-caching popular searches...");

    let cached = 0;

    for (const term of POPULAR_SEARCHES) {
        const cacheKey = term.toLowerCase().replace(/\s+/g, "_");
        const cacheRef = db.collection("placesCache").doc(`autocomplete_${cacheKey}`);

        try {
            // Check if already cached recently
            const existing = await cacheRef.get();
            if (existing.exists) {
                const age = Date.now() - (existing.data().cachedAt?.toMillis?.() || 0);
                if (age < 24 * 60 * 60 * 1000) {
                    // Already fresh
                    continue;
                }
            }

            // Fetch from Google
            const response = await axios.get(
                "https://maps.googleapis.com/maps/api/place/autocomplete/json",
                {
                    params: {
                        input: term,
                        key: GOOGLE_MAPS_API_KEY,
                        types: "establishment",
                    },
                }
            );

            if (response.data.status === "OK") {
                const predictions = (response.data.predictions || []).map((p) => ({
                    placeId: p.place_id,
                    description: p.description,
                    mainText: p.structured_formatting?.main_text || "",
                    secondaryText: p.structured_formatting?.secondary_text || "",
                    types: p.types || [],
                }));

                await cacheRef.set({
                    query: term,
                    predictions,
                    cachedAt: new Date(),
                    source: "cron_precache",
                });
                cached++;
            }

            // Rate limit
            await new Promise((r) => setTimeout(r, 200));
        } catch (e) {
            console.warn(`Pre-cache failed for "${term}":`, e.message);
        }
    }

    console.log(`✅ [Cron] Pre-cached ${cached} popular searches`);
    return { cached };
}

/**
 * Clean up stale cache entries
 */
async function cleanupStaleCache() {
    console.log("🧹 [Cron] Cleaning up stale cache...");

    const staleThreshold = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000); // 30 days

    try {
        // Clean autocomplete cache
        const staleAutocomplete = await db
            .collection("placesCache")
            .where("cachedAt", "<", staleThreshold)
            .limit(100)
            .get();

        let deleted = 0;
        const batch = db.batch();

        staleAutocomplete.docs.forEach((doc) => {
            batch.delete(doc.ref);
            deleted++;
        });

        if (deleted > 0) {
            await batch.commit();
        }

        console.log(`✅ [Cron] Cleaned up ${deleted} stale cache entries`);
        return { deleted };
    } catch (e) {
        console.error("❌ [Cron] Cleanup error:", e.message);
        return { error: e.message };
    }
}

/**
 * Initialize cron job
 * Runs daily at 3 AM server time
 */
function initPlacesCacheCron() {
    // Run at 3:00 AM every day
    cron.schedule("0 3 * * *", async () => {
        console.log("📅 [Cron] Running daily places cache refresh...");

        await cacheVenuesFromEvents();
        await preCachePopularSearches();
        await cleanupStaleCache();

        console.log("✅ [Cron] Daily places cache refresh complete");
    });

    console.log("📅 [Cron] Places cache cron job scheduled (daily at 3 AM)");
}

/**
 * Manual trigger for testing
 */
async function runManualRefresh() {
    console.log("🔄 [Manual] Running places cache refresh...");

    const results = {
        venues: await cacheVenuesFromEvents(),
        searches: await preCachePopularSearches(),
        cleanup: await cleanupStaleCache(),
    };

    console.log("✅ [Manual] Refresh complete:", results);
    return results;
}

module.exports = {
    initPlacesCacheCron,
    runManualRefresh,
    cacheVenuesFromEvents,
    preCachePopularSearches,
    cleanupStaleCache,
};
