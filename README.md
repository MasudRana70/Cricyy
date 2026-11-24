<div align="center">

# Cricyy

**Lightweight, Ad-Free Cricket Scoring & Player Statistics Application**

[![Flutter](https://img.shields.io/badge/Frontend-Flutter%20%7C%20Material%203-02569B?style=for-the-badge&logo=flutter&logoColor=white)](./Frontend)
[![Dart](https://img.shields.io/badge/Dart-%5E3.12.2-0175C2?style=for-the-badge&logo=dart&logoColor=white)](./Frontend/pubspec.yaml)
[![Node.js](https://img.shields.io/badge/Backend-Node.js%20%7C%20Express-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](./Backend)
[![MongoDB](https://img.shields.io/badge/Database-MongoDB%20%7C%20Mongoose-47A248?style=for-the-badge&logo=mongodb&logoColor=white)](./Backend)

*Score every ball cleanly, enforce real cricket rules automatically, and track career batting & bowling analytics with interactive performance charts.*

</div>

---

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Key Features](#key-features)
- [Architecture & Project Structure](#architecture--project-structure)
- [Getting Started](#getting-started)
- [Free Cloud Deployment (Vercel + MongoDB Atlas)](#free-cloud-deployment-vercel--mongodb-atlas)
- [API Overview](#api-overview)
- [Running Tests](#running-tests)

---

## Overview

**Cricyy** is built for fast, distraction-free cricket match scoring on mobile and web. Designed with a strict separation between a **Flutter (Material 3)** client and a **Node.js / Express / MongoDB** REST API, it handles real-world cricket scoring rules—extras, strike rotation, maiden overs, wickets, 2nd-innings target chases, and dynamic player career aggregation—without clutter or advertisements.

---

## Tech Stack

| Layer | Technologies |
| :--- | :--- |
| **Frontend** | Flutter, Dart (`^3.12.2`), Material Design 3, `provider`, `shared_preferences`, `http`, `intl`, `google_fonts` |
| **Backend** | Node.js, Express.js (`^4.19.2`), CommonJS, `express-validator`, `multer`, `morgan`, `cors` |
| **Database** | MongoDB, Mongoose ODM (`^8.4.1`) |
| **Testing** | Jest & Supertest (Backend), `flutter_test` (Frontend) |

---

## Key Features

### 1. Match Creation & Configuration
- Create two custom teams and assign players dynamically.
- Support for **T10**, **T20**, **ODI**, or **Custom Overs** formats.
- Configure toss winner and decision (*Bat* / *Bowl*), then set opening striker, non-striker, and opening bowler.

### 2. Live Ball-by-Ball Scoring Engine
- **Fast Scoring Controls**: One-tap run buttons (`0`, `1`, `2`, `3`, `4`, `6`).
- **Complete Extras Support**:
  - **Wide**: 1 penalty run + any additional completed/boundary runs, without incrementing legal balls.
  - **No Ball**: 1 penalty run + runs scored off the bat credited to the striker, without incrementing legal balls.
  - **Bye & Leg Bye**: Credited to team extras without charging the bowler.
- **Over & Strike Management**:
  - Automatic odd-run and end-of-over strike rotation.
  - Manual **Side Change (Swap Strike)** control.
  - Automatic **maiden over** detection when 0 bowler-conceded runs occur in a completed 6-ball over.
  - Flexible bowler selection at the end of every over (without restrictive over caps).
- **Wickets & Corrections**: Supports standard dismissal types, incoming batter assignment, and **Undo Ball** rollback.
- **2nd Innings & Match Result**: Automatic innings transition with target tracking, required run rate, and win-margin calculation.

### 3. Persistent History & Full Scorecards
- Matches and ball-by-ball states persist across sessions.
- Inspect full **1st & 2nd Innings Scorecards** (batting table, bowling figures, extras breakdown, and fall of wickets) from both Live Scoring and Match History.

### 4. Player Analytics & Interactive Performance Graphs
- **Zero Dummy Data**: Players are automatically extracted and aggregated from real created matches.
- **Search & Sort Directory**: Filter players by name and sort by **Most Runs**, **Most Wickets**, **Matches**, or **Name (A–Z)**.
- **Interactive Performance Trends (`PlayerPerformanceChart`)**:
  - Tap any player name or **Graph** button in the **Players** directory, **Live Scoring**, or **Full Scorecard** to inspect their interactive **Batting (Runs)** and **Bowling (Wickets)** bar graph or open their full career profile.
  - Tap any match bar inside the chart to inspect opponent, date, strike rate, boundaries, and economy.

### 5. Minimalistic Neomorphism UI & Multi-User Real-Time Sync
- **Minimalistic Neomorphism Design**: Soft tactile shadows (`NeoCard`, `NeoIconButton`, `NeoPillButton`, animated scoring buttons) with responsive wide-screen centering across mobile & web.
- **Shared Cloud Matches + Auto-Refresh (5s)**: Matches created or scored by any user sync automatically to MongoDB Atlas (`/api/shared-matches`), with an automatic **5-second live refresh**, **pull-to-refresh**, **manual refresh button**, and an in-app **Cloud Sync Settings** modal.

---

## Architecture & Project Structure

The codebase is organized into two completely independent root directories (`Frontend/` and `Backend/`):

```text
Cricyy/
├── Frontend/                        # Flutter & Dart client (Android & Web)
│   ├── android/                     # Android native configuration
│   ├── web/                         # Web entrypoint & icons
│   ├── lib/
│   │   ├── core/                    # Theme, colors, typography, spacing, routes
│   │   ├── models/                  # Match, Innings, Batter, Bowler, Player models
│   │   ├── providers/               # MatchProvider & PlayerProvider state logic
│   │   ├── screens/                 # Home, Create Match, Live Scoring, Scorecard, History, Player Profile
│   │   ├── services/                # LocalStorageService, PlayerStatsAggregator, REST API clients
│   │   ├── widgets/                 # ScoreBadge, PlayerPerformanceChart, PlayerQuickViewSheet, AppCard
│   │   └── main.dart                # Application entrypoint
│   ├── test/                        # Widget tests
│   └── pubspec.yaml
│
└── Backend/                         # Node.js + Express + MongoDB REST API
    ├── config/                      # MongoDB connection & cricket rules constants
    ├── controllers/                 # Route handlers (Match, Innings, Delivery, Scorecard, Team, Player)
    ├── middleware/                  # Central error handler & Multer upload config
    ├── models/                      # Mongoose schemas
    ├── routes/                      # Express API route definitions
    ├── services/                    # Pure cricket scoring engine & statistics services
    ├── socketHandlers/              # Reserved for future real-time WebSocket support
    ├── tests/                       # Jest scoring engine unit tests
    ├── uploads/                     # Optional player/team profile image storage
    ├── utils/                       # Cricket math & API response helpers
    ├── validators/                  # express-validator request validation rules
    ├── .env.example                 # Environment variables template
    ├── index.js                     # Express server entrypoint
    └── package.json
```

---

## Getting Started

### Prerequisites
- **Node.js** (v18+ recommended) & **npm**
- **MongoDB** (local instance on port `27017` or MongoDB Atlas URI)
- **Flutter SDK** (`Dart ^3.12.2`)

### 1. Backend Setup

```bash
cd Backend
npm install
```

Create your local `.env` file from `.env.example`:

```powershell
# Windows (PowerShell)
Copy-Item .env.example .env
```

```bash
# macOS / Linux
cp .env.example .env
```

Review `Backend/.env` (default `PORT=5000`, `MONGODB_URI=mongodb://127.0.0.1:27017/cricyy`) and start the server:

```bash
# Development mode (with nodemon)
npm run dev

# Production mode
npm start
```

Verify the server health check at `http://localhost:5000/api/health`.

### 2. Frontend Setup

```bash
cd Frontend
flutter pub get
```

Run on your target platform:

```bash
# Android device / emulator
flutter run

# Chrome (Web)
flutter run -d chrome --web-port 3000 --web-hostname localhost
```

---

## Free Cloud Deployment (Vercel + MongoDB Atlas)

Deploy both the Express API and Flutter Web frontend for **free** using **Vercel Hobby** + **MongoDB Atlas M0 (512 MB)**:

👉 See the complete step-by-step instructions in [VERCEL_DEPLOYMENT_GUIDE.md](./VERCEL_DEPLOYMENT_GUIDE.md).

---

## API Overview

All scoring calculations on the server live under `Backend/services/` and expose REST endpoints under `/api`:

| Resource | Base Endpoint | Capabilities |
| :--- | :--- | :--- |
| **Health** | `/api/health` | Server & MongoDB connection verification |
| **Shared Matches** | `/api/shared-matches` | Multi-user live match sync, create/update/fetch across devices |
| **Players** | `/api/players` | CRUD, career statistics, match-by-match history |
| **Teams** | `/api/teams` | Team CRUD and roster member management |
| **Matches** | `/api/matches` | Create match, manage innings, record/correct/undo deliveries, scorecard, complete match |

See [Backend/README.md](./Backend/README.md) for the complete endpoint table and environment variable reference.

---

## Running Tests

```bash
# Backend unit tests (Jest)
cd Backend
npm test

# Frontend widget tests (Flutter)
cd Frontend
flutter test
```
