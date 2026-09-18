import '../../../models/finance_models.dart';
import '../../export/domain/export_share_gateway.dart';

abstract class ReportArchiveRepository {
  Stream<List<ReportArchiveEntry>> watchArchives(String userId);

  Future<ExportFilePayload> loadArchiveFile({
    required String userId,
    required ReportArchiveEntry archive,
  });

  Future<void> archiveFile({
    required String userId,
    required ExportFilePayload file,
    required DateTime periodStart,
    required ReportArchiveFormat format,
    String? reportId,
  });

  Future<void> deleteArchive({
    required String userId,
    required ReportArchiveEntry archive,
  });
}

abstract class ReportArchiveDownloadUriRepository {
  Future<Uri?> getArchiveDownloadUri({
    required String userId,
    required ReportArchiveEntry archive,
  });
}
