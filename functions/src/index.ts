import * as functions from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.firestore();

export const deleteAuthUser = functions.https.onCall<{ uid: string }>(
  async (request) => {
    const callerUid = request.auth?.uid;
    if (!callerUid) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'You must be signed in to delete a user.',
      );
    }

    const callerDoc = await db.collection('users').doc(callerUid).get();
    const callerData = callerDoc.data();
    if (!callerData || callerData['role'] !== 'admin') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can delete users.',
      );
    }

    const { uid } = request.data;
    if (!uid) {
      throw new functions.https.HttpsError(
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
        // Auth user already gone, clean up Firestore
        try {
          await db.collection('users').doc(uid).delete();
        } catch {
          // ignore
        }
        return { success: true };
      }
      throw new functions.https.HttpsError(
        'internal',
        `Failed to delete auth user: ${e.message}`,
      );
    }
  },
);
