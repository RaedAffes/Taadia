import 'dart:async';

class BackgroundDownloadService {
  static final instance = BackgroundDownloadService._();
  BackgroundDownloadService._();

  Stream<int> get progressStream => const Stream.empty();

  Future<void> init() async {}

  Future<void> stop() async {}
}
