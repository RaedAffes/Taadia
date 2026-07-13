import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

String _mimeFromFilename(String filename) {
  if (filename.endsWith('.pdf')) return 'application/pdf';
  if (filename.endsWith('.xlsx') || filename.endsWith('.xls')) {
    return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }
  if (filename.endsWith('.csv')) return 'text/csv';
  return 'application/octet-stream';
}

Future<void> downloadFile(List<int> bytes, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final sanitized = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  final file = File('${dir.path}/$sanitized');
  await file.writeAsBytes(bytes);

  if (Platform.isAndroid || Platform.isIOS) {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: _mimeFromFilename(filename))],
    );
  }
}
