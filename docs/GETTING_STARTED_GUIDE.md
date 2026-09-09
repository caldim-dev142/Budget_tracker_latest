# 6. Getting Started & Setup Guide

## 1. Prerequisites

Ensure your development machine has the following tools installed:

- **Flutter SDK**: `3.19.0` or higher (`Dart 3.3.0+`)
- **Node.js**: `v18.x` or `v20.x` LTS
- **Package Managers**: `npm` or `pnpm`
- **Database**: Local PostgreSQL 15+ or a cloud [Supabase](https://supabase.com) project
- **IDE**: VS Code (with Flutter/Dart & Prisma extensions) or Android Studio

---

## 2. Frontend Setup (Flutter)

### Step 1: Install Flutter Dependencies
From the repository root:
```bash
flutter pub get
```

### Step 2: Run Code Generation (Riverpod, Drift, Freezed)
Whenever modifying entities, Drift tables, or Riverpod `@riverpod` annotations, run `build_runner`:
```bash
dart run build_runner build --delete-conflicting-outputs
```

To run continuous code-generation while developing:
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
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Ensure your `DATABASE_URL` is set to a valid PostgreSQL instance:
```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/budget_tracker?schema=public"
JWT_SECRET="your-super-secure-jwt-secret-key-change-me"
PORT=3000
```

### Step 4: Apply Database Schema & Migrations
```bash
# Push Prisma schema directly to your database
npx prisma db push

# (Alternatively) Run standard migrations
npx prisma migrate dev --name init
```

### Step 5: Start the Development Server
```bash
# Start NestJS in watch mode
npm run start:dev
```
The server will start at `http://localhost:3000`.

---

## 4. App Branding & Asset Generation

To regenerate launcher icons across Android (`mipmap-*`), iOS (`AppIcon.appiconset`), macOS, Windows (`.ico`), and Web from the master logo:

```bash
# Ensure Pillow is installed: pip install pillow
python scripts/generate_app_icons.py
```

---

## 5. Setting Up Supabase (Alternative)

If you are using Supabase directly:
1. Open the Supabase SQL Editor for your project.
2. Copy and execute the contents of [supabase_schema.sql](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/supabase_schema.sql).
3. Copy your project's PostgreSQL connection string and paste it into `backend/.env` under `DATABASE_URL`.

