// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js' as js;

Future<String> triggerPwaInstall() async {
  final result = await js.context.callMethod('triggerPwaInstall');
  return result as String;
}
