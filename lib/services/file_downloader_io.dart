import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> downloadFile(List<int> bytes, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final sanitized = filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  final file = File('${dir.path}/$sanitized');
  await file.writeAsBytes(bytes);
}
