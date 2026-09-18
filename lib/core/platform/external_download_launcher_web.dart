import 'package:web/web.dart' as web;

Future<void> launchExternalDownload(
  Uri uri, {
  required String filename,
}) async {
  final anchor = web.HTMLAnchorElement()
    ..href = uri.toString()
    ..target = '_blank'
    ..rel = 'noopener';

  final normalizedFilename = filename.trim();
  if (normalizedFilename.isNotEmpty) {
    anchor.download = normalizedFilename;
  }

  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
}
