import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ta3dia/models/taadia_model.dart';
import 'package:ta3dia/services/code_lookup_service.dart';
import 'package:ta3dia/services/connectivity_service.dart';

import 'package:ta3dia/services/offline_queue_service.dart';

class TaadiaService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityService _connectivityService;
  final OfflineQueueService _offlineQueue;
  final CodeLookupService? _codeLookup;
  StreamSubscription<QuerySnapshot>? _taadiaSub;
  StreamSubscription<User?>? _authSub;

  TaadiaService(this._connectivityService, this._offlineQueue, [this._codeLookup]) {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) clear();
    });
  }

  List<Taadia> _taadias = [];
  List<Taadia> _userPrivateTaadias = [];
  List<Taadia> _myTaadias = [];
  bool _isLoading = false;
  String? _errorMessage;
  List<Taadia> get taadias => _taadias;
  List<Taadia> get userPrivateTaadias => _userPrivateTaadias;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadTaadias() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _taadiaSub?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Try to load from cache first to avoid infinite loading when offline
    try {
      final cacheSnapshot = await _firestore
          .collection('taadia')
          .get(const GetOptions(source: Source.cache));
      _taadias = cacheSnapshot.docs
          .map((doc) => Taadia.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map)))
          .toList();
    } catch (_) {
      // No cache yet — loading finishes, listener will populate when available
    }
    _mergePendingLocalTaadias();
    _taadias.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _isLoading = false;
    notifyListeners();

    _taadiaSub = _firestore.collection('taadia').snapshots(includeMetadataChanges: true).listen(
          (snapshot) {
            if (!_connectivityService.isOnline && snapshot.metadata.isFromCache) return;
            try {
              _taadias = snapshot.docs
                  .map((doc) => Taadia.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map)))
                  .toList();
              _mergePendingLocalTaadias();
              _taadias.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            } catch (_) {}
            _isLoading = false;
            notifyListeners();
          },
          onError: (_) {
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> loadUserPrivateTaadias() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final snapshot = await _firestore
          .collection('taadia')
          .where('visibility', isEqualTo: 'private')
          .where('createdBy', isEqualTo: user.uid)
          .get();
      _userPrivateTaadias = snapshot.docs
          .map((doc) => Taadia.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map)))
          .toList();
    } catch (e) {
      _userPrivateTaadias = [];
    }
    _mergePendingLocalTaadias();
    notifyListeners();
  }

  Future<String?> createTaadia(
    String title, {
    String description = '',
    String formula = 'mahalia',
    String visibility = 'public',
    Map<String, bool> accessGroups = const {},
    Map<String, bool> accessUsers = const {},
    String? accessCode,
    List<String> categories = const [],
    List<ClassificationConfig> classifications = const [],
  }) async {
    if (_auth.currentUser == null) return null;
    final code = accessCode ?? generateAccessCode();
    final offlineId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'createdBy': _auth.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'formula': formula,
      'visibility': visibility,
      'accessGroups': accessGroups,
      'accessUsers': accessUsers,
      'accessCode': code,
      'categories': categories,
      'classifications': classifications.map((c) => c.toMap()).toList(),
    };

    final localTaadia = Taadia(
      id: offlineId,
      title: title,
      description: description,
      createdBy: _auth.currentUser!.uid,
      createdAt: now,
      status: 'active',
      formula: formula,
      visibility: visibility,
      accessGroups: accessGroups,
      accessUsers: accessUsers,
      accessCode: code,
      categories: categories,
      classifications: classifications,
    );
    _taadias.insert(0, localTaadia);
    notifyListeners();

    final queueData = _offlineSafeData(data);
    queueData['_offlineId'] = offlineId;

    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('createTaadia', queueData);
      _errorMessage = null;
      return offlineId;
    }

    try {
      _errorMessage = null;
      final docRef = await _firestore.collection('taadia').add(data);
      _taadias = _taadias.map((t) {
        if (t.id == offlineId) {
          return Taadia(
            id: docRef.id,
            title: t.title,
            description: t.description,
            createdBy: t.createdBy,
            createdAt: t.createdAt,
            status: t.status,
            formula: t.formula,
            visibility: t.visibility,
            accessGroups: t.accessGroups,
            accessUsers: t.accessUsers,
            accessCode: t.accessCode,
            categories: t.categories,
            classifications: t.classifications,
          );
        }
        return t;
      }).toList();
      notifyListeners();
      return docRef.id;
    } catch (e) {
      await _offlineQueue.enqueue('createTaadia', queueData);
      _errorMessage = null;
      return offlineId;
    }
  }

  Map<String, dynamic> _offlineSafeData(Map<String, dynamic> data) {
    final safe = Map<String, dynamic>.from(data);
    if (safe['createdAt'] is FieldValue) {
      safe['createdAt'] = DateTime.now().toIso8601String();
    }
    safe.remove('updatedAt');
    return safe;
  }

  Future<String?> createPrivateTaadia(
    String title, {
    String description = '',
    String formula = 'mahalia',
  }) async {
    if (_auth.currentUser == null) return null;
    final offlineId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'createdBy': _auth.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'formula': formula,
      'visibility': 'private',
    };

    final localTaadia = Taadia(
      id: offlineId,
      title: title,
      description: description,
      createdBy: _auth.currentUser!.uid,
      createdAt: now,
      status: 'active',
      formula: formula,
      visibility: 'private',
    );
    _userPrivateTaadias.insert(0, localTaadia);
    notifyListeners();

    final queueData = _offlineSafeData(data);
    queueData['_offlineId'] = offlineId;

    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('createTaadia', queueData);
      _errorMessage = null;
      return offlineId;
    }

    try {
      _errorMessage = null;
      final docRef = await _firestore.collection('taadia').add(data);
      _userPrivateTaadias = _userPrivateTaadias.map((t) {
        if (t.id == offlineId) {
          return Taadia(
            id: docRef.id,
            title: t.title,
            description: t.description,
            createdBy: t.createdBy,
            createdAt: t.createdAt,
            status: t.status,
            formula: t.formula,
            visibility: 'private',
          );
        }
        return t;
      }).toList();
      notifyListeners();
      return docRef.id;
    } catch (e) {
      await _offlineQueue.enqueue('createTaadia', queueData);
      _errorMessage = null;
      return offlineId;
    }
  }

  Future<bool> _updateTaadiaField(String taadiaId, String field, dynamic value) async {
    final updates = <String, dynamic>{field: value};
    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('updateTaadia', {
        'taadiaId': taadiaId,
        'updates': updates,
      });
      _updateLocalTaadia(taadiaId, updates);
      return true;
    }
    try {
      await _firestore.collection('taadia').doc(taadiaId).update(updates);
      await loadTaadias();
      return true;
    } catch (e) {
      await _offlineQueue.enqueue('updateTaadia', {
        'taadiaId': taadiaId,
        'updates': updates,
      });
      _updateLocalTaadia(taadiaId, updates);
      return true;
    }
  }

  void _updateLocalTaadia(String taadiaId, Map<String, dynamic> updates) {
    _taadias = _taadias.map((t) {
      if (t.id == taadiaId) {
        return Taadia(
          id: t.id,
          title: updates['title'] ?? t.title,
          description: updates['description'] ?? t.description,
          createdBy: t.createdBy,
          createdAt: t.createdAt,
          status: updates['status'] ?? t.status,
          formula: updates['formula'] ?? t.formula,
          visibility: t.visibility,
          accessGroups: t.accessGroups,
          accessUsers: t.accessUsers,
          accessCode: t.accessCode,
          categories: t.categories,
          classifications: t.classifications,
        );
      }
      return t;
    }).toList();
    notifyListeners();
  }

  Future<bool> closeTaadia(String taadiaId) async {
    return _updateTaadiaField(taadiaId, 'status', 'closed');
  }

  Future<bool> openTaadia(String taadiaId) async {
    return _updateTaadiaField(taadiaId, 'status', 'active');
  }

  Future<bool> deleteTaadia(String taadiaId) async {
    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('deleteTaadia', {'taadiaId': taadiaId});
      _taadias.removeWhere((t) => t.id == taadiaId);
      _userPrivateTaadias.removeWhere((t) => t.id == taadiaId);
      _myTaadias.removeWhere((t) => t.id == taadiaId);
      notifyListeners();
      return true;
    }
    try {
      await _firestore.collection('taadia').doc(taadiaId).delete();
      try {
        final evalSnapshot = await _firestore
            .collection('evaluations')
            .where('taadiaId', isEqualTo: taadiaId)
            .get();
        for (var doc in evalSnapshot.docs) {
          try {
            await doc.reference.delete();
          } catch (_) {
          }
        }
      } catch (_) {
      }
      _taadias.removeWhere((t) => t.id == taadiaId);
      _userPrivateTaadias.removeWhere((t) => t.id == taadiaId);
      _myTaadias.removeWhere((t) => t.id == taadiaId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<List<Taadia>> getAvailableTaadias() async {
    try {
      final snapshot = await _firestore
          .collection('taadia')
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs.map((doc) {
        return Taadia.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data()));
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateFormula(String taadiaId, String formula) async {
    return _updateTaadiaField(taadiaId, 'formula', formula);
  }

  Future<bool> updateTaadia(
    String taadiaId, {
    String? title,
    String? description,
    String? formula,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (formula != null) data['formula'] = formula;
    if (data.isEmpty) return true;

    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('updateTaadia', {
        'taadiaId': taadiaId,
        'updates': data,
      });
      _updateLocalTaadia(taadiaId, data);
      return true;
    }

    try {
      await _firestore.collection('taadia').doc(taadiaId).update(data);
      await loadTaadias();
      return true;
    } catch (e) {
      await _offlineQueue.enqueue('updateTaadia', {
        'taadiaId': taadiaId,
        'updates': data,
      });
      _updateLocalTaadia(taadiaId, data);
      return true;
    }
  }

  Future<bool> isTaadiaActive(String taadiaId) async {
    try {
      final doc = await _firestore.collection('taadia').doc(taadiaId).get();
      return doc.data()?['status'] == 'active';
    } catch (_) {
      return false;
    }
  }

  Future<void> cacheTaadiaByCode(Taadia taadia) async {
    if (_codeLookup == null || taadia.accessCode.isEmpty) return;
    await _codeLookup!.storeCodeMapping(
      taadia.accessCode,
      CachedTaadia(
        id: taadia.id,
        title: taadia.title,
        description: taadia.description,
        categories: taadia.categories,
        classifications: taadia.classifications.map((c) => c.toMap()).toList(),
        active: taadia.status == 'active',
      ),
    );
  }

  String generateAccessCode() {
    final random = Random();
    final code = (random.nextInt(9000) + 1000).toString();
    return code;
  }

  Future<bool> _updateTaadiaAccessLocal(
    String taadiaId, {
    Map<String, bool>? accessGroups,
    Map<String, bool>? accessUsers,
    String? accessCode,
  }) async {
    final data = <String, dynamic>{};
    if (accessGroups != null) data['accessGroups'] = accessGroups;
    if (accessUsers != null) data['accessUsers'] = accessUsers;
    if (accessCode != null) data['accessCode'] = accessCode;
    if (data.isEmpty) return true;

    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('updateTaadia', {
        'taadiaId': taadiaId,
        'updates': data,
      });
      return true;
    }

    try {
      await _firestore.collection('taadia').doc(taadiaId).update(data);
      return true;
    } catch (e) {
      await _offlineQueue.enqueue('updateTaadia', {
        'taadiaId': taadiaId,
        'updates': data,
      });
      return true;
    }
  }

  Future<bool> updateTaadiaAccess(
    String taadiaId, {
    Map<String, bool>? accessGroups,
    Map<String, bool>? accessUsers,
    String? accessCode,
  }) async {
    return _updateTaadiaAccessLocal(taadiaId,
        accessGroups: accessGroups,
        accessUsers: accessUsers,
        accessCode: accessCode);
  }

  Future<bool> grantUserAccess(String taadiaId, String userId) async {
    _taadias = _taadias.map((t) {
      if (t.id == taadiaId) {
        return Taadia(
          id: t.id,
          title: t.title,
          description: t.description,
          createdBy: t.createdBy,
          createdAt: t.createdAt,
          status: t.status,
          formula: t.formula,
          visibility: t.visibility,
          accessGroups: t.accessGroups,
          accessUsers: Map<String, bool>.from(t.accessUsers)..[userId] = true,
          accessCode: t.accessCode,
          categories: t.categories,
          classifications: t.classifications,
        );
      }
      return t;
    }).toList();
    notifyListeners();

    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('updateTaadia', {
        'taadiaId': taadiaId,
        'updates': {'accessUsers.$userId': true},
      });
      return true;
    }

    try {
      await _firestore
          .collection('taadia')
          .doc(taadiaId)
          .update({'accessUsers.$userId': true});
      return true;
    } catch (_) {
      await _offlineQueue.enqueue('updateTaadia', {
        'taadiaId': taadiaId,
        'updates': {'accessUsers.$userId': true},
      });
      return true;
    }
  }

  Taadia? validateAccessCode(String code) {
    for (final t in _taadias) {
      if (t.accessCode == code && t.status == 'active') {
        return t;
      }
    }
    if (_connectivityService.isOffline && _codeLookup != null) {
      final cached = _codeLookup!.lookup(code);
      if (cached != null && cached.active) {
        return Taadia(
          id: cached.id,
          title: cached.title,
          description: cached.description,
          createdBy: '',
          createdAt: DateTime.now(),
          status: 'active',
          accessCode: code,
          categories: cached.categories,
          classifications: cached.classifications
              .map((m) => ClassificationConfig.fromMap(m))
              .toList(),
        );
      }
    }
    return null;
  }

  Future<Taadia?> resolveCodeToTaadia(String code) async {
    if (_connectivityService.isOnline) {
      try {
        final snapshot = await _firestore
            .collection('taadia')
            .where('accessCode', isEqualTo: code)
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          return Taadia.fromFirestore(
              doc.id, Map<String, dynamic>.from(doc.data() as Map));
        }
      } catch (_) {}
    }
    if (_codeLookup != null) {
      final cached = _codeLookup!.lookup(code);
      if (cached != null && cached.active) {
        return Taadia(
          id: cached.id,
          title: cached.title,
          description: cached.description,
          createdBy: '',
          createdAt: DateTime.now(),
          status: 'active',
          accessCode: code,
          categories: cached.categories,
          classifications: cached.classifications
              .map((m) => ClassificationConfig.fromMap(m))
              .toList(),
        );
      }
    }
    return null;
  }

  List<Taadia> getAccessibleTaadias(String userId, List<String> userGroupIds) {
    return _taadias.where((t) {
      if (t.isPrivate) return false;
      if (t.createdBy == userId) return true;
      return t.userHasAccess(userId, userGroupIds);
    }).toList();
  }

  void _mergePendingLocalTaadias() {
    final pendingCreates = _offlineQueue.getPendingByType('createTaadia');
    for (final op in pendingCreates) {
      final data = op.data;
      final localId = data['_offlineId'] as String? ?? 'offline_${op.timestamp.millisecondsSinceEpoch}';
      final alreadyExists = _taadias.any((t) => t.id == localId);
      if (alreadyExists) continue;
      _taadias.add(Taadia(
        id: localId,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        createdBy: data['createdBy'] ?? '',
        createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? op.timestamp,
        status: data['status'] ?? 'active',
        formula: data['formula'] ?? 'mahalia',
        visibility: data['visibility'] ?? 'public',
        accessGroups: Map<String, bool>.from(
            (data['accessGroups'] as Map?)?.map((k, v) => MapEntry(k as String, v == true)) ?? {}),
        accessUsers: Map<String, bool>.from(
            (data['accessUsers'] as Map?)?.map((k, v) => MapEntry(k as String, v == true)) ?? {}),
        accessCode: data['accessCode'] ?? '',
        categories: (data['categories'] as List<dynamic>?)?.cast<String>() ?? [],
        classifications: [],
      ));
    }
  }

  void clear() {
    _taadiaSub?.cancel();
    _taadiaSub = null;
    _taadias = [];
    _userPrivateTaadias = [];
    _myTaadias = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _taadiaSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
