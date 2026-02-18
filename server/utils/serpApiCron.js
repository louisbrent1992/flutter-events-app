/**
 * SerpApi Events Cron Job (EventEase)
 *
 * Strategy:
 * - Runs twice per day (06:00 and 18:00 UTC).
 * - Cycles through TARGET_CITIES sequentially so every city gets equal coverage.
 * - Each city is fetched AT MOST twice per calendar day (enforced via in-memory tracking).
 * - Stops fetching once the daily or monthly budget cap is reached.
 * - City list is sized to maximise the monthly API quota.
 *
 * Budget maths (adjust DAILY_BUDGET / MONTHLY_BUDGET to match your SerpApi plan):
 *   Free  plan  : 100  searches/month → MONTHLY_BUDGET = 100
 *   Hobby plan  : 5000 searches/month → MONTHLY_BUDGET = 5000
 *   etc.
 *
 * With 2 runs/day the cron fetches `Math.min(cities, DAILY_BUDGET / 2)` cities per run.
 */

const cron = require("node-cron");
const { getFirestore } = require("firebase-admin/firestore");
const crypto = require("crypto");
const { fetchGoogleEvents } = require("./serpApi");

// ─── Budget configuration ────────────────────────────────────────────────────
// Adjust these to match your SerpApi subscription tier.
const MONTHLY_BUDGET = Number(process.env.SERPAPI_MONTHLY_BUDGET || 250);
const DAILY_BUDGET = Math.ceil(MONTHLY_BUDGET / 30); // distribute evenly across month

// ─── City list ───────────────────────────────────────────────────────────────
// Budget maths for the SerpApi FREE tier (250 searches/month):
//   250 searches ÷ 30 days ≈ 8 searches/day
//   2 runs/day → 4 cities per run → 8 unique cities covered per day
//
// We keep exactly 8 cities so every city is refreshed twice daily and the
// monthly budget is fully utilised without going over.
//
// If you upgrade to a paid plan, increase SERPAPI_MONTHLY_BUDGET and add
// more cities — the cron will automatically fetch more per run.
const TARGET_CITIES = [
    "New York, NY",
    "Los Angeles, CA",
    "Chicago, IL",
    "Miami, FL",
    "San Francisco, CA",
    "Austin, TX",
    "Las Vegas, NV",
    "London, UK",
];

// ─── In-memory fetch tracking ─────────────────────────────────────────────────
// Tracks how many times each city has been fetched today.
// Resets at midnight UTC automatically (new Date().toDateString() changes).
const fetchLog = new Map(); // city → { date: string, count: number }

// Monthly search counter (resets on 1st of each month)
let monthlyUsage = { month: new Date().getMonth(), count: 0 };

function getTodayKey() {
    return new Date().toISOString().slice(0, 10); // "YYYY-MM-DD"
}

function getThisMonth() {
    return new Date().getMonth();
}

function canFetchCity(city) {
    const today = getTodayKey();
    const log = fetchLog.get(city);
    if (!log || log.date !== today) return true; // new day or never fetched
    return log.count < 2; // max 2x per day
}

function recordFetch(city) {
    const today = getTodayKey();
    const log = fetchLog.get(city);
    if (!log || log.date !== today) {
        fetchLog.set(city, { date: today, count: 1 });
    } else {
        log.count += 1;
    }

    // Monthly usage tracking
    const thisMonth = getThisMonth();
    if (monthlyUsage.month !== thisMonth) {
        monthlyUsage = { month: thisMonth, count: 1 };
    } else {
        monthlyUsage.count += 1;
    }
}

function budgetExhausted() {
    // Monthly cap
    const thisMonth = getThisMonth();
    if (monthlyUsage.month !== thisMonth) {
        monthlyUsage = { month: thisMonth, count: 0 };
    }
    if (monthlyUsage.count >= MONTHLY_BUDGET) {
        console.warn(`⛔ [Cron] Monthly SerpApi budget exhausted (${monthlyUsage.count}/${MONTHLY_BUDGET})`);
        return true;
    }
    return false;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
function generateEventId(url) {
    return crypto.createHash("md5").update(url).digest("hex");
}

// ─── Core sync ────────────────────────────────────────────────────────────────
/**
 * Run one full pass: iterate through all cities, fetch each one that:
 *   1. Has been fetched < 2 times today, AND
 *   2. The monthly budget is not exhausted.
 *
 * This is called twice per day (06:00 and 18:00 UTC).
 */
async function runSerpApiSync() {
    if (budgetExhausted()) return;

    const db = getFirestore();
    let totalFetched = 0;
    let totalSaved = 0;

    console.log(`🌍 [Cron] Starting SerpApi sync pass. Monthly usage: ${monthlyUsage.count}/${MONTHLY_BUDGET}`);

    for (const city of TARGET_CITIES) {
        if (budgetExhausted()) break;
        if (!canFetchCity(city)) {
            // Already fetched twice today — skip
            continue;
        }

        try {
            const query = `Events in ${city}`;
            console.log(`  🔍 Fetching: ${city}`);
            const events = await fetchGoogleEvents(query);
            recordFetch(city);
            totalFetched++;

            if (events.length === 0) continue;

            // Upsert into Firestore
            const batch = db.batch();
            let batchSize = 0;

            for (const event of events) {
                if (!event.sourceUrl) continue;
                const id = `google_${generateEventId(event.sourceUrl)}`;
                const docRef = db.collection("discoverEvents").doc(id);
                batch.set(
                    docRef,
                    {
                        ...event,
                        source: "google_events",
                        city: city.split(",")[0].trim(),
                        updatedAt: new Date().toISOString(),
                    },
                    { merge: true }
                );
                batchSize++;

                // Firestore batch limit is 500 ops; commit early if needed
                if (batchSize >= 400) {
                    await batch.commit();
                    batchSize = 0;
                }
            }

            if (batchSize > 0) {
                await batch.commit();
            }

            totalSaved += events.length;
            console.log(`  ✅ Saved ${events.length} events for ${city}`);

            // Small delay between API calls to be polite
            await new Promise((r) => setTimeout(r, 500));
        } catch (e) {
            console.error(`  ❌ Error fetching ${city}:`, e.message);
        }
    }

    console.log(
        `🏁 [Cron] Sync pass complete. Cities fetched: ${totalFetched}, Events saved: ${totalSaved}. Monthly usage: ${monthlyUsage.count}/${MONTHLY_BUDGET}`
    );
}

// ─── Scheduler ────────────────────────────────────────────────────────────────
function initSerpApiCron() {
    // Run at 06:00 UTC and 18:00 UTC every day (twice per day)
    cron.schedule("0 6 * * *", async () => {
        console.log("⏰ [Cron] 06:00 UTC — starting morning SerpApi sync");
        await runSerpApiSync();
    });

    cron.schedule("0 18 * * *", async () => {
        console.log("⏰ [Cron] 18:00 UTC — starting evening SerpApi sync");
        await runSerpApiSync();
    });

    console.log(
        `📅 [Cron] SerpApi sync scheduled at 06:00 & 18:00 UTC daily. Budget: ${DAILY_BUDGET}/day, ${MONTHLY_BUDGET}/month`
    );

    // In dev/staging, trigger once after startup (with a short delay)
    if (process.env.NODE_ENV !== "production") {
        setTimeout(() => {
            console.log("🚀 [Dev] Triggering initial SerpApi sync...");
            runSerpApiSync();
        }, 10000);
    }
}

module.exports = {
    initSerpApiCron,
    runSerpApiSync,
};
