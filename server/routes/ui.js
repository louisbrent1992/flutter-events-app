const express = require("express");
const router = express.Router();
const { getFirestore } = require("firebase-admin/firestore");

const db = getFirestore();

const CONFIG_DOC_PATH = { collection: "appConfig", doc: "ui" };

function nowIso() {
  return new Date().toISOString();
}

function deepMerge(base, overrides) {
  if (!overrides || typeof overrides !== "object") return base;
  const out = Array.isArray(base) ? [...base] : { ...(base || {}) };
  for (const [k, v] of Object.entries(overrides)) {
    // Treat explicit null as "unset" so older stored configs don't accidentally
    // wipe new defaults (e.g. globalBackground.imageUrl).
    // If you want to intentionally disable a string field, set it to "" instead.
    if (v === null || typeof v === "undefined") continue;
    if (
      v &&
      typeof v === "object" &&
      !Array.isArray(v) &&
      base &&
      typeof base[k] === "object" &&
      !Array.isArray(base[k])
    ) {
      out[k] = deepMerge(base[k], v);
    } else {
      out[k] = v;
    }
  }
  return out;
}

function defaultUiConfig() {
  return {
    version: 1,
    fetchedAt: nowIso(),
    // Home screen hero image - can be updated without app release
    heroImageUrl: null,
    // Welcome message - supports {username} placeholder
    welcomeMessage: "Welcome,",
    // Hero subtitle text
    heroSubtitle: "What are you planning today?",
    // Section visibility toggles - set to false to hide sections
    sectionVisibility: {
      yourEventsList: true,
      upcomingSection: true,
      featuresSection: true,
    },
    globalBackground: {
      // Choose either imageUrl or colors (for gradient/solid)
      // Server-hosted image (served by Express static from server/public)
      // On Cloud Run this becomes: https://<your-service>/ui/background_image.png
      // You can replace this file via GitHub deploys without updating the app binary.
      imageUrl: null,
      colors: ["#E6F9FC", "#F1ECFF"],
      animateGradient: true,
      kenBurns: true,
      opacity: 1.0,
    },
    banners: [],
  };
}

// GET /api/ui/config
// Firestore-backed dynamic UI config so you can update UI without publishing a new app build.
router.get("/ui/config", async (req, res) => {
  const base = defaultUiConfig();
  try {
    const snap = await db
      .collection(CONFIG_DOC_PATH.collection)
      .doc(CONFIG_DOC_PATH.doc)
      .get();

    if (!snap.exists) {
      return res.json({ success: true, data: base });
    }

    const stored = snap.data() || {};
    const merged = deepMerge(base, stored);
    merged.fetchedAt = nowIso();
    return res.json({ success: true, data: merged });
  } catch (e) {
    // Fail open: return default config if Firestore read fails.
    console.error("ui/config read error:", e);
    return res.json({ success: true, data: base, warning: "fallback_default" });
  }
});

// PUT /api/ui/config
// Secured by an admin key header, intended for updating runtime UI without redeploy.
// Header: x-ui-admin-key: <UI_ADMIN_KEY>
router.put("/ui/config", async (req, res) => {
  const adminKey = process.env.UI_ADMIN_KEY;
  if (!adminKey) {
    return res.status(500).json({
      success: false,
      message: "UI_ADMIN_KEY is not set on the server.",
    });
  }

  const provided = (req.header("x-ui-admin-key") || "").toString();
  if (provided !== adminKey) {
    return res.status(401).json({ success: false, message: "Unauthorized." });
  }

  const body = req.body || {};
  if (!body || typeof body !== "object") {
    return res.status(400).json({ success: false, message: "Invalid JSON body." });
  }

  try {
    const toStore = { ...body };
    // fetchedAt is server-owned.
    delete toStore.fetchedAt;

    await db
      .collection(CONFIG_DOC_PATH.collection)
      .doc(CONFIG_DOC_PATH.doc)
      .set(toStore, { merge: true });

    const merged = deepMerge(defaultUiConfig(), toStore);
    merged.fetchedAt = nowIso();
    return res.json({ success: true, data: merged });
  } catch (e) {
    console.error("ui/config write error:", e);
    return res.status(500).json({ success: false, message: "Failed to update ui config." });
  }
});

module.exports = router;