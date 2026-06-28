/**
 * One-time migration: add `visibility: 'public'` to all taadias
 * that are missing the field (legacy documents).
 *
 * Usage:
 *   1. Download your Firebase service account key from
 *      Project Settings > Service accounts > Generate new private key
 *   2. Set GOOGLE_APPLICATION_CREDENTIALS to the path of that file
 *      OR place it next to this script as service-account.json
 *   3. Run: node migrate_visiblity.js
 */
const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = process.env.GOOGLE_APPLICATION_CREDENTIALS
  || path.join(__dirname, 'service-account.json');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

async function migrate() {
  const snapshot = await db.collection('taadia').get();
  let updated = 0;
  let skipped = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (data.visibility == null) {
      await doc.ref.update({ visibility: 'public' });
      console.log(`Updated ${doc.id} — set visibility: public`);
      updated++;
    } else {
      skipped++;
    }
  }

  console.log(`Done. ${updated} updated, ${skipped} already had visibility.`);
}

migrate().catch(console.error);
