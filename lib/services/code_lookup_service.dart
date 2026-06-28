import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ta3dia/services/connectivity_service.dart';

class CachedTaadia {
  final String id;
  final String title;
  final String description;
  final List<String> categories;
  final List<Map<String, dynamic>> classifications;
  final bool active;

  CachedTaadia({
    required this.id,
    required this.title,
    this.description = '',
    this.categories = const [],
    this.classifications = const [],
    this.active = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'categories': categories,
    'classifications': classifications,
    'active': active,
  };

  factory CachedTaadia.fromMap(Map<String, dynamic> map) => CachedTaadia(
    id: map['id'] as String,
    title: map['title'] as String? ?? '',
    description: map['description'] as String? ?? '',
    categories: (map['categories'] as List<dynamic>?)?.cast<String>() ?? [],
    classifications: (map['classifications'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [],
    active: map['active'] as bool? ?? true,
  );
}

class CodeLookupService extends ChangeNotifier {
  static const String _storageKey = 'code_lookup_table';
  final ConnectivityService _connectivityService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot>? _pendingWatcher;

  Map<String, CachedTaadia> _codeToTaadia = {};

  VoidCallback? onCodeResolved;

  CodeLookupService(this._connectivityService) {
    _connectivityService.addListener(_onConnectivityChanged);
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) clear();
    });
    _loadFromPrefs().then((_) {
      if (_connectivityService.isOnline) {
        resolvePendingCodes();
      }
      _setupPendingWatcher();
    });
  }

  List<MapEntry<String, CachedTaadia>> get allEntries =>
      _codeToTaadia.entries.toList();

  CachedTaadia? lookup(String code) => _codeToTaadia[code];

  bool hasCode(String code) => _codeToTaadia.containsKey(code);

  List<String> get pendingCodes =>
      _codeToTaadia.entries
          .where((e) => e.value.id.startsWith('pending_'))
          .map((e) => e.key)
          .toList();

  Future<void> storeCodeMapping(String code, CachedTaadia taadia) async {
    _codeToTaadia[code] = taadia;
    await _saveToPrefs();
    notifyListeners();
    _setupPendingWatcher();
  }

  Future<void> removeEntry(String code) async {
    _codeToTaadia.remove(code);
    await _saveToPrefs();
    notifyListeners();
    _setupPendingWatcher();
  }

  Future<void> clear() async {
    _codeToTaadia.clear();
    _pendingWatcher?.cancel();
    _pendingWatcher = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  void _setupPendingWatcher() {
    _pendingWatcher?.cancel();
    _pendingWatcher = null;

    final codes = pendingCodes;
    if (codes.isEmpty || !_connectivityService.isOnline) return;

    if (codes.length == 1) {
      _pendingWatcher = _firestore
          .collection('taadia')
          .where('accessCode', isEqualTo: codes.first)
          .where('status', isEqualTo: 'active')
          .snapshots()
          .listen((snapshot) => _handleWatcherSnapshot(snapshot));
    } else {
      for (final code in codes) {
        final sub = _firestore
            .collection('taadia')
            .where('accessCode', isEqualTo: code)
            .where('status', isEqualTo: 'active')
            .snapshots()
            .listen((snapshot) => _handleWatcherSnapshot(snapshot, forCode: code));
        _pendingWatcher ??= sub;
      }
    }
  }

  void _handleWatcherSnapshot(QuerySnapshot snapshot, {String? forCode}) {
    if (snapshot.docs.isEmpty) return;
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
        final doc = change.doc;
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        final code = data['accessCode'] as String?;
        if (code == null || !_codeToTaadia.containsKey(code)) continue;
        final cached = _codeToTaadia[code]!;
        if (!cached.id.startsWith('pending_')) continue;

        final resolved = CachedTaadia(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          categories: (data['categories'] as List<dynamic>?)
                  ?.cast<String>() ?? [],
          classifications: (data['classifications'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ?? [],
          active: data['status'] == 'active',
        );
        _codeToTaadia[code] = resolved;
        _saveToPrefs();
        notifyListeners();
        onCodeResolved?.call();
      }
    }
  }

  Future<void> resolvePendingCodes() async {
    if (!_connectivityService.isOnline) return;

    final codesToResolve = _codeToTaadia.entries
        .where((e) => e.value.id.startsWith('pending_'))
        .map((e) => e.key)
        .toList();

    if (codesToResolve.isEmpty) {
      _setupPendingWatcher();
      return;
    }

    for (final code in codesToResolve) {
      try {
        final snapshot = await _firestore
            .collection('taadia')
            .where('accessCode', isEqualTo: code)
            .where('status', isEqualTo: 'active')
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          final data = doc.data();
          final cached = CachedTaadia(
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
          );
          _codeToTaadia[code] = cached;
        }
      } catch (_) {}
    }
    await _saveToPrefs();
    notifyListeners();
    _setupPendingWatcher();
    onCodeResolved?.call();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      final map = jsonDecode(stored) as Map<String, dynamic>;
      _codeToTaadia = map.map((k, v) =>
          MapEntry(k, CachedTaadia.fromMap(Map<String, dynamic>.from(v as Map))));
      notifyListeners();
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _codeToTaadia.map((k, v) => MapEntry(k, v.toMap()));
    await prefs.setString(_storageKey, jsonEncode(map));
  }

  void _onConnectivityChanged() {
    if (_connectivityService.isOnline) {
      resolvePendingCodes().then((_) {
        onCodeResolved?.call();
      });
    } else {
      _pendingWatcher?.cancel();
      _pendingWatcher = null;
    }
  }

  @override
  void dispose() {
    _pendingWatcher?.cancel();
    _connectivityService.removeListener(_onConnectivityChanged);
    _authSub?.cancel();
    super.dispose();
  }
}
