/**
 * One-time bulk copy: export all Firestore data from ta3dia to ta3dia-backup.
 *
 * Prerequisites:
 *   1. Create the ta3dia-backup Firebase project and enable Firestore
 *   2. Generate service account keys for BOTH projects:
 *        Firebase Console > Project Settings > Service accounts > "Generate new private key"
 *   3. Save the keys in this folder as:
 *        - ta3dia-service-account.json   (for the source)
 *        - ta3dia-backup-service-account.json   (for the backup)
 *   4. Run: node backup-initial.js
 */
const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');
const path = require('path');

const SOURCE_PROJECT_ID = 'ta3dia';
const BACKUP_PROJECT_ID = 'ta3dia-backup';

// ---------- Source (ta3dia) ----------
const sourceKeyPath = path.join(__dirname, 'ta3dia-service-account.json');
const sourceServiceAccount = require(sourceKeyPath);
const sourceApp = admin.initializeApp({
  credential: admin.cert(sourceServiceAccount),
  projectId: SOURCE_PROJECT_ID,
});
const sourceDb = getFirestore(sourceApp);

// ---------- Destination (ta3dia-backup) ----------
const backupKeyPath = path.join(__dirname, 'ta3dia-backup-service-account.json');
const backupServiceAccount = require(backupKeyPath);
const backupApp = admin.initializeApp({
  credential: admin.cert(backupServiceAccount),
  projectId: BACKUP_PROJECT_ID,
}, 'backup');
const backupDb = getFirestore(backupApp);

// ---------- Copy logic ----------
async function copyCollection(sourceCol, targetCol) {
  const snapshot = await sourceCol.get();
  let copied = 0;
  let skipped = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();

    // Copy the document
    await targetCol.doc(doc.id).set(data);
    console.log(`  ✓ ${doc.ref.path}`);
    copied++;

    // Recursively copy subcollections
    const subCollections = await doc.ref.listCollections();
    for (const subCol of subCollections) {
      const targetSubCol = targetCol.doc(doc.id).collection(subCol.id);
      const subResult = await copyCollection(subCol, targetSubCol);
      copied += subResult.copied;
      skipped += subResult.skipped;
    }
  }

  return { copied, skipped };
}

async function main() {
  console.log('Starting backup from ta3dia → ta3dia-backup...\n');

  const collections = await sourceDb.listCollections();
  let totalCopied = 0;

  for (const col of collections) {
    console.log(`Collection: ${col.id}`);
    const result = await copyCollection(col, backupDb.collection(col.id));
    console.log(`  → ${result.copied} docs copied\n`);
    totalCopied += result.copied;
  }

  console.log(`Backup complete. ${totalCopied} documents copied across ${collections.length} collections.`);
}

main().catch((err) => {
  console.error('Backup failed:', err);
  process.exit(1);
});
