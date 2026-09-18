import 'dart:convert';
import 'dart:typed_data';

import 'package:excel_community/excel_community.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/transaction_import/application/transaction_csv_import_service.dart';
import 'package:finovo/features/transaction_import/domain/import_category_rule.dart';
import 'package:finovo/features/transaction_import/domain/transaction_csv_column_mapping.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  const service = TransactionCsvImportService();

  test('parses app export CSV and skips duplicates', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        '"sekcja","pole","wartosc"\n'
        '"transakcje","id","title","category","amount","date","type","goalId","note"\n'
        '"transakcje","","Zakupy","Dom","120.50","2026-06-01T00:00:00.000","expense","","Market"\n'
        '"transakcje","","Pensja","Praca","8200.00","2026-06-02T00:00:00.000","income","",""\n',
      ),
    );

    final preview = service.parse(
      bytes: bytes,
      existingTransactions: [
        FinanceTransaction(
          id: 't-1',
          title: 'Zakupy',
          category: 'Dom',
          amount: 120.5,
          date: DateTime(2026, 6, 1),
          type: TransactionType.expense,
          note: 'Stary wpis nie bierze udzialu w dedupe po notatce',
        ),
      ],
    );

    expect(preview.formatLabel, 'Eksport aplikacji');
    expect(preview.validCount, 1);
    expect(preview.duplicateCount, 1);
    expect(preview.issues, isEmpty);
    expect(preview.transactionsToImport.single.title, 'Pensja');
  });

  test('parses simple transaction CSV with Polish headers', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        '"nazwa","kategoria","kwota","data","typ","notatka"\n'
        '"Kawa","Jedzenie","18,40","03.06.2026","wydatek","Biuro"\n'
        '"Oszczednosci","Oszczednosci","500","2026-06-04","transfer","Cel wakacje"\n',
      ),
    );

    final preview = service.parse(bytes: bytes, existingTransactions: const []);

    expect(preview.formatLabel, 'Prosty CSV transakcji');
    expect(preview.validCount, 2);
    expect(preview.duplicateCount, 0);
    expect(preview.issues, isEmpty);
    expect(preview.transactionsToImport.first.amount, 18.4);
    expect(preview.transactionsToImport.last.type, TransactionType.transfer);
  });

  test('reports invalid rows and missing headers', () {
    final badHeaders = service.parse(
      bytes: Uint8List.fromList(utf8.encode('"foo","bar"\n"1","2"\n')),
      existingTransactions: const [],
    );

    expect(badHeaders.validCount, 0);
    expect(
      badHeaders.issues.single.message,
      contains('Brakuje wymaganych kolumn'),
    );

    final badRows = service.parse(
      bytes: Uint8List.fromList(
        utf8.encode(
          '"title","category","amount","date"\n'
          '"Zakupy","Dom","abc","2026-06-01"\n'
          '"","","10","2026-06-01"\n',
        ),
      ),
      existingTransactions: const [],
    );

    expect(badRows.validCount, 0);
    expect(badRows.issues.length, 2);
  });

  test('parses bank CSV with manual column mapping', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        '"Opis transakcji";"Kwota operacji";"Data ksiegowania";"Kategoria banku";"Szczegoly"\n'
        '"Bilet";"15,90";"05.06.2026";"Transport";"Autobus"\n',
      ),
    );

    final source = service.readRaw(bytes);
    final preview = service.parseWithColumnMapping(
      source: source,
      mapping: const TransactionCsvColumnMapping(
        titleColumn: 'Opis transakcji',
        categoryColumn: 'Kategoria banku',
        amountColumn: 'Kwota operacji',
        dateColumn: 'Data ksiegowania',
        noteColumn: 'Szczegoly',
      ),
      existingTransactions: const [],
    );

    expect(source.header, hasLength(5));
    expect(preview.formatLabel, 'CSV z mapowaniem kolumn');
    expect(preview.validCount, 1);
    expect(preview.transactionsToImport.single.title, 'Bilet');
    expect(preview.transactionsToImport.single.note, 'Autobus');
  });

  test(
    'auto-assigns category from keywords when csv has no category column',
    () {
      final bytes = Uint8List.fromList(
        utf8.encode(
          '"title","amount","date","note"\n'
          '"Biedronka","45,30","2026-06-05","Zakupy spozywcze"\n',
        ),
      );

      final preview = service.parse(
        bytes: bytes,
        existingTransactions: const [],
      );

      expect(preview.validCount, 1);
      expect(preview.transactionsToImport.single.category, 'Jedzenie');
    },
  );

  test('applies saved import category rules before keyword fallback', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        '"title","amount","date","note"\n'
        '"Sklep ABC","45,30","2026-06-05","Zakupy"\n',
      ),
    );

    final preview = service.parse(
      bytes: bytes,
      existingTransactions: const [],
      importCategoryRules: [
        ImportCategoryRule(
          id: 'expense:sklepabc',
          pattern: 'Sklep ABC',
          category: 'Dom',
          type: TransactionType.expense,
          updatedAt: DateTime(2026, 6, 6),
        ),
      ],
    );

    expect(preview.validCount, 1);
    expect(preview.transactionsToImport.single.category, 'Dom');
  });

  test('detects own account transfers from bank descriptions', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        '"title","amount","date","note"\n'
        '"Przelew wlasny","500","2026-06-05","Konto oszczednosciowe"\n',
      ),
    );

    final preview = service.parse(bytes: bytes, existingTransactions: const []);

    expect(preview.validCount, 1);
    expect(preview.transactionsToImport.single.type, TransactionType.transfer);
  });

  test('parses xlsx with bank template and signed amounts', () {
    final bytes = _buildWorkbookBytes([
      const [
        'Data księgowania',
        'Opis operacji',
        'Kwota operacji',
        'Szczegóły operacji',
      ],
      const ['2026-06-05', 'Biedronka', '-45,30', 'Zakupy spozywcze'],
      const ['2026-06-10', 'Pensja', '8200,00', 'Umowa o prace'],
    ]);

    final preview = service.parse(
      bytes: bytes,
      existingTransactions: const [],
      fileName: 'wyciag-mbank.xlsx',
    );

    expect(preview.formatLabel, 'Szablon bankowy: mBank');
    expect(preview.validCount, 2);
    expect(preview.transactionsToImport.first.type, TransactionType.expense);
    expect(preview.transactionsToImport.first.amount, 45.3);
    expect(preview.transactionsToImport.first.category, 'Jedzenie');
    expect(preview.transactionsToImport.last.type, TransactionType.income);
    expect(preview.transactionsToImport.last.category, 'Praca');
  });

  test('detects bank template with correctly encoded Polish headers', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        '"Data księgowania";"Opis operacji";"Kwota operacji";"Szczegóły operacji"\n'
        '"2026-06-05";"Biedronka";"-45,30";"Zakupy spozywcze"\n',
      ),
    );

    final preview = service.parse(
      bytes: bytes,
      existingTransactions: const [],
      fileName: 'wyciag-mbank.csv',
    );

    expect(preview.formatLabel, 'Szablon bankowy: mBank');
    expect(preview.validCount, 1);
    expect(preview.transactionsToImport.single.type, TransactionType.expense);
    expect(preview.transactionsToImport.single.amount, 45.3);
  });

  test('parses pko bp export with metadata rows and currency amounts', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        '"Historia rachunku"\n'
        '"Okres";"01.06.2026 - 30.06.2026"\n'
        '"Data operacji";"Data waluty";"Typ transakcji";"Opis";"Kwota";"Waluta";"Saldo po operacji"\n'
        '"05-06-2026";"05-06-2026";"Platnosc karta";"Biedronka";"-1 234,56 PLN";"PLN";"1000,00 PLN"\n'
        '"2026.06.10";"2026.06.10";"Przelew";"Pensja";"8 200,00 PLN";"PLN";"9200,00 PLN"\n',
      ),
    );

    final preview = service.parse(
      bytes: bytes,
      existingTransactions: const [],
      fileName: 'historia-pko.csv',
    );

    expect(preview.formatLabel, 'Szablon bankowy: PKO BP');
    expect(preview.validCount, 2);
    expect(preview.expenseCount, 1);
    expect(preview.incomeCount, 1);
    expect(preview.expenseTotal, 1234.56);
    expect(preview.firstDate, DateTime(2026, 6, 5));
    expect(preview.lastDate, DateTime(2026, 6, 10));
    expect(preview.transactionsToImport.first.category, 'Jedzenie');
    expect(preview.transactionsToImport.first.amount, 1234.56);
    expect(preview.transactionsToImport.last.type, TransactionType.income);
  });

  test('detects pekao export by file name and common bank headers', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        '"Data operacji";"Opis operacji";"Kwota";"Tytul platnosci";"Numer referencyjny"\n'
        '"2026-06-07";"ORLEN";"-250,10 PLN";"Paliwo";"ABC123"\n'
        '"2026-06-10";"Pensja";"8200,00 PLN";"Wynagrodzenie";"ABC124"\n',
      ),
    );

    final preview = service.parse(
      bytes: bytes,
      existingTransactions: const [],
      fileName: 'historia-pekao.csv',
    );

    expect(preview.formatLabel, 'Szablon bankowy: Pekao SA');
    expect(preview.validCount, 2);
    expect(preview.transactionsToImport.first.category, 'Transport');
    expect(preview.transactionsToImport.first.amount, 250.1);
    expect(preview.transactionsToImport.last.type, TransactionType.income);
  });

  test('detects millennium export by file name and receiver sender column', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        '"Data ksiegowania";"Odbiorca/Nadawca";"Kwota transakcji";"Opis";"Waluta"\n'
        '"08.06.2026";"NETFLIX";"-49,99";"Abonament";"PLN"\n',
      ),
    );

    final preview = service.parse(
      bytes: bytes,
      existingTransactions: const [],
      fileName: 'millennium-operacje.csv',
    );

    expect(preview.formatLabel, 'Szablon bankowy: Millennium');
    expect(preview.validCount, 1);
    expect(preview.transactionsToImport.single.category, 'Subskrypcje');
    expect(preview.transactionsToImport.single.amount, 49.99);
  });

  test('detects alior export by file name and sender receiver column', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        '"Data operacji";"Nazwa nadawcy/odbiorcy";"Kwota";"Tytul"\n'
        '"09.06.2026";"Apteka";"-35,70 PLN";"Leki"\n',
      ),
    );

    final preview = service.parse(
      bytes: bytes,
      existingTransactions: const [],
      fileName: 'alior-transakcje.csv',
    );

    expect(preview.formatLabel, 'Szablon bankowy: Alior Bank');
    expect(preview.validCount, 1);
    expect(preview.transactionsToImport.single.category, 'Zdrowie');
    expect(preview.transactionsToImport.single.amount, 35.7);
  });

  test('decodes pko bp csv exported as windows-1250', () {
    final bytes = _windows1250Bytes(
      '"Data operacji";"Data waluty";"Typ transakcji";"Opis";"Kwota";"Waluta"\n'
      '"16.06.2026";"16.06.2026";"P\u0142atno\u015b\u0107 kart\u0105";"Wp\u0142ata got\u00f3wki we wp\u0142atomacie";"-918,40 PLN";"PLN"\n',
    );

    final source = service.readRaw(bytes, fileName: 'historia-ipko.csv');
    final preview = service.parse(
      bytes: bytes,
      existingTransactions: const [],
      fileName: 'historia-ipko.csv',
    );

    expect(source.rows.single[2], 'P\u0142atno\u015b\u0107 kart\u0105');
    expect(
      source.rows.single[3],
      'Wp\u0142ata got\u00f3wki we wp\u0142atomacie',
    );
    expect(source.rows.single.join(' '), isNot(contains('\uFFFD')));
    expect(preview.formatLabel, 'Szablon bankowy: PKO BP');
    expect(preview.validCount, 1);
    expect(
      preview.transactionsToImport.single.title,
      'Wp\u0142ata got\u00f3wki we wp\u0142atomacie',
    );
  });

  test('skips duplicate transactions even when category changed', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        '"title","category","amount","date","type"\n'
        '"Biedronka","Inne","45,30","2026-06-05","expense"\n',
      ),
    );

    final preview = service.parse(
      bytes: bytes,
      existingTransactions: [
        FinanceTransaction(
          id: 't-1',
          title: 'Biedronka',
          category: 'Jedzenie',
          amount: 45.3,
          date: DateTime(2026, 6, 5),
          type: TransactionType.expense,
        ),
      ],
    );

    expect(preview.validCount, 0);
    expect(preview.duplicateCount, 1);
    expect(preview.issues, isEmpty);
  });
}

Uint8List _buildWorkbookBytes(List<List<String>> rows) {
  final excel = Excel.createExcel();
  final sheet = excel['Sheet1'];

  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
    for (
      var columnIndex = 0;
      columnIndex < rows[rowIndex].length;
      columnIndex++
    ) {
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: columnIndex,
              rowIndex: rowIndex,
            ),
          )
          .value = TextCellValue(
        rows[rowIndex][columnIndex],
      );
    }
  }

  final bytes = excel.save();
  return Uint8List.fromList(bytes!);
}

Uint8List _windows1250Bytes(String source) {
  return Uint8List.fromList(source.runes.map(_windows1250Byte).toList());
}

int _windows1250Byte(int rune) {
  const codePoints = <int, int>{
    0x0104: 0xA5,
    0x0105: 0xB9,
    0x0106: 0xC6,
    0x0107: 0xE6,
    0x0118: 0xCA,
    0x0119: 0xEA,
    0x0141: 0xA3,
    0x0142: 0xB3,
    0x0143: 0xD1,
    0x0144: 0xF1,
    0x00D3: 0xD3,
    0x00F3: 0xF3,
    0x015A: 0x8C,
    0x015B: 0x9C,
    0x0179: 0x8F,
    0x017A: 0x9F,
    0x017B: 0xAF,
    0x017C: 0xBF,
  };

  return codePoints[rune] ?? rune;
}
