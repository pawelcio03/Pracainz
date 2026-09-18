import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../models/finance_models.dart';
import '../../export/domain/export_share_gateway.dart';
import '../domain/report_archive_repository.dart';

class FirebaseReportArchiveRepository
    implements ReportArchiveRepository, ReportArchiveDownloadUriRepository {
  const FirebaseReportArchiveRepository({this.firestore, this.storage});

  final FirebaseFirestore? firestore;
  final FirebaseStorage? storage;

  FirebaseFirestore get _firestore => firestore ?? FirebaseFirestore.instance;

  FirebaseStorage get _storage => storage ?? FirebaseStorage.instance;

  @override
  Stream<List<ReportArchiveEntry>> watchArchives(String userId) {
    return _archives(userId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDocument).toList());
  }

  @override
  Future<ExportFilePayload> loadArchiveFile({
    required String userId,
    required ReportArchiveEntry archive,
  }) async {
    final bytes = await _storage.ref(archive.storagePath).getData();
    if (bytes == null) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'object-not-found',
        message: 'Nie udalo sie pobrac pliku z Firebase Storage.',
      );
    }

    return ExportFilePayload(
      filename: archive.filename,
      mimeType: archive.contentType,
      bytes: bytes,
      subject: 'Archiwum raportu ${_periodKey(archive.periodStart)}',
      text: 'Archiwalny raport pobrany z Firebase Storage.',
    );
  }

  @override
  Future<Uri?> getArchiveDownloadUri({
    required String userId,
    required ReportArchiveEntry archive,
  }) async {
    if (archive.storagePath.trim().isEmpty) {
      return null;
    }

    final url = await _storage.ref(archive.storagePath).getDownloadURL();
    return Uri.parse(url);
  }

  @override
  Future<void> archiveFile({
    required String userId,
    required ExportFilePayload file,
    required DateTime periodStart,
    required ReportArchiveFormat format,
    String? reportId,
  }) async {
    final normalizedPeriod = DateTime(periodStart.year, periodStart.month);
    final document = _archives(userId).doc();
    final periodKey = _periodKey(normalizedPeriod);
    final filename = file.filename.trim();
    final storagePath =
        'users/$userId/reports/$periodKey/${document.id}-$filename';
    final uploadedAt = DateTime.now();

    await _storage
        .ref(storagePath)
        .putData(file.bytes, SettableMetadata(contentType: file.mimeType));

    await document.set({
      'reportId': reportId,
      'filename': filename,
      'format': format.name,
      'periodStart': Timestamp.fromDate(normalizedPeriod),
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'sizeBytes': file.bytes.length,
      'contentType': file.mimeType,
      'storagePath': storagePath,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteArchive({
    required String userId,
    required ReportArchiveEntry archive,
  }) async {
    await _storage.ref(archive.storagePath).delete();
    await _archives(userId).doc(archive.id).delete();
  }

  CollectionReference<Map<String, dynamic>> _archives(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('reportArchives');
  }

  ReportArchiveEntry _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final periodStart =
        (data['periodStart'] as Timestamp?)?.toDate() ?? DateTime.now();
    final uploadedAt =
        (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return ReportArchiveEntry(
      id: document.id,
      reportId: data['reportId'] as String?,
      filename: data['filename'] as String? ?? 'raport',
      format: _formatFromName(data['format'] as String?),
      periodStart: DateTime(periodStart.year, periodStart.month),
      uploadedAt: uploadedAt,
      sizeBytes: (data['sizeBytes'] as num?)?.toInt() ?? 0,
      contentType: data['contentType'] as String? ?? 'application/octet-stream',
      storagePath: data['storagePath'] as String? ?? '',
    );
  }

  ReportArchiveFormat _formatFromName(String? value) {
    return ReportArchiveFormat.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => ReportArchiveFormat.pdf,
    );
  }

  String _periodKey(DateTime periodStart) {
    final month = periodStart.month.toString().padLeft(2, '0');
    return '${periodStart.year}-$month';
  }
}
