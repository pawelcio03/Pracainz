import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/formatting/display_number_formatter.dart';
import '../../../models/finance_models.dart';
import '../domain/export_share_gateway.dart';

class FinanceExportService {
  const FinanceExportService();

  ExportFilePayload buildCsv({
    required UserProfile? profile,
    required List<FinanceTransaction> transactions,
    required List<CategoryBudget> budgets,
    required List<SavingsGoal> goals,
    required List<InvestmentHolding> investments,
    required List<SubscriptionPlan> subscriptions,
    required DateTime exportedAt,
  }) {
    final lines = <List<String>>[
      ['sekcja', 'pole', 'wartosc'],
      ['profil', 'display_name', profile?.displayName ?? ''],
      ['profil', 'email', profile?.email ?? ''],
      ['profil', 'exported_at', exportedAt.toIso8601String()],
      ['profil', 'transactions_count', '${transactions.length}'],
      ['profil', 'budgets_count', '${budgets.length}'],
      ['profil', 'goals_count', '${goals.length}'],
      ['profil', 'investments_count', '${investments.length}'],
      ['profil', 'subscriptions_count', '${subscriptions.length}'],
      [''],
      [
        'transakcje',
        'id',
        'title',
        'category',
        'amount',
        'date',
        'type',
        'goalId',
        'note',
      ],
      ...transactions.map(
        (transaction) => [
          'transakcje',
          transaction.id,
          transaction.title,
          transaction.category,
          transaction.amount.toStringAsFixed(2),
          transaction.date.toIso8601String(),
          transaction.type.name,
          transaction.goalId ?? '',
          transaction.note ?? '',
        ],
      ),
      [''],
      ['budzety', 'id', 'category', 'limit', 'spent', 'periodStart'],
      ...budgets.map(
        (budget) => [
          'budzety',
          budget.id,
          budget.category,
          budget.limit.toStringAsFixed(2),
          budget.spent.toStringAsFixed(2),
          budget.periodStart.toIso8601String(),
        ],
      ),
      [''],
      ['cele', 'id', 'name', 'targetAmount', 'savedAmount', 'deadline'],
      ...goals.map(
        (goal) => [
          'cele',
          goal.id,
          goal.name,
          goal.targetAmount.toStringAsFixed(2),
          goal.savedAmount.toStringAsFixed(2),
          goal.deadline.toIso8601String(),
        ],
      ),
      [''],
      [
        'inwestycje',
        'id',
        'assetType',
        'symbol',
        'name',
        'units',
        'buyPrice',
        'currentPrice',
        'lastPriceDate',
      ],
      ...investments.map(
        (investment) => [
          'inwestycje',
          investment.id,
          investment.assetType.name,
          investment.displaySymbol,
          investment.name,
          investment.units.toStringAsFixed(4),
          investment.buyPrice.toStringAsFixed(2),
          investment.currentPrice.toStringAsFixed(2),
          investment.lastPriceDate?.toIso8601String() ?? '',
        ],
      ),
      [''],
      [
        'subskrypcje',
        'id',
        'name',
        'category',
        'amount',
        'billingCycle',
        'nextBillingDate',
        'isActive',
        'note',
      ],
      ...subscriptions.map(
        (subscription) => [
          'subskrypcje',
          subscription.id,
          subscription.name,
          subscription.category,
          subscription.amount.toStringAsFixed(2),
          subscription.billingCycle.name,
          subscription.nextBillingDate.toIso8601String(),
          '${subscription.isActive}',
          subscription.note ?? '',
        ],
      ),
    ];

    final csv = lines.map(_csvRow).join('\n');

    return ExportFilePayload(
      filename: _filename(
        prefix: 'finanse-export',
        extension: 'csv',
        exportedAt: exportedAt,
      ),
      mimeType: 'text/csv',
      bytes: Uint8List.fromList(utf8.encode('\uFEFF$csv')),
      subject: 'Eksport CSV finansow',
      text: 'Eksport danych finansowych w formacie CSV.',
    );
  }

  Future<ExportFilePayload> buildPdf({
    required UserProfile? profile,
    required DashboardSnapshot dashboard,
    required List<CategoryBudget> budgets,
    required List<SavingsGoal> goals,
    required List<InvestmentHolding> investments,
    required List<SubscriptionPlan> subscriptions,
    required DateTime exportedAt,
  }) async {
    final document = pw.Document();
    final regularFont = pw.Font.ttf(
      (await rootBundle.load(
        'assets/fonts/NotoSans-Regular.ttf',
      )).buffer.asByteData(),
    );
    final boldFont = pw.Font.ttf(
      (await rootBundle.load(
        'assets/fonts/NotoSans-Bold.ttf',
      )).buffer.asByteData(),
    );
    final theme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: theme,
        build: (context) => [
          pw.Text(
            'Raport finansowy',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Profil: ${profile?.displayName ?? dashboard.userName}'),
          pw.Text('E-mail: ${profile?.email ?? ''}'),
          pw.Text('Wygenerowano: ${_dateTime(exportedAt)}'),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Podsumowanie'),
          _summaryTable(dashboard),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Transakcje'),
          _transactionsTable(dashboard.transactions),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Budzety'),
          _budgetsTable(budgets),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Cele oszczednosciowe'),
          _goalsTable(goals),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Portfel inwestycyjny'),
          _investmentsTable(investments),
          pw.SizedBox(height: 18),
          _pdfSectionTitle('Subskrypcje'),
          _subscriptionsTable(subscriptions),
        ],
      ),
    );

    return ExportFilePayload(
      filename: _filename(
        prefix: 'finanse-raport',
        extension: 'pdf',
        exportedAt: exportedAt,
      ),
      mimeType: 'application/pdf',
      bytes: await document.save(),
      subject: 'Raport PDF finansow',
      text: 'Raport finansowy w formacie PDF.',
    );
  }

  String _filename({
    required String prefix,
    required String extension,
    required DateTime exportedAt,
  }) {
    final year = exportedAt.year.toString().padLeft(4, '0');
    final month = exportedAt.month.toString().padLeft(2, '0');
    final day = exportedAt.day.toString().padLeft(2, '0');
    final hour = exportedAt.hour.toString().padLeft(2, '0');
    final minute = exportedAt.minute.toString().padLeft(2, '0');
    return '$prefix-$year$month$day-$hour$minute.$extension';
  }

  String _csvRow(List<String> values) {
    return values.map(_csvCell).join(';');
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _currency(double value) {
    return formatDisplayCurrency(value);
  }

  String _date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
  }

  String _dateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${_date(value)} $hour:$minute';
  }

  pw.Widget _pdfSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _summaryTable(DashboardSnapshot dashboard) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headers: ['Wskaznik', 'Wartosc'],
      data: [
        ['Saldo', _currency(dashboard.balance)],
        ['Przychody', _currency(dashboard.incomeTotal)],
        ['Wydatki', _currency(dashboard.expenseTotal)],
        ['Transfery', _currency(dashboard.transferTotal)],
        ['Portfel', _currency(dashboard.investedTotal)],
        ['Wynik inwestycji', _currency(dashboard.investmentProfit)],
      ],
    );
  }

  pw.Widget _transactionsTable(List<FinanceTransaction> transactions) {
    if (transactions.isEmpty) {
      return pw.Text('Brak transakcji do eksportu.');
    }

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headers: ['Data', 'Tytul', 'Kategoria', 'Typ', 'Kwota'],
      data: transactions
          .map(
            (transaction) => [
              _date(transaction.date),
              transaction.title,
              transaction.category,
              transaction.type.name,
              _currency(transaction.amount),
            ],
          )
          .toList(),
    );
  }

  pw.Widget _budgetsTable(List<CategoryBudget> budgets) {
    if (budgets.isEmpty) {
      return pw.Text('Brak budzetow do eksportu.');
    }

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headers: ['Kategoria', 'Limit', 'Wydane', 'Okres'],
      data: budgets
          .map(
            (budget) => [
              budget.category,
              _currency(budget.limit),
              _currency(budget.spent),
              _date(budget.periodStart),
            ],
          )
          .toList(),
    );
  }

  pw.Widget _goalsTable(List<SavingsGoal> goals) {
    if (goals.isEmpty) {
      return pw.Text('Brak celow do eksportu.');
    }

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headers: ['Cel', 'Target', 'Zebrane', 'Termin'],
      data: goals
          .map(
            (goal) => [
              goal.name,
              _currency(goal.targetAmount),
              _currency(goal.savedAmount),
              _date(goal.deadline),
            ],
          )
          .toList(),
    );
  }

  pw.Widget _investmentsTable(List<InvestmentHolding> investments) {
    if (investments.isEmpty) {
      return pw.Text('Brak inwestycji do eksportu.');
    }

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headers: [
        'Typ',
        'Symbol',
        'Nazwa',
        'Jednostki',
        'Kupno',
        'Aktualna',
        'Wartosc',
      ],
      data: investments
          .map(
            (investment) => [
              investment.assetType.label,
              investment.displaySymbol,
              investment.name,
              investment.units.toStringAsFixed(4),
              _currency(investment.buyPrice),
              _currency(investment.currentPrice),
              _currency(investment.currentValue),
            ],
          )
          .toList(),
    );
  }

  pw.Widget _subscriptionsTable(List<SubscriptionPlan> subscriptions) {
    if (subscriptions.isEmpty) {
      return pw.Text('Brak subskrypcji do eksportu.');
    }

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headers: ['Nazwa', 'Kategoria', 'Cykl', 'Kwota', 'Termin', 'Aktywna'],
      data: subscriptions
          .map(
            (subscription) => [
              subscription.name,
              subscription.category,
              subscription.billingCycle.name,
              _currency(subscription.amount),
              _date(subscription.nextBillingDate),
              subscription.isActive ? 'tak' : 'nie',
            ],
          )
          .toList(),
    );
  }
}
