import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ta3dia/models/organization_model.dart';

class OrgService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Organization? _currentOrg;
  List<Organization> _myOrgs = [];
  List<Organization> _allApprovedOrgs = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<DocumentSnapshot>? _orgWatchSub;

  Organization? get currentOrg => _currentOrg;
  String? get currentOrgId => _currentOrg?.id;
  List<Organization> get myOrgs => _myOrgs;
  List<Organization> get allApprovedOrgs => _allApprovedOrgs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _error;

  Future<String?> createOrganization({
    required String name,
    required String password,
    required String creatorUid,
    required String creatorName,
  }) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      final orgData = {
        'name': name,
        'password': password,
        'createdBy': creatorUid,
        'creatorName': creatorName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'memberCount': 1,
        'taadiaCount': 0,
      };

      final docRef = await _firestore.collection('organizations').add(orgData);
      await _firestore
          .collection('organizations')
          .doc(docRef.id)
          .collection('members')
          .doc(creatorUid)
          .set({
        'uid': creatorUid,
        'name': creatorName,
        'role': 'admin',
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });
      await _setMembership(docRef.id, creatorUid, creatorName, 'admin');

      _isLoading = false;
      notifyListeners();
      return docRef.id;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> joinOrganization({
    required String orgId,
    required String password,
    required String uid,
    required String userName,
  }) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      final orgDoc = await _firestore.collection('organizations').doc(orgId).get();
      if (!orgDoc.exists) {
        _error = 'Organization not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final orgData = orgDoc.data()!;
      if (orgData['status'] != 'approved') {
        _error = 'Organization is not approved yet';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final storedPassword = orgData['password'] ?? '';
      if (storedPassword != password) {
        _error = 'Incorrect password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final existingMember = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(uid)
          .get();
      if (existingMember.exists) {
        final memberData = existingMember.data();
        if (memberData?['status'] == 'removed') {
          final previousRole = memberData?['role'] ?? 'user';
          await _firestore
              .collection('organizations')
              .doc(orgId)
              .collection('members')
              .doc(uid)
              .set({
            'uid': uid,
            'name': userName,
            'role': previousRole,
            'joinedAt': FieldValue.serverTimestamp(),
            'status': 'active',
          }, SetOptions(merge: true));
          await _firestore.collection('organizations').doc(orgId).update({
            'memberCount': FieldValue.increment(1),
          });
          await _setMembership(orgId, uid, userName, previousRole);
          _isLoading = false;
          if (_currentOrg == null) {
            _currentOrg = Organization.fromFirestore(orgDoc);
          }
          notifyListeners();
          return true;
        }
        _error = 'Already a member';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(uid)
          .set({
        'uid': uid,
        'name': userName,
        'role': 'user',
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });
      await _firestore.collection('organizations').doc(orgId).update({
        'memberCount': FieldValue.increment(1),
      });
      await _setMembership(orgId, uid, userName, 'user');

      _isLoading = false;
      if (_currentOrg == null) {
        _currentOrg = Organization.fromFirestore(orgDoc);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMyOrgs(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      final membershipSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('memberships')
          .get();

      _myOrgs = [];
      if (membershipSnapshot.docs.isEmpty) {
        final snapshot = await _firestore
            .collection('organizations')
            .where('status', isEqualTo: 'approved')
            .get();
        for (final doc in snapshot.docs) {
          final memberDoc = await _firestore
              .collection('organizations')
              .doc(doc.id)
              .collection('members')
              .doc(uid)
              .get();
          if (memberDoc.exists) {
            final memberData = memberDoc.data();
            if (memberData?['status'] != 'removed') {
              _myOrgs.add(Organization.fromFirestore(doc));
            }
          }
        }
      } else {
        final orgIds = membershipSnapshot.docs
            .where((d) => d.data()['status'] != 'removed')
            .map((d) => d.id)
            .toList();
        final orgDocs = await Future.wait(
          orgIds.map((id) => _firestore.collection('organizations').doc(id).get()),
        );
        for (final doc in orgDocs) {
          if (doc.exists) _myOrgs.add(Organization.fromFirestore(doc));
        }
      }

      if (_myOrgs.length == 1 && _currentOrg == null) {
        _currentOrg = _myOrgs.first;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> leaveOrganization(String orgId, String uid) async {
    try {
      final memberDoc = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(uid)
          .get();
      if (memberDoc.exists) {
        final data = memberDoc.data()!;
        final role = data['role'] ?? 'user';
        final orgDoc =
            await _firestore.collection('organizations').doc(orgId).get();
        if (role == 'admin' && orgDoc.data()?['createdBy'] == uid) {
          final adminDocs = await _firestore
              .collection('organizations')
              .doc(orgId)
              .collection('members')
              .where('role', isEqualTo: 'admin')
              .where('status', isEqualTo: 'active')
              .get();
          final hasOtherAdmin = adminDocs.docs.any((d) => d.id != uid);
          if (!hasOtherAdmin) {
            _error = 'owner_cannot_leave';
            notifyListeners();
            return false;
          }
        }
      }

      await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(uid)
          .update({'status': 'removed'});
      await _firestore.collection('organizations').doc(orgId).update({
        'memberCount': FieldValue.increment(-1),
      });
      await _removeMembership(orgId, uid);
      _myOrgs.removeWhere((o) => o.id == orgId);
      if (_currentOrg?.id == orgId) {
        _currentOrg = _myOrgs.isNotEmpty ? _myOrgs.first : null;
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadApprovedOrgs() async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .where('status', isEqualTo: 'approved')
          .get();
      _allApprovedOrgs = snapshot.docs
          .map((doc) => Organization.fromFirestore(doc))
          .toList();
      _allApprovedOrgs.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  void setCurrentOrg(Organization? org) {
    _currentOrg = org;
    _watchOrgDocument(org?.id);
    notifyListeners();
  }

  Future<Organization?> getOrg(String orgId) async {
    try {
      final doc =
          await _firestore.collection('organizations').doc(orgId).get();
      if (!doc.exists) return null;
      return Organization.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  void _watchOrgDocument(String? orgId) {
    _orgWatchSub?.cancel();
    if (orgId == null) return;
    _orgWatchSub = _firestore
        .collection('organizations')
        .doc(orgId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) {
        _myOrgs.removeWhere((o) => o.id == orgId);
        _allApprovedOrgs.removeWhere((o) => o.id == orgId);
        _currentOrg = _myOrgs.isNotEmpty ? _myOrgs.first : null;
        _watchOrgDocument(_currentOrg?.id);
        notifyListeners();
      }
    });
  }

  Future<bool> isMember(String orgId, String uid) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(uid)
          .get();
      if (doc.exists) {
        return doc.data()?['status'] != 'removed';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getMemberRole(String orgId, String uid) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(uid)
          .get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> loadMembers(String orgId) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> loadOrgPassword(String orgId) async {
    try {
      final doc =
          await _firestore.collection('organizations').doc(orgId).get();
      return doc.data()?['password'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateOrgName(String orgId, String newName) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(orgId)
          .update({'name': newName});
      _currentOrg = _currentOrg?.copyWith(name: newName);
      final idx = _myOrgs.indexWhere((o) => o.id == orgId);
      if (idx >= 0) _myOrgs[idx] = _myOrgs[idx].copyWith(name: newName);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateOrgPassword(String orgId, String newPassword) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(orgId)
          .update({'password': newPassword});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeMember(String orgId, String memberUid) async {
    try {
      await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(memberUid)
          .update({'status': 'removed'});
      await _firestore.collection('organizations').doc(orgId).update({
        'memberCount': FieldValue.increment(-1),
      });
      await _removeMembership(orgId, memberUid);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleMemberRole(String orgId, String memberUid) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(memberUid)
          .get();
      if (!doc.exists) return false;
      final data = doc.data()!;
      final currentRole = data['role'] ?? 'user';
      final newRole = currentRole == 'admin' ? 'user' : 'admin';
      await doc.reference.update({'role': newRole});
      await _setMembership(orgId, memberUid, data['name'] ?? '', newRole);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _setMembership(
    String orgId,
    String uid,
    String name,
    String role,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('memberships')
          .doc(orgId)
          .set({
        'orgId': orgId,
        'name': name,
        'role': role,
        'status': 'active',
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _removeMembership(String orgId, String uid) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('memberships')
          .doc(orgId)
          .delete();
    } catch (_) {}
  }

  Future<String?> getMemberEmail(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['email'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<List<Organization>> getAdminOrgs(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .where('createdBy', isEqualTo: uid)
          .get();
      return snapshot.docs
          .map((doc) => Organization.fromFirestore(doc))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> deleteOrganization(String orgId) async {
    try {
      final subcollections = ['members', 'taadia', 'taadias', 'evaluations', 'groups'];
      for (final subcol in subcollections) {
        final snapshot = await _firestore
            .collection('organizations')
            .doc(orgId)
            .collection(subcol)
            .get();
        for (final doc in snapshot.docs) {
          if (subcol == 'members') {
            await _removeMembership(orgId, doc.id);
          }
          await doc.reference.delete();
        }
      }
      await _firestore.collection('organizations').doc(orgId).delete();
      _myOrgs.removeWhere((o) => o.id == orgId);
      _allApprovedOrgs.removeWhere((o) => o.id == orgId);
      if (_currentOrg?.id == orgId) {
        _currentOrg = _myOrgs.isNotEmpty ? _myOrgs.first : null;
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _orgWatchSub?.cancel();
    super.dispose();
  }
}
