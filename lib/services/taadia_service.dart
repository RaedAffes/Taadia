import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ta3dia/models/taadia_model.dart';
import 'package:ta3dia/services/connectivity_service.dart';
import 'package:ta3dia/services/offline_queue_service.dart';

class TaadiaService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityService _connectivityService;
  final OfflineQueueService _offlineQueue;
  StreamSubscription<QuerySnapshot>? _taadiaSub;
  StreamSubscription<User?>? _authSub;

  String? _currentOrgId;
  String? get currentOrgId => _currentOrgId;

  TaadiaService(this._connectivityService, this._offlineQueue) {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) clear();
    });
  }

  CollectionReference<Map<String, dynamic>> _col(String name) {
    if (_currentOrgId != null) {
      return _firestore
          .collection('organizations')
          .doc(_currentOrgId)
          .collection(name);
    }
    return _firestore.collection(name);
  }

  void setCurrentOrg(String? orgId) {
    _currentOrgId = orgId;
    notifyListeners();
  }

  List<Taadia> _taadias = [];
  List<Taadia> _userPrivateTaadias = [];
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

    _taadiaSub = _col('taadia').snapshots(includeMetadataChanges: true).listen(
          (snapshot) {
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
      final snapshot = await _col('taadia')
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
    List<String> categories = const [],
    List<ClassificationConfig> classifications = const [],
    List<String> accessUsers = const [],
  }) async {
    if (_auth.currentUser == null) return null;
    final offlineId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final accessUsersMap = <String, dynamic>{};
    for (final uid in accessUsers) {
      accessUsersMap[uid] = true;
    }
    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'createdBy': _auth.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'formula': formula,
      'visibility': visibility,
      'categories': categories,
      'classifications': classifications.map((c) => c.toMap()).toList(),
      'accessUsers': accessUsersMap,
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
      categories: categories,
      classifications: classifications,
      accessUsers: accessUsersMap.cast<String, bool>(),
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
      final docRef = await _col('taadia').add(data);
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
      final docRef = await _col('taadia').add(data);
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
      await _col('taadia').doc(taadiaId).update(updates);
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
      notifyListeners();
      return true;
    }
    try {
      await _col('taadia').doc(taadiaId).delete();
      try {
        final evalSnapshot = await _col('evaluations')
            .where('taadiaId', isEqualTo: taadiaId)
            .get();
        for (var doc in evalSnapshot.docs) {
          try {
            await doc.reference.delete();
          } catch (_) {}
        }
      } catch (_) {}
      _taadias.removeWhere((t) => t.id == taadiaId);
      _userPrivateTaadias.removeWhere((t) => t.id == taadiaId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      notifyListeners();
      return false;
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
      await _col('taadia').doc(taadiaId).update(data);
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
    if (taadiaId.startsWith('offline_')) return true;
    try {
      final doc = await _col('taadia').doc(taadiaId).get();
      return doc.data()?['status'] == 'active';
    } catch (_) {
      return true;
    }
  }

  List<Taadia> getAccessibleTaadias(String userId, List<String> userGroupIds) {
    return _taadias.where((t) => t.visibility != 'private').toList();
  }

  void _mergePendingLocalTaadias() {
    final pendingCreates = _offlineQueue.getPendingByType('createTaadia');
    for (final op in pendingCreates) {
      final data = op.data;
      final localId = data['_offlineId'] as String? ?? 'offline_${op.timestamp.millisecondsSinceEpoch}';
      final title = data['title'] ?? '';
      final createdBy = data['createdBy'] ?? '';
      final alreadyExists = _taadias.any((t) =>
          t.id == localId ||
          (t.title == title && t.createdBy == createdBy));
      if (alreadyExists) continue;
      final classificationsRaw = data['classifications'] as List<dynamic>?;
      final classifications = classificationsRaw != null
          ? classificationsRaw
              .map((e) => e is Map
                  ? ClassificationConfig.fromMap(Map<String, dynamic>.from(e))
                  : ClassificationConfig(name: e.toString()))
              .toList()
          : <ClassificationConfig>[];
      _taadias.add(Taadia(
        id: localId,
        title: title,
        description: data['description'] ?? '',
        createdBy: createdBy,
        createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? op.timestamp,
        status: data['status'] ?? 'active',
        formula: data['formula'] ?? 'mahalia',
        visibility: data['visibility'] ?? 'public',
        categories: (data['categories'] as List<dynamic>?)?.cast<String>() ?? [],
        classifications: classifications,
      ));
    }
  }

  void clear() {
    _taadiaSub?.cancel();
    _taadiaSub = null;
    _taadias = [];
    _userPrivateTaadias = [];
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
