import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class BackgroundDownloadService {
  static const _baseUrl =
      'https://raw.githubusercontent.com/quranpedia/quran-svg/main/mushafs/qalon/kfqc/svg';
  static const totalPages = 604;
  static const _concurrency = 6;

  static final instance = BackgroundDownloadService._();
  BackgroundDownloadService._();

  static final _controller = StreamController<int>.broadcast();
  Stream<int> get progressStream => _controller.stream;

  Future<void> init() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'quran_download',
        initialNotificationTitle: '',
        initialNotificationContent: '',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
      ),
    );

    final running = await service.isRunning();
    if (!running) {
      await service.startService();
    }
  }

  static void _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    service.on('stopService').listen((_) {
      service.stopSelf();
    });

    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/quran_svg');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final completed = <int>{};
    final files = cacheDir.listSync().whereType<File>();
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final match = RegExp(r'^(\d+)\.svg$').firstMatch(name);
      if (match != null) {
        completed.add(int.parse(match.group(1)!));
      }
    }

    final pagesToDownload = <int>[];
    for (var p = 1; p <= totalPages; p++) {
      if (!completed.contains(p)) {
        pagesToDownload.add(p);
      }
    }

    if (pagesToDownload.isEmpty) {
      if (service is AndroidServiceInstance) {
        await service.setForegroundNotificationInfo(
          title: 'Taadia',
          content: 'All Quran pages downloaded',
        );
      }
      service.invoke('update', {'complete': true});
      return;
    }

    final total = pagesToDownload.length;
    var downloaded = 0;

    if (service is AndroidServiceInstance) {
      await service.setForegroundNotificationInfo(
        title: 'Downloading Quran',
        content: '0/$total pages',
      );
    }

    for (var i = 0; i < pagesToDownload.length; i += _concurrency) {
      final batch = pagesToDownload.sublist(
        i,
        (i + _concurrency).clamp(0, pagesToDownload.length),
      );

      await Future.wait(batch.map((page) async {
        if (service is AndroidServiceInstance && await service.isForegroundService() == false) {
          return;
        }
        try {
          final url = '$_baseUrl/${page.toString().padLeft(3, '0')}.svg';
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            final file = File('${cacheDir.path}/${page.toString().padLeft(3, '0')}.svg');
            await file.writeAsString(response.body);
            downloaded++;
            _controller.add(downloaded);

            if (service is AndroidServiceInstance) {
              await service.setForegroundNotificationInfo(
                title: 'Downloading Quran',
                content: '$downloaded/$total pages',
              );
            }
            service.invoke('update', {
              'downloaded': downloaded,
              'total': total,
            });
          }
        } catch (e) {
          debugPrint('BackgroundDownload: failed page $page: $e');
        }
      }));
    }

    if (service is AndroidServiceInstance) {
      await service.setForegroundNotificationInfo(
        title: 'Taadia',
        content: 'All Quran pages downloaded!',
      );
    }
    service.invoke('update', {'complete': true, 'downloaded': downloaded, 'total': total});
  }

  Future<void> stop() async {
    final service = FlutterBackgroundService();
    final running = await service.isRunning();
    if (running) {
      service.invoke('stopService');
    }
  }
}
