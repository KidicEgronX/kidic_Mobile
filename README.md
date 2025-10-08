# Kidic Mobile (Flutter)

## Quick overview

Kidic is a Flutter mobile app for parents to manage child health, growth, meals, vaccines, milestones, family management and to interact with an AI-powered chatbot. The app is structured with feature pages in `lib/pages/` and services in `lib/services/`.

## Highlights / Best features

- Chatbot (AI): An integrated AI assistant that answers parenting and child-care questions, and receives synced user context so answers are personalized (`lib/services/ai/chatbot_service.dart`, `lib/services/ai/chatbot_sync_service.dart`).
- Child growth & milestones: Track growth and developmental milestones (`lib/pages/child/growth_page.dart`, `lib/pages/child/milestones.dart`).
- Vaccines & health: Vaccine scheduling and related health endpoints (`lib/services/health/vaccine_service.dart`).
- Meals & nutrition: Create, list and manage child meals (including recipe data) (`lib/pages/features/meals_page.dart`, `lib/services/child/meal_service.dart`).
- Family features: Create/join families and share child data across parents (`lib/pages/family/`).
- Notifications and real-time friendly UI for parents (`lib/pages/main/notifications_page.dart`, `lib/services/notification/notification_service.dart`).
- Clean modular architecture: Pages in `lib/pages/`, data models in `lib/models/`, and API logic in `lib/services/`.

## Prerequisites

- Flutter SDK (stable channel). See https://flutter.dev/docs/get-started/install
- Dart (bundled with Flutter)
- Android Studio or Visual Studio Code (for emulator/device management)
- For iOS development: Xcode (macOS only)
- (Optional) Backend server (Java Spring Boot) running locally on port 8080 for full functionality
- (Optional) Chatbot server (AI) running locally on port 8000 for chatbot features
# Kidic Mobile

A simple Flutter mobile app for parents to track child health and use a chatbot feature.

This repository contains the Flutter app source code.

## Prerequisites

- Flutter SDK (stable)
- An editor such as Android Studio or VS Code
- For iOS development: Xcode on macOS

## Quick setup

Open PowerShell in the project root and run:

```powershell
# 1) Check Flutter install and environment
flutter doctor
```

```powershell
# 2) Accept Android licenses (if prompted)
flutter doctor --android-licenses
```

```powershell
# 3) Get packages
flutter pub get
```

```powershell
# 4) List devices/emulators
flutter devices
```

```powershell
# 5) Run on the default device/emulator
flutter run
```

## Run on a device or emulator

- List available devices:

```powershell
flutter devices
```

- Run on the default device/emulator:

```powershell
flutter run
```

- Run on a specific device:

```powershell
flutter run -d <device-id>
```

Notes:
- On Android emulators, use your emulator manager to start a virtual device.
- On macOS you can use the iOS Simulator.
- If the app needs a backend service for full features, run that service separately and configure the app's base URL accordingly.

## Features (short)

- AI Chatbot assistant (in-app chat)
- Child growth tracking and milestones
- Vaccination and health reminders
- Meal and nutrition logging
- Family/parent data sharing and notifications

## Project layout

- `lib/main.dart` — app entry point
- `lib/pages/` — UI pages and screens
- `lib/services/` — API and background services
- `lib/models/` — data models
- `assets/` — images, fonts and other bundled assets