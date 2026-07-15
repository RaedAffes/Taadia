import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ta3dia/models/evaluation_model.dart';
import 'package:ta3dia/services/code_lookup_service.dart';
import 'package:ta3dia/services/connectivity_service.dart';
import 'package:ta3dia/services/offline_queue_service.dart';

class EvaluationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityService _connectivityService;
  final OfflineQueueService _offlineQueue;
  final CodeLookupService? _codeLookup;
  StreamSubscription<QuerySnapshot>? _evalSub;

  EvaluationService(this._connectivityService, this._offlineQueue, [this._codeLookup]);

  List<Evaluation> _evaluations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Evaluation> get evaluations => _evaluations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadEvaluations(String taadiaId) async {
    _evalSub?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final isPending = taadiaId.startsWith('pending_code_');

    if (isPending) {
      try {
        _evaluations = [];
        _mergePendingLocalEvaluations(taadiaId: taadiaId);
        final accessCode = taadiaId.substring(12);
        final seen = <String>{};
        for (final e in _evaluations) {
          if (e.id.isNotEmpty) seen.add(e.id);
        }
        try {
          final q = _firestore
              .collection('evaluations')
              .where('taadiaId', isEqualTo: taadiaId);
          final snap = await q.get(const GetOptions(source: Source.cache));
          for (final doc in snap.docs) {
            final eval = Evaluation.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map));
            if (seen.add(eval.id)) _evaluations.add(eval);
          }
        } catch (_) {}
        try {
          final q = _firestore
              .collection('evaluations')
              .where('taadiaId', isEqualTo: taadiaId);
          final snap = await q.get();
          for (final doc in snap.docs) {
            final eval = Evaluation.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map));
            if (seen.add(eval.id)) _evaluations.add(eval);
          }
        } catch (_) {}
        try {
          final q = _firestore
              .collection('evaluations')
              .where('accessCode', isEqualTo: accessCode);
          final snap = await q.get();
          for (final doc in snap.docs) {
            final eval = Evaluation.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map));
            if (seen.add(eval.id)) _evaluations.add(eval);
          }
        } catch (_) {}
        _evaluations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (_) {}
      _isLoading = false;
      notifyListeners();
      return;
    }

    Query query = _firestore
        .collection('evaluations')
        .where('taadiaId', isEqualTo: taadiaId);

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        final isAdmin = userDoc.data()?['role'] == 'admin';
        if (!isAdmin) {
          query = query.where('userId', isEqualTo: user.uid);
        }
      } catch (_) {
        query = query.where('userId', isEqualTo: user.uid);
      }
    }

    final seen = <String>{};
    try {
      final cacheSnapshot = await query.get(const GetOptions(source: Source.cache));
      _evaluations = cacheSnapshot.docs
          .map((doc) => Evaluation.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map)))
          .where((e) => seen.add(e.id))
          .toList();
      _errorMessage = null;
    } catch (_) {
    }
    final accessCode = _findAccessCode(taadiaId);
    if (accessCode != null) {
      try {
        final q = _firestore
            .collection('evaluations')
            .where('accessCode', isEqualTo: accessCode);
        final snap = await q.get();
        for (final doc in snap.docs) {
          final eval = Evaluation.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map));
          if (seen.add(eval.id)) _evaluations.add(eval);
        }
      } catch (_) {}
    }
    try {
      _mergePendingLocalEvaluations(taadiaId: taadiaId);
      _evaluations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {}
    _isLoading = false;
    notifyListeners();

    _evalSub = query.snapshots(includeMetadataChanges: true).listen(
          (snapshot) {
            if (!_connectivityService.isOnline && snapshot.metadata.isFromCache) return;
            try {
              final seen2 = <String>{};
              _evaluations = snapshot.docs
                  .map((doc) => Evaluation.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map)))
                  .where((e) => seen2.add(e.id))
                  .toList();
              _mergePendingLocalEvaluations(taadiaId: taadiaId);
              _evaluations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              _errorMessage = null;
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

  Future<void> loadMyEvaluations(String taadiaId) async {
    if (_auth.currentUser == null) return;
    _evalSub?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final isPending = taadiaId.startsWith('pending_code_');

    if (isPending) {
      try {
        _evaluations = [];
        _mergePendingLocalEvaluations(taadiaId: taadiaId);
        final accessCode = taadiaId.substring(12);
        final uid = _auth.currentUser!.uid;
        final seen = <String>{};
        for (final e in _evaluations) {
          if (e.id.isNotEmpty) seen.add(e.id);
        }
        try {
          final q = _firestore
              .collection('evaluations')
              .where('taadiaId', isEqualTo: taadiaId)
              .where('userId', isEqualTo: uid);
          final snap = await q.get(const GetOptions(source: Source.cache));
          for (final doc in snap.docs) {
            final eval = Evaluation.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map));
            if (seen.add(eval.id)) _evaluations.add(eval);
          }
        } catch (_) {}
        try {
          final q = _firestore
              .collection('evaluations')
              .where('taadiaId', isEqualTo: taadiaId)
              .where('userId', isEqualTo: uid);
          final snap = await q.get();
          for (final doc in snap.docs) {
            final eval = Evaluation.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map));
            if (seen.add(eval.id)) _evaluations.add(eval);
          }
        } catch (_) {}
        try {
          final q = _firestore
              .collection('evaluations')
              .where('accessCode', isEqualTo: accessCode)
              .where('userId', isEqualTo: uid);
          final snap = await q.get();
          for (final doc in snap.docs) {
            final eval = Evaluation.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map));
            if (seen.add(eval.id)) _evaluations.add(eval);
          }
        } catch (_) {}
        _evaluations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (_) {}
      _isLoading = false;
      notifyListeners();
      return;
    }

    final query = _firestore
        .collection('evaluations')
        .where('taadiaId', isEqualTo: taadiaId)
        .where('userId', isEqualTo: _auth.currentUser!.uid);

    final seen = <String>{};
    try {
      final cacheSnapshot = await query.get(const GetOptions(source: Source.cache));
      _evaluations = cacheSnapshot.docs
          .map((doc) => Evaluation.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map)))
          .where((e) => seen.add(e.id))
          .toList();
      _errorMessage = null;
    } catch (_) {
    }
    final accessCode = _findAccessCode(taadiaId);
    if (accessCode != null) {
      try {
        final q = _firestore
            .collection('evaluations')
            .where('accessCode', isEqualTo: accessCode)
            .where('userId', isEqualTo: _auth.currentUser!.uid);
        final snap = await q.get();
        for (final doc in snap.docs) {
          final eval = Evaluation.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map));
          if (seen.add(eval.id)) _evaluations.add(eval);
        }
      } catch (_) {}
    }
    try {
      _mergePendingLocalEvaluations(taadiaId: taadiaId);
      _evaluations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {}
    _isLoading = false;
    notifyListeners();

    _evalSub = query.snapshots(includeMetadataChanges: true).listen(
          (snapshot) {
            if (!_connectivityService.isOnline && snapshot.metadata.isFromCache) return;
            try {
              final seen2 = <String>{};
              _evaluations = snapshot.docs
                  .map((doc) => Evaluation.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map)))
                  .where((e) => seen2.add(e.id))
                  .toList();
              _mergePendingLocalEvaluations(taadiaId: taadiaId);
              _evaluations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              _errorMessage = null;
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

  Map<String, dynamic> _offlineSafeEval(Map<String, dynamic> data) {
    final safe = Map<String, dynamic>.from(data);
    if (safe['evaluation'] is Map) {
      final inner = Map<String, dynamic>.from(safe['evaluation'] as Map);
      if (inner['createdAt'] is DateTime) {
        inner['createdAt'] = (inner['createdAt'] as DateTime).toIso8601String();
      }
      if (inner['questions'] is List) {
        inner['questions'] = (inner['questions'] as List)
            .map((q) => Map<String, dynamic>.from(q as Map))
            .toList();
      }
      safe['evaluation'] = inner;
    }
    return safe;
  }

  String? _extractAccessCode(String taadiaId) {
    if (taadiaId.startsWith('code_')) {
      return taadiaId.substring(5);
    }
    if (taadiaId.startsWith('pending_code_')) {
      return taadiaId.substring(12);
    }
    return null;
  }

  String? _findAccessCode(String taadiaId) {
    if (_codeLookup == null) return null;
    for (final entry in _codeLookup!.allEntries) {
      if (entry.value.id == taadiaId) {
        return entry.key;
      }
    }
    return null;
  }

  Future<bool> saveEvaluation(Evaluation evaluation) async {
    final offlineId = evaluation.id.isEmpty
        ? 'offline_eval_${DateTime.now().millisecondsSinceEpoch}'
        : evaluation.id;
    final evalData = evaluation.toFirestore();
    final accessCode = _extractAccessCode(evaluation.taadiaId) ?? _findAccessCode(evaluation.taadiaId);
    final isPending = evaluation.taadiaId.startsWith('pending_code_');
    final data = <String, dynamic>{
      'evaluation': evalData,
      'evalId': evaluation.id.isEmpty ? offlineId : evaluation.id,
      '_offlineId': offlineId,
      'taadiaId': evaluation.taadiaId,
    };
    if (accessCode != null) {
      data['accessCode'] = accessCode;
    }

    if (evaluation.id.isEmpty) {
      final localEval = Evaluation(
        id: offlineId,
        taadiaId: evaluation.taadiaId,
        userId: evaluation.userId,
        evaluatorName: evaluation.evaluatorName,
        studentName: evaluation.studentName,
        categories: evaluation.categories,
        classificationValues: evaluation.classificationValues,
        numQuestions: evaluation.numQuestions,
        numAhzab: evaluation.numAhzab,
        specialAhzab: evaluation.specialAhzab,
        rangeCriteria: evaluation.rangeCriteria,
        questions: evaluation.questions,
        note: evaluation.note,
        createdAt: DateTime.now(),
      );
      _evaluations.add(localEval);
    } else {
      _evaluations = _evaluations.map((e) {
        if (e.id == evaluation.id) return evaluation;
        return e;
      }).toList();
    }
    _evaluations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();

    if (accessCode != null) {
      evalData['accessCode'] = accessCode;
      if (isPending) {
        final cached = _codeLookup?.lookup(accessCode);
        if (cached != null && !cached.id.startsWith('pending_')) {
          evalData['taadiaId'] = cached.id;
        }
      }
    }

    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('saveEvaluation', _offlineSafeEval(data));
      _errorMessage = null;
      return true;
    }

    try {
      await _firestoreWriteEvaluation(evalData, evaluation.id.isEmpty ? '' : evaluation.id);
      if (isPending && accessCode != null) {
        final cached = _codeLookup?.lookup(accessCode);
        if (cached != null && !cached.id.startsWith('pending_') && evalData['taadiaId'] != cached.id) {
          evalData['taadiaId'] = cached.id;
          final docQuery = await _firestore
              .collection('evaluations')
              .where('accessCode', isEqualTo: accessCode)
              .get();
          if (docQuery.docs.isNotEmpty) {
            final batch = _firestore.batch();
            for (final doc in docQuery.docs) {
              batch.update(doc.reference, {'taadiaId': cached.id});
            }
            await batch.commit();
          }
        }
      }
      _errorMessage = null;
    } catch (_) {
      await _offlineQueue.enqueue('saveEvaluation', _offlineSafeEval(data));
    }
    return true;
  }

  Future<void> updateTaadiaIdByAccessCode(String accessCode, String newTaadiaId) async {
    try {
      final snapshot = await _firestore
          .collection('evaluations')
          .where('accessCode', isEqualTo: accessCode)
          .get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'taadiaId': newTaadiaId});
      }
      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (_) {}
  }

  Future<void> _firestoreWriteEvaluation(Map<String, dynamic> evalData, String evalId) async {
    if (evalId.isEmpty) {
      await _firestore.collection('evaluations').add(evalData);
    } else {
      await _firestore.collection('evaluations').doc(evalId).set(evalData, SetOptions(merge: true));
    }
  }

  Future<void> updateFormula(String evalId, String formula) async {
    _evaluations = _evaluations.map((e) {
      if (e.id == evalId) {
        return Evaluation(
          id: e.id,
          taadiaId: e.taadiaId,
          userId: e.userId,
          evaluatorName: e.evaluatorName,
          studentName: e.studentName,
          categories: e.categories,
          classificationValues: e.classificationValues,
          numQuestions: e.numQuestions,
          numAhzab: e.numAhzab,
          specialAhzab: e.specialAhzab,
          rangeCriteria: e.rangeCriteria,
          questions: e.questions,
          note: e.note,
          formula: formula,
          createdAt: e.createdAt,
        );
      }
      return e;
    }).toList();
    notifyListeners();
    try {
      await _firestore.collection('evaluations').doc(evalId).set(
        {'formula': formula},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Future<bool> deleteEvaluation(String evalId) async {
    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('deleteEvaluation', {'evalId': evalId});
      _evaluations.removeWhere((e) => e.id == evalId);
      notifyListeners();
      return true;
    }

    try {
      await _firestore.collection('evaluations').doc(evalId).delete();
      _evaluations.removeWhere((e) => e.id == evalId);
      notifyListeners();
      return true;
    } catch (e) {
      await _offlineQueue.enqueue('deleteEvaluation', {'evalId': evalId});
      _evaluations.removeWhere((e) => e.id == evalId);
      notifyListeners();
      return true;
    }
  }

  Future<Map<String, dynamic>> getTaadiaStats(String taadiaId) async {
    final localEvals = _evaluations.where((e) => e.taadiaId == taadiaId).toList();
    if (localEvals.isNotEmpty) {
      return _computeStats(localEvals);
    }

    Query query = _firestore
        .collection('evaluations')
        .where('taadiaId', isEqualTo: taadiaId);

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        final isAdmin = userDoc.data()?['role'] == 'admin';
        if (!isAdmin) {
          query = query.where('userId', isEqualTo: user.uid);
        }
      } catch (_) {
        query = query.where('userId', isEqualTo: user.uid);
      }
    }

    try {
      final snapshot = await query.get(const GetOptions(source: Source.cache));
      final docs = snapshot.docs.map((d) => Map<String, dynamic>.from(d.data() as Map)).toList();
      if (docs.isNotEmpty) {
        return _computeStatsFromMaps(docs);
      }
    } catch (_) {}

    try {
      final snapshot = await query.get();
      final docs = snapshot.docs.map((d) => Map<String, dynamic>.from(d.data() as Map)).toList();
      return _computeStatsFromMaps(docs);
    } catch (_) {
      return {'totalStudents': 0, 'totalQuestions': 0, 'ahzabList': <String>[], 'totalTeachers': 0};
    }
  }

  Map<String, dynamic> _computeStats(List<Evaluation> evals) {
    var totalQuestions = 0;
    final ahzabSet = <String>{};
    final teacherNames = <String>{};
    for (var e in evals) {
      totalQuestions += e.numQuestions;
      if (e.specialAhzab.isNotEmpty) ahzabSet.add(e.specialAhzab);
      teacherNames.add(e.userId);
    }
    return {
      'totalStudents': evals.length,
      'totalQuestions': totalQuestions,
      'ahzabList': ahzabSet.toList(),
      'totalTeachers': teacherNames.length,
    };
  }

  Map<String, dynamic> _computeStatsFromMaps(List<Map<String, dynamic>> docs) {
    var totalQuestions = 0;
    final ahzabSet = <String>{};
    final teacherNames = <String>{};
    for (var data in docs) {
      totalQuestions += (data['numQuestions'] ?? 0) as int;
      final ahzab = data['specialAhzab'] as String? ?? '';
      if (ahzab.isNotEmpty) ahzabSet.add(ahzab);
      teacherNames.add(data['userId'] ?? '');
    }
    return {
      'totalStudents': docs.length,
      'totalQuestions': totalQuestions,
      'ahzabList': ahzabSet.toList(),
      'totalTeachers': teacherNames.length,
    };
  }

  Future<List<Evaluation>> getEvaluationsOnce(String taadiaId) async {
    final localEvals = _evaluations.where((e) => e.taadiaId == taadiaId).toList();
    if (localEvals.isNotEmpty) {
      localEvals.sort((a, b) => a.studentName.compareTo(b.studentName));
      return localEvals;
    }

    Query query = _firestore
        .collection('evaluations')
        .where('taadiaId', isEqualTo: taadiaId);

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        final isAdmin = userDoc.data()?['role'] == 'admin';
        if (!isAdmin) {
          query = query.where('userId', isEqualTo: user.uid);
        }
      } catch (_) {
        query = query.where('userId', isEqualTo: user.uid);
      }
    }

    final seen = <String>{};
    final result = <Evaluation>[];
    try {
      final snapshot = await query.get(const GetOptions(source: Source.cache));
      for (final doc in snapshot.docs) {
        final eval = Evaluation.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map));
        if (seen.add(eval.id)) result.add(eval);
      }
    } catch (_) {}
    try {
      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
        final eval = Evaluation.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map));
        if (seen.add(eval.id)) result.add(eval);
      }
    } catch (_) {}

    final accessCode = _findAccessCode(taadiaId);
    if (accessCode != null) {
      Query acQuery = _firestore
          .collection('evaluations')
          .where('accessCode', isEqualTo: accessCode);
      if (user != null) {
        try {
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          if (userDoc.data()?['role'] != 'admin') {
            acQuery = acQuery.where('userId', isEqualTo: user.uid);
          }
        } catch (_) {
          acQuery = acQuery.where('userId', isEqualTo: user.uid);
        }
      }
      try {
        final acSnap = await acQuery.get();
        for (final doc in acSnap.docs) {
          final eval = Evaluation.fromFirestore(doc.id, Map<String, dynamic>.from(doc.data() as Map));
          if (seen.add(eval.id)) result.add(eval);
        }
      } catch (_) {}
    }

    result.sort((a, b) => a.studentName.compareTo(b.studentName));
    return result;
  }

  void _mergePendingLocalEvaluations({String? taadiaId}) {
    final pendingSaves = _offlineQueue.getPendingByType('saveEvaluation');
    for (final op in pendingSaves) {
      final data = op.data;
      final localId = data['_offlineId'] as String? ?? 'offline_eval_${op.timestamp.millisecondsSinceEpoch}';
      final opTaadiaId = data['taadiaId'] as String? ?? '';
      if (opTaadiaId.isEmpty) continue;
      if (taadiaId != null && opTaadiaId != taadiaId && !opTaadiaId.startsWith('pending_code_')) continue;
      final alreadyExists = _evaluations.any((e) => e.id == localId);
      if (alreadyExists) continue;
      final evalData = data['evaluation'] as Map<String, dynamic>?;
      if (evalData == null) continue;
      final reconstructed = Map<String, dynamic>.from(evalData);
      final eval = Evaluation.fromFirestore(localId, reconstructed);
      _evaluations.add(eval);
    }
  }

  @override
  void dispose() {
    _evalSub?.cancel();
    super.dispose();
  }
}
