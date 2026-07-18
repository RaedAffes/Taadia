import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ta3dia/firebase_options.dart';
import 'package:workmanager/workmanager.dart';

const _quranTaskName = 'quranPageDownload';
const _offlineSyncTaskName = 'offlineQueueSync';
const _baseUrl =
    'https://raw.githubusercontent.com/quranpedia/quran-svg/main/mushafs/qalon/kfqc/svg';
const _totalPages = 604;
const _batchSize = 20;

Future<void> _processOfflineQueue() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('offline_queue');
  if (stored == null) return;

  final list = jsonDecode(stored) as List<dynamic>;
  if (list.isEmpty) return;

  final firestore = FirebaseFirestore.instance;
  final queue = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();

  debugPrint('WorkManager: processing ${queue.length} offline operations');

  final remaining = <Map<String, dynamic>>[];

  for (final op in queue) {
    final type = op['type'] as String?;
    final data = Map<String, dynamic>.from(op['data'] as Map);
    try {
      switch (type) {
        case 'createTaadia':
          await firestore.collection('taadia').add(data);
          break;
        case 'updateTaadia':
          await firestore
              .collection('taadia')
              .doc(data['taadiaId'] as String)
              .update(Map<String, dynamic>.from(data['updates'] as Map));
          break;
        case 'deleteTaadia':
          await firestore
              .collection('taadia')
              .doc(data['taadiaId'] as String)
              .delete();
          break;
        case 'saveEvaluation':
          final evalData = Map<String, dynamic>.from(data['evaluation'] as Map);
          if (evalData['createdAt'] is String) {
            evalData['createdAt'] =
                DateTime.tryParse(evalData['createdAt'] as String) ??
                    DateTime.now();
          }
          final evalId = data['evalId'] as String?;
          if (evalId != null &&
              evalId.isNotEmpty &&
              !evalId.startsWith('pending_') &&
              !evalId.startsWith('code_')) {
            await firestore
                .collection('evaluations')
                .doc(evalId)
                .set(evalData, SetOptions(merge: true));
          } else {
            await firestore.collection('evaluations').add(evalData);
          }
          break;
        case 'deleteEvaluation':
          await firestore
              .collection('evaluations')
              .doc(data['evalId'] as String)
              .delete();
          break;
        case 'createGroup':
          await firestore.collection('groups').add(data);
          break;
        case 'updateGroup':
          await firestore
              .collection('groups')
              .doc(data['groupId'] as String)
              .update(Map<String, dynamic>.from(data['updates'] as Map));
          break;
        case 'deleteGroup':
          await firestore
              .collection('groups')
              .doc(data['groupId'] as String)
              .delete();
          break;
        case 'addGroupMember':
          await firestore
              .collection('groups')
              .doc(data['groupId'] as String)
              .update({'members.${data['userId']}': true});
          break;
        case 'removeGroupMember':
          await firestore
              .collection('groups')
              .doc(data['groupId'] as String)
              .update({'members.${data['userId']}': FieldValue.delete()});
          break;
        case 'submitFeedback':
          await firestore.collection('feedback').add(data);
          break;
        case 'addFeedbackReply':
          await firestore
              .collection('feedback')
              .doc(data['feedbackId'] as String)
              .collection('replies')
              .add(Map<String, dynamic>.from(data['reply'] as Map));
          break;
        case 'deleteFeedbackReply':
          await firestore
              .collection('feedback')
              .doc(data['feedbackId'] as String)
              .collection('replies')
              .doc(data['replyId'] as String)
              .delete();
          break;
        default:
          remaining.add(op);
      }
      debugPrint('WorkManager: ${type} synced');
    } catch (e) {
      debugPrint('WorkManager: ${type} failed: $e');
      remaining.add(op);
    }
  }

  await prefs.setString('offline_queue', jsonEncode(remaining));
  debugPrint('WorkManager: ${queue.length - remaining.length}/${queue.length} operations synced');
}

@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('WorkManager: running task $task');

    if (task == _offlineSyncTaskName) {
      try {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
        FirebaseFirestore.instance.settings = Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        await _processOfflineQueue();
        return true;
      } catch (e) {
        debugPrint('WorkManager: offline sync error: $e');
        return false;
      }
    }

    if (task == _quranTaskName) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final cacheDir = Directory('${appDir.path}/quran_svg');
        if (!await cacheDir.exists()) {
          await cacheDir.create(recursive: true);
        }

        final completed = <int>{};
        for (final file in cacheDir.listSync().whereType<File>()) {
          final match =
              RegExp(r'^(\d+)\.svg$').firstMatch(file.uri.pathSegments.last);
          if (match != null) {
            completed.add(int.parse(match.group(1)!));
          }
        }

        if (completed.length >= _totalPages) {
          debugPrint(
              'WorkManager: all $_totalPages pages already downloaded');
          return true;
        }

        final missing = <int>[];
        for (var p = 1; p <= _totalPages; p++) {
          if (!completed.contains(p)) missing.add(p);
        }

        final batch = missing.take(_batchSize).toList();
        debugPrint(
            'WorkManager: downloading ${batch.length} pages (${completed.length}/$_totalPages done)');

        await Future.wait(batch.map((page) async {
          for (var attempt = 0; attempt < 3; attempt++) {
            try {
              final url =
                  '$_baseUrl/${page.toString().padLeft(3, '0')}.svg';
              final response = await http
                  .get(Uri.parse(url))
                  .timeout(const Duration(seconds: 30));
              if (response.statusCode == 200) {
                final file = File(
                    '${cacheDir.path}/${page.toString().padLeft(3, '0')}.svg');
                await file.writeAsString(response.body);
                debugPrint('WorkManager: page $page saved');
                return;
              }
            } catch (e) {
              if (attempt < 2) {
                await Future.delayed(const Duration(seconds: 2));
              }
            }
          }
        }));

        return true;
      } catch (e) {
        debugPrint('WorkManager: quran download error: $e');
        return false;
      }
    }

    return true;
  });
}

Future<void> initQuranWorkManager() async {
  if (kIsWeb) return;
  await Workmanager().initialize(
    workmanagerCallbackDispatcher,
    isInDebugMode: false,
  );
  await Workmanager().registerPeriodicTask(
    'quranPageDownloadPeriodic',
    _quranTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    backoffPolicy: BackoffPolicy.exponential,
    initialDelay: const Duration(minutes: 1),
  );
  await Workmanager().registerPeriodicTask(
    'offlineQueueSyncPeriodic',
    _offlineSyncTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    backoffPolicy: BackoffPolicy.exponential,
    initialDelay: const Duration(minutes: 2),
  );
  debugPrint('WorkManager: periodic Quran download + offline sync registered');
}
