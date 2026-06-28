import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ta3dia/services/code_lookup_service.dart';
import 'package:ta3dia/services/connectivity_service.dart';

class PendingOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };

  factory PendingOperation.fromMap(Map<String, dynamic> map) => PendingOperation(
    id: map['id'] as String,
    type: map['type'] as String,
    data: Map<String, dynamic>.from(map['data'] as Map),
    timestamp: DateTime.parse(map['timestamp'] as String),
  );
}

class OfflineQueueService extends ChangeNotifier {
  static const String _storageKey = 'offline_queue';
  List<PendingOperation> _queue = [];
  bool _isProcessing = false;
  final ConnectivityService _connectivityService;
  final CodeLookupService? _codeLookup;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  OfflineQueueService(this._connectivityService, [this._codeLookup]) {
    _connectivityService.addListener(_onConnectivityChanged);
    _loadQueue();
  }

  List<PendingOperation> get queue => List.unmodifiable(_queue);
  int get pendingCount => _queue.length;
  bool get isProcessing => _isProcessing;

  List<PendingOperation> getPendingByType(String type) {
    return _queue.where((op) => op.type == type).toList();
  }

  Future<void> _loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      final list = jsonDecode(stored) as List<dynamic>;
      _queue = list
          .map((e) => PendingOperation.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
    }
    if (_connectivityService.isOnline && _queue.isNotEmpty) {
      processQueue();
    }
  }

  Future<void> _saveQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_queue.map((op) => op.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> enqueue(String type, Map<String, dynamic> data) async {
    final op = PendingOperation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      data: data,
      timestamp: DateTime.now(),
    );
    _queue.add(op);
    await _saveQueue();
    notifyListeners();
  }

  Future<void> dequeue(String id) async {
    _queue.removeWhere((op) => op.id == id);
    await _saveQueue();
    notifyListeners();
  }

  Future<void> processQueue() async {
    if (_isProcessing) return;
    if (!_connectivityService.isOnline) return;

    _isProcessing = true;
    notifyListeners();

    if (_queue.isNotEmpty) {
      final ops = List<PendingOperation>.from(_queue);
      for (final op in ops) {
        try {
          await _processOperation(op);
          await dequeue(op.id);
        } catch (_) {
          // Don't block other operations on failure
        }
      }
    }

    if (_codeLookup != null) {
      for (final entry in _codeLookup!.allEntries) {
        if (!entry.value.id.startsWith('pending_')) {
          try {
            final snapshot = await _firestore
                .collection('evaluations')
                .where('accessCode', isEqualTo: entry.key)
                .get();
            if (snapshot.docs.isNotEmpty) {
              final batch = _firestore.batch();
              for (final doc in snapshot.docs) {
                batch.update(doc.reference, {
                  'taadiaId': entry.value.id,
                });
              }
              await batch.commit();
            }
          } catch (_) {}
        }
      }
    }

    _isProcessing = false;
    notifyListeners();
  }

  void _onConnectivityChanged() {
    if (_connectivityService.isOnline && _queue.isNotEmpty) {
      processQueue();
    }
  }

  Future<void> _processOperation(PendingOperation op) async {
    switch (op.type) {
      case 'createTaadia':
        await _firestore.collection('taadia').add(
          Map<String, dynamic>.from(op.data),
        );
        break;
      case 'updateTaadia':
        await _firestore.collection('taadia').doc(
          op.data['taadiaId'] as String,
        ).update(
          Map<String, dynamic>.from(op.data['updates'] as Map),
        );
        break;
      case 'deleteTaadia':
        await _firestore.collection('taadia').doc(
          op.data['taadiaId'] as String,
        ).delete();
        break;
      case 'saveEvaluation':
        final evalData = Map<String, dynamic>.from(
          op.data['evaluation'] as Map,
        );
        if (evalData['createdAt'] is String) {
          evalData['createdAt'] = DateTime.tryParse(evalData['createdAt'] as String) ?? DateTime.now();
        }
        final accessCode = op.data['accessCode'] as String?;
        if (accessCode != null && accessCode.isNotEmpty) {
          evalData['accessCode'] = accessCode;
          final resolvedId = await _resolveTaadiaIdByCode(accessCode);
          if (resolvedId != null) {
            evalData['taadiaId'] = resolvedId;
            try {
              final pendingSnapshot = await _firestore
                  .collection('evaluations')
                  .where('accessCode', isEqualTo: accessCode)
                  .get();
              if (pendingSnapshot.docs.isNotEmpty) {
                final batch = _firestore.batch();
                for (final doc in pendingSnapshot.docs) {
                  batch.update(doc.reference, {
                    'taadiaId': resolvedId,
                  });
                }
                await batch.commit();
              }
            } catch (_) {}
          } else {
            throw Exception('Unresolved code: $accessCode');
          }
        }
        final evalId = op.data['evalId'] as String?;
        if (evalId != null && evalId.isNotEmpty && !evalId.startsWith('pending_') && !evalId.startsWith('code_')) {
          await _firestore.collection('evaluations').doc(evalId).set(
            evalData,
            SetOptions(merge: true),
          );
        } else {
          await _firestore.collection('evaluations').add(evalData);
        }
        break;
      case 'deleteEvaluation':
        await _firestore.collection('evaluations').doc(
          op.data['evalId'] as String,
        ).delete();
        break;
      case 'createGroup':
        await _firestore.collection('groups').add(
          Map<String, dynamic>.from(op.data),
        );
        break;
      case 'updateGroup':
        await _firestore.collection('groups').doc(
          op.data['groupId'] as String,
        ).update(
          Map<String, dynamic>.from(op.data['updates'] as Map),
        );
        break;
      case 'deleteGroup':
        await _firestore.collection('groups').doc(
          op.data['groupId'] as String,
        ).delete();
        break;
      case 'addGroupMember':
        await _firestore.collection('groups').doc(
          op.data['groupId'] as String,
        ).update({'members.${op.data['userId']}': true});
        break;
      case 'removeGroupMember':
        await _firestore.collection('groups').doc(
          op.data['groupId'] as String,
        ).update({'members.${op.data['userId']}': FieldValue.delete()});
        break;
      case 'submitFeedback':
        await _firestore.collection('feedback').add(
          Map<String, dynamic>.from(op.data),
        );
        break;
      case 'deleteFeedback':
        final replies = await _firestore.collection('feedback').doc(
          op.data['feedbackId'] as String,
        ).collection('replies').get();
        for (var r in replies.docs) {
          await r.reference.delete();
        }
        await _firestore.collection('feedback').doc(
          op.data['feedbackId'] as String,
        ).delete();
        break;
      case 'addFeedbackReply':
        await _firestore.collection('feedback').doc(
          op.data['feedbackId'] as String,
        ).collection('replies').add(
          Map<String, dynamic>.from(op.data['reply'] as Map),
        );
        break;
      case 'deleteFeedbackReply':
        await _firestore.collection('feedback').doc(
          op.data['feedbackId'] as String,
        ).collection('replies').doc(
          op.data['replyId'] as String,
        ).delete();
        break;
    }
  }

  Future<void> removePendingEvaluationsByCode(String accessCode) async {
    final pendingId = 'pending_code_$accessCode';
    _queue.removeWhere((op) {
      if (op.type == 'saveEvaluation') {
        final taadiaId = op.data['taadiaId'] as String? ?? '';
        return taadiaId == pendingId;
      }
      return false;
    });
    await _saveQueue();
    notifyListeners();
  }

  Future<String?> _resolveTaadiaIdByCode(String accessCode) async {
    if (_codeLookup != null) {
      final cached = _codeLookup!.lookup(accessCode);
      if (cached != null && !cached.id.startsWith('pending_')) {
        return cached.id;
      }
    }
    try {
      final snapshot = await _firestore
          .collection('taadia')
          .where('accessCode', isEqualTo: accessCode)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        if (_codeLookup != null) {
          final data = doc.data();
          await _codeLookup!.storeCodeMapping(accessCode, CachedTaadia(
            id: doc.id,
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            categories: (data['categories'] as List<dynamic>?)
                    ?.cast<String>() ??
                [],
            classifications: (data['classifications'] as List<dynamic>?)
                    ?.map((e) => Map<String, dynamic>.from(e as Map))
                    .toList() ??
                [],
            active: data['status'] == 'active',
          ));
        }
        return doc.id;
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
