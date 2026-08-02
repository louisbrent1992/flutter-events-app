const axios = require("axios");
const { getFirestore } = require("firebase-admin/firestore");
const { upgradeImageUrl } = require("./imageUtils");

// const db = getFirestore(); // Removed: Not used here
const SERPAPI_KEY = process.env.SERPAPI_API_KEY;
const BASE_URL = "https://serpapi.com/search.json";

/**
 * Fetch events from SerpApi Google Events
 * @param {string} query - Search query (e.g., "Events in Austin, TX")
 * @returns {Promise<Array>} - List of mapped events
 */
async function fetchGoogleEvents(query) {
    if (!SERPAPI_KEY) {
        console.warn("SERPAPI_API_KEY is not set.");
        return [];
    }

    try {
        console.log(`🔍 [SerpApi] Fetching events for: "${query}"`);

        const params = {
            engine: "google_events",
            q: query,
            api_key: SERPAPI_KEY,
            hl: "en",
            gl: "us"
        };

        const response = await axios.get(BASE_URL, { params });

        if (!response.data || !response.data.events_results) {
            console.log("⚠️ [SerpApi] No events found for query:", query);
            return [];
        }

        return response.data.events_results.map(mapSerpApiEvent);
    } catch (error) {
        console.error("❌ [SerpApi] Error fetching events:", error.message);
        if (error.response) {
            console.error("   Response data:", error.response.data);
        }
        return [];
    }
}

/**
 * Map SerpApi event to EventEase schema
 */
function mapSerpApiEvent(ev) {
    const venue = ev.venue || {};
    const addressList = ev.address || [];

    // Parse date
    let startAt = null;
    let endAt = null;

    if (ev.date) {
        if (ev.date.start_date) {
            // "Dec 7" isn't a full date, but sometimes they provide specific formatting in 'when'
            // For now, let's try to parse the 'when' string or rely on future parsing if needed.
            // SerpApi often returns a structured date object if available.
            // But usually 'start_date' is just a string.
            // Helper: We typically need a real date object. 
            // If the date is "Today" or "Tomorrow" or "Dec 7", we might need smarter parsing.
            // For this MVP, we will try to use a simple parser or current year.
            startAt = parseSerpApiDate(ev.date.start_date, ev.date.when);
        }
    }



    // Extract image
    let imageUrl = ev.thumbnail;
    if (ev.image) imageUrl = ev.image;

    // Upgrade image quality
    if (imageUrl) {
        imageUrl = upgradeImageUrl(imageUrl);
    }

    // Price
    let ticketPrice = null;
    if (ev.ticket_info && ev.ticket_info.length > 0) {
        // Find the first one with a price or just use the first link
        const withPrice = ev.ticket_info.find(t => t.price);
        if (withPrice) ticketPrice = withPrice.price;
    }

    // Links
    const sourceUrl = ev.link;
    const ticketUrl = ev.ticket_info && ev.ticket_info.length > 0 ? ev.ticket_info[0].link : ev.link;

    // Construct full address
    const fullAddress = addressList.join(", ");
    const city = addressList.length > 1 ? addressList[1].split(',')[0].trim() : ""; // Rough guess

    return {
        title: ev.title,
        description: ev.description || `${ev.title} at ${venue.name || 'Unknown Venue'}`,
        startAt: startAt ? startAt.toISOString() : new Date().toISOString(), // Fallback to now if parsing fails
        endAt: null,
        venueName: venue.name || "Unknown Venue",
        address: fullAddress,
        city: city, // This might need better extraction
        region: "", // Hard to extract reliably without geocoding
        country: "US", // Default for now
        latitude: null, // Google Events results don't always have lat/long directly in the main list
        longitude: null,
        ticketUrl,
        ticketPrice,
        imageUrl,
        sourceUrl,
        sourcePlatform: "google_events",
        categories: ["Events"], // Default category
        isDiscoverable: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        externalId: ev.link // Use link as a rough unique ID
    };
}

/**
 * Simple date parser for common Google Event date formats
 * e.g. "Dec 7", "Today", "Tomorrow", "Fri, Dec 8"
 */
function parseSerpApiDate(startDateStr, whenStr) {
    try {
        const now = new Date();
        const currentYear = now.getFullYear();

        // Combine with current year to make it parseable
        // "Dec 7" -> "Dec 7 2024"
        let dateStr = startDateStr;
        if (dateStr && !dateStr.includes(currentYear.toString())) {
            dateStr = `${dateStr} ${currentYear}`;
        }

        let date = new Date(dateStr);

        // If invalid, try to parse 'when' string which usually has time "Dec 7, 9:00 PM"
        if (isNaN(date.getTime()) && whenStr) {
            // Remove the end part " – Dec 30..."
            const firstPart = whenStr.split('–')[0].trim();
            // "Dec 2, 9:00 PM"
            if (!firstPart.includes(currentYear.toString())) {
                date = new Date(`${firstPart} ${currentYear}`);
            } else {
                date = new Date(firstPart);
            }
        }

        if (isNaN(date.getTime())) return new Date(); // Fallback

        return date;
    } catch (e) {
        return new Date();
    }
}

module.exports = {
    fetchGoogleEvents
};
