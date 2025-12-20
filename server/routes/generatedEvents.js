/**
 * Generated Events Routes (EventEase)
 *
 * Endpoints:
 * - POST /import : Import event details from a shared URL (Instagram/TikTok/YouTube/Web)
 * - POST /scan   : Extract event details from a flyer/screenshot image (base64)
 * - POST /plan   : AI planner to generate an itinerary (list of event blocks)
 *
 * Notes:
 * - This module intentionally mirrors the style of `generatedRecipes.js` but is leaner.
 * - Uses OpenAI structured outputs (json_schema) for reliable parsing.
 */

const express = require("express");
const router = express.Router();
const axios = require("axios");
const OpenAI = require("openai");

const { getInstagramMediaFromUrl } = require("../utils/instagramAPI");
const { getTikTokVideoFromUrl } = require("../utils/tiktokAPI");
const { getYouTubeVideoFromUrl } = require("../utils/youtubeAPI");

// Jina Reader fallback for blocked pages (same idea as generatedRecipes.js)
const JINA_AI_BASE_URL = process.env.JINA_AI_BASE_URL || "https://r.jina.ai/";
const JINA_AI_API_KEY = process.env.JINA_AI_API_KEY;
const JINA_AI_TIMEOUT_MS = Number(process.env.JINA_AI_TIMEOUT_MS || 20000);
const JINA_AI_RETRIES = Number(process.env.JINA_AI_RETRIES || 1);

const client = new OpenAI({
	apiKey: process.env.OPENAI_API_KEY || process.env.LlamaAI_API_KEY,
	baseURL: process.env.OPENAI_BASE_URL || process.env.LlamaAI_API_URL,
	timeout: 120000,
	maxRetries: 2,
});

function stripHtml(html) {
	if (!html || typeof html !== "string") return "";
	return html
		.replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "")
		.replace(/<style[^>]*>[\s\S]*?<\/style>/gi, "")
		.replace(/<noscript[^>]*>[\s\S]*?<\/noscript>/gi, "")
		.replace(/<!--[\s\S]*?-->/g, "")
		.replace(/<[^>]+>/g, " ")
		.replace(/&nbsp;/g, " ")
		.replace(/&[a-z]+;/gi, " ")
		.replace(/\s+/g, " ")
		.trim();
}

function extractEventJsonLd(html) {
	if (!html || typeof html !== "string") return "";
	const blocks = [];
	const re = /<script[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
	let m;
	while ((m = re.exec(html)) !== null) {
		const raw = (m[1] || "").trim();
		if (!raw) continue;
		try {
			const parsed = JSON.parse(raw);
			const candidates = Array.isArray(parsed) ? parsed : [parsed];
			for (const c of candidates) {
				const t = c && (c["@type"] || c["@type"]?.toString());
				const types = Array.isArray(t) ? t : [t];
				if (types.some((x) => (x || "").toString().toLowerCase() === "event")) {
					blocks.push(JSON.stringify(c));
				}
			}
		} catch (_) {
			// ignore non-JSON blocks
		}
	}
	return blocks.length ? `JSON-LD Events:\n${blocks.join("\n")}` : "";
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Cost-efficient fetch fallback for blocked pages.
// Returns primarily text/markdown content; may include JSON-LD if present.
async function fetchViaJinaAI(url) {
	const jinaUrl = `${JINA_AI_BASE_URL}${url}`;
	console.log(`🌱 Trying cost-efficient fallback fetch via Jina: ${jinaUrl}`);

	let lastErr;
	for (let attempt = 0; attempt <= JINA_AI_RETRIES; attempt++) {
		if (attempt > 0) {
			const backoff = 250 * Math.pow(2, attempt - 1);
			await sleep(backoff);
		}
		try {
			const headers = {
				"User-Agent": "EventEaseApp/1.0",
				Accept: "application/json,text/plain,text/html,*/*",
			};
			if (JINA_AI_API_KEY) {
				headers.Authorization = `Bearer ${JINA_AI_API_KEY}`;
			}

			const resp = await axios.get(jinaUrl, {
				timeout: JINA_AI_TIMEOUT_MS,
				maxRedirects: 5,
				// Ensure we always receive a string (Reader UI sometimes returns JSON)
				responseType: "text",
				transformResponse: [(data) => data],
				headers,
				validateStatus: (status) => status < 500,
			});

			if (resp.status >= 400) {
				throw new Error(`Jina fallback returned status ${resp.status}`);
			}

			let body = resp.data;
			if (!body || typeof body !== "string") {
				throw new Error("No response body received from Jina fallback");
			}

			// If JSON response, extract useful content.
			try {
				const parsed = JSON.parse(body);
				if (parsed && typeof parsed === "object") {
					body =
						parsed.markdown ||
						parsed.content ||
						parsed.text ||
						parsed.data?.content ||
						parsed.data?.text ||
						body;
				}
			} catch (_) {
				// Not JSON; keep as-is.
			}

			if (!body || typeof body !== "string") {
				throw new Error("No text content extracted from Jina fallback");
			}

			const jsonLd = extractEventJsonLd(body);
			const pageContent = `${jsonLd}\n\n${body.trim()}`.trim();
			if (!pageContent || pageContent.length < 100) {
				throw new Error("Insufficient content extracted via Jina fallback");
			}
			console.log("✅ Jina fallback extraction successful");
			return pageContent;
		} catch (err) {
			lastErr = err;
			const code = err?.code ? ` (${err.code})` : "";
			console.warn(
				`⚠️  Jina fallback attempt ${attempt + 1}/${
					JINA_AI_RETRIES + 1
				} failed${code}: ${err?.message || err}`
			);
		}
	}

	throw lastErr || new Error("Jina fallback failed");
}

function detectPlatform(url) {
	const u = (url || "").toString();
	if (/instagram/i.test(u)) return "instagram";
	if (/tiktok/i.test(u)) return "tiktok";
	if (/youtube|youtu\.be/i.test(u)) return "youtube";
	return "web";
}

async function fetchContentFromUrl(url) {
	const platform = detectPlatform(url);
	if (platform === "instagram") {
		const d = await getInstagramMediaFromUrl(url);
		return {
			platform,
			text: d?.caption || "",
			imageUrl: d?.thumbnailUrl || d?.imageUrl || null,
			metadata: d || null,
		};
	}
	if (platform === "tiktok") {
		const d = await getTikTokVideoFromUrl(url);
		return {
			platform,
			text: d?.description || "",
			imageUrl: d?.coverUrl || d?.thumbnailUrl || null,
			metadata: d || null,
		};
	}
	if (platform === "youtube") {
		const d = await getYouTubeVideoFromUrl(url);
		return {
			platform,
			text: d?.description || "",
			imageUrl: d?.thumbnailUrl || null,
			metadata: d || null,
		};
	}

	// Web import: try direct fetch first, then fall back to Jina Reader for blocked pages.
	try {
		const resp = await axios.get(url, {
			timeout: 20000,
			maxRedirects: 5,
			headers: {
				"User-Agent":
					"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
				Accept:
					"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
				"Accept-Language": "en-US,en;q=0.9",
				Referer: "https://www.google.com/",
			},
			validateStatus: (s) => s < 500,
		});
		if (resp.status >= 400) {
			throw new Error(`Website returned status ${resp.status}`);
		}
		const html = resp.data;
		const jsonLd = extractEventJsonLd(html);
		const text = stripHtml(html);
		const combined = `${jsonLd}\n\n${text}`.trim();
		// If extraction is suspiciously short, attempt fallback.
		if (combined.length < 300) {
			throw new Error("Direct fetch returned insufficient content");
		}
		return { platform: "web", text: combined, imageUrl: null, metadata: null };
	} catch (directErr) {
		try {
			const fallback = await fetchViaJinaAI(url);
			const combined = `${fallback}\n\n${stripHtml(fallback)}`.trim();
			return {
				platform: "web",
				text: combined,
				imageUrl: null,
				metadata: { fallback: "jina", directError: directErr?.message || String(directErr) },
			};
		} catch (jinaErr) {
			// Prefer direct error context if both fail.
			throw directErr || jinaErr;
		}
	}
}

const eventSchema = {
	name: "event_import",
	strict: true,
	schema: {
		type: "object",
		additionalProperties: false,
		properties: {
			title: { type: "string" },
			description: { type: "string" },
			startAt: { type: ["string", "null"], description: "ISO-8601 datetime if known" },
			endAt: { type: ["string", "null"], description: "ISO-8601 datetime if known" },
			venueName: { type: ["string", "null"] },
			address: { type: ["string", "null"] },
			city: { type: ["string", "null"] },
			region: { type: ["string", "null"] },
			country: { type: ["string", "null"] },
			latitude: { type: ["number", "null"] },
			longitude: { type: ["number", "null"] },
			ticketUrl: { type: ["string", "null"] },
			ticketPrice: { type: ["string", "null"] },
			imageUrl: { type: ["string", "null"] },
			categories: { type: "array", items: { type: "string" } },
		},
		required: ["title", "description", "startAt", "endAt", "venueName", "address", "city", "region", "country", "latitude", "longitude", "ticketUrl", "ticketPrice", "imageUrl", "categories"],
	},
};

router.post("/import", async (req, res) => {
	try {
		const url = req.body?.url;
		if (!url) return res.status(400).json({ error: "URL is required" });

		const fetched = await fetchContentFromUrl(url);
		const sourcePlatform = fetched.platform;

		const prompt = [
			"You are an expert assistant that extracts real-world event details from messy text.",
			"Return a best-effort parse. If something is unknown, return null (not an empty string).",
			"Prefer ISO-8601 datetime with timezone offset if explicitly stated; otherwise use ISO without offset.",
			"Categories should be a small list like: Music, Art, Tech, Nightlife, Food, Sports, Community, Family.",
		].join("\n");

		const completion = await client.chat.completions.create({
			model: process.env.OPENAI_EVENTS_MODEL || "gpt-4o-mini",
			messages: [
				{ role: "developer", content: prompt },
				{
					role: "user",
					content: `SOURCE_URL:\n${url}\n\nSOURCE_PLATFORM:\n${sourcePlatform}\n\nCONTENT:\n${(fetched.text || "").slice(0, 12000)}`,
				},
			],
			response_format: { type: "json_schema", json_schema: eventSchema },
			max_completion_tokens: 3500,
		});

		const raw = completion.choices?.[0]?.message?.content || "{}";
		const parsed = JSON.parse(raw);

		return res.json({
			...parsed,
			sourceUrl: url,
			sourcePlatform,
			// Prefer an extracted image if model didn't set it.
			imageUrl: parsed.imageUrl || fetched.imageUrl || null,
			fromCache: false,
		});
	} catch (e) {
		console.error("Event import error:", e);
		return res.status(500).json({ error: "Failed to import event" });
	}
});

router.post("/scan", async (req, res) => {
	try {
		const imageBase64 = req.body?.imageBase64;
		if (!imageBase64) return res.status(400).json({ error: "imageBase64 is required" });

		const dataUrl = imageBase64.startsWith("data:")
			? imageBase64
			: `data:image/jpeg;base64,${imageBase64}`;

		const prompt = [
			"You extract event details from an event flyer image.",
			"Read the flyer text and return the event fields.",
			"If the flyer says relative dates like 'This Friday', infer a reasonable date using the current date.",
			"Return null for unknown fields.",
		].join("\n");

		const completion = await client.chat.completions.create({
			model: process.env.OPENAI_EVENTS_VISION_MODEL || "gpt-4o-mini",
			messages: [
				{ role: "developer", content: prompt },
				{
					role: "user",
					content: [
						{ type: "text", text: "Extract the event details from this flyer." },
						{ type: "image_url", image_url: { url: dataUrl } },
					],
				},
			],
			response_format: { type: "json_schema", json_schema: eventSchema },
			max_completion_tokens: 3500,
		});

		const raw = completion.choices?.[0]?.message?.content || "{}";
		const parsed = JSON.parse(raw);

		return res.json({
			...parsed,
			sourceUrl: null,
			sourcePlatform: "camera",
			imageUrl: parsed.imageUrl || null,
		});
	} catch (e) {
		console.error("Event scan error:", e);
		return res.status(500).json({ error: "Failed to scan flyer" });
	}
});

const planSchema = {
	name: "event_plan",
	strict: true,
	schema: {
		type: "object",
		additionalProperties: false,
		properties: {
			title: { type: "string" },
			itinerary: {
				type: "array",
				items: {
					type: "object",
					additionalProperties: false,
					properties: {
						title: { type: "string" },
						startAt: { type: ["string", "null"] },
						endAt: { type: ["string", "null"] },
						venueName: { type: ["string", "null"] },
						address: { type: ["string", "null"] },
						notes: { type: "string" },
						categories: { type: "array", items: { type: "string" } },
					},
					required: ["title", "startAt", "endAt", "venueName", "address", "notes", "categories"],
				},
			},
		},
		required: ["title", "itinerary"],
	},
};

router.post("/plan", async (req, res) => {
	try {
		const { vibe, budget, location, dates, constraints } = req.body || {};
		const prompt = [
			"You are an expert event concierge.",
			"Generate a realistic itinerary as a sequence of event blocks with times and logistics.",
			"Use ISO-8601 for times when possible; otherwise null.",
			"Keep notes concise and actionable.",
		].join("\n");

		const completion = await client.chat.completions.create({
			model: process.env.OPENAI_EVENTS_PLANNER_MODEL || "gpt-4o-mini",
			messages: [
				{ role: "developer", content: prompt },
				{
					role: "user",
					content: JSON.stringify({ vibe, budget, location, dates, constraints }, null, 2),
				},
			],
			response_format: { type: "json_schema", json_schema: planSchema },
			max_completion_tokens: 4500,
		});

		const raw = completion.choices?.[0]?.message?.content || "{}";
		return res.json(JSON.parse(raw));
	} catch (e) {
		console.error("Planner error:", e);
		return res.status(500).json({ error: "Failed to generate plan" });
	}
});

module.exports = router;


