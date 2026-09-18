import 'dart:convert';
import 'dart:typed_data';

import 'package:excel_community/excel_community.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finovo/features/subscription_import/application/subscription_csv_import_service.dart';
import 'package:finovo/features/subscription_import/domain/subscription_csv_column_mapping.dart';
import 'package:finovo/models/finance_models.dart';

void main() {
  const service = SubscriptionCsvImportService();

  test('parses app export CSV and skips duplicates', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        '"sekcja","pole","wartosc"\n'
        '"subskrypcje","id","name","category","amount","billingCycle","nextBillingDate","isActive","note"\n'
        '"subskrypcje","","Netflix","Rozrywka","67.00","monthly","2026-06-15T00:00:00.000","true","HD"\n'
        '"subskrypcje","","Spotify","Rozrywka","29.99","monthly","2026-06-20T00:00:00.000","true",""\n',
      ),
    );

    final preview = service.parse(
      bytes: bytes,
      existingSubscriptions: [
        SubscriptionPlan(
          id: 's-1',
          name: 'Netflix',
          category: 'Rozrywka',
          amount: 67,
          billingCycle: SubscriptionBillingCycle.monthly,
          nextBillingDate: DateTime(2026, 6, 15),
          isActive: true,
          note: 'Stary wpis',
        ),
      ],
    );

    expect(preview.formatLabel, 'Eksport aplikacji');
    expect(preview.validCount, 1);
    expect(preview.duplicateCount, 1);
    expect(preview.issues, isEmpty);
    expect(preview.subscriptionsToImport.single.name, 'Spotify');
  });

  test('parses simple subscription CSV with semicolon separator', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        'nazwa;kategoria;kwota;cykl;data;aktywna;notatka\n'
        'Adobe;Praca;89,90;miesiecznie;06.06.2026;tak;Pakiet graficzny\n'
        'OC;Auto;1200;rocznie;2026-07-01;nie;Polisa\n',
      ),
    );

    final preview = service.parse(
      bytes: bytes,
      existingSubscriptions: const [],
    );

    expect(preview.formatLabel, 'Prosty CSV subskrypcji');
    expect(preview.validCount, 2);
    expect(preview.duplicateCount, 0);
    expect(preview.issues, isEmpty);
    expect(preview.subscriptionsToImport.first.amount, 89.9);
    expect(
      preview.subscriptionsToImport.last.billingCycle,
      SubscriptionBillingCycle.yearly,
    );
    expect(preview.subscriptionsToImport.last.isActive, isFalse);
  });

  test('reports missing headers and invalid rows', () {
    final badHeaders = service.parse(
      bytes: Uint8List.fromList(utf8.encode('foo,bar\n1,2\n')),
      existingSubscriptions: const [],
    );

    expect(badHeaders.validCount, 0);
    expect(
      badHeaders.issues.single.message,
      contains('Brakuje wymaganych kolumn'),
    );

    final badRows = service.parse(
      bytes: Uint8List.fromList(
        utf8.encode(
          'name,category,amount,billingCycle,nextBillingDate\n'
          'Prime,Rozrywka,abc,monthly,2026-06-10\n'
          ',,29.99,monthly,2026-06-10\n',
        ),
      ),
      existingSubscriptions: const [],
    );

    expect(badRows.validCount, 0);
    expect(badRows.issues.length, 2);
  });

  test(
    'auto-assigns subscription category when category column is missing',
    () {
      final bytes = Uint8List.fromList(
        utf8.encode(
          'name,amount,billingCycle,nextBillingDate,note\n'
          'Netflix,67.00,monthly,2026-06-15,Plan rodzinny\n',
        ),
      );

      final preview = service.parse(
        bytes: bytes,
        existingSubscriptions: const [],
        availableCategories: const ['Rozrywka', 'Subskrypcje', 'Praca'],
      );

      expect(preview.validCount, 1);
      expect(preview.subscriptionsToImport.single.category, 'Rozrywka');
    },
  );

  test('parses subscription csv with manual column mapping', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        '"Usluga";"Kwota";"Cykl";"Termin";"Komentarz"\n'
        '"Adobe";"89,90";"miesiecznie";"06.06.2026";"Pakiet"\n',
      ),
    );

    final source = service.readRaw(bytes);
    final preview = service.parseWithColumnMapping(
      source: source,
      mapping: const SubscriptionCsvColumnMapping(
        nameColumn: 'Usluga',
        amountColumn: 'Kwota',
        billingCycleColumn: 'Cykl',
        nextBillingDateColumn: 'Termin',
        noteColumn: 'Komentarz',
      ),
      existingSubscriptions: const [],
      availableCategories: const ['Praca', 'Subskrypcje'],
    );

    expect(preview.formatLabel, 'CSV z mapowaniem kolumn');
    expect(preview.validCount, 1);
    expect(preview.subscriptionsToImport.single.category, 'Praca');
    expect(preview.subscriptionsToImport.single.note, 'Pakiet');
  });

  test('decodes subscription csv exported as iso-8859-2', () {
    final bytes = _iso88592Bytes(
      'nazwa;kategoria;kwota;cykl;data;aktywna;notatka\n'
      'Muzyka;Rozrywka;29,99;miesi\u0119cznie;20.06.2026;tak;P\u0142atno\u015b\u0107 miesi\u0119czna\n',
    );

    final preview = service.parse(
      bytes: bytes,
      existingSubscriptions: const [],
    );

    expect(preview.validCount, 1);
    expect(preview.issues, isEmpty);
    expect(
      preview.subscriptionsToImport.single.note,
      'P\u0142atno\u015b\u0107 miesi\u0119czna',
    );
    expect(
      preview.subscriptionsToImport.single.note,
      isNot(contains('\uFFFD')),
    );
  });

  test('parses xlsx subscriptions and auto-detects category', () {
    final bytes = _buildWorkbookBytes([
      const ['Usluga', 'Kwota', 'Cykl', 'Termin', 'Komentarz'],
      const ['Netflix', '67,00', 'miesiecznie', '2026-06-15', 'Plan rodzinny'],
    ]);

    final preview = service.parse(
      bytes: bytes,
      existingSubscriptions: const [],
      availableCategories: const ['Rozrywka', 'Subskrypcje', 'Praca'],
      fileName: 'subskrypcje.xlsx',
    );

    expect(preview.validCount, 1);
    expect(preview.subscriptionsToImport.single.category, 'Rozrywka');
    expect(preview.subscriptionsToImport.single.amount, 67);
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

Uint8List _iso88592Bytes(String source) {
  return Uint8List.fromList(source.runes.map(_iso88592Byte).toList());
}

int _iso88592Byte(int rune) {
  const codePoints = <int, int>{
    0x0104: 0xA1,
    0x0105: 0xB1,
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
    0x015A: 0xA6,
    0x015B: 0xB6,
    0x0179: 0xAC,
    0x017A: 0xBC,
    0x017B: 0xAF,
    0x017C: 0xBF,
  };

  return codePoints[rune] ?? rune;
}
