import 'dart:typed_data';

class ExportFilePayload {
  const ExportFilePayload({
    required this.filename,
    required this.mimeType,
    required this.bytes,
    this.subject,
    this.text,
  });

  final String filename;
  final String mimeType;
  final Uint8List bytes;
  final String? subject;
  final String? text;
}

abstract class ExportShareGateway {
  Future<void> share(ExportFilePayload file);
}
