import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/finance_models.dart';
import '../../export/domain/export_share_gateway.dart';
import '../domain/report_archive_repository.dart';

class ReportArchivesController extends ChangeNotifier {
  ReportArchivesController({required this.repository, required this.userId}) {
    _subscription = repository
        .watchArchives(userId)
        .listen(
          (archives) {
            _archives = archives;
            _error = null;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _error = error;
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  final ReportArchiveRepository repository;
  final String userId;
  late final StreamSubscription<List<ReportArchiveEntry>> _subscription;

  bool _isLoading = true;
  Object? _error;
  List<ReportArchiveEntry> _archives = const [];

  bool get isLoading => _isLoading;

  Object? get error => _error;

  List<ReportArchiveEntry> get archives => _archives;

  List<ReportArchiveEntry> archivesForPeriod(DateTime periodStart) {
    final normalizedPeriod = DateTime(periodStart.year, periodStart.month);
    return _archives
        .where(
          (archive) =>
              archive.periodStart.year == normalizedPeriod.year &&
              archive.periodStart.month == normalizedPeriod.month,
        )
        .toList();
  }

  Future<ExportFilePayload> loadFile(ReportArchiveEntry archive) {
    return repository.loadArchiveFile(userId: userId, archive: archive);
  }

  Future<void> archiveFile({
    required ExportFilePayload file,
    required DateTime periodStart,
    required ReportArchiveFormat format,
    String? reportId,
  }) {
    return repository.archiveFile(
      userId: userId,
      file: file,
      periodStart: periodStart,
      format: format,
      reportId: reportId,
    );
  }

  Future<void> delete(ReportArchiveEntry archive) {
    return repository.deleteArchive(userId: userId, archive: archive);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
