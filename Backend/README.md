# Cricyy Backend

> Node.js + Express.js + MongoDB backend for the Cricyy Cricket Scoring App.

## Quick Start

```powershell
# 1. Install dependencies
cd Backend
npm install

# 2. Copy the example env file and fill in your MongoDB URI
Copy-Item .env.example .env

# 3. Start development server (auto-restarts on save)
npx nodemon index.js

# 4. Run tests
npm test
```

## Folder Structure

```
Backend/
├── config/
│   ├── db.js            ← MongoDB connection
│   └── constants.js     ← App-wide constants (dismissal types, formats, etc.)
├── controllers/         ← Handle HTTP req/res, call services
├── middleware/          ← Error handler, file upload
├── models/              ← Mongoose schemas
├── routes/              ← Express route definitions
├── services/            ← Business logic & scoring engine
├── socketHandlers/      ← Future real-time support (empty in v1)
├── uploads/             ← Player/team images
├── utils/               ← Reusable math helpers
├── validators/          ← Semantic request validation
├── tests/               ← Jest unit tests
├── .env                 ← Your local environment variables (not in git)
├── .env.example         ← Template for environment variables
└── index.js             ← Entry point
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/health | Server health check |
| GET | /api/players | List all players |
| POST | /api/players | Create a player |
| GET | /api/players/:id | Get a player |
| PUT | /api/players/:id | Update a player |
| DELETE | /api/players/:id | Deactivate a player |
| GET | /api/players/:id/statistics | Career stats |
| GET | /api/players/:id/history | Match history |
| GET | /api/teams | List teams |
| POST | /api/teams | Create a team |
| GET | /api/teams/:id | Get a team |
| PUT | /api/teams/:id | Update a team |
| POST | /api/teams/:id/members | Add player to team |
| DELETE | /api/teams/:id/members/:pid | Remove player from team |
| GET | /api/matches | List matches |
| POST | /api/matches | Create a match |
| GET | /api/matches/:id | Get a match |
| POST | /api/matches/:id/innings | Start an innings |
| GET | /api/matches/:id/innings | Get innings |
| POST | /api/matches/:id/deliveries | Record a delivery |
| GET | /api/matches/:id/deliveries | List deliveries |
| POST | /api/matches/:id/undo | Undo last delivery |
| PUT | /api/matches/:id/deliveries/:did | Correct last delivery |
| GET | /api/matches/:id/scorecard | Full scorecard |
| POST | /api/matches/:id/complete | Complete a match |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| PORT | 5000 | HTTP server port |
| NODE_ENV | development | Environment |
| MONGODB_URI | mongodb://127.0.0.1:27017/cricyy | MongoDB connection string |
| UPLOAD_DIR | uploads | Directory for uploaded files |
| MAX_FILE_SIZE_MB | 5 | Max upload size in MB |
