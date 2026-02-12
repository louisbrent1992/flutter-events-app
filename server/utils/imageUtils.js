/**
 * Utility functions for handling and upgrading image URLs
 */

/**
 * Upgrades a given image URL to a higher quality version if possible.
 * Uses patterns for common image hosts (Google, Ticketmaster, etc.) to request larger sizes.
 * @param {string} url - The original image URL
 * @returns {string} - The upgraded image URL or the original if no upgrade is known
 */
function upgradeImageUrl(url) {
    if (!url) return null;

    try {
        // 1. Google (encrypted-tbn0.gstatic.com)
        // These are thumbnails. Sometimes changing the 's' param helps, but often it's fixed.
        // Pattern: https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9Gc...&s
        if (url.includes('encrypted-tbn0.gstatic.com') || url.includes('lh3.googleusercontent.com')) {
            // Try to request a larger size by modifying the query parameters
            // Common params: s, w, h. 
            // replacing 's' limits with strict sizing often works on googleusercontent.

            // For googleusercontent: =s<size> e.g., =s200 -> =s1000
            if (url.includes('=s')) {
                return url.replace(/=s\d+(-c)?/g, '=s1200'); // Request 1200px
            }

            // For encrypted-tbn0, it's harder. The 's' param is often a hash, but sometimes a size.
            // But usually these remain small. We can try removing generic size constraints if they exist.
        }

        // 2. Ticketmaster / LiveNation
        // Pattern: https://s1.ticketm.net/dam/a/c40/..._RESIZE.jpg
        // or query params like ?width=200
        if (url.includes('ticketm.net') || url.includes('ticketmaster.com')) {
            // Remove specific sizing in path (e.g., _TABLET_LANDSCAPE_LARGE_16_9)
            // But easier: append/replace query params
            const u = new URL(url);
            u.searchParams.set('width', '1024');
            u.searchParams.set('height', '576'); // 16:9 aspect
            u.searchParams.set('fit', 'crop');
            u.searchParams.delete('w');
            u.searchParams.delete('h');
            return u.toString();
        }

        // 3. Eventbrite
        // Pattern: https://img.evbuc.com/...?w=300&h=150...
        if (url.includes('img.evbuc.com')) {
            const u = new URL(url);
            u.searchParams.set('w', '1080'); // HD width
            u.searchParams.set('h', '540');  // Maintain rough aspect or let it float
            return u.toString();
        }

        // 4. SeatGeek
        // Usually provided as 'huge', but if we find a small one:
        // https://seatgeek.com/images/performers-landscape/generic-concert-huge.jpg
        if (url.includes('seatgeek.com/images') && !url.includes('huge')) {
            // Check if we can swap 'small' or 'regular' with 'huge'
            if (url.includes('small.jpg')) return url.replace('small.jpg', 'huge.jpg');
            if (url.includes('regular.jpg')) return url.replace('regular.jpg', 'huge.jpg');
            if (url.includes('block.jpg')) return url.replace('block.jpg', 'huge.jpg');
        }

        return url;
    } catch (e) {
        return url; // Fallback to original
    }
}

module.exports = {
    upgradeImageUrl
};
