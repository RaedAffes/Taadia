# Scripts

## migrate_visiblity.js

Adds `visibility: 'public'` to legacy taadia documents that don't have the field.
Run once after deploying the updated app.

### Steps

1. Enable the Cloud Firestore API for your project at
   https://console.cloud.google.com/apis/library/firestore.googleapis.com
2. Generate a service account key at
   Firebase Console > Project Settings > Service accounts > "Generate new private key"
3. Save the JSON file as `service-account.json` in this `scripts/` folder
4. Install dependencies: `npm install firebase-admin`
5. Run: `node migrate_visiblity.js`
