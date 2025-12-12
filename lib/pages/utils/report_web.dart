import 'dart:typed_data';
import 'dart:html' as html;

Future<String> saveReport({
  required Uint8List bytes,
  required String fileName,
}) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();

  html.Url.revokeObjectUrl(url);
  return "Download dimulai (Web)";
}
