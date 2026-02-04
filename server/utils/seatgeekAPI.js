const axios = require("axios");

const SEATGEEK_CLIENT_ID = process.env.SEATGEEK_CLIENT_ID;
const BASE_URL = "https://api.seatgeek.com/2/events";

/**
 * Fetch events from SeatGeek API
 * @param {Object} params - Search parameters
 * @param {string} params.keyword - Search query (q)
 * @param {string} params.city - City name
 * @returns {Promise<Array>} - List of mapped events
 */
async function fetchSeatgeekEvents({ keyword, city }) {
    if (!SEATGEEK_CLIENT_ID) {
        console.warn("SEATGEEK_CLIENT_ID is not set. Skipping SeatGeek search.");
        return [];
    }

    try {
        const params = {
            client_id: SEATGEEK_CLIENT_ID,
            q: keyword,
            "venue.city": city,
            sort: "score.desc", // SeatGeek's popularity score
            per_page: 20
        };

        // Filter out undefined params
        Object.keys(params).forEach(key => params[key] === undefined && delete params[key]);

        const response = await axios.get(BASE_URL, { params });

        if (!response.data || !response.data.events) {
            return [];
        }

        return response.data.events.map(mapSeatgeekEvent);
    } catch (error) {
        console.error("Error fetching SeatGeek events:", error.message);
        return [];
    }
}

function mapSeatgeekEvent(sgEvent) {
    const venue = sgEvent.venue || {};

    // Find the highest resolution performer image
    let imageUrl = null;
    if (sgEvent.performers && sgEvent.performers.length > 0) {
        imageUrl = sgEvent.performers[0].image;
    }

    return {
        id: `sg-${sgEvent.id}`,
        source: "seatgeek",
        title: sgEvent.short_title || sgEvent.title,
        description: sgEvent.type ? `Type: ${sgEvent.type}` : "", // SeatGeek doesn't provide rich descriptions in list
        startAt: sgEvent.datetime_utc, // ISO string
        endAt: null, // Often not provided
        venueName: venue.name || "Unknown Venue",
        address: venue.address || "",
        city: venue.city || "",
        region: venue.state || "",
        categories: [sgEvent.type].filter(Boolean),
        imageUrl: imageUrl,
        externalUrl: sgEvent.url,
        price: {
            min: sgEvent.stats ? sgEvent.stats.lowest_price : null,
            max: sgEvent.stats ? sgEvent.stats.highest_price : null,
            currency: "USD" // Usually USD for SeatGeek default
        }
    };
}

module.exports = { fetchSeatgeekEvents };
