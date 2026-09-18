import 'package:share_plus/share_plus.dart';

import '../domain/export_share_gateway.dart';

class SharePlusExportShareGateway implements ExportShareGateway {
  const SharePlusExportShareGateway();

  @override
  Future<void> share(ExportFilePayload file) {
    return SharePlus.instance.share(
      ShareParams(
        subject: file.subject,
        text: file.text,
        files: [
          XFile.fromData(
            file.bytes,
            mimeType: file.mimeType,
            name: file.filename,
          ),
        ],
        fileNameOverrides: [file.filename],
      ),
    );
  }
}
