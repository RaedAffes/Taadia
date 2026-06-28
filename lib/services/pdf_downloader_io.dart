import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<void> downloadPdf(Uint8List bytes, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final sanitized = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  final file = File('${dir.path}/$sanitized');
  await file.writeAsBytes(bytes);

  if (Platform.isWindows) {
    await Process.run('cmd', ['/c', 'start', '', file.path]);
  } else if (Platform.isMacOS) {
    await Process.run('open', [file.path]);
  } else if (Platform.isLinux) {
    await Process.run('xdg-open', [file.path]);
  }
}
