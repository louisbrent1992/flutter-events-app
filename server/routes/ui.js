const express = require("express");
const router = express.Router();

// Simple dynamic UI config endpoint
// You can update this JSON (or back it with Firestore) without changing the app
router.get("/ui/config", (req, res) => {
  const now = new Date();
  const config = {
    version: 1,
    fetchedAt: now.toISOString(),
    // Home screen hero image - can be updated without app release
    heroImageUrl: null,
    // Welcome message - supports {username} placeholder
    welcomeMessage: "Welcome,", // Default: "Welcome," or customize like "Welcome back, {username}!"
    // Hero subtitle text
    heroSubtitle: "What are you planning today?",
    // Section visibility toggles - set to false to hide sections
    sectionVisibility: {
      yourEventsList: true,
      upcomingSection: true,
      featuresSection: true
    },
    globalBackground: {
      // Choose either imageUrl or colors (for gradient/solid)
      imageUrl: null,
      // Match app theme primary/secondary (see client/lib/theme/theme.dart)
      // Use light tints so logos/headers remain readable on top of the background.
      colors: ["#E6F9FC", "#F1ECFF"], // light cyan tint → light purple tint
      animateGradient: true,
      kenBurns: true,
      opacity: 1.0
    },
    banners: [
      {
        id: "seasonal_home",
        placement: "home_top",
        title: "Weekend Plans",
        subtitle: "Build an itinerary in seconds",
        ctaText: "Open AI Planner",
        ctaUrl: "app://planner",
        imageUrl: null,
        backgroundColor: "#FFF3E0",
        textColor: "#7B3F00",
        priority: 10,
        startAt: null,
        endAt: null
      },
      {
        id: "shop_discount",
        placement: "shop_top",
        title: "Limited-Time Offer",
        subtitle: "Save 67% on Unlimited (Yearly)",
        ctaText: "Shop Now",
        ctaUrl: "app://subscription", // open in-app route
        imageUrl: null,
        backgroundColor: "#E8F5E9",
        textColor: "#1B5E20",
        priority: 20,
        startAt: null,
        endAt: null
      }
    ]
  };
  res.json({ success: true, data: config });
});

module.exports = router;