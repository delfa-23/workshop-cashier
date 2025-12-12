import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String> saveReport({
  required Uint8List bytes,
  required String fileName,
}) async {
  await Permission.storage.request();

  Directory? dir;
  if (Platform.isAndroid) {
    dir = Directory('/storage/emulated/0/Download');
  } else {
    dir = await getDownloadsDirectory();
  }

  final path = '${dir!.path}/$fileName';
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);

  return "Disimpan di: $path";
}
