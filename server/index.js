/**
 * EventEase Server
 *
 * Main server entrypoint that configures Express and registers routes
 */

const express = require("express");
const cors = require("cors");
require("dotenv").config();
const errorHandler = require("./utils/errorHandler");

// Initialize Firebase
require("./config/firebase").initFirebase();

// Simple in-memory cache for performance
const cache = new Map();
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

// Cache middleware
const cacheMiddleware = (duration = CACHE_TTL) => {
	return (req, res, next) => {
		const key = `${req.method}:${req.originalUrl}`;
		const cached = cache.get(key);

		if (cached && Date.now() - cached.timestamp < duration) {
			return res.json(cached.data);
		}

		// Store original send method
		const originalSend = res.json;

		// Override send method to cache response
		res.json = function (data) {
			cache.set(key, {
				data,
				timestamp: Date.now(),
			});

			// Clean up old cache entries
			const now = Date.now();
			for (const [cacheKey, value] of cache.entries()) {
				if (now - value.timestamp > CACHE_TTL) {
					cache.delete(cacheKey);
				}
			}

			originalSend.call(this, data);
		};

		next();
	};
};

// Import routes
const aiEventRoutes = require("./routes/generatedEvents");
const userRoutes = require("./routes/users");
const authRoutes = require("./middleware/auth");
const eventRoutes = require("./routes/events");
const dataDeletionRoutes = require("./routes/data-deletion");
const uiRoutes = require("./routes/ui");

const app = express();
const port = process.env.PORT || 8080;

// Middleware
app.use(express.json({ limit: '5mb' }));
app.use(express.urlencoded({ extended: true, limit: '5mb' }));
app.use(cors());

// Timeout middleware removed to prevent conflicts with long-running operations

// Trust proxy for rate limiting and IP detection (needed for data deletion)
app.set("trust proxy", 1);

// Serve static files from public directory (for data deletion page)
app.use(express.static(require("path").join(__dirname, "public")));

// Add request logger in development
if (process.env.NODE_ENV !== "production") {
	app.use((req, res, next) => {
		console.log(`${req.method} ${req.url}`);
		next();
	});
}

// API Routes with clean naming structure
app.use("/api/ai/events", aiEventRoutes);
app.use("/api/users", userRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/events", eventRoutes);
app.use("/api", dataDeletionRoutes);
app.use("/api", uiRoutes);

// Server homepage
app.get("/", (req, res) => {
	res.sendFile(require("path").join(__dirname, "public", "index.html"));
});

// Serve the data deletion page (for Google Play Console compliance)
app.get("/data-deletion", (req, res) => {
	res.sendFile(require("path").join(__dirname, "public", "data-deletion.html"));
});

// Health check endpoint
app.get("/health", (req, res) => {
	res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// Environment info endpoint (useful for debugging which server you're connected to)
app.get("/api/env", (req, res) => {
	res.json({
		environment: process.env.NODE_ENV || "development",
		version: process.env.npm_package_version || "1.0.0",
		timestamp: new Date().toISOString(),
	});
});

// 404 handler for undefined routes
app.use((req, res) => {
	errorHandler.notFound(res, `Route not found: ${req.method} ${req.url}`);
});

// Global error handler
app.use(errorHandler.globalHandler);

// Start server
app.listen(port, () => {
	const env = process.env.NODE_ENV || "development";
	const envEmoji = env === "production" ? "🟢" : env === "staging" ? "🟡" : "🔵";
	console.log(`${envEmoji} Environment: ${env.toUpperCase()}`);
	console.log(`🚀 Server running on port ${port}`);
	console.log(`🔗 API available at http://localhost:${port}/api`);
});
