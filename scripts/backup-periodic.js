/**
 * Periodic Firestore backup: ta3dia → ta3dia-backup.
 * Designed to run on a schedule (e.g. GitHub Actions, cron).
 *
 * Reads keys from environment variables (for GitHub Secrets):
 *   - TA3DIA_SERVICE_ACCOUNT      base64-encoded JSON
 *   - TA3DIA_BACKUP_SERVICE_ACCOUNT base64-encoded JSON
 *
 * Also supports local key files (same as backup-initial.js) as fallback.
 */
const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');
const path = require('path');

function loadKey(name, envVar) {
  const encoded = process.env[envVar];
  if (encoded) {
    return JSON.parse(Buffer.from(encoded, 'base64').toString('utf-8'));
  }
  // Fallback: try loading from a local file
  const filePath = path.join(__dirname, name);
  try {
    return require(filePath);
  } catch {
    throw new Error(
      `Missing key: set env var ${envVar} or place ${name} in scripts/`
    );
  }
}

const srcKey = loadKey('ta3dia-service-account.json', 'TA3DIA_SERVICE_ACCOUNT');
const bkpKey = loadKey(
  'ta3dia-backup-service-account.json',
  'TA3DIA_BACKUP_SERVICE_ACCOUNT'
);

const srcApp = admin.initializeApp({
  credential: admin.cert(srcKey),
  projectId: 'ta3dia',
});
const srcDb = getFirestore(srcApp);

const bkpApp = admin.initializeApp({
  credential: admin.cert(bkpKey),
  projectId: 'ta3dia-backup',
}, 'backup');
const bkpDb = getFirestore(bkpApp);

// ---------- Copy logic ----------

async function copyCollection(srcCol, bkpCol) {
  const snapshot = await srcCol.get();
  let count = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (!data) continue;

    await bkpCol.doc(doc.id).set(data);
    count++;

    // Recursively copy subcollections
    const subs = await doc.ref.listCollections();
    for (const sub of subs) {
      const target = bkpCol.doc(doc.id).collection(sub.id);
      count += (await copyCollection(sub, target)).count;
    }
  }

  return { count };
}

async function main() {
  const start = Date.now();
  console.log(`[${new Date().toISOString()}] Starting periodic backup...`);

  const collections = await srcDb.listCollections();
  let total = 0;

  for (const col of collections) {
    const result = await copyCollection(col, bkpDb.collection(col.id));
    console.log(`  ${col.id}: ${result.count} docs`);
    total += result.count;
  }

  const elapsed = ((Date.now() - start) / 1000).toFixed(1);
  console.log(`Done. ${total} docs synced in ${elapsed}s`);
}

main().catch((err) => {
  console.error('Backup failed:', err);
  process.exit(1);
});
