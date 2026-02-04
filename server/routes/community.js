/**
 * Community Routes (EventEase)
 *
 * Public endpoint (auth required) to discover user-shared events from the community.
 * Adapted from RecipEase's community.js for events.
 *
 * Firestore collection: "events" (where isDiscoverable === true)
 */

const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const { getFirestore } = require("firebase-admin/firestore");
const errorHandler = require("../utils/errorHandler");

const db = getFirestore();

// Get community events (user-shared events from other users)
router.get("/events", auth, async (req, res) => {
    try {
        const { query, category, random } = req.query;
        const page = parseInt(req.query.page) || 1;
        const limitParam = parseInt(req.query.limit);
        const limit = isNaN(limitParam) ? 12 : Math.min(limitParam, 500);
        const isRandom = random === 'true';
        const currentUserId = req.user.uid;

        // Build Firestore query - community events (isDiscoverable === true, not current user's)
        let eventsRef = db.collection("events")
            .where("isDiscoverable", "==", true);

        // Aggregate tokens from query and category
        const gatherTokens = (input) => {
            if (!input || typeof input !== 'string') return [];
            return input
                .toLowerCase()
                .split(',')
                .map((s) => s.trim().replace(/\s+/g, ' '))
                .filter((s) => s.length > 0);
        };

        // Generate both hyphen and space variations of a phrase
        const generateVariations = (phrase) => {
            const variations = new Set([phrase]);
            const spaceVersion = phrase.replace(/-/g, ' ');
            if (spaceVersion !== phrase) variations.add(spaceVersion);
            const hyphenVersion = phrase.replace(/\s+/g, '-');
            if (hyphenVersion !== phrase) variations.add(hyphenVersion);
            return Array.from(variations);
        };

        let phraseTokens = [];
        phraseTokens = phraseTokens.concat(gatherTokens(query));
        phraseTokens = phraseTokens.concat(gatherTokens(category));

        // Build final tokens list
        let tokens = [];
        const addedTokens = new Set();

        // Add each phrase exactly once
        for (const phrase of phraseTokens) {
            if (tokens.length >= 10) break;
            if (!addedTokens.has(phrase)) {
                tokens.push(phrase);
                addedTokens.add(phrase);
            }
        }

        // Add hyphen/space variations
        for (const phrase of phraseTokens) {
            if (tokens.length >= 10) break;
            const hyphenVersion = phrase.replace(/\s+/g, "-");
            if (hyphenVersion !== phrase && !addedTokens.has(hyphenVersion) && tokens.length < 10) {
                tokens.push(hyphenVersion);
                addedTokens.add(hyphenVersion);
            }
            if (tokens.length >= 10) break;
            const spaceVersion = phrase.replace(/-/g, " ");
            if (spaceVersion !== phrase && !addedTokens.has(spaceVersion) && tokens.length < 10) {
                tokens.push(spaceVersion);
                addedTokens.add(spaceVersion);
            }
        }

        // Optionally add individual words
        if (tokens.length < 10) {
            for (const phrase of phraseTokens) {
                if (tokens.length >= 10) break;
                const words = phrase.split(/[\s-]+/).filter((w) => w.length > 0);
                for (const word of words) {
                    if (tokens.length >= 10) break;
                    if (word.length > 2 && !addedTokens.has(word)) {
                        tokens.push(word);
                        addedTokens.add(word);
                    }
                }
            }
        }

        if (tokens.length > 10) {
            console.warn(
                `array-contains-any supports up to 10 values; capped to 10 (had ${tokens.length})`
            );
            tokens = tokens.slice(0, 10);
        }

        // Apply search tokens if available
        if (tokens.length > 0) {
            eventsRef = eventsRef.where(
                "searchableFields",
                "array-contains-any",
                tokens
            );
        }

        // Get total count for pagination
        const totalQuery = await eventsRef.count().get();
        const totalEvents = totalQuery.data().count;

        // Calculate pagination offsets
        const startAt = (page - 1) * limit;

        // Fetch events
        let snapshot;
        try {
            if (isRandom) {
                if (limit === 1) {
                    const dailyPoolSize = Math.min(500, totalEvents);
                    snapshot = await eventsRef.limit(dailyPoolSize).get();
                } else {
                    // For random mode, fetch all to maximize results after filtering
                    snapshot = await eventsRef.limit(500).get();
                }
            } else {
                snapshot = await eventsRef
                    .orderBy("createdAt", "desc")
                    .offset(startAt)
                    .limit(limit)
                    .get();
            }
        } catch (e) {
            // Fallback if ordering fails
            snapshot = await eventsRef.limit(limit).get();
        }

        let events = [];
        snapshot.forEach((doc) => {
            const data = doc.data();
            // Exclude current user's events and non-discoverable events
            if (data.userId !== currentUserId && data.isDiscoverable !== false) {
                events.push({
                    id: doc.id,
                    ...data,
                });
            }
        });

        // Random selection if requested
        if (isRandom && events.length > 0) {
            if (limit === 1) {
                // "Event of the Day" mode - pick one random event
                const randomIndex = Math.floor(Math.random() * events.length);
                events = [events[randomIndex]];
            } else {
                // Shuffle and slice
                for (let i = events.length - 1; i > 0; i--) {
                    const j = Math.floor(Math.random() * (i + 1));
                    [events[i], events[j]] = [events[j], events[i]];
                }
                events = events.slice(0, limit);
            }
        }

        const totalPages = Math.ceil(totalEvents / limit);

        res.json({
            events,
            pagination: {
                total: totalEvents,
                page,
                limit,
                totalPages,
                hasNextPage: page < totalPages,
                hasPrevPage: page > 1,
            },
        });
    } catch (error) {
        console.error("Error fetching community events:", error);
        errorHandler.serverError(res, "Failed to fetch community events");
    }
});

// Get a single community event by ID (public view)
router.get("/events/:id", auth, async (req, res) => {
    try {
        const { id } = req.params;

        const eventDoc = await db.collection("events").doc(id).get();

        if (!eventDoc.exists) {
            return errorHandler.notFound(res, "Event not found");
        }

        const eventData = eventDoc.data();

        // Only allow viewing if event is discoverable
        if (!eventData.isDiscoverable) {
            return errorHandler.notFound(res, "Event not found");
        }

        res.json({
            id: eventDoc.id,
            ...eventData,
        });
    } catch (error) {
        console.error("Error fetching community event:", error);
        errorHandler.serverError(res, "Failed to fetch event");
    }
});

module.exports = router;
