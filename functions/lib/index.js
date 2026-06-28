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
exports.deleteAuthUser = void 0;
const functions = __importStar(require("firebase-functions/v2"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
const db = admin.firestore();
exports.deleteAuthUser = functions.https.onCall(async (request) => {
    const callerUid = request.auth?.uid;
    if (!callerUid) {
        throw new functions.https.HttpsError('unauthenticated', 'You must be signed in to delete a user.');
    }
    const callerDoc = await db.collection('users').doc(callerUid).get();
    const callerData = callerDoc.data();
    if (!callerData || callerData['role'] !== 'admin') {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can delete users.');
    }
    const { uid } = request.data;
    if (!uid) {
        throw new functions.https.HttpsError('invalid-argument', 'The function must be called with a "uid" argument.');
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
            // Auth user already gone, clean up Firestore
            try {
                await db.collection('users').doc(uid).delete();
            }
            catch {
                // ignore
            }
            return { success: true };
        }
        throw new functions.https.HttpsError('internal', `Failed to delete auth user: ${e.message}`);
    }
});
//# sourceMappingURL=index.js.map