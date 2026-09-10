# 6. Getting Started & Setup Guide

## 1. Prerequisites

Ensure your development machine has the following tools installed:

- **Flutter SDK**: `3.19.0` or higher (`Dart 3.3.0+`)
- **Node.js**: `v18.x` or `v20.x` LTS
- **Package Managers**: `npm` or `pnpm`
- **Database**: Local PostgreSQL 15+ or a cloud [Supabase](https://supabase.com) project
- **Python**: Python 3.9+ with `pillow` (for icon generation script)
- **IDE**: VS Code (with Flutter/Dart & Prisma extensions) or Android Studio

---

## 2. Frontend Setup (Flutter)

### Step 1: Install Flutter Dependencies
From the repository root:
```bash
flutter pub get
```

### Step 2: Run Code Generation (Riverpod, Drift)
Whenever modifying Drift tables or Riverpod `@riverpod` annotations, run `build_runner`:
```bash
dart run build_runner build --delete-conflicting-outputs
```

To run continuous code generation while developing:
```bash
dart run build_runner watch --delete-conflicting-outputs
```

### Step 3: Run the Flutter App
```bash
# Run on connected mobile device or emulator
flutter run

# Run on Chrome (Web)
flutter run -d chrome

# Run on Windows Desktop
flutter run -d windows
```

### Step 4: Run Tests & Static Analysis
```bash
# Run static analysis
flutter analyze

# Run unit and golden engine tests
flutter test
```

---

## 3. Backend Setup (NestJS + Prisma)

### Step 1: Navigate to the Backend Directory
```bash
cd backend
```

### Step 2: Install Node Dependencies
```bash
npm install
```

### Step 3: Configure Environment Variables
Create a `backend/.env` file:
```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/budget_tracker?schema=public"
FIREBASE_PROJECT_ID="your-firebase-project-id"
JWT_SECRET="your-super-secure-jwt-secret-key-change-me"
PORT=3001
```

### Step 4: Apply Database Schema
```bash
# Push Prisma schema directly to your PostgreSQL database
npx prisma db push
```

### Step 5: Start the Development Server
```bash
# Start NestJS in watch mode (runs on http://localhost:3001)
npm run start:dev
```

---

## 4. Connecting the Mobile App to Local Backend

1. Find your development machine's local Wi-Fi IP address (e.g. `192.168.1.50`).
2. Open the Flutter app on your mobile device (must be on the **same Wi-Fi network**).
3. Navigate to **Settings → Server Connection → Backend Server URL**.
4. Enter: `http://192.168.1.50:3001`
5. Tap **Test Connection** to verify network reachability.

---

## 5. Useful Helper Scripts

### Icon Generator (Cross-Platform)
To regenerate all application icons across Android (`mipmap-*`), iOS (`AppIcon.appiconset`), macOS, Windows (`.ico`), and Web:
```bash
# Install Pillow if not already present: pip install pillow
python scripts/generate_app_icons.py
```

### Backend Database Utilities
From the `backend/` directory:
```bash
# Prune legacy or duplicate default accounts
npx ts-node scripts/cleanup_default_accounts.ts

# Wipe all data for a clean development slate
npx ts-node scripts/clear_all_data.ts
```

---

## 6. Building Production Releases

### Building Android Release APK
```bash
flutter clean
flutter pub get
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```
