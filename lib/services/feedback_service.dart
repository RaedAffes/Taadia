import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ta3dia/models/feedback_model.dart';
import 'package:ta3dia/services/connectivity_service.dart';
import 'package:ta3dia/services/offline_queue_service.dart';

class FeedbackService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConnectivityService _connectivityService;
  final OfflineQueueService _offlineQueue;
  StreamSubscription<QuerySnapshot>? _sub;
  StreamSubscription<QuerySnapshot>? _mySub;
  List<FeedbackItem> _items = [];
  List<FeedbackItem> _myItems = [];
  bool _loading = false;
  bool _myLoading = false;

  List<FeedbackItem> get items => _items;
  List<FeedbackItem> get myItems => _myItems;
  bool get loading => _loading;
  bool get myLoading => _myLoading;

  FeedbackService(this._connectivityService, this._offlineQueue);

  Future<void> loadFeedback() async {
    _sub?.cancel();
    _loading = true;
    notifyListeners();

    try {
      final cacheSnapshot = await _firestore
          .collection('feedback')
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.cache));
      _items = cacheSnapshot.docs
          .map((d) => FeedbackItem.fromFirestore(d.id, d.data()))
          .toList();
    } catch (_) {}

    _mergePendingLocalFeedback();
    _loading = false;
    notifyListeners();

    _sub = _firestore
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snap) {
            _items = snap.docs
                .map((d) => FeedbackItem.fromFirestore(d.id, d.data()))
                .toList();
            _mergePendingLocalFeedback();
            _loading = false;
            notifyListeners();
          },
          onError: (_) {
            _loading = false;
            notifyListeners();
          },
        );
  }

  Future<void> loadMyFeedback(String userId) async {
    _mySub?.cancel();
    _myLoading = true;
    notifyListeners();

    try {
      final cacheSnapshot = await _firestore
          .collection('feedback')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.cache));
      _myItems = cacheSnapshot.docs
          .map((d) => FeedbackItem.fromFirestore(d.id, d.data()))
          .toList();
    } catch (_) {}

    _mergePendingLocalFeedback();
    _myLoading = false;
    notifyListeners();

    _mySub = _firestore
        .collection('feedback')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snap) {
            _myItems = snap.docs
                .map((d) => FeedbackItem.fromFirestore(d.id, d.data()))
                .toList();
            _mergePendingLocalFeedback();
            _myLoading = false;
            notifyListeners();
          },
          onError: (_) {
            _myLoading = false;
            notifyListeners();
          },
        );
  }

  Future<String> submitFeedback(
    String userId,
    String userName,
    String message,
  ) async {
    final data = <String, dynamic>{
      'userId': userId,
      'userName': userName,
      'message': message,
      'createdAt': DateTime.now().toIso8601String(),
    };

    final localId = 'offline_fb_${DateTime.now().millisecondsSinceEpoch}';
    final localItem = FeedbackItem(
      id: localId,
      userId: userId,
      userName: userName,
      message: message,
      createdAt: DateTime.now(),
    );
    _items.insert(0, localItem);
    _myItems.insert(0, localItem);
    notifyListeners();

    data['_offlineId'] = localId;

    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('submitFeedback', data);
      return '';
    }

    try {
      await _firestore.collection('feedback').add(data);
      return '';
    } catch (e) {
      await _offlineQueue.enqueue('submitFeedback', data);
      return '';
    }
  }

  Stream<List<FeedbackReply>> repliesStream(String feedbackId) {
    return _firestore
        .collection('feedback')
        .doc(feedbackId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => FeedbackReply.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  Future<String> addReply({
    required String feedbackId,
    required String message,
    required String senderId,
    required String senderName,
    required bool isAdmin,
  }) async {
    final data = <String, dynamic>{
      'message': message,
      'senderId': senderId,
      'senderName': senderName,
      'isAdmin': isAdmin,
      'createdAt': DateTime.now().toIso8601String(),
    };

    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('addFeedbackReply', {
        'feedbackId': feedbackId,
        'reply': data,
      });
      return '';
    }

    try {
      await _firestore
          .collection('feedback')
          .doc(feedbackId)
          .collection('replies')
          .add(data);
      return '';
    } catch (e) {
      await _offlineQueue.enqueue('addFeedbackReply', {
        'feedbackId': feedbackId,
        'reply': data,
      });
      return '';
    }
  }

  Future<String> deleteFeedback(String docId) async {
    _items.removeWhere((i) => i.id == docId);
    _myItems.removeWhere((i) => i.id == docId);
    notifyListeners();

    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('deleteFeedback', {'feedbackId': docId});
      return '';
    }

    try {
      final replies = await _firestore
          .collection('feedback')
          .doc(docId)
          .collection('replies')
          .get();
      for (var r in replies.docs) {
        await r.reference.delete();
      }
      await _firestore.collection('feedback').doc(docId).delete();
      return '';
    } catch (e) {
      await _offlineQueue.enqueue('deleteFeedback', {'feedbackId': docId});
      return '';
    }
  }

  Future<String> deleteReply(String feedbackId, String replyId) async {
    if (_connectivityService.isOffline) {
      await _offlineQueue.enqueue('deleteFeedbackReply', {
        'feedbackId': feedbackId,
        'replyId': replyId,
      });
      return '';
    }

    try {
      await _firestore
          .collection('feedback')
          .doc(feedbackId)
          .collection('replies')
          .doc(replyId)
          .delete();
      return '';
    } catch (e) {
      await _offlineQueue.enqueue('deleteFeedbackReply', {
        'feedbackId': feedbackId,
        'replyId': replyId,
      });
      return '';
    }
  }

  void _mergePendingLocalFeedback() {
    final pending = _offlineQueue.getPendingByType('submitFeedback');
    for (final op in pending) {
      final data = op.data;
      final localId = data['_offlineId'] as String? ?? 'offline_fb_${op.timestamp.millisecondsSinceEpoch}';
      final alreadyExists = _items.any((i) => i.id == localId);
      if (alreadyExists) continue;
      final item = FeedbackItem(
        id: localId,
        userId: data['userId'] ?? '',
        userName: data['userName'] ?? '',
        message: data['message'] ?? '',
        createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? op.timestamp,
      );
      _items.add(item);
      _myItems.add(item);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _mySub?.cancel();
    super.dispose();
  }
}
