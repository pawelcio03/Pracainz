import '../../../core/data/csv_utils.dart';
import 'transaction_csv_column_mapping.dart';
import 'transaction_csv_source_data.dart';

class BankTransactionImportTemplate {
  const BankTransactionImportTemplate({
    required this.label,
    required this.mapping,
  });

  final String label;
  final TransactionCsvColumnMapping mapping;
}

abstract class BankTransactionImportTemplateDetector {
  static BankTransactionImportTemplate? detect(
    TransactionCsvSourceData source,
  ) {
    for (final detector in _detectors) {
      final template = detector(source);
      if (template != null) {
        return template;
      }
    }

    return null;
  }

  static const List<
    BankTransactionImportTemplate? Function(TransactionCsvSourceData)
  >
  _detectors = [
    _detectPkoBp,
    _detectPekao,
    _detectMillennium,
    _detectAlior,
    _detectMBank,
    _detectIng,
    _detectSantander,
  ];

  static BankTransactionImportTemplate? _detectMBank(
    TransactionCsvSourceData source,
  ) {
    return _buildTemplate(
      source: source,
      label: 'Szablon bankowy: mBank',
      titleAliases: const [
        'opisoperacji',
        'tytuloperacji',
        'opis',
        'kontrahent',
      ],
      amountAliases: const ['kwotaoperacji', 'kwota', 'kwotawpln'],
      dateAliases: const ['dataksiegowania', 'dataoperacji', 'datawaluty'],
      noteAliases: const ['opisoperacji', 'szczegolyoperacji', 'tytuloperacji'],
    );
  }

  static BankTransactionImportTemplate? _detectIng(
    TransactionCsvSourceData source,
  ) {
    return _buildTemplate(
      source: source,
      label: 'Szablon bankowy: ING',
      titleAliases: const [
        'opistransakcji',
        'szczegolytransakcji',
        'opis',
        'kontrahent',
      ],
      amountAliases: const ['kwotatransakcji', 'kwota', 'kwotawpln'],
      dateAliases: const ['datatransakcji', 'dataksiegowania', 'dataoperacji'],
      noteAliases: const [
        'szczegolytransakcji',
        'daneodbiorcy',
        'tytulplatnosci',
      ],
    );
  }

  static BankTransactionImportTemplate? _detectSantander(
    TransactionCsvSourceData source,
  ) {
    return _buildTemplate(
      source: source,
      label: 'Szablon bankowy: Santander',
      titleAliases: const [
        'opistransakcji',
        'opis',
        'opisoperacji',
        'kontrahent',
      ],
      amountAliases: const ['kwota', 'kwotapln', 'kwotaoperacji'],
      dateAliases: const ['dataksiegowania', 'datatransakcji', 'dataoperacji'],
      noteAliases: const ['nazwaodbiorcy', 'daneodbiorcy', 'opis', 'tytul'],
    );
  }

  static BankTransactionImportTemplate? _detectPkoBp(
    TransactionCsvSourceData source,
  ) {
    final normalizedHeaders = source.header.map(_normalize).toSet();
    final looksLikePkoBp =
        _sourceNameContains(source, const ['pkobp', 'ipko']) ||
        const [
          'datawaluty',
          'saldopooperacji',
          'typtransakcji',
          'rachunek',
          'nrrb',
        ].any(normalizedHeaders.contains);
    if (!looksLikePkoBp) {
      return null;
    }

    return _buildTemplate(
      source: source,
      label: 'Szablon bankowy: PKO BP',
      titleAliases: const [
        'opis',
        'opisoperacji',
        'typtransakcji',
        'nadawcaodbiorca',
        'kontrahent',
      ],
      amountAliases: const [
        'kwotaoperacji',
        'kwota',
        'kwotatransakcji',
        'kwotawwalucierachunku',
      ],
      dateAliases: const [
        'dataoperacji',
        'dataksiegowania',
        'datatransakcji',
        'datawaluty',
      ],
      noteAliases: const [
        'opis',
        'opisoperacji',
        'szczegoly',
        'tytul',
        'tytuloperacji',
        'nadawcaodbiorca',
      ],
    );
  }

  static BankTransactionImportTemplate? _detectPekao(
    TransactionCsvSourceData source,
  ) {
    if (!_sourceNameContains(source, const ['pekao'])) {
      return null;
    }

    return _buildTemplate(
      source: source,
      label: 'Szablon bankowy: Pekao SA',
      titleAliases: const [
        'opisoperacji',
        'opis',
        'tytul',
        'tytulplatnosci',
        'kontrahent',
        'nazwakontrahenta',
      ],
      amountAliases: const [
        'kwota',
        'kwotaoperacji',
        'kwotawpln',
        'wartoscoperacji',
      ],
      dateAliases: const [
        'dataoperacji',
        'dataksiegowania',
        'datawaluty',
        'datarealizacji',
      ],
      noteAliases: const [
        'tytul',
        'tytulplatnosci',
        'opis',
        'numerreferencyjny',
      ],
    );
  }

  static BankTransactionImportTemplate? _detectMillennium(
    TransactionCsvSourceData source,
  ) {
    if (!_sourceNameContains(source, const ['millennium', 'millenium'])) {
      return null;
    }

    return _buildTemplate(
      source: source,
      label: 'Szablon bankowy: Millennium',
      titleAliases: const [
        'opisoperacji',
        'opis',
        'tytul',
        'odbiorcanadawca',
        'nadawcaodbiorca',
        'nazwanadawcyodbiorcy',
        'kontrahent',
      ],
      amountAliases: const [
        'kwota',
        'kwotaoperacji',
        'kwotatransakcji',
        'kwotawpln',
      ],
      dateAliases: const [
        'dataoperacji',
        'dataksiegowania',
        'datawaluty',
        'datarealizacji',
      ],
      noteAliases: const ['opisoperacji', 'opis', 'tytul', 'referencje'],
    );
  }

  static BankTransactionImportTemplate? _detectAlior(
    TransactionCsvSourceData source,
  ) {
    if (!_sourceNameContains(source, const ['alior'])) {
      return null;
    }

    return _buildTemplate(
      source: source,
      label: 'Szablon bankowy: Alior Bank',
      titleAliases: const [
        'nazwanadawcyodbiorcy',
        'nazwaodbiorcy',
        'nadawcaodbiorca',
        'kontrahent',
        'opistransakcji',
        'opis',
        'opisoperacji',
        'tytul',
      ],
      amountAliases: const [
        'kwota',
        'kwotaoperacji',
        'kwotatransakcji',
        'kwotawpln',
      ],
      dateAliases: const [
        'dataoperacji',
        'dataksiegowania',
        'datawaluty',
        'datarealizacji',
      ],
      noteAliases: const ['tytul', 'szczegoly', 'opisoperacji', 'opis'],
    );
  }

  static BankTransactionImportTemplate? _buildTemplate({
    required TransactionCsvSourceData source,
    required String label,
    required List<String> titleAliases,
    required List<String> amountAliases,
    required List<String> dateAliases,
    List<String> noteAliases = const [],
  }) {
    final title = _findHeader(source, titleAliases);
    final amount = _findHeader(source, amountAliases);
    final date = _findHeader(source, dateAliases);
    if (title == null || amount == null || date == null) {
      return null;
    }

    final note = _findHeader(source, noteAliases);
    return BankTransactionImportTemplate(
      label: label,
      mapping: TransactionCsvColumnMapping(
        titleColumn: title,
        amountColumn: amount,
        dateColumn: date,
        noteColumn: note,
      ),
    );
  }

  static String? _findHeader(
    TransactionCsvSourceData source,
    List<String> aliases,
  ) {
    for (final alias in aliases) {
      for (final header in source.header) {
        if (_normalize(header) == alias) {
          return header;
        }
      }
    }
    return null;
  }

  static String _normalize(String value) {
    final repaired = value
        .replaceAll('Ä…', 'a')
        .replaceAll('Ä‡', 'c')
        .replaceAll('Ä™', 'e')
        .replaceAll('Ĺ‚', 'l')
        .replaceAll('Ĺ„', 'n')
        .replaceAll('Ăł', 'o')
        .replaceAll('Ĺ›', 's')
        .replaceAll('Ĺş', 'z')
        .replaceAll('ĹĽ', 'z');
    return CsvUtils.normalizeHeader(repaired);
  }

  static bool _sourceNameContains(
    TransactionCsvSourceData source,
    List<String> markers,
  ) {
    final sourceName = _normalize(source.sourceName);
    if (sourceName.isEmpty) {
      return false;
    }

    return markers.any(sourceName.contains);
  }
}
