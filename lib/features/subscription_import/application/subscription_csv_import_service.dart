import 'dart:typed_data';

import '../../../core/data/csv_utils.dart';
import '../../../core/data/tabular_import_file_reader.dart';
import '../../../models/finance_models.dart';
import '../../categories/domain/import_category_suggester.dart';
import '../domain/subscription_csv_column_mapping.dart';
import '../domain/subscription_csv_import_preview.dart';
import '../domain/subscription_csv_source_data.dart';

class SubscriptionCsvImportService {
  const SubscriptionCsvImportService();

  SubscriptionCsvSourceData readRaw(
    Uint8List bytes, {
    String fileName = 'import.csv',
  }) {
    final rows = TabularImportFileReader.readRows(
      bytes: bytes,
      fileName: fileName,
    );
    final nonEmptyRows = rows
        .where((row) => row.any((cell) => cell.trim().isNotEmpty))
        .toList();

    if (nonEmptyRows.isEmpty) {
      return const SubscriptionCsvSourceData(
        header: <String>[],
        rows: <List<String>>[],
      );
    }

    return SubscriptionCsvSourceData(
      header: nonEmptyRows.first,
      rows: nonEmptyRows.skip(1).toList(),
    );
  }

  SubscriptionCsvImportPreview parse({
    required Uint8List bytes,
    required List<SubscriptionPlan> existingSubscriptions,
    List<String> availableCategories = const [],
    String fileName = 'import.csv',
  }) {
    final source = readRaw(bytes, fileName: fileName);
    final rows = <List<String>>[
      source.header,
      ...source.rows,
    ].where((row) => row.any((cell) => cell.trim().isNotEmpty)).toList();

    if (rows.isEmpty) {
      return const SubscriptionCsvImportPreview(
        formatLabel: 'Nieznany format',
        subscriptionsToImport: <SubscriptionPlan>[],
        duplicateCount: 0,
        issues: <SubscriptionCsvImportIssue>[
          SubscriptionCsvImportIssue(
            rowNumber: 0,
            message: 'Plik CSV jest pusty.',
            row: <String>[],
          ),
        ],
      );
    }

    return _isAppExport(rows)
        ? _parseAppExport(
            rows: rows,
            existingSubscriptions: existingSubscriptions,
            availableCategories: availableCategories,
          )
        : _parseSimple(
            rows: rows,
            existingSubscriptions: existingSubscriptions,
            availableCategories: availableCategories,
          );
  }

  SubscriptionCsvImportPreview parseWithColumnMapping({
    required SubscriptionCsvSourceData source,
    required SubscriptionCsvColumnMapping mapping,
    required List<SubscriptionPlan> existingSubscriptions,
    List<String> availableCategories = const [],
  }) {
    final headerMap = <String, int>{};
    for (var index = 0; index < source.header.length; index++) {
      headerMap[CsvUtils.normalizeHeader(source.header[index])] = index;
    }

    int? columnIndex(String column) =>
        headerMap[CsvUtils.normalizeHeader(column)];

    final nameIndex = columnIndex(mapping.nameColumn);
    final categoryIndex = mapping.categoryColumn == null
        ? null
        : columnIndex(mapping.categoryColumn!);
    final amountIndex = columnIndex(mapping.amountColumn);
    final cycleIndex = columnIndex(mapping.billingCycleColumn);
    final nextBillingIndex = columnIndex(mapping.nextBillingDateColumn);

    if (nameIndex == null ||
        amountIndex == null ||
        cycleIndex == null ||
        nextBillingIndex == null) {
      return const SubscriptionCsvImportPreview(
        formatLabel: 'Mapowanie kolumn',
        subscriptionsToImport: <SubscriptionPlan>[],
        duplicateCount: 0,
        issues: <SubscriptionCsvImportIssue>[
          SubscriptionCsvImportIssue(
            rowNumber: 1,
            message: 'Mapowanie kolumn jest niepelne albo niepoprawne.',
            row: <String>[],
          ),
        ],
      );
    }

    final activeIndex = mapping.isActiveColumn == null
        ? null
        : columnIndex(mapping.isActiveColumn!);
    final noteIndex = mapping.noteColumn == null
        ? null
        : columnIndex(mapping.noteColumn!);

    final parsedRows = <_ParsedSubscriptionRow>[];
    for (var index = 0; index < source.rows.length; index++) {
      final row = source.rows[index];
      if (row.every((cell) => cell.trim().isEmpty)) {
        continue;
      }

      parsedRows.add(
        _ParsedSubscriptionRow(
          rowNumber: index + 2,
          subscription: _subscriptionFromSimpleRow(
            row: row,
            availableCategories: availableCategories,
            nameIndex: nameIndex,
            categoryIndex: categoryIndex,
            amountIndex: amountIndex,
            cycleIndex: cycleIndex,
            nextBillingIndex: nextBillingIndex,
            activeIndex: activeIndex,
            noteIndex: noteIndex,
          ),
          rawRow: row,
        ),
      );
    }

    return _buildPreview(
      formatLabel: 'CSV z mapowaniem kolumn',
      parsedRows: parsedRows,
      existingSubscriptions: existingSubscriptions,
    );
  }

  bool canOfferColumnMapping(SubscriptionCsvSourceData source) {
    return source.hasHeader && source.hasRows && source.header.length >= 4;
  }

  SubscriptionCsvImportPreview _parseAppExport({
    required List<List<String>> rows,
    required List<SubscriptionPlan> existingSubscriptions,
    required List<String> availableCategories,
  }) {
    final startIndex = rows.indexWhere(
      (row) =>
          row.length >= 9 &&
          CsvUtils.normalizeHeader(row[0]) == 'subskrypcje' &&
          CsvUtils.normalizeHeader(row[1]) == 'id',
    );
    if (startIndex == -1) {
      return const SubscriptionCsvImportPreview(
        formatLabel: 'Eksport aplikacji',
        subscriptionsToImport: <SubscriptionPlan>[],
        duplicateCount: 0,
        issues: <SubscriptionCsvImportIssue>[
          SubscriptionCsvImportIssue(
            rowNumber: 0,
            message: 'Nie znaleziono sekcji subskrypcji w eksporcie CSV.',
            row: <String>[],
          ),
        ],
      );
    }

    final parsedRows = <_ParsedSubscriptionRow>[];
    for (var index = startIndex + 1; index < rows.length; index++) {
      final row = rows[index];
      if (row.isEmpty || row.every((cell) => cell.trim().isEmpty)) {
        break;
      }
      if (CsvUtils.normalizeHeader(row.firstOrNull ?? '') != 'subskrypcje') {
        break;
      }

      parsedRows.add(
        _ParsedSubscriptionRow(
          rowNumber: index + 1,
          subscription: _subscriptionFromExportRow(
            row,
            availableCategories: availableCategories,
          ),
          rawRow: row,
        ),
      );
    }

    return _buildPreview(
      formatLabel: 'Eksport aplikacji',
      parsedRows: parsedRows,
      existingSubscriptions: existingSubscriptions,
    );
  }

  SubscriptionCsvImportPreview _parseSimple({
    required List<List<String>> rows,
    required List<SubscriptionPlan> existingSubscriptions,
    required List<String> availableCategories,
  }) {
    final header = rows.first;
    final headerMap = <String, int>{};
    for (var index = 0; index < header.length; index++) {
      headerMap[CsvUtils.normalizeHeader(header[index])] = index;
    }

    final nameIndex = _findHeaderIndex(headerMap, const [
      'name',
      'nazwa',
      'usluga',
      'service',
    ]);
    final categoryIndex = _findHeaderIndex(headerMap, const [
      'category',
      'kategoria',
    ]);
    final amountIndex = _findHeaderIndex(headerMap, const [
      'amount',
      'kwota',
      'value',
    ]);
    final cycleIndex = _findHeaderIndex(headerMap, const [
      'billingcycle',
      'cycle',
      'cykl',
    ]);
    final nextBillingIndex = _findHeaderIndex(headerMap, const [
      'nextbillingdate',
      'date',
      'data',
      'termin',
      'terminplatnosci',
    ]);
    final activeIndex = _findHeaderIndex(headerMap, const [
      'isactive',
      'active',
      'aktywna',
    ]);
    final noteIndex = _findHeaderIndex(headerMap, const [
      'note',
      'notatka',
      'opis',
    ]);

    final missingRequired = <String>[];
    if (nameIndex == null) {
      missingRequired.add('name');
    }
    if (amountIndex == null) {
      missingRequired.add('amount');
    }
    if (cycleIndex == null) {
      missingRequired.add('billingCycle');
    }
    if (nextBillingIndex == null) {
      missingRequired.add('nextBillingDate');
    }

    if (missingRequired.isNotEmpty) {
      return SubscriptionCsvImportPreview(
        formatLabel: 'Prosty CSV subskrypcji',
        subscriptionsToImport: const <SubscriptionPlan>[],
        duplicateCount: 0,
        issues: <SubscriptionCsvImportIssue>[
          SubscriptionCsvImportIssue(
            rowNumber: 1,
            message:
                'Brakuje wymaganych kolumn: ${missingRequired.join(', ')}. Oczekiwane minimum: name, amount, billingCycle, nextBillingDate. Kategoria moze zostac zgadnieta automatycznie.',
            row: header,
          ),
        ],
      );
    }

    final parsedRows = <_ParsedSubscriptionRow>[];
    for (var index = 1; index < rows.length; index++) {
      final row = rows[index];
      if (row.every((cell) => cell.trim().isEmpty)) {
        continue;
      }

      parsedRows.add(
        _ParsedSubscriptionRow(
          rowNumber: index + 1,
          subscription: _subscriptionFromSimpleRow(
            row: row,
            availableCategories: availableCategories,
            nameIndex: nameIndex!,
            categoryIndex: categoryIndex,
            amountIndex: amountIndex!,
            cycleIndex: cycleIndex!,
            nextBillingIndex: nextBillingIndex!,
            activeIndex: activeIndex,
            noteIndex: noteIndex,
          ),
          rawRow: row,
        ),
      );
    }

    return _buildPreview(
      formatLabel: 'Prosty CSV subskrypcji',
      parsedRows: parsedRows,
      existingSubscriptions: existingSubscriptions,
    );
  }

  SubscriptionCsvImportPreview _buildPreview({
    required String formatLabel,
    required List<_ParsedSubscriptionRow> parsedRows,
    required List<SubscriptionPlan> existingSubscriptions,
  }) {
    final issues = <SubscriptionCsvImportIssue>[];
    final existingKeys = existingSubscriptions.map(_subscriptionKey).toSet();
    final pendingKeys = <String>{};
    final subscriptionsToImport = <SubscriptionPlan>[];
    var duplicateCount = 0;

    for (final parsedRow in parsedRows) {
      final subscription = parsedRow.subscription;
      if (subscription == null) {
        issues.add(
          SubscriptionCsvImportIssue(
            rowNumber: parsedRow.rowNumber,
            message: 'Nie udalo sie odczytac subskrypcji z tego wiersza.',
            row: parsedRow.rawRow,
          ),
        );
        continue;
      }

      final validationError = _validateSubscription(subscription);
      if (validationError != null) {
        issues.add(
          SubscriptionCsvImportIssue(
            rowNumber: parsedRow.rowNumber,
            message: validationError,
            row: parsedRow.rawRow,
          ),
        );
        continue;
      }

      final key = _subscriptionKey(subscription);
      if (existingKeys.contains(key) || pendingKeys.contains(key)) {
        duplicateCount++;
        continue;
      }

      pendingKeys.add(key);
      subscriptionsToImport.add(subscription);
    }

    return SubscriptionCsvImportPreview(
      formatLabel: formatLabel,
      subscriptionsToImport: subscriptionsToImport,
      duplicateCount: duplicateCount,
      issues: issues,
    );
  }

  SubscriptionPlan? _subscriptionFromExportRow(
    List<String> row, {
    required List<String> availableCategories,
  }) {
    if (row.length < 9) {
      return null;
    }

    final amount = _parseAmount(row[4]);
    final billingCycle = _parseBillingCycle(row[5]);
    final nextBillingDate = _parseDate(row[6]);
    if (amount == null || billingCycle == null || nextBillingDate == null) {
      return null;
    }

    return SubscriptionPlan(
      id: '',
      name: row[2].trim(),
      category: ImportCategorySuggester.resolveSubscriptionCategory(
        availableCategories: availableCategories,
        name: row[2].trim(),
        rawCategory: row[3].trim(),
        note: _nullableText(row[8]),
      ),
      amount: amount,
      billingCycle: billingCycle,
      nextBillingDate: nextBillingDate,
      isActive: _parseBool(row[7]) ?? true,
      note: _nullableText(row[8]),
    );
  }

  SubscriptionPlan? _subscriptionFromSimpleRow({
    required List<String> row,
    required List<String> availableCategories,
    required int nameIndex,
    int? categoryIndex,
    required int amountIndex,
    required int cycleIndex,
    required int nextBillingIndex,
    int? activeIndex,
    int? noteIndex,
  }) {
    final amount = _parseAmount(_cell(row, amountIndex));
    final billingCycle = _parseBillingCycle(_cell(row, cycleIndex));
    final nextBillingDate = _parseDate(_cell(row, nextBillingIndex));
    if (amount == null || billingCycle == null || nextBillingDate == null) {
      return null;
    }

    final name = _cell(row, nameIndex).trim();
    final rawCategory = categoryIndex == null ? '' : _cell(row, categoryIndex);
    final note = noteIndex == null
        ? null
        : _nullableText(_cell(row, noteIndex));

    return SubscriptionPlan(
      id: '',
      name: name,
      category: ImportCategorySuggester.resolveSubscriptionCategory(
        availableCategories: availableCategories,
        name: name,
        rawCategory: rawCategory,
        note: note,
      ),
      amount: amount,
      billingCycle: billingCycle,
      nextBillingDate: nextBillingDate,
      isActive: activeIndex == null
          ? true
          : (_parseBool(_cell(row, activeIndex)) ?? true),
      note: note,
    );
  }

  String? _validateSubscription(SubscriptionPlan subscription) {
    if (subscription.name.trim().isEmpty) {
      return 'Brak nazwy subskrypcji.';
    }
    if (subscription.category.trim().isEmpty) {
      return 'Brak kategorii subskrypcji.';
    }
    if (subscription.amount <= 0) {
      return 'Kwota subskrypcji musi byc wieksza od zera.';
    }
    return null;
  }

  String _subscriptionKey(SubscriptionPlan subscription) {
    final amount = subscription.amount.toStringAsFixed(2);
    final date = DateTime(
      subscription.nextBillingDate.year,
      subscription.nextBillingDate.month,
      subscription.nextBillingDate.day,
    ).toIso8601String();

    return [
      CsvUtils.normalizeHeader(subscription.name),
      CsvUtils.normalizeHeader(subscription.category),
      amount,
      subscription.billingCycle.name,
      date,
      '${subscription.isActive}',
    ].join('|');
  }

  int? _findHeaderIndex(Map<String, int> headerMap, List<String> aliases) {
    for (final alias in aliases) {
      final index = headerMap[CsvUtils.normalizeHeader(alias)];
      if (index != null) {
        return index;
      }
    }

    return null;
  }

  bool _isAppExport(List<List<String>> rows) {
    return rows.any(
      (row) =>
          row.length >= 3 &&
          CsvUtils.normalizeHeader(row[0]) == 'sekcja' &&
          CsvUtils.normalizeHeader(row[1]) == 'pole',
    );
  }

  String _cell(List<String> row, int index) {
    if (index < 0 || index >= row.length) {
      return '';
    }
    return row[index];
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  double? _parseAmount(String value) {
    final normalized = value.trim().replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final isoDate = DateTime.tryParse(trimmed);
    if (isoDate != null) {
      return isoDate;
    }

    final dotMatch = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(trimmed);
    if (dotMatch != null) {
      return DateTime(
        int.parse(dotMatch.group(3)!),
        int.parse(dotMatch.group(2)!),
        int.parse(dotMatch.group(1)!),
      );
    }

    final slashMatch = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(trimmed);
    if (slashMatch != null) {
      return DateTime(
        int.parse(slashMatch.group(3)!),
        int.parse(slashMatch.group(2)!),
        int.parse(slashMatch.group(1)!),
      );
    }

    final dashMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(trimmed);
    if (dashMatch != null) {
      return DateTime(
        int.parse(dashMatch.group(1)!),
        int.parse(dashMatch.group(2)!),
        int.parse(dashMatch.group(3)!),
      );
    }

    return null;
  }

  SubscriptionBillingCycle? _parseBillingCycle(String value) {
    return switch (CsvUtils.normalizeHeader(value)) {
      'monthly' ||
      'miesieczny' ||
      'miesiecznie' => SubscriptionBillingCycle.monthly,
      'quarterly' ||
      'kwartalny' ||
      'kwartalnie' => SubscriptionBillingCycle.quarterly,
      'yearly' || 'roczny' || 'rocznie' => SubscriptionBillingCycle.yearly,
      _ => null,
    };
  }

  bool? _parseBool(String value) {
    return switch (CsvUtils.normalizeHeader(value)) {
      'true' || '1' || 'tak' || 'yes' || 'active' || 'aktywna' => true,
      'false' || '0' || 'nie' || 'no' || 'inactive' || 'nieaktywna' => false,
      '' => null,
      _ => null,
    };
  }
}

class _ParsedSubscriptionRow {
  const _ParsedSubscriptionRow({
    required this.rowNumber,
    required this.subscription,
    required this.rawRow,
  });

  final int rowNumber;
  final SubscriptionPlan? subscription;
  final List<String> rawRow;
}

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
