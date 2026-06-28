import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ta3dia/models/group_model.dart';
import 'package:ta3dia/services/connectivity_service.dart';
import 'package:ta3dia/services/offline_queue_service.dart';

class GroupService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityService _connectivityService;
  final OfflineQueueService _offlineQueue;
  StreamSubscription<QuerySnapshot>? _groupsSub;
  StreamSubscription<User?>? _authSub;

  List<GroupModel> _groups = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<GroupModel> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  GroupService(this._connectivityService, this._offlineQueue) {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) clear();
    });
  }

  Future<void> loadGroups() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _groupsSub?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cacheSnapshot = await _firestore
          .collection('groups')
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.cache));
      _groups = cacheSnapshot.docs
          .map((doc) => GroupModel.fromFirestore(
              doc.id, Map<String, dynamic>.from(doc.data() as Map)))
          .toList();
    } catch (_) {}

    _mergePendingLocalGroups();
    _isLoading = false;
    notifyListeners();

    _groupsSub = _firestore
        .collection('groups')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _groups = snapshot.docs
                .map((doc) => GroupModel.fromFirestore(
                    doc.id, Map<String, dynamic>.from(doc.data() as Map)))
                .toList();
            _mergePendingLocalGroups();
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (_) {
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<String?> createGroup(String name) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final data = <String, dynamic>{
      'name': name,
      'createdBy': user.uid,
      'createdAt': DateTime.now().toIso8601String(),
      'members': {},
    };

    final localId = 'offline_group_${DateTime.now().millisecondsSinceEpoch}';
    final localGroup = GroupModel(
      id: localId,
      name: name,
      createdBy: user.uid,
      createdAt: DateTime.now(),
    );
    _groups.insert(0, localGroup);
    notifyListeners();

    data['_offlineId'] = localId;

    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('createGroup', data);
      _errorMessage = null;
      return localId;
    }

    try {
      _errorMessage = null;
      final docRef = await _firestore.collection('groups').add(data);
      _groups.removeWhere((g) => g.id == localId);
      notifyListeners();
      return docRef.id;
    } catch (e) {
      await _offlineQueue.enqueue('createGroup', data);
      _errorMessage = null;
      return localId;
    }
  }

  Future<bool> updateGroupName(String groupId, String name) async {
    _groups = _groups.map((g) {
      if (g.id == groupId) {
        return GroupModel(
          id: g.id,
          name: name,
          createdBy: g.createdBy,
          createdAt: g.createdAt,
          members: g.members,
        );
      }
      return g;
    }).toList();
    notifyListeners();

    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('updateGroup', {
        'groupId': groupId,
        'updates': {'name': name},
      });
      return true;
    }

    try {
      await _firestore.collection('groups').doc(groupId).update({'name': name});
      return true;
    } catch (e) {
      await _offlineQueue.enqueue('updateGroup', {
        'groupId': groupId,
        'updates': {'name': name},
      });
      return true;
    }
  }

  Future<bool> deleteGroup(String groupId) async {
    _groups.removeWhere((g) => g.id == groupId);
    notifyListeners();

    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('deleteGroup', {'groupId': groupId});
      return true;
    }

    try {
      await _firestore.collection('groups').doc(groupId).delete();
      return true;
    } catch (e) {
      await _offlineQueue.enqueue('deleteGroup', {'groupId': groupId});
      return true;
    }
  }

  Future<bool> addMember(String groupId, String userId) async {
    _groups = _groups.map((g) {
      if (g.id == groupId) {
        final updatedMembers = Map<String, bool>.from(g.members);
        updatedMembers[userId] = true;
        return GroupModel(
          id: g.id,
          name: g.name,
          createdBy: g.createdBy,
          createdAt: g.createdAt,
          members: updatedMembers,
        );
      }
      return g;
    }).toList();
    notifyListeners();

    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('addGroupMember', {
        'groupId': groupId,
        'userId': userId,
      });
      return true;
    }

    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .update({'members.$userId': true});
      return true;
    } catch (e) {
      await _offlineQueue.enqueue('addGroupMember', {
        'groupId': groupId,
        'userId': userId,
      });
      return true;
    }
  }

  Future<bool> removeMember(String groupId, String userId) async {
    _groups = _groups.map((g) {
      if (g.id == groupId) {
        final updatedMembers = Map<String, bool>.from(g.members);
        updatedMembers.remove(userId);
        return GroupModel(
          id: g.id,
          name: g.name,
          createdBy: g.createdBy,
          createdAt: g.createdAt,
          members: updatedMembers,
        );
      }
      return g;
    }).toList();
    notifyListeners();

    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('removeGroupMember', {
        'groupId': groupId,
        'userId': userId,
      });
      return true;
    }

    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .update({'members.$userId': FieldValue.delete()});
      return true;
    } catch (e) {
      await _offlineQueue.enqueue('removeGroupMember', {
        'groupId': groupId,
        'userId': userId,
      });
      return true;
    }
  }

  List<String> getUserGroupIds(String userId) {
    return _groups
        .where((g) => g.members.containsKey(userId) && g.members[userId] == true)
        .map((g) => g.id)
        .toList();
  }

  void _mergePendingLocalGroups() {
    final pendingCreates = _offlineQueue.getPendingByType('createGroup');
    for (final op in pendingCreates) {
      final data = op.data;
      final localId = data['_offlineId'] as String? ?? 'offline_group_${op.timestamp.millisecondsSinceEpoch}';
      final alreadyExists = _groups.any((g) => g.id == localId);
      if (alreadyExists) continue;
      _groups.add(GroupModel(
        id: localId,
        name: data['name'] ?? '',
        createdBy: data['createdBy'] ?? '',
        createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? op.timestamp,
        members: Map<String, bool>.from(
            (data['members'] as Map?)?.map((k, v) => MapEntry(k as String, v == true)) ?? {}),
      ));
    }
  }

  void clear() {
    _groupsSub?.cancel();
    _groupsSub = null;
    _groups = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _groupsSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
