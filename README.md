# Ta3dia (تuـدية)

A Quran memorization tracking app for teachers and students. Built with Flutter + Firebase.

## Features

- Teachers create assessments (called "Taadia") and grade students on recitation
- Visual cube-based scoring for errors
- AI picks random Quran verses for each assessment
- Generate PDF reports
- Works offline — data syncs when you're back online
- Arabic + English support

## Project Structure

```
📁 lib/                → The app code
   ├── screens/        → App pages (login, home, evaluation, admin, etc.)
   ├── services/       → Talks to Firebase
   ├── models/         → Data types (user, assessment, evaluation, etc.)
   ├── widgets/        → Reusable buttons, headers, etc.
   ├── providers/      → App state management
   ├── l10n/           → Arabic & English translations
   └── ai/             → Quran verse picker
📁 scripts/            → Backup & migration tools
📁 functions/          → Cloud Functions (optional — needs Blaze plan)
📁 android/ ios/ web/  → Platform-specific files (ignore these)
```

## Getting Started

### 1. Clone & Install

```bash
git clone https://github.com/RaedAffes/Taadia.git
cd ta3dia
flutter pub get
```

### 2. Run the App

```bash
flutter run
```

That's it — the app connects to the existing Firebase project (`ta3dia`).

## Backup (GitHub Actions)

The app automatically backs up Firestore data every hour to a second Firebase project (`ta3dia-backup`).

- The backup script lives in `scripts/backup-periodic.js`
- It runs via GitHub Actions (see `.github/workflows/backup-sync.yml`)

**To set up backups, add two GitHub Secrets:**

1. Go to your repo → **Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Add:

| Secret name | What it is |
|-------------|-----------|
| `TA3DIA_SERVICE_ACCOUNT` | Base64 of `scripts/ta3dia-service-account.json` |
| `TA3DIA_BACKUP_SERVICE_ACCOUNT` | Base64 of `scripts/ta3dia-backup-service-account.json` |

You get these files from Firebase Console → Project Settings → Service Accounts → "Generate new private key".

## Run Backup Locally

```bash
cd scripts
npm install
node backup-initial.js
```

## ⚠️ Important

Never commit these files:

- `scripts/*service-account*.json` (Firebase secret keys)
- `.env` or `functions/.env` (environment variables)
