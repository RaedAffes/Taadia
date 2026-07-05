"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteAuthUser = exports.syncSubToBackup = exports.syncToBackup = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v1/firestore");
const https_1 = require("firebase-functions/v1/https");
admin.initializeApp();
const db = admin.firestore();
// ---------- Backup sync (ta3dia → ta3dia-backup) ----------
const BACKUP_PROJECT_ID = 'ta3dia-backup';
let backupApp = null;
function getBackupDb() {
    if (!backupApp) {
        const raw = process.env.BACKUP_SERVICE_ACCOUNT;
        if (!raw) {
            throw new Error('BACKUP_SERVICE_ACCOUNT env var is not set. ' +
                'Add the ta3dia-backup service account key as a Cloud Functions secret or in .env file.');
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
exports.syncToBackup = (0, firestore_1.document)('{collection}/{docId}')
    .onWrite(async (change, context) => {
    // Skip deletes — we only copy, never remove from backup
    if (!change.after.exists)
        return;
    const { collection, docId } = context.params;
    const data = change.after.data();
    if (!data)
        return;
    try {
        const backupDb = getBackupDb();
        await backupDb.collection(collection).doc(docId).set(data);
        console.log(`Synced ${collection}/${docId} to backup`);
    }
    catch (err) {
        console.error(`Failed to sync ${collection}/${docId}:`, err);
    }
});
// Sync subcollections (e.g. feedback/{docId}/replies/{replyId})
exports.syncSubToBackup = (0, firestore_1.document)('{collection}/{docId}/{subcollection}/{subdocId}')
    .onWrite(async (change, context) => {
    if (!change.after.exists)
        return;
    const { collection, docId, subcollection, subdocId } = context.params;
    const data = change.after.data();
    if (!data)
        return;
    try {
        const backupDb = getBackupDb();
        await backupDb
            .collection(collection).doc(docId)
            .collection(subcollection).doc(subdocId)
            .set(data);
        console.log(`Synced ${collection}/${docId}/${subcollection}/${subdocId} to backup`);
    }
    catch (err) {
        console.error(`Failed to sync ${collection}/${docId}/${subcollection}/${subdocId}:`, err);
    }
});
// ---------- Existing functions ----------
exports.deleteAuthUser = (0, https_1.onCall)(async (data, context) => {
    const callerUid = context.auth?.uid;
    if (!callerUid) {
        throw new https_1.HttpsError('unauthenticated', 'You must be signed in to delete a user.');
    }
    const callerDoc = await db.collection('users').doc(callerUid).get();
    const callerData = callerDoc.data();
    if (!callerData || callerData['role'] !== 'admin') {
        throw new https_1.HttpsError('permission-denied', 'Only admins can delete users.');
    }
    const uid = data.uid;
    if (!uid) {
        throw new https_1.HttpsError('invalid-argument', 'The function must be called with a "uid" argument.');
    }
    try {
        await admin.auth().deleteUser(uid);
        try {
            await db.collection('users').doc(uid).delete();
        }
        catch {
            // Firestore doc may already be deleted
        }
        return { success: true };
    }
    catch (e) {
        if (e.code === 'auth/user-not-found') {
            try {
                await db.collection('users').doc(uid).delete();
            }
            catch {
                // ignore
            }
            return { success: true };
        }
        throw new https_1.HttpsError('internal', `Failed to delete auth user: ${e.message}`);
    }
});
//# sourceMappingURL=index.js.map