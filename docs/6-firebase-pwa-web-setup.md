# MK Restaurants PWA Web Setup Guide

This document outlines the steps to build, test, and deploy the MK Restaurants Sales Dashboard as a Progressive Web App (PWA) using Firebase Hosting.

## 1. Prerequisites
- **Flutter SDK**: Ensure you are on the stable channel (`flutter channel stable`).
- **Firebase CLI**: Installed via npm (`npm install -g firebase-tools`).
- **Google Account**: Logged in via CLI (`firebase login`).

## 2. Project Configuration
The project is already configured with the following files in `parser/mobile/`:
- `web/manifest.json`: Defines the PWA name, colors, and icons.
- `web/index.html`: Optimized for modern Flutter web initialization.
- `firebase.json`: Configures Hosting to serve `build/web` as a Single Page App (SPA).
- `.firebaserc`: Links the local project to the Firebase project ID `mk-restaurants-dashboard`.

## 3. Local Development & Testing
To run the app locally for development:

### Option A: Chrome (Default)
```powershell
cd parser/mobile
flutter run -d chrome
```

### Option B: Any Browser (Firefox, Safari, etc.)
```powershell
cd parser/mobile
flutter run -d web-server
# Open the URL provided in the terminal (e.g., http://localhost:55555)
```

## 4. Building the PWA
Before deploying, you must generate a production build:
```powershell
cd parser/mobile
flutter build web --release
```
This generates the optimized web files in `parser/mobile/build/web`.

## 5. Deployment to Firebase
To push the latest build to the live web:
```powershell
cd parser/mobile
firebase deploy --only hosting
```
Once complete, the CLI will provide a Hosting URL (e.g., `https://mk-restaurants-dashboard.web.app`).

## 6. PWA Installation
Once deployed:
1. Open the Hosting URL on a mobile device (Chrome for Android, Safari for iOS).
2. **Android**: Tap the "Add to Home Screen" prompt or find it in the browser menu.
3. **iOS**: Tap the "Share" icon and select "Add to Home Screen".
4. The app will now appear on your home screen with the MK logo and run without a browser address bar.

## 7. PWA Installability (Android)
To ensure the "Add to Home Screen" works correctly on Android:
- A custom service worker `sw.js` is used to satisfy Chrome's PWA requirements.
- The `index.html` manually registers `sw.js`.
- Manifest icons include both regular and `maskable` purposes.

## 8. Troubleshooting
- **Blank Screen**: Check the browser console (F12) for `.env` loading errors. Ensure `assets/.env` exists and is referenced correctly in `pubspec.yaml`.
- **Icons not showing**: Verify that the images in `web/icons/` match the paths defined in `web/manifest.json`.
- **Firebase CLI Crashes**: If `firebase` commands fail on Node.js 25+, run `npm install -g firebase-tools` to update to the latest compatible version.
