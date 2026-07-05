import * as admin from 'firebase-admin';
import { document } from 'firebase-functions/v1/firestore';
import { onCall, HttpsError } from 'firebase-functions/v1/https';

admin.initializeApp();

const db = admin.firestore();

// ---------- Backup sync (ta3dia → ta3dia-backup) ----------

const BACKUP_PROJECT_ID = 'ta3dia-backup';

let backupApp: admin.app.App | null = null;

function getBackupDb(): admin.firestore.Firestore {
  if (!backupApp) {
    const raw = process.env.BACKUP_SERVICE_ACCOUNT;
    if (!raw) {
      throw new Error(
        'BACKUP_SERVICE_ACCOUNT env var is not set. ' +
        'Add the ta3dia-backup service account key as a Cloud Functions secret or in .env file.',
      );
    }
    // Support both raw JSON and base64-encoded JSON
    const json = raw.startsWith('{')
      ? raw
      : Buffer.from(raw, 'base64').toString('utf-8');
    backupApp = admin.initializeApp({
      credential: admin.credential.cert(JSON.parse(json)),
      projectId: BACKUP_PROJECT_ID,
    }, 'backup');
  }
  return admin.firestore(backupApp);
}

// Sync top-level collections (e.g. users, taadia, feedback, groups, evaluations)
export const syncToBackup = document('{collection}/{docId}')
  .onWrite(async (change, context) => {
    // Skip deletes — we only copy, never remove from backup
    if (!change.after.exists) return;

    const { collection, docId } = context.params;
    const data = change.after.data();
    if (!data) return;

    try {
      const backupDb = getBackupDb();
      await backupDb.collection(collection).doc(docId).set(data);
      console.log(`Synced ${collection}/${docId} to backup`);
    } catch (err) {
      console.error(`Failed to sync ${collection}/${docId}:`, err);
    }
  });

// Sync subcollections (e.g. feedback/{docId}/replies/{replyId})
export const syncSubToBackup = document('{collection}/{docId}/{subcollection}/{subdocId}')
  .onWrite(async (change, context) => {
    if (!change.after.exists) return;

    const { collection, docId, subcollection, subdocId } = context.params;
    const data = change.after.data();
    if (!data) return;

    try {
      const backupDb = getBackupDb();
      await backupDb
        .collection(collection).doc(docId)
        .collection(subcollection).doc(subdocId)
        .set(data);
      console.log(`Synced ${collection}/${docId}/${subcollection}/${subdocId} to backup`);
    } catch (err) {
      console.error(`Failed to sync ${collection}/${docId}/${subcollection}/${subdocId}:`, err);
    }
  });

// ---------- Existing functions ----------

export const deleteAuthUser = onCall(async (data, context) => {
  const callerUid = context.auth?.uid;
  if (!callerUid) {
    throw new HttpsError(
      'unauthenticated',
      'You must be signed in to delete a user.',
    );
  }

  const callerDoc = await db.collection('users').doc(callerUid).get();
  const callerData = callerDoc.data();
  if (!callerData || callerData['role'] !== 'admin') {
    throw new HttpsError(
      'permission-denied',
      'Only admins can delete users.',
    );
  }

  const uid = data.uid;
  if (!uid) {
    throw new HttpsError(
      'invalid-argument',
      'The function must be called with a "uid" argument.',
    );
  }

  try {
    await admin.auth().deleteUser(uid);
    try {
      await db.collection('users').doc(uid).delete();
    } catch {
      // Firestore doc may already be deleted
    }
    return { success: true };
  } catch (e: any) {
    if (e.code === 'auth/user-not-found') {
      try {
        await db.collection('users').doc(uid).delete();
      } catch {
        // ignore
      }
      return { success: true };
    }
    throw new HttpsError(
      'internal',
      `Failed to delete auth user: ${e.message}`,
    );
  }
});
