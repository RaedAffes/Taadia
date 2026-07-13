import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ta3dia/l10n/app_localizations.dart';
import 'package:ta3dia/models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GoogleSignIn? _googleSignIn;
  StreamSubscription<QuerySnapshot>? _usersSub;
  List<AppUser> _allUsers = [];

  List<AppUser> get allUsers => _allUsers;

  GoogleSignIn get _googleSignInInstance {
    _googleSignIn ??= GoogleSignIn(
      serverClientId: '308482841964-lc4gs73gb1d3671l489n5k9u6dru88eh.apps.googleusercontent.com',
    );
    return _googleSignIn!;
  }

  User? _currentUser;
  bool _isLoading = true;
  String? _errorCode;
  AppUser? _appUser;
  bool _authReady = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage =>
      _errorCode != null ? _getErrorMessage(_errorCode!) : null;
  String? get errorCode => _errorCode;
  AppUser? get appUser => _appUser;
  bool get authReady => _authReady;

  AuthService() {
    if (_auth.currentUser == null) {
      _currentUser = null;
      _appUser = null;
      _isLoading = false;
      _authReady = true;
    } else {
      _currentUser = _auth.currentUser;
      _authReady = true;
      _isLoading = false;
    }
    _auth.authStateChanges().listen((User? user) async {
      _currentUser = user;
      if (user != null) {
        await _ensureUserDoc(user);
      } else {
        _appUser = null;
        notifyListeners();
      }
      if (!_authReady) {
        _isLoading = false;
        _authReady = true;
        notifyListeners();
      }
    });
  }

  Future<void> _ensureUserDoc(User user) async {
    try {
      DocumentSnapshot<Map<String, dynamic>>? doc;
      try {
        doc = await _firestore.collection('users').doc(user.uid).get(
          const GetOptions(source: Source.cache),
        ).timeout(Duration(seconds: 1));
      } catch (_) {
        doc = null;
      }
      if (doc != null && doc.exists) {
        final data = Map<String, dynamic>.from(doc.data()!);
        if (data['accountStatus'] == 'deleted') {
          await _auth.signOut();
          return;
        }
        _appUser = AppUser.fromFirestore(data);
        _authReady = true;
        _isLoading = false;
        notifyListeners();
        _firestore.collection('users').doc(user.uid).get().then((fresh) {
          if (!fresh.exists || fresh.data()?['accountStatus'] == 'deleted') return;
          final freshData = Map<String, dynamic>.from(fresh.data()!);
          if (_appUser?.role != freshData['role']) {
            _appUser = AppUser.fromFirestore(freshData);
            notifyListeners();
          }
        });
        return;
      }
      final networkDoc = await _firestore.collection('users').doc(user.uid).get();
      if (networkDoc.exists) {
        final data = Map<String, dynamic>.from(networkDoc.data()!);
        if (data['accountStatus'] == 'deleted') {
          await _auth.signOut();
          return;
        }
        _appUser = AppUser.fromFirestore(data);
      } else {
        final now = FieldValue.serverTimestamp();
        final provider = user.isAnonymous
            ? 'anonymous'
            : user.providerData.any((p) => p.providerId == 'google.com')
            ? 'google'
            : 'email';
        final userData = {
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName': user.displayName ?? 'User',
          'role': 'user',
          'authProvider': provider,
          'createdAt': now,
          'lastLoginAt': now,
        };
        await _firestore.collection('users').doc(user.uid).set(userData);
        _appUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          role: 'user',
          authProvider: provider,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
      }
    } catch (_) {}
  }

  bool get isAdmin => _appUser?.isAdmin ?? false;

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _errorCode = null;
      _isLoading = true;
      notifyListeners();

      final isAnonymous = _auth.currentUser?.isAnonymous ?? false;
      UserCredential result;

      if (isAnonymous) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        result = await _auth.currentUser!.linkWithCredential(credential);
      } else {
        result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      if (result.user != null) {
        await result.user!.updateDisplayName(displayName);

        final existing = await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .get();
        if (existing.exists) {
          await existing.reference.update({
            'email': email,
            'displayName': displayName,
            'authProvider': 'email',
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        } else {
          await _firestore.collection('users').doc(result.user!.uid).set({
            'uid': result.user!.uid,
            'email': email,
            'displayName': displayName,
            'role': 'user',
            'authProvider': 'email',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }

        _currentUser = result.user;
        await _ensureUserDoc(result.user!);
        _cleanupDeletedDocs(email);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final ok = await _handleDeletedAccountReRegister(
            email, password, displayName);
        if (ok) return true;
      }
      _errorCode = e.code;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorCode = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> _handleDeletedAccountReRegister(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('accountStatus', isEqualTo: 'deleted')
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        _errorCode = 'email-already-in-use';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final deletedUid = snapshot.docs.first.id;
      await _firestore.collection('users').doc(deletedUid).delete();
      try {
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        await _auth.currentUser?.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
          _errorCode = 'deleted-account-wrong-password';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        rethrow;
      }
      return signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> _cleanupDeletedDocs(String email) async {
    try {
      final snap = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('accountStatus', isEqualTo: 'deleted')
          .get();
      for (var doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      _errorCode = null;
      _isLoading = true;
      notifyListeners();

      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        final doc = await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .get();
        if (doc.exists && doc.data()?['accountStatus'] == 'deleted') {
          await _auth.signOut();
          _errorCode = 'user-deleted';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        await _firestore.collection('users').doc(result.user!.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        _currentUser = result.user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _errorCode = e.code;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorCode = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> signInWithGoogle() async {
    try {
      _errorCode = null;
      _isLoading = true;
      notifyListeners();

      final isAnonymous = _auth.currentUser?.isAnonymous ?? false;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        if (isAnonymous) {
          await _auth.currentUser!.linkWithPopup(provider);
        } else {
          await _auth.signInWithPopup(provider);
        }
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignInInstance
            .signIn();
        if (googleUser == null) {
          _isLoading = false;
          notifyListeners();
          return false;
        }
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        if (isAnonymous) {
          await _auth.currentUser!.linkWithCredential(credential);
        } else {
          await _auth.signInWithCredential(credential);
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorCode = e.code;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorCode = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> signInAnonymously({String? displayName}) async {
    try {
      _errorCode = null;
      _isLoading = true;
      notifyListeners();

      final result = await _auth.signInAnonymously();
      final user = result.user;

      if (displayName != null && user != null) {
        await user.updateDisplayName(displayName);
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName': displayName,
          'role': 'user',
          'authProvider': 'anonymous',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        _appUser = AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: displayName,
          role: 'user',
          authProvider: 'anonymous',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorCode = e.code;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorCode = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn?.signOut();
    }
    await _auth.signOut();
    _currentUser = null;
    _appUser = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorCode = e.code;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({String? displayName}) async {
    try {
      if (_currentUser != null) {
        if (displayName != null) {
          await _currentUser!.updateDisplayName(displayName);
          await _firestore.collection('users').doc(_currentUser!.uid).update({
            'displayName': displayName,
          });
        }
        if (_appUser != null) {
          _appUser = AppUser(
            uid: _appUser!.uid,
            email: _appUser!.email,
            displayName: displayName ?? _appUser!.displayName,
            role: _appUser!.role,
            promotedBy: _appUser!.promotedBy,
            authProvider: _appUser!.authProvider,
            createdAt: _appUser!.createdAt,
            lastLoginAt: _appUser!.lastLoginAt,
          );
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorCode = 'Error: ${e.toString()}';
      notifyListeners();
    }
    return false;
  }

  Future<List<AppUser>> getAllUsers() async {
    _usersSub ??= _firestore.collection('users').snapshots().listen((snapshot) {
      _allUsers = snapshot.docs
          .where((doc) => doc.data()['accountStatus'] != 'deleted')
          .map((doc) => AppUser.fromFirestore(Map<String, dynamic>.from(doc.data())))
          .toList();
      notifyListeners();
    });
    final snapshot = await _firestore.collection('users').get();
    _allUsers = snapshot.docs
        .where((doc) => doc.data()['accountStatus'] != 'deleted')
        .map((doc) => AppUser.fromFirestore(Map<String, dynamic>.from(doc.data())))
        .toList();
    return _allUsers;
  }

  Future<AppUser?> getUserByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return AppUser.fromFirestore(snapshot.docs.first.data());
      }
    } catch (_) {}
    return null;
  }

  Future<bool> setUserRole(
    String uid,
    String role, {
    String? promoterUid,
  }) async {
    try {
      final updates = <String, dynamic>{'role': role};
      if (role == 'admin' && promoterUid != null) {
        updates['promotedBy'] = promoterUid;
      }
      if (role == 'user') {
        updates['promotedBy'] = '';
      }
      await _firestore.collection('users').doc(uid).update(updates);
      return true;
    } catch (e) {
      _errorCode = 'Error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String uid) async {
    try {
      _errorCode = null;
      await _firestore.collection('users').doc(uid).set({
        'accountStatus': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final evals = await _firestore
          .collection('evaluations')
          .where('userId', isEqualTo: uid)
          .get();
      for (var doc in evals.docs) {
        await doc.reference.delete();
      }
      try {
        await FirebaseFunctions.instance
            .httpsCallable('deleteAuthUser')
            .call({'uid': uid});
      } catch (_) {
        // Cloud function may not be deployed yet; skip auth deletion
      }
      return true;
    } catch (e) {
      _errorCode = 'Error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      _errorCode = null;
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) return false;

      try {
        await user.delete();
        await _firestore.collection('users').doc(user.uid).delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          _errorCode = 'requires-recent-login';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        rethrow;
      }

      _currentUser = null;
      _appUser = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorCode = e.code;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorCode = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reauthenticateAndDelete({String? password}) async {
    try {
      _errorCode = null;
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) return false;

      final provider =
          user.providerData.any((p) => p.providerId == 'google.com')
          ? 'google'
          : 'email';

      if (provider == 'google') {
        if (kIsWeb) {
          await user.reauthenticateWithPopup(GoogleAuthProvider());
        } else {
          final googleUser = await _googleSignInInstance.signIn();
          if (googleUser == null) {
            _isLoading = false;
            _errorCode = 'cancelled';
            notifyListeners();
            return false;
          }
          final auth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: auth.accessToken,
            idToken: auth.idToken,
          );
          await user.reauthenticateWithCredential(credential);
        }
      } else {
        if (password == null || password.isEmpty) {
          _isLoading = false;
          _errorCode = 'password-required';
          notifyListeners();
          return false;
        }
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }

      await user.delete();

      _currentUser = null;
      _appUser = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorCode = e.code;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorCode = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String? localizedError(AppLocalizations l) {
    if (_errorCode == null) return null;
    switch (_errorCode!) {
      case 'user-not-found':
        return l.authErrorUserNotFound;
      case 'wrong-password':
        return l.authErrorWrongPassword;
      case 'email-already-in-use':
        return l.authErrorEmailAlreadyInUse;
      case 'weak-password':
        return l.authErrorWeakPassword;
      case 'invalid-email':
        return l.authErrorInvalidEmail;
      case 'user-disabled':
        return l.authErrorUserDisabled;
      case 'user-deleted':
        return l.accountDeletedByAdmin;
      case 'too-many-requests':
        return l.authErrorTooManyRequests;
      case 'deleted-account-wrong-password':
        return l.deletedAccountWrongPassword;
      default:
        return l.authErrorDefault;
    }
  }

  void clearError() {
    _errorCode = null;
    notifyListeners();
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email address.';
      case 'user-deleted':
        return 'Your account has been deleted by the admin.';
      case 'deleted-account-wrong-password':
        return 'This email belongs to a deleted account. Please use the original password to reclaim it.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    super.dispose();
  }
}
