import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ta3dia/models/organization_model.dart';

class SuperAdminService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSuperAdmin = false;
  List<Organization> _pendingOrgs = [];
  List<Organization> _approvedOrgs = [];
  List<Organization> _rejectedOrgs = [];
  bool _isLoading = false;
  String? _error;

  bool get isSuperAdmin => _isSuperAdmin;
  List<Organization> get pendingOrgs => _pendingOrgs;
  List<Organization> get approvedOrgs => _approvedOrgs;
  List<Organization> get rejectedOrgs => _rejectedOrgs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> checkSuperAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final wasSuperAdmin = _isSuperAdmin;
      _isSuperAdmin = doc.exists && doc.data()?['role'] == 'super_admin';
      if (wasSuperAdmin != _isSuperAdmin) notifyListeners();
    } catch (_) {
      _isSuperAdmin = false;
    }
  }

  Stream<List<Organization>> get pendingOrgsStream {
    return _firestore
        .collection('organizations')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Organization.fromFirestore(doc))
            .toList());
  }

  Stream<List<Organization>> get allOrgsStream {
    return _firestore
        .collection('organizations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Organization.fromFirestore(doc))
            .toList());
  }

  Future<void> loadAllOrgs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .orderBy('createdAt', descending: true)
          .get();
      final orgs = snapshot.docs
          .map((doc) => Organization.fromFirestore(doc))
          .toList();
      _pendingOrgs = orgs.where((o) => o.isPending).toList();
      _approvedOrgs = orgs.where((o) => o.isApproved).toList();
      _rejectedOrgs = orgs.where((o) => o.isRejected).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> approveOrg(String orgId) async {
    try {
      await _firestore.collection('organizations').doc(orgId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      await loadAllOrgs();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectOrg(String orgId) async {
    try {
      await _firestore.collection('organizations').doc(orgId).update({
        'status': 'rejected',
      });
      await loadAllOrgs();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOrg(String orgId) async {
    try {
      final members =
          await _firestore.collection('organizations').doc(orgId).collection('members').get();
      for (final doc in members.docs) {
        await doc.reference.delete();
      }
      final taadias =
          await _firestore.collection('organizations').doc(orgId).collection('taadia').get();
      for (final doc in taadias.docs) {
        await doc.reference.delete();
      }
      final evaluations =
          await _firestore.collection('organizations').doc(orgId).collection('evaluations').get();
      for (final doc in evaluations.docs) {
        await doc.reference.delete();
      }
      final groups =
          await _firestore.collection('organizations').doc(orgId).collection('groups').get();
      for (final doc in groups.docs) {
        await doc.reference.delete();
      }
      final feedback =
          await _firestore.collection('organizations').doc(orgId).collection('feedback').get();
      for (final doc in feedback.docs) {
        await doc.reference.delete();
      }
      await _firestore.collection('organizations').doc(orgId).delete();
      await loadAllOrgs();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> getOrgStats(String orgId) async {
    final members =
        await _firestore.collection('organizations').doc(orgId).collection('members').get();
    final taadias =
        await _firestore.collection('organizations').doc(orgId).collection('taadia').get();
    final evaluations =
        await _firestore.collection('organizations').doc(orgId).collection('evaluations').get();
    return {
      'members': members.docs.length,
      'taadias': taadias.docs.length,
      'evaluations': evaluations.docs.length,
    };
  }

  @override
  void dispose() {
    super.dispose();
  }
}
