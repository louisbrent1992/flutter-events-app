const axios = require("axios");
const { upgradeImageUrl } = require("./imageUtils");

const SEATGEEK_CLIENT_ID = process.env.SEATGEEK_CLIENT_ID;
const BASE_URL = "https://api.seatgeek.com/2/events";

/**
 * Fetch events from SeatGeek API
 * @param {Object} params - Search parameters
 * @param {string} params.keyword - Search query (q)
 * @param {string} params.city - City name
 * @returns {Promise<Array>} - List of mapped events
 */
async function fetchSeatgeekEvents({ keyword, city, category }) {
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

        // Map broad categories to SeatGeek taxonomies
        if (category) {
            const catLower = category.toLowerCase();
            if (catLower === 'sports') params['taxonomies.name'] = 'sports';
            else if (catLower === 'concerts' || catLower === 'music') params['taxonomies.name'] = 'concert';
            else if (catLower === 'theater') params['taxonomies.name'] = 'theater';
            else if (catLower === 'comedy') params['taxonomies.name'] = 'comedy'; // or type=comedy
            else if (catLower === 'family') params['taxonomies.name'] = 'family';
            // For others, we can treat it as part of the query if not a strict taxonomy
            else if (!keyword) {
                params.q = category;
            }
        }

        // Filter out undefined or empty params
        Object.keys(params).forEach(key => {
            if (params[key] === undefined || params[key] === null || params[key] === "") {
                delete params[key];
            }
        });

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
        const p = sgEvent.performers[0];
        imageUrl = (p.images && p.images.huge) || p.image;
        if (imageUrl) imageUrl = upgradeImageUrl(imageUrl);
    }

    // Generate a rich description if none exists
    let description = sgEvent.description || "";
    const performers = sgEvent.performers || [];
    const performerNames = performers.map(p => p.name).join(", ");

    if (!description || description.trim().length === 0) {
        const parts = [];
        if (performers.length > 0) {
            parts.push(`Don't miss ${performerNames} live at ${venue.name || "the venue"}!`);
        } else {
            parts.push(`Example synthesized description for ${sgEvent.title}.`);
        }

        if (venue.city) {
            parts.push(`Happening in ${venue.city}.`);
        }

        if (sgEvent.stats && sgEvent.stats.lowest_price) {
            parts.push(`Tickets currently start at $${sgEvent.stats.lowest_price}.`);
        } else {
            parts.push("Check ticket availability for latest prices.");
        }

        if (sgEvent.url) {
            parts.push(`\n\nGet your tickets here: ${sgEvent.url}`);
        }

        description = parts.join(" ");
    }

    return {
        id: `sg-${sgEvent.id}`,
        source: "seatgeek",
        title: sgEvent.short_title || sgEvent.title,
        description: description,
        startAt: sgEvent.datetime_utc, // ISO string
        endAt: null, // Often not provided
        venueName: venue.name || "Unknown Venue",
        address: venue.address || "",
        city: venue.city || "",
        region: venue.state || "",
        // Add coordinates from venue location
        latitude: venue.location?.lat || null,
        longitude: venue.location?.lon || null,
        categories: [
            sgEvent.type,
            ...(sgEvent.taxonomies || []).map(t => t.name)
        ].filter(Boolean),
        imageUrl: imageUrl,
        externalUrl: sgEvent.url,
        ticketPrice: sgEvent.stats && sgEvent.stats.lowest_price ? `$${sgEvent.stats.lowest_price}` : null,
        price: {
            min: sgEvent.stats ? sgEvent.stats.lowest_price : null,
            max: sgEvent.stats ? sgEvent.stats.highest_price : null,
            currency: "USD"
        },
        performers: performers.map(p => ({
            name: p.name,
            image: p.image,
            type: p.type
        }))
    };
}

module.exports = { fetchSeatgeekEvents };
