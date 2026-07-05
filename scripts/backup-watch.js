/**
 * Real-time Firestore backup watcher.
 * Listens for document changes in ta3dia and replicates them to ta3dia-backup.
 *
 * Run: node backup-watch.js
 * It stays running and syncs changes in real-time.
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

// ---------- Watch logic ----------

function syncDoc(doc) {
  if (!doc || !doc.exists) return;
  const data = doc.data();
  if (!data) return;
  const path = `${doc.ref.path}`;
  backupDb.doc(doc.ref.path).set(data)
    .then(() => console.log(`Synced ${path}`))
    .catch(err => console.error(`Failed to sync ${path}:`, err.message));
}

function watchCollection(collectionPath) {
  const ref = sourceDb.collection(collectionPath);

  ref.onSnapshot(
    (snapshot) => {
      snapshot.docChanges().forEach((change) => {
        if (change.type === 'removed') return;
        try {
          syncDoc(change.doc);
        } catch (err) {
          console.error('Error handling change:', err);
        }
      });
    },
    (err) => {
      console.error(`Listener error on ${collectionPath}:`, err.message);
    },
  );

  console.log(`Watching: ${collectionPath}`);
}

// Watch top-level collections
const collectionsToWatch = ['users', 'taadia', 'evaluations', 'groups', 'feedback'];

for (const col of collectionsToWatch) {
  watchCollection(col);
}

// Watch all 'replies' subcollections
sourceDb.collectionGroup('replies').onSnapshot(
  (snapshot) => {
    snapshot.docChanges().forEach((change) => {
      if (change.type === 'removed') return;
      try {
        syncDoc(change.doc);
      } catch (err) {
        console.error('Error handling reply change:', err);
      }
    });
  },
  (err) => console.error('Listener error on collectionGroup replies:', err.message),
);
console.log('Watching: collectionGroup replies');

console.log('\nBackup watcher running. Press Ctrl+C to stop.\n');
