import 'dart:typed_data';

import '../../../core/data/csv_utils.dart';
import '../../../core/data/tabular_import_file_reader.dart';
import '../../../models/finance_models.dart';
import '../../categories/domain/import_category_suggester.dart';
import '../domain/bank_transaction_import_template.dart';
import '../domain/import_category_rule.dart';
import '../domain/transaction_csv_column_mapping.dart';
import '../domain/transaction_csv_import_preview.dart';
import '../domain/transaction_csv_source_data.dart';

class TransactionCsvImportService {
  const TransactionCsvImportService();

  static const List<String> _titleHeaderAliases = [
    'title',
    'nazwa',
    'tytul',
    'description',
    'opis',
    'opisoperacji',
    'tytuloperacji',
    'opistransakcji',
    'szczegolytransakcji',
    'typtransakcji',
    'nazwaodbiorcy',
    'daneodbiorcy',
    'odbiorca',
    'nadawca',
    'nadawcaodbiorca',
    'odbiorcanadawca',
    'nazwanadawcyodbiorcy',
    'kontrahent',
    'nazwakontrahenta',
    'danekontrahenta',
    'tytulplatnosci',
    'opisplatnosci',
  ];

  static const List<String> _categoryHeaderAliases = [
    'category',
    'kategoria',
    'kategoriabanku',
  ];

  static const List<String> _amountHeaderAliases = [
    'amount',
    'kwota',
    'value',
    'kwotaoperacji',
    'kwotatransakcji',
    'kwotapln',
    'kwotawpln',
    'kwotawwalucierachunku',
    'kwotarachunku',
    'kwotaplatnosci',
    'kwotazaksiegowana',
    'wartoscoperacji',
  ];

  static const List<String> _dateHeaderAliases = [
    'date',
    'data',
    'dataoperacji',
    'dataksiegowania',
    'datatransakcji',
    'datawaluty',
    'datazlecenia',
    'datarealizacji',
  ];

  static const List<String> _typeHeaderAliases = [
    'type',
    'typ',
    'typoperacji',
    'rodzajoperacji',
    'typtransakcji',
  ];

  static const List<String> _noteHeaderAliases = [
    'note',
    'notatka',
    'opistransakcji',
    'szczegoly',
    'szczegolyoperacji',
    'daneodbiorcy',
    'tytul',
    'tytuloperacji',
    'tytulplatnosci',
    'opisplatnosci',
    'numerreferencyjny',
    'referencje',
    'informacje',
  ];

  static const List<String> _goalHeaderAliases = ['goalid', 'celid', 'goal'];

  TransactionCsvSourceData readRaw(
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
      return const TransactionCsvSourceData(
        header: <String>[],
        rows: <List<String>>[],
        sourceName: '',
      );
    }

    final headerIndex = _findLikelyHeaderRowIndex(nonEmptyRows);
    return TransactionCsvSourceData(
      header: nonEmptyRows[headerIndex],
      rows: nonEmptyRows.skip(headerIndex + 1).toList(),
      sourceName: fileName,
    );
  }

  TransactionCsvImportPreview parse({
    required Uint8List bytes,
    required List<FinanceTransaction> existingTransactions,
    List<FinanceCategory> availableCategories = const [],
    List<ImportCategoryRule> importCategoryRules = const [],
    String fileName = 'import.csv',
  }) {
    final source = readRaw(bytes, fileName: fileName);

    if (!source.hasHeader) {
      return const TransactionCsvImportPreview(
        formatLabel: 'Nieznany format',
        transactionsToImport: <FinanceTransaction>[],
        duplicateCount: 0,
        issues: <TransactionCsvImportIssue>[
          TransactionCsvImportIssue(
            rowNumber: 0,
            message: 'Plik CSV jest pusty.',
            row: <String>[],
          ),
        ],
      );
    }

    final nonEmptyRows = <List<String>>[source.header, ...source.rows];
    if (_isAppExport(nonEmptyRows)) {
      return _parseAppExport(
        rows: nonEmptyRows,
        existingTransactions: existingTransactions,
        availableCategories: availableCategories,
        importCategoryRules: importCategoryRules,
      );
    }

    final bankTemplate = BankTransactionImportTemplateDetector.detect(source);
    if (bankTemplate != null) {
      return parseWithColumnMapping(
        source: source,
        mapping: bankTemplate.mapping,
        existingTransactions: existingTransactions,
        availableCategories: availableCategories,
        importCategoryRules: importCategoryRules,
        formatLabel: bankTemplate.label,
      );
    }

    return _parseSimpleTransactions(
      rows: nonEmptyRows,
      existingTransactions: existingTransactions,
      availableCategories: availableCategories,
      importCategoryRules: importCategoryRules,
    );
  }

  TransactionCsvImportPreview parseWithColumnMapping({
    required TransactionCsvSourceData source,
    required TransactionCsvColumnMapping mapping,
    required List<FinanceTransaction> existingTransactions,
    List<FinanceCategory> availableCategories = const [],
    List<ImportCategoryRule> importCategoryRules = const [],
    String formatLabel = 'CSV z mapowaniem kolumn',
  }) {
    final headerMap = <String, int>{};
    for (var index = 0; index < source.header.length; index++) {
      headerMap[CsvUtils.normalizeHeader(source.header[index])] = index;
    }

    int? columnIndex(String column) =>
        headerMap[CsvUtils.normalizeHeader(column)];

    final titleIndex = columnIndex(mapping.titleColumn);
    final categoryIndex = mapping.categoryColumn == null
        ? null
        : columnIndex(mapping.categoryColumn!);
    final amountIndex = columnIndex(mapping.amountColumn);
    final dateIndex = columnIndex(mapping.dateColumn);

    if (titleIndex == null || amountIndex == null || dateIndex == null) {
      return const TransactionCsvImportPreview(
        formatLabel: 'Mapowanie kolumn',
        transactionsToImport: <FinanceTransaction>[],
        duplicateCount: 0,
        issues: <TransactionCsvImportIssue>[
          TransactionCsvImportIssue(
            rowNumber: 1,
            message: 'Mapowanie kolumn jest niepelne albo niepoprawne.',
            row: <String>[],
          ),
        ],
      );
    }

    final typeIndex = mapping.typeColumn == null
        ? null
        : columnIndex(mapping.typeColumn!);
    final noteIndex = mapping.noteColumn == null
        ? null
        : columnIndex(mapping.noteColumn!);
    final goalIdIndex = mapping.goalIdColumn == null
        ? null
        : columnIndex(mapping.goalIdColumn!);

    final parsedRows = <_ParsedImportRow>[];
    for (var index = 0; index < source.rows.length; index++) {
      final row = source.rows[index];
      if (row.every((cell) => cell.trim().isEmpty)) {
        continue;
      }

      parsedRows.add(
        _ParsedImportRow(
          rowNumber: index + 2,
          transaction: _transactionFromSimpleRow(
            row: row,
            availableCategories: availableCategories,
            importCategoryRules: importCategoryRules,
            titleIndex: titleIndex,
            categoryIndex: categoryIndex,
            amountIndex: amountIndex,
            dateIndex: dateIndex,
            typeIndex: typeIndex,
            noteIndex: noteIndex,
            goalIdIndex: goalIdIndex,
          ),
          rawRow: row,
        ),
      );
    }

    return _buildPreview(
      formatLabel: formatLabel,
      parsedRows: parsedRows,
      existingTransactions: existingTransactions,
    );
  }

  bool canOfferColumnMapping(TransactionCsvSourceData source) {
    return source.hasHeader && source.hasRows && source.header.length >= 4;
  }

  TransactionCsvImportPreview _parseAppExport({
    required List<List<String>> rows,
    required List<FinanceTransaction> existingTransactions,
    required List<FinanceCategory> availableCategories,
    required List<ImportCategoryRule> importCategoryRules,
  }) {
    final startIndex = rows.indexWhere(
      (row) =>
          row.length >= 9 &&
          CsvUtils.normalizeHeader(row[0]) == 'transakcje' &&
          CsvUtils.normalizeHeader(row[1]) == 'id',
    );

    if (startIndex == -1) {
      return const TransactionCsvImportPreview(
        formatLabel: 'Eksport aplikacji',
        transactionsToImport: <FinanceTransaction>[],
        duplicateCount: 0,
        issues: <TransactionCsvImportIssue>[
          TransactionCsvImportIssue(
            rowNumber: 0,
            message: 'Nie znaleziono sekcji transakcji w eksporcie CSV.',
            row: <String>[],
          ),
        ],
      );
    }

    final transactionRows = <_ParsedImportRow>[];
    for (var index = startIndex + 1; index < rows.length; index++) {
      final row = rows[index];
      if (row.isEmpty || row.every((cell) => cell.trim().isEmpty)) {
        break;
      }
      if (CsvUtils.normalizeHeader(row.firstOrNull ?? '') != 'transakcje') {
        break;
      }

      transactionRows.add(
        _ParsedImportRow(
          rowNumber: index + 1,
          transaction: _transactionFromExportRow(
            row,
            availableCategories: availableCategories,
            importCategoryRules: importCategoryRules,
          ),
          rawRow: row,
        ),
      );
    }

    return _buildPreview(
      formatLabel: 'Eksport aplikacji',
      parsedRows: transactionRows,
      existingTransactions: existingTransactions,
    );
  }

  TransactionCsvImportPreview _parseSimpleTransactions({
    required List<List<String>> rows,
    required List<FinanceTransaction> existingTransactions,
    required List<FinanceCategory> availableCategories,
    required List<ImportCategoryRule> importCategoryRules,
  }) {
    final header = rows.first;
    final headerMap = <String, int>{};
    for (var index = 0; index < header.length; index++) {
      headerMap[CsvUtils.normalizeHeader(header[index])] = index;
    }

    final titleIndex = _findHeaderIndex(headerMap, _titleHeaderAliases);
    final categoryIndex = _findHeaderIndex(headerMap, _categoryHeaderAliases);
    final amountIndex = _findHeaderIndex(headerMap, _amountHeaderAliases);
    final dateIndex = _findHeaderIndex(headerMap, _dateHeaderAliases);
    final typeIndex = _findHeaderIndex(headerMap, _typeHeaderAliases);
    final noteIndex = _findHeaderIndex(headerMap, _noteHeaderAliases);
    final goalIdIndex = _findHeaderIndex(headerMap, _goalHeaderAliases);

    final missingRequired = <String>[];
    if (titleIndex == null) {
      missingRequired.add('title');
    }
    if (amountIndex == null) {
      missingRequired.add('amount');
    }
    if (dateIndex == null) {
      missingRequired.add('date');
    }

    if (missingRequired.isNotEmpty) {
      return TransactionCsvImportPreview(
        formatLabel: 'Prosty CSV transakcji',
        transactionsToImport: const <FinanceTransaction>[],
        duplicateCount: 0,
        issues: <TransactionCsvImportIssue>[
          TransactionCsvImportIssue(
            rowNumber: 1,
            message:
                'Brakuje wymaganych kolumn: ${missingRequired.join(', ')}. Oczekiwane minimum: title, amount, date. Kategoria moze zostac zgadnieta automatycznie.',
            row: header,
          ),
        ],
      );
    }

    final parsedRows = <_ParsedImportRow>[];
    for (var index = 1; index < rows.length; index++) {
      final row = rows[index];
      if (row.every((cell) => cell.trim().isEmpty)) {
        continue;
      }

      parsedRows.add(
        _ParsedImportRow(
          rowNumber: index + 1,
          transaction: _transactionFromSimpleRow(
            row: row,
            availableCategories: availableCategories,
            importCategoryRules: importCategoryRules,
            titleIndex: titleIndex!,
            categoryIndex: categoryIndex,
            amountIndex: amountIndex!,
            dateIndex: dateIndex!,
            typeIndex: typeIndex,
            noteIndex: noteIndex,
            goalIdIndex: goalIdIndex,
          ),
          rawRow: row,
        ),
      );
    }

    return _buildPreview(
      formatLabel: 'Prosty CSV transakcji',
      parsedRows: parsedRows,
      existingTransactions: existingTransactions,
    );
  }

  TransactionCsvImportPreview _buildPreview({
    required String formatLabel,
    required List<_ParsedImportRow> parsedRows,
    required List<FinanceTransaction> existingTransactions,
  }) {
    final issues = <TransactionCsvImportIssue>[];
    final existingKeys = existingTransactions.map(_transactionKey).toSet();
    final pendingKeys = <String>{};
    final transactionsToImport = <FinanceTransaction>[];
    var duplicateCount = 0;

    for (final parsedRow in parsedRows) {
      final transaction = parsedRow.transaction;
      if (transaction == null) {
        issues.add(
          TransactionCsvImportIssue(
            rowNumber: parsedRow.rowNumber,
            message: 'Nie udalo sie odczytac transakcji z tego wiersza.',
            row: parsedRow.rawRow,
          ),
        );
        continue;
      }

      final validationError = _validateTransaction(transaction);
      if (validationError != null) {
        issues.add(
          TransactionCsvImportIssue(
            rowNumber: parsedRow.rowNumber,
            message: validationError,
            row: parsedRow.rawRow,
          ),
        );
        continue;
      }

      final key = _transactionKey(transaction);
      if (existingKeys.contains(key) || pendingKeys.contains(key)) {
        duplicateCount++;
        continue;
      }

      pendingKeys.add(key);
      transactionsToImport.add(transaction);
    }

    return TransactionCsvImportPreview(
      formatLabel: formatLabel,
      transactionsToImport: transactionsToImport,
      duplicateCount: duplicateCount,
      issues: issues,
    );
  }

  FinanceTransaction? _transactionFromExportRow(
    List<String> row, {
    required List<FinanceCategory> availableCategories,
    required List<ImportCategoryRule> importCategoryRules,
  }) {
    if (row.length < 9) {
      return null;
    }

    final amount = _parseAmount(row[4]);
    final date = _parseDate(row[5]);
    final title = row[2].trim();
    final note = _nullableText(row[8]);
    final type =
        _parseType(row[6]) ??
        _inferType(
          rawAmount: amount,
          title: title,
          rawCategory: row[3].trim(),
          note: note,
        );
    if (amount == null || date == null || type == null) {
      return null;
    }

    return FinanceTransaction(
      id: '',
      title: title,
      category: ImportCategorySuggester.resolveTransactionCategory(
        type: type,
        availableCategories: availableCategories,
        title: title,
        rawCategory: row[3].trim(),
        note: note,
        importCategoryRules: importCategoryRules,
      ),
      amount: amount.abs(),
      date: date,
      type: type,
      goalId: _nullableText(row[7]),
      note: note,
    );
  }

  FinanceTransaction? _transactionFromSimpleRow({
    required List<String> row,
    required List<FinanceCategory> availableCategories,
    required List<ImportCategoryRule> importCategoryRules,
    required int titleIndex,
    int? categoryIndex,
    required int amountIndex,
    required int dateIndex,
    int? typeIndex,
    int? noteIndex,
    int? goalIdIndex,
  }) {
    final amount = _parseAmount(_cell(row, amountIndex));
    final date = _parseDate(_cell(row, dateIndex));
    final title = _cell(row, titleIndex).trim();
    final rawCategory = categoryIndex == null ? '' : _cell(row, categoryIndex);
    final note = noteIndex == null
        ? null
        : _nullableText(_cell(row, noteIndex));
    final type =
        (typeIndex == null ? null : _parseType(_cell(row, typeIndex))) ??
        _inferType(
          rawAmount: amount,
          title: title,
          rawCategory: rawCategory,
          note: note,
        );
    if (amount == null || date == null || type == null) {
      return null;
    }

    return FinanceTransaction(
      id: '',
      title: title,
      category: ImportCategorySuggester.resolveTransactionCategory(
        type: type,
        availableCategories: availableCategories,
        title: title,
        rawCategory: rawCategory,
        note: note,
        importCategoryRules: importCategoryRules,
      ),
      amount: amount.abs(),
      date: date,
      type: type,
      goalId: goalIdIndex == null
          ? null
          : _nullableText(_cell(row, goalIdIndex)),
      note: note,
    );
  }

  String? _validateTransaction(FinanceTransaction transaction) {
    if (transaction.title.trim().isEmpty) {
      return 'Brak tytulu transakcji.';
    }
    if (transaction.category.trim().isEmpty) {
      return 'Brak kategorii transakcji.';
    }
    if (transaction.amount <= 0) {
      return 'Kwota musi byc wieksza od zera.';
    }
    return null;
  }

  TransactionType? _inferType({
    required double? rawAmount,
    required String title,
    required String rawCategory,
    required String? note,
  }) {
    if (rawAmount == null || rawAmount == 0) {
      return null;
    }

    final combined = _normalize('$title $rawCategory ${note ?? ''}');
    if (const [
      'oszczed',
      'savings',
      'transfer',
      'skarbonk',
      'cel',
      'przelewwewnetrzny',
      'rachunekwlasny',
      'przelewmiedzy',
      'przelewwlasny',
      'miedzywlasnymi',
      'wlasnyrachunek',
      'wlasnekonto',
      'rachunekoszczednosciowy',
      'kontooszczednosciowe',
      'automatyczneoszczedzanie',
      'splatakarty',
      'kartakredytowa',
      'zalozenielokaty',
      'zerwanielokaty',
    ].any(combined.contains)) {
      return TransactionType.transfer;
    }

    if (rawAmount < 0) {
      return TransactionType.expense;
    }

    if (const [
      'pensja',
      'wynagrodzenie',
      'salary',
      'payroll',
      'premia',
      'bonus',
      'faktura',
      'refund',
      'zwrot',
      'cashback',
      'dywidenda',
      'odsetki',
    ].any(combined.contains)) {
      return TransactionType.income;
    }

    return TransactionType.expense;
  }

  String _transactionKey(FinanceTransaction transaction) {
    final amount = transaction.amount.toStringAsFixed(2);
    final date = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    ).toIso8601String();

    return [
      _normalize(transaction.title),
      amount,
      date,
      transaction.type.name,
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

  bool _isAppExport(List<List<String>> rows) {
    return rows.any(
      (row) =>
          row.length >= 3 &&
          CsvUtils.normalizeHeader(row[0]) == 'sekcja' &&
          CsvUtils.normalizeHeader(row[1]) == 'pole',
    );
  }

  double? _parseAmount(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final isNegative =
        trimmed.contains('-') ||
        (trimmed.startsWith('(') && trimmed.endsWith(')'));
    final cleaned = trimmed
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'[^0-9,.\-]'), '');
    final unsigned = cleaned.replaceAll('-', '');
    if (unsigned.isEmpty || !RegExp(r'\d').hasMatch(unsigned)) {
      return null;
    }

    final commaIndex = unsigned.lastIndexOf(',');
    final dotIndex = unsigned.lastIndexOf('.');
    final decimalIndex = commaIndex > dotIndex ? commaIndex : dotIndex;
    String numeric;

    if (decimalIndex != -1 &&
        unsigned.length - decimalIndex > 1 &&
        unsigned.length - decimalIndex <= 3) {
      final integerPart = unsigned
          .substring(0, decimalIndex)
          .replaceAll(RegExp(r'[^0-9]'), '');
      final fractionPart = unsigned
          .substring(decimalIndex + 1)
          .replaceAll(RegExp(r'[^0-9]'), '');
      numeric = '$integerPart.$fractionPart';
    } else {
      numeric = unsigned.replaceAll(RegExp(r'[^0-9]'), '');
    }

    if (numeric.isEmpty || numeric == '.') {
      return null;
    }

    final parsed = double.tryParse(isNegative ? '-$numeric' : numeric);
    return parsed;
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

    final dayFirstDashMatch = RegExp(
      r'^(\d{2})-(\d{2})-(\d{4})$',
    ).firstMatch(trimmed);
    if (dayFirstDashMatch != null) {
      return DateTime(
        int.parse(dayFirstDashMatch.group(3)!),
        int.parse(dayFirstDashMatch.group(2)!),
        int.parse(dayFirstDashMatch.group(1)!),
      );
    }

    final yearFirstDotMatch = RegExp(
      r'^(\d{4})[.\/](\d{2})[.\/](\d{2})$',
    ).firstMatch(trimmed);
    if (yearFirstDotMatch != null) {
      return DateTime(
        int.parse(yearFirstDotMatch.group(1)!),
        int.parse(yearFirstDotMatch.group(2)!),
        int.parse(yearFirstDotMatch.group(3)!),
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

  TransactionType? _parseType(String value) {
    return switch (_normalize(value)) {
      'income' || 'przychod' || 'przychody' => TransactionType.income,
      'expense' || 'wydatek' || 'wydatki' => TransactionType.expense,
      'transfer' || 'oszczednosci' || 'oszczednosc' => TransactionType.transfer,
      '' => null,
      _ => null,
    };
  }

  String _normalize(String value) {
    return CsvUtils.normalizeHeader(value);
  }

  int _findLikelyHeaderRowIndex(List<List<String>> rows) {
    if (_looksLikeAppExportMarker(rows.first)) {
      return 0;
    }

    var bestIndex = 0;
    var bestScore = 0;
    final rowsToScan = rows.length < 25 ? rows.length : 25;

    for (var index = 0; index < rowsToScan; index++) {
      final score = _headerScore(rows[index]);
      if (score > bestScore) {
        bestScore = score;
        bestIndex = index;
      }
    }

    return bestScore >= 9 ? bestIndex : 0;
  }

  bool _looksLikeAppExportMarker(List<String> row) {
    return row.length >= 2 &&
        CsvUtils.normalizeHeader(row[0]) == 'sekcja' &&
        CsvUtils.normalizeHeader(row[1]) == 'pole';
  }

  int _headerScore(List<String> row) {
    final headers = row
        .map(CsvUtils.normalizeHeader)
        .where((header) => header.isNotEmpty)
        .toSet();
    if (headers.isEmpty) {
      return 0;
    }

    var score = 0;
    if (_containsAny(headers, _titleHeaderAliases)) {
      score += 3;
    }
    if (_containsAny(headers, _amountHeaderAliases)) {
      score += 3;
    }
    if (_containsAny(headers, _dateHeaderAliases)) {
      score += 3;
    }
    if (_containsAny(headers, _categoryHeaderAliases)) {
      score += 1;
    }
    if (_containsAny(headers, _typeHeaderAliases)) {
      score += 1;
    }
    if (_containsAny(headers, _noteHeaderAliases)) {
      score += 1;
    }

    return score;
  }

  bool _containsAny(Set<String> values, List<String> aliases) {
    for (final alias in aliases) {
      if (values.contains(alias)) {
        return true;
      }
    }
    return false;
  }
}

class _ParsedImportRow {
  const _ParsedImportRow({
    required this.rowNumber,
    required this.transaction,
    required this.rawRow,
  });

  final int rowNumber;
  final FinanceTransaction? transaction;
  final List<String> rawRow;
}

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
