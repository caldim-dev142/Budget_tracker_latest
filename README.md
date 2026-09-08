# 💰 Budget Tracker — Financial Planning Platform

A full-stack, offline-first household financial planning platform built with **Flutter** (Riverpod + Drift SQLite) and **NestJS** (Prisma + PostgreSQL).

---

## 📖 Comprehensive Documentation

Complete project documentation is available in the [`docs/`](./docs/) directory:

- 📑 **[Documentation Master Index](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/docs/README.md)**
- 🗺️ **[1. Project Overview & Architecture](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/docs/PROJECT_OVERVIEW.md)**
- 🔢 **[2. Financial Waterfall Calculation Engine](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/docs/FINANCIAL_WATERFALL_ENGINE.md)**
- 📱 **[3. Frontend Architecture (Flutter)](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/docs/FRONTEND_ARCHITECTURE.md)**
- ⚙️ **[4. Backend Architecture (NestJS)](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/docs/BACKEND_ARCHITECTURE.md)**
- 🗄️ **[5. Database Schema & Data Models](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/docs/DATABASE_SCHEMA.md)**
- 🚀 **[6. Getting Started & Setup Guide](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/docs/GETTING_STARTED_GUIDE.md)**
- 🛡️ **[7. Developer Rules, Invariants & Roadmap](file:///c:/Users/USER/Desktop/caldim%20projects/Budget_tracker_latest/docs/DEVELOPER_RULES_AND_ROADMAP.md)**

---

## ⚡ Quick Start

### Frontend (Flutter)
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Backend (NestJS)
```bash
cd backend
npm install
npx prisma db push
npm run start:dev
```

