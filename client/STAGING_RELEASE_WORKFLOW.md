# Staging Workflow Guide

Quick reference for developing and testing with staging environment before production release.

## Daily Development Workflow

### 1. Work on Staging Branch
```bash
git checkout staging
git pull origin staging
# Make your changes
```

### 2. Push to Staging (Auto-Deploys)
```bash
git add .
git commit -m "Your changes"
git push origin staging
# Cloud Build automatically deploys to staging server
```

### 3. Test Locally
```bash
# Run app against staging server
flutter run --dart-define=ENV=staging
```

### 4. Test on Device (TestFlight)
```bash
# Build staging IPA
cd client
./build_staging_ios.sh

# Upload via Transporter app:
# 1. Open Transporter (Mac App Store)
# 2. Drag .ipa from: client/build/ios/ipa/*.ipa
# 3. Click "Deliver"
# 4. Wait 5-15 min, then add testers in App Store Connect
```

### 5. Repeat Until Thoroughly Tested
Continue steps 1-4 until you're confident the changes work correctly.

---

## Production Release (When Ready)

### 6. Merge to Main
```bash
git checkout main
git pull origin main
git merge staging
git push origin main
# No ENV flag needed (defaults to production)
# IOS
flutter build ipa --release --export-options-plist=ios/export_options.plist
# Android
flutter build appbundle --release
# Or explicitly: flutter build ipa --release --dart-define=ENV=production

## Important Notes

- **Server Environment**: `NODE_ENV` is set automatically by Cloud Build configs (staging vs production)
- **Flutter Environment**: Use `--dart-define=ENV=staging` for staging builds, omit for production
- **Auto-Deployment**: Set up Cloud Build triggers for automatic deployments:
  - Staging trigger: Branch `^staging$` → `cloudbuild-staging.yaml`
  - Production trigger: Branch `^main$` → `cloudbuild-production.yaml`
- **Staging API URL**: Update in `client/lib/config/app_config.dart` after deploying staging server

---

## Quick Reference

| Task | Command |
|------|---------|
| Run staging locally | `flutter run --dart-define=ENV=staging` |
| Build staging IPA | `cd client && ./build_staging_ios.sh` |
| Build production IPA | `flutter build ipa --release` |
| Check server environment | `curl <server-url>/api/env` |

