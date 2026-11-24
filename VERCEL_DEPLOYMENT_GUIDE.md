# Deploying Cricyy for Free on Vercel + MongoDB Atlas (512 MB Free Tier)

This guide explains **step by step** how to deploy both your **Backend API (Node.js + Express)** and **Frontend Web App (Flutter Web)** on **Vercel (Free Hobby Plan)** backed by **MongoDB Atlas (Free M0 — 512 MB)** so anyone anywhere can create matches and watch live updates automatically.

---

## Step 1: Set Up MongoDB Atlas (Free 512 MB)

1. Go to [https://www.mongodb.com/cloud/atlas](https://www.mongodb.com/cloud/atlas) and sign in or create a free account.
2. Create a new project (e.g. `Cricyy`) and click **Create** under **Deployments**.
3. Choose the **M0 (FREE)** tier (512 MB storage, shared RAM). Select a cloud region close to your users (e.g. Singapore or Mumbai) and click **Create Deployment**.
4. **Create a Database User**:
   - In **Security → Database Access → Add New Database User**, choose **Password** authentication.
   - Enter a username (e.g. `cricyy_admin`) and a strong alphanumeric password (avoid special characters like `@`, `:`, `/` or URL-encode them), and grant **Read and write to any database**.
5. **Allow Vercel Serverless Access**:
   - Go to **Security → Network Access → Add IP Address**.
   - Click **Allow Access from Anywhere** (`0.0.0.0/0`) and click **Confirm**.
   *(Required because Vercel serverless functions run from dynamic IP addresses.)*
6. **Copy Your Connection String**:
   - Go to **Database → Connect → Drivers → Node.js**.
   - Copy the SRV URI and add `/cricyy` as the database name right before the `?`:
     ```env
     mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/cricyy?retryWrites=true&w=majority
     ```

---

## Step 2: Push Your Code to GitHub

Commit and push all project updates to your GitHub repository (`main` branch):

```bash
git add .
git commit -m "Add Vercel serverless config, multi-user cloud sync, and neomorphism UI"
git push origin main
```

---

## Step 3: Deploy the Backend API on Vercel (Free)

The `Backend/` folder already includes:
- [`Backend/vercel.json`](Backend/vercel.json) (routes all HTTP traffic to Vercel serverless functions)
- [`Backend/api/index.js`](Backend/api/index.js) (serverless entrypoint)
- [`Backend/config/db.js`](Backend/config/db.js) (cached Mongoose connection for Vercel cold/warm reuse)
- `/api/shared-matches` endpoints for multi-user real-time match sharing

1. Go to [https://vercel.com](https://vercel.com) and sign in with **GitHub**.
2. Click **Add New… → Project** and import your `Cricyy` repository.
3. **Set Root Directory**:
   - Click **Edit** next to **Root Directory** and select **`Backend`**.
4. **Framework Preset**: Keep as **`Other`**. (Do not override Build/Output commands.)
5. **Add Environment Variables**:
   Expand **Environment Variables** and add:
   | Key | Value |
   | --- | --- |
   | `MONGODB_URI` | `mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/cricyy?retryWrites=true&w=majority` |
   | `NODE_ENV` | `production` |
6. Click **Deploy**.
7. Once finished, copy your Backend URL (e.g. `https://cricyy-backend.vercel.app`) and visit:
   ```
   https://cricyy-backend.vercel.app/api/health
   ```
   Confirm you see:
   ```json
   {
     "status": "ok",
     "message": "Cricyy backend is running",
     "database": "connected"
   }
   ```

---

## Step 4: Deploy the Flutter Web Frontend on Vercel (Free)

You can host the Flutter Web UI directly on Vercel as a second project pointing to your Backend URL!

1. In Vercel Dashboard, click **Add New… → Project** and import the **same `Cricyy` GitHub repository**.
2. **Set Root Directory**: Select **`Frontend`**.
3. **Framework Preset**: Select **`Other`**.
4. **Build & Output Settings** (toggle **Override** on each):
   - **Install Command**:
     ```bash
     if cd flutter; then git pull && cd ..; else git clone https://github.com/flutter/flutter.git -b stable --depth 1; fi && flutter/bin/flutter doctor && flutter/bin/flutter config --enable-web
     ```
   - **Build Command**:
     ```bash
     flutter/bin/flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL
     ```
   - **Output Directory**:
     ```text
     build/web
     ```
5. **Add Environment Variable**:
   | Key | Value |
   | --- | --- |
   | `API_BASE_URL` | `https://cricyy-backend.vercel.app/api` *(replace with your Step 3 URL)* |
6. Click **Deploy**! (The first Flutter Web build takes ~3–4 minutes while Vercel clones Flutter SDK.)

---

## Step 5: Using Android APK or Local App with Your Live Vercel Server

If you also run the app on Android or locally in Chrome and want everyone to sync with your Vercel + MongoDB Atlas server:

- **Option A (No rebuild required — Inside the App)**:
  Open Cricyy → tap the **Cloud Sync / Auto 5s pill** (or banner) on the Dashboard → enter your Vercel Backend URL (e.g. `https://cricyy-backend.vercel.app`) → tap **Save & Sync**.
- **Option B (Hardcode for APK builds)**:
  Set `defaultProdBaseUrl` in [`Frontend/lib/core/app_constants.dart`](Frontend/lib/core/app_constants.dart) or build with:
  ```bash
  flutter build apk --release --dart-define=API_BASE_URL=https://cricyy-backend.vercel.app/api
  ```

---

## Multi-User Auto-Refresh & Storage Notes

- **Multi-User Live Updates**: Every match created or scored is persisted in MongoDB Atlas (`SharedMatch` collection). Other users receive updates automatically every **5 seconds** (`AUTO 5s` indicator in top bar) or anytime via **Manual Refresh** / **Pull-to-Refresh**.
- **MongoDB Atlas 512 MB Free Limit**: Each full cricket match snapshot takes only ~3–8 KB in MongoDB Atlas — meaning 512 MB easily holds **50,000+ matches**!
