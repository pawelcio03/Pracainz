part of 'dashboard_screen.dart';

extension _DashboardScreenContent on _DashboardScreenState {
  List<Widget> _buildErrorBanners() {
    final banners = <Widget>[];

    void addBanner({required String title, required String message}) {
      banners.add(
        _SectionStateCard(
          icon: Icons.sync_problem_outlined,
          title: title,
          description: message,
          tone: _SectionStateTone.danger,
        ),
      );
      banners.add(const SizedBox(height: 20));
    }

    if (_transactionsController.error != null) {
      addBanner(
        title: 'Transakcje',
        message: _transactionError(_transactionsController.error),
      );
    }
    if (_budgetsController.error != null) {
      addBanner(
        title: 'Budzety',
        message: _budgetError(_budgetsController.error),
      );
    }
    if (_categoriesController.error != null) {
      addBanner(
        title: 'Kategorie',
        message: _categoryError(_categoriesController.error),
      );
    }
    if (_userProfileController.error != null) {
      addBanner(
        title: 'Konto',
        message: _profileError(_userProfileController.error),
      );
    }
    if (_goalsController.error != null) {
      addBanner(title: 'Cele', message: _goalError(_goalsController.error));
    }
    if (_goalContributionPlansController.error != null) {
      addBanner(
        title: 'Plany wplat',
        message: _goalContributionPlanError(
          _goalContributionPlansController.error,
        ),
      );
    }
    if (_monthlyReportsController.error != null) {
      addBanner(
        title: 'Raporty',
        message: _monthlyReportError(_monthlyReportsController.error),
      );
    }
    if (_reportArchivesController.error != null) {
      addBanner(
        title: 'Archiwa raportow',
        message: _reportArchiveError(_reportArchivesController.error),
      );
    }
    if (_recurringIncomesController.error != null) {
      addBanner(
        title: 'Stale dochody',
        message: _recurringIncomeError(_recurringIncomesController.error),
      );
    }
    if (_subscriptionsController.error != null) {
      addBanner(
        title: 'Subskrypcje',
        message: _subscriptionError(_subscriptionsController.error),
      );
    }
    if (_investmentsController.error != null) {
      addBanner(
        title: 'Inwestycje',
        message: _investmentError(_investmentsController.error),
      );
    }

    return banners;
  }

  Widget _buildSectionContent({
    required bool compact,
    required UserProfile? profile,
    required List<FinanceCategory> categories,
    required DashboardSnapshot dashboard,
    required List<CategoryBudget> budgets,
    required Map<String, List<FinanceTransaction>> goalContributionHistory,
    required List<ReportArchiveEntry> archives,
    required List<MonthlyReport> monthlyReports,
    required List<PortfolioDailySnapshot> dailyPortfolioSnapshots,
    required List<RecurringIncomePlan> recurringIncomes,
    required List<SubscriptionPlan> subscriptions,
    required DashboardAnalyticsSnapshot analytics,
    required List<DashboardAlertItem> alerts,
    required bool isInitialLoad,
    required bool isProfileLoad,
    required bool isBudgetLoad,
    required bool isCategoryLoad,
    required bool isGoalLoad,
    required bool isArchiveLoad,
    required bool isInvestmentLoad,
    required bool isMonthlyReportLoad,
    required bool isRecurringIncomeLoad,
    required bool isSubscriptionLoad,
    required List<FinanceTransaction> visibleTransactions,
    required String email,
  }) {
    return switch (_selectedSection) {
      DashboardSection.overview => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hero(dashboard, email: email),
          const SizedBox(height: 20),
          _summary(dashboard),
          const SizedBox(height: 20),
          _alertsSection(alerts),
          const SizedBox(height: 20),
          _analyticsSection(analytics, profile?.createdAt),
        ],
      ),
      DashboardSection.transactions => _transactionsCard(
        isInitialLoad,
        isRecurringIncomeLoad,
        recurringIncomes,
        visibleTransactions,
      ),
      DashboardSection.budgets => _budgetsCard(budgets, isBudgetLoad),
      DashboardSection.goals => _goalsCard(
        dashboard.goals,
        goalContributionHistory,
        isGoalLoad,
      ),
      DashboardSection.investments => _investmentsCard(
        dashboard,
        isInvestmentLoad,
        analytics,
        monthlyReports,
        dailyPortfolioSnapshots,
        profile?.createdAt,
      ),
      DashboardSection.subscriptions => _subscriptionsCard(
        subscriptions,
        isSubscriptionLoad,
      ),
      DashboardSection.reports => _reportsCard(
        profile: profile,
        dashboard: dashboard,
        budgets: budgets,
        archives: archives,
        monthlyReports: monthlyReports,
        subscriptions: subscriptions,
        isArchiveLoad: isArchiveLoad,
        isMonthlyReportLoad: isMonthlyReportLoad,
      ),
      DashboardSection.categories => _categoriesCard(
        categories,
        isCategoryLoad,
      ),
      DashboardSection.account => _accountWorkspace(
        compact: compact,
        profile: profile,
        isProfileLoad: isProfileLoad,
        dashboard: dashboard,
        budgets: budgets,
        subscriptions: subscriptions,
      ),
    };
  }

  void _clearTransactionFilters() {
    _searchController.clear();
    _transactionsController.clearFilters();
  }

  Future<void> _showCompactSectionsSheet({
    required String displayName,
    required String email,
  }) {
    return showAppBottomSheet<void>(
      context,
      builder: (sheetContext) => _CompactSectionsSheet(
        displayName: displayName,
        email: email,
        selectedSection: _selectedSection,
        themeMode: widget.themeMode,
        onSectionSelected: _selectSection,
        onThemeModeChanged: widget.onThemeModeChanged,
        onSignOut: widget.onSignOut,
      ),
    );
  }

  FloatingActionButton? _sectionActionButton() {
    switch (_selectedSection) {
      case DashboardSection.overview:
        return null;
      case DashboardSection.transactions:
        return FloatingActionButton.extended(
          onPressed: _createTransaction,
          icon: const Icon(Icons.add),
          label: const Text('Dodaj transakcje'),
        );
      case DashboardSection.budgets:
        return FloatingActionButton.extended(
          onPressed: _createBudget,
          icon: const Icon(Icons.add_chart),
          label: const Text('Dodaj budzet'),
        );
      case DashboardSection.goals:
        return FloatingActionButton.extended(
          onPressed: _createGoal,
          icon: const Icon(Icons.flag),
          label: const Text('Dodaj cel'),
        );
      case DashboardSection.investments:
        return FloatingActionButton.extended(
          onPressed: _createInvestment,
          icon: const Icon(Icons.trending_up),
          label: const Text('Dodaj inwestycje'),
        );
      case DashboardSection.subscriptions:
        return FloatingActionButton.extended(
          onPressed: _createSubscription,
          icon: const Icon(Icons.subscriptions_outlined),
          label: const Text('Dodaj subskrypcje'),
        );
      case DashboardSection.reports:
        final isClosed = _monthlyReportsController.isPeriodClosed(
          _budgetsController.selectedPeriod,
        );
        return FloatingActionButton.extended(
          onPressed: isClosed
              ? null
              : () => _saveMonthlyReport(
                  transactions: _transactionsController.transactions,
                  budgets: _budgetSnapshots(
                    _transactionsController.transactions,
                  ),
                  goals: _goalSnapshots(
                    _goalContributionHistory(
                      _transactionsController.transactions,
                    ),
                  ),
                  investments: _investmentsController.investments,
                ),
          icon: const Icon(Icons.save),
          label: Text(isClosed ? 'Miesiac zamkniety' : 'Zapisz raport'),
        );
      case DashboardSection.categories:
        return FloatingActionButton.extended(
          onPressed: _createCategory,
          icon: const Icon(Icons.category),
          label: const Text('Dodaj kategorie'),
        );
      case DashboardSection.account:
        return null;
    }
  }

  String _sectionTitle(DashboardSection section) {
    switch (section) {
      case DashboardSection.overview:
        return 'Przeglad';
      case DashboardSection.transactions:
        return 'Transakcje';
      case DashboardSection.budgets:
        return 'Budzety';
      case DashboardSection.goals:
        return 'Cele';
      case DashboardSection.investments:
        return 'Inwestycje';
      case DashboardSection.subscriptions:
        return 'Subskrypcje';
      case DashboardSection.reports:
        return 'Raporty';
      case DashboardSection.categories:
        return 'Kategorie';
      case DashboardSection.account:
        return 'Konto';
    }
  }

  String _sectionSubtitle(DashboardSection section) {
    switch (section) {
      case DashboardSection.overview:
        return 'Szybki przeglad salda, alertow i analityki.';
      case DashboardSection.transactions:
        return 'Lista, filtry i pelny CRUD transakcji.';
      case DashboardSection.budgets:
        return 'Miesieczne limity i wykorzystanie kategorii.';
      case DashboardSection.goals:
        return 'Cele oszczednosciowe i historia wplat.';
      case DashboardSection.investments:
        return 'Typy aktywow, krypto, reczne ceny i historia wycen.';
      case DashboardSection.subscriptions:
        return 'Stale koszty i nadchodzace obciazenia.';
      case DashboardSection.reports:
        return 'Raporty miesieczne i archiwum plikow.';
      case DashboardSection.categories:
        return 'Kategorie wykorzystywane przez formularze i raporty.';
      case DashboardSection.account:
        return 'Nick, dostep, dane i wyglad w jednym miejscu.';
    }
  }

  Widget _hero(DashboardSnapshot dashboard, {required String email}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 720;
        final heroPadding = narrow ? 20.0 : 28.0;
        final textWidth = math.min(constraints.maxWidth, 430.0);
        final summaryWidth = math.min(constraints.maxWidth, 260.0);
        final heroGradientColors =
            Theme.of(context).brightness == Brightness.dark
            ? const [Color(0xFF12302C), Color(0xFF1A5A51), Color(0xFF7A642E)]
            : const [Color(0xFF12372A), Color(0xFF1F6E62), Color(0xFFE8A44C)];

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(heroPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              colors: heroGradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 20,
            children: [
              SizedBox(
                width: textWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Panel finansowy',
                      style: TextStyle(
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Czesc ${dashboard.userName}, dane transakcyjne sa juz uporzadkowane w panelu sekcji.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: narrow ? 28 : 34,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(email, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              Container(
                width: summaryWidth,
                padding: EdgeInsets.all(narrow ? 18 : 22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo biezace',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currency(dashboard.balance),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: narrow ? 28 : 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Przychody ${_currency(dashboard.incomeTotal)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Wydatki ${_currency(dashboard.expenseTotal)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Transfery ${_currency(dashboard.transferTotal)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (widget.onSignOut != null) ...[
                      const SizedBox(height: 14),
                      OutlinedButton(
                        onPressed: widget.onSignOut,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Text('Wyloguj'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summary(DashboardSnapshot dashboard) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final cards = [
          _MetricCard(
            'Miesieczne przychody',
            _currency(dashboard.incomeTotal),
            _successColor(context),
          ),
          _MetricCard(
            'Miesieczne wydatki',
            _currency(dashboard.expenseTotal),
            _dangerColor(context),
          ),
          _MetricCard(
            'Wartosc portfela',
            _currency(dashboard.investedTotal),
            _infoColor(context),
          ),
        ];

        if (compact) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: 16),
            ],
          ],
        );
      },
    );
  }

  Widget _alertsSection(List<DashboardAlertItem> alerts) {
    return _SectionCard(
      title: 'Alerty',
      subtitle:
          'Szybkie ostrzezenia z budzetow, celow, subskrypcji i koncentracji portfela.',
      child: alerts.isEmpty
          ? const _SectionStateCard(
              icon: Icons.verified_outlined,
              title: 'Brak aktywnych alertow',
              description:
                  'Na ten moment limity, terminy i portfel nie wymagaja pilnej reakcji.',
              tone: _SectionStateTone.success,
            )
          : Column(
              children: alerts
                  .map(
                    (alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AlertTile(alert: alert),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _analyticsSection(
    DashboardAnalyticsSnapshot analytics,
    DateTime? accountCreatedAt,
  ) {
    final trendRangeLabel = _overviewTrendRangeLabel(
      selectedMonths: _overviewTrendMonths,
      accountCreatedAt: accountCreatedAt,
    );

    return _SectionCard(
      title: 'Analiza',
      subtitle:
          'Trend przychodow i wydatkow $trendRangeLabel oraz struktura wydatkow dla wybranego okresu.',
      action: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _softSurfaceColor(context),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Okres ${_periodLabel(_budgetsController.selectedPeriod)}',
            ),
          ),
          _TrendMonthsToggleGroup(
            selectedMonths: _overviewTrendMonths,
            onMonthsChanged: _setOverviewTrendMonths,
          ),
        ],
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final chipWidth = constraints.maxWidth < 460
                  ? constraints.maxWidth
                  : constraints.maxWidth < 760
                  ? (constraints.maxWidth - 12) / 2
                  : 220.0;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: chipWidth,
                    child: _AnalyticsStatChip(
                      label: 'Wplaty na cele',
                      value:
                          '${_currency(analytics.currentMonthTransfers)} | ${_percent(analytics.transferRate)}',
                      accent: analytics.currentMonthTransfers > 0
                          ? _successColor(context)
                          : _mutedTextColor(context),
                    ),
                  ),
                  SizedBox(
                    width: chipWidth,
                    child: _AnalyticsStatChip(
                      label: 'Sredni wydatek',
                      value: _currency(analytics.averageExpense),
                      accent: _warningColor(context),
                    ),
                  ),
                  SizedBox(
                    width: chipWidth,
                    child: _AnalyticsStatChip(
                      label: 'Top kategoria',
                      value: analytics.topExpenseCategory ?? 'Brak danych',
                      accent: _infoColor(context),
                    ),
                  ),
                  SizedBox(
                    width: chipWidth,
                    child: _AnalyticsStatChip(
                      label: 'Cele zagrozone',
                      value: '${analytics.atRiskGoals}',
                      accent: analytics.atRiskGoals == 0
                          ? _successColor(context)
                          : _dangerColor(context),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 860;
              if (compact) {
                return Column(
                  children: [
                    _AnalyticsPanel(
                      title: 'Trend przychodow i wydatkow',
                      subtitle: trendRangeLabel,
                      child: _CashflowChart(
                        points: analytics.monthlyCashflow,
                        hasData: analytics.hasTransactionData,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AnalyticsPanel(
                      title: 'Wydatki wg kategorii',
                      subtitle: 'Dla wybranego miesiaca',
                      child: _ExpenseBreakdownList(
                        points: analytics.expensesByCategory,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: _AnalyticsPanel(
                      title: 'Trend przychodow i wydatkow',
                      subtitle: trendRangeLabel,
                      child: _CashflowChart(
                        points: analytics.monthlyCashflow,
                        hasData: analytics.hasTransactionData,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _AnalyticsPanel(
                          title: 'Wydatki wg kategorii',
                          subtitle: 'Dla wybranego miesiaca',
                          child: _ExpenseBreakdownList(
                            points: analytics.expensesByCategory,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _transactionsCard(
    bool isInitialLoad,
    bool isRecurringIncomeLoad,
    List<RecurringIncomePlan> recurringIncomes,
    List<FinanceTransaction> transactions,
  ) {
    final allTransactions = _transactionsController.transactions;
    final visibleMetrics = _transactionMetrics(transactions);
    final expenseTrend = _transactionExpenseTrend(transactions);
    final activeRecurringIncomes = recurringIncomes
        .where((plan) => plan.isActive)
        .toList();
    final nextRecurringIncomePayout = activeRecurringIncomes
        .map(_recurringIncomesController.nextPayoutDate)
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (earliest, candidate) =>
              earliest == null || candidate.isBefore(earliest)
              ? candidate
              : earliest,
        );
    final showDateGroups =
        _transactionsController.sortOption == TransactionSortOption.newest ||
        _transactionsController.sortOption == TransactionSortOption.oldest;
    final transactionGroups = showDateGroups
        ? _groupTransactionsByDay(transactions)
        : const <_TransactionDayGroup>[];
    final topExpenseCategory = _topExpenseCategory(transactions);
    final largestExpense = _largestExpenseTransaction(transactions);
    final filterSummary = _transactionFilterSummary(
      visibleCount: transactions.length,
      totalCount: allTransactions.length,
    );

    return _SectionCard(
      title: 'Transakcje',
      subtitle:
          'Widok ruchow pienieznych z importem wyciagow, szybkim bilansem, filtrami i historia pozycji.',
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: _importTransactionsCsv,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Importuj wyciag'),
          ),
          OutlinedButton.icon(
            onPressed: _createTransaction,
            icon: const Icon(Icons.add),
            label: const Text('Dodaj recznie'),
          ),
          OutlinedButton.icon(
            onPressed: _createRecurringIncome,
            icon: const Icon(Icons.event_repeat),
            label: const Text('Staly dochod'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _moduleInsights([
            _DetailChip(
              label: 'Wszystkie wpisy',
              value: '${allTransactions.length}',
            ),
            _DetailChip(
              label: 'Widoczne po filtrach',
              value: '${transactions.length}',
            ),
            _DetailChip(
              label: 'Wplyw na saldo',
              value: _signedCurrency(_netForTransactions(transactions)),
            ),
            _DetailChip(
              label: 'Zakres widoku',
              value: _transactionDateRangeLabel(transactions),
            ),
          ]),
          const SizedBox(height: 18),
          if (allTransactions.isNotEmpty) ...[
            _InlineModuleCard(
              title: 'Przeglad widoku',
              subtitle: _transactionsController.hasActiveFilters
                  ? 'Podsumowanie dotyczy tylko aktualnie przefiltrowanej listy.'
                  : 'Szybki obraz przychodow, wydatkow i transferow dla calej listy.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _moduleInsights([
                    _DetailChip(
                      label: 'Przychody',
                      value: _currency(visibleMetrics.incomeTotal),
                    ),
                    _DetailChip(
                      label: 'Wydatki',
                      value: _currency(visibleMetrics.expenseTotal),
                    ),
                    _DetailChip(
                      label: 'Transfery',
                      value: _currency(visibleMetrics.transferTotal),
                    ),
                    _DetailChip(
                      label: 'Saldo netto',
                      value: _signedCurrency(visibleMetrics.netImpact),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  _moduleInsights([
                    _DetailChip(
                      label: 'Top kategoria wydatkow',
                      value: topExpenseCategory ?? 'Brak wydatkow',
                    ),
                    _DetailChip(
                      label: 'Najwiekszy wydatek',
                      value: largestExpense == null
                          ? 'Brak'
                          : '${largestExpense.title} | ${_currency(largestExpense.amount)}',
                    ),
                    _DetailChip(
                      label: 'Powiazane z celami',
                      value: '${visibleMetrics.goalLinkedCount}',
                    ),
                    _DetailChip(
                      label: 'Stale dochody w widoku',
                      value: '${visibleMetrics.recurringIncomeCount}',
                    ),
                  ]),
                  if (_transactionsController.hasActiveFilters) ...[
                    const SizedBox(height: 14),
                    _SectionStateCard(
                      icon: Icons.filter_alt_outlined,
                      title: 'Aktywny widok listy',
                      description: filterSummary,
                      tone: _SectionStateTone.neutral,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (allTransactions.isNotEmpty) ...[
            _InlineModuleCard(
              title: 'Rytm wydatkow',
              subtitle: expenseTrend.subtitle,
              child: !expenseTrend.hasExpenseData
                  ? const _SectionStateCard(
                      icon: Icons.bar_chart_outlined,
                      title: 'Brak wydatkow w tym widoku',
                      description:
                          'Zmiana zakresu, typu albo filtrow moze od razu pokazac dzienny trend wydatkow.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _moduleInsights([
                          _DetailChip(
                            label: 'Suma wydatkow',
                            value: _currency(expenseTrend.totalExpense),
                          ),
                          _DetailChip(
                            label: 'Dni z wydatkami',
                            value: '${expenseTrend.activeDayCount}',
                          ),
                          _DetailChip(
                            label: 'Sredni dzien',
                            value: _currency(
                              expenseTrend.averageActiveDayExpense,
                            ),
                          ),
                          _DetailChip(
                            label: 'Najmocniejszy dzien',
                            value: expenseTrend.peakPoint == null
                                ? 'Brak'
                                : '${_dayMonthLabel(expenseTrend.peakPoint!.day)} | ${_currency(expenseTrend.peakPoint!.expenseTotal)}',
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _TransactionExpenseTrendChart(
                          points: expenseTrend.points,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 18),
          ],
          _TransactionFilters(
            controller: _transactionsController,
            searchController: _searchController,
            availableCategories: _availableFilterCategories(),
            availableGoals: _goalsController.goals,
          ),
          const SizedBox(height: 18),
          if (isInitialLoad)
            const _TransactionSectionSkeleton()
          else if (_transactionsController.transactions.isEmpty)
            _SectionStateCard(
              icon: Icons.upload_file_outlined,
              title: 'Brak transakcji',
              description:
                  'Wgraj wyciag bankowy CSV lub XLSX, a aplikacja pokaze podglad, odfiltruje duplikaty i zapisze wybrane pozycje jako transakcje.',
              actionLabel: 'Importuj wyciag',
              onAction: _importTransactionsCsv,
            )
          else if (transactions.isEmpty)
            _SectionStateCard(
              icon: Icons.filter_alt_off_outlined,
              title: 'Brak wynikow',
              description:
                  'Aktualne filtry nic nie zwracaja. Zmien je albo wyczysc i sprawdz cala liste.',
              actionLabel: 'Wyczysc filtry',
              onAction: _clearTransactionFilters,
            )
          else if (showDateGroups)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: transactionGroups
                  .expand(
                    (group) => [
                      _TransactionDayHeader(
                        day: group.day,
                        count: group.transactions.length,
                        netImpact: _netForTransactions(group.transactions),
                      ),
                      const SizedBox(height: 10),
                      ...group.transactions.map(
                        (transaction) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TransactionTile(
                            transaction: transaction,
                            goalName: _goalName(transaction.goalId),
                            onEdit: () => _editTransaction(transaction),
                            onDelete: () => _deleteTransaction(transaction),
                          ),
                        ),
                      ),
                    ],
                  )
                  .toList(),
            )
          else
            Column(
              children: transactions
                  .map(
                    (transaction) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TransactionTile(
                        transaction: transaction,
                        goalName: _goalName(transaction.goalId),
                        onEdit: () => _editTransaction(transaction),
                        onDelete: () => _deleteTransaction(transaction),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 18),
          _InlineModuleCard(
            title: 'Stale dochody',
            subtitle:
                'Miesieczne wyplaty, ktore same dopisuja brakujace transakcje.',
            action: TextButton.icon(
              onPressed: _createRecurringIncome,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj plan'),
            ),
            child: isRecurringIncomeLoad
                ? const _SimpleListSectionSkeleton(
                    itemCount: 2,
                    showHeaderChips: true,
                  )
                : recurringIncomes.isEmpty
                ? _SectionStateCard(
                    icon: Icons.payments_outlined,
                    title: 'Brak stalych dochodow',
                    description:
                        'Dodaj pensje albo inny powtarzalny przychod, a aplikacja bedzie sama dopisywac miesiace.',
                    actionLabel: 'Dodaj staly dochod',
                    onAction: _createRecurringIncome,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _moduleInsights([
                        _DetailChip(
                          label: 'Aktywne plany',
                          value: '${activeRecurringIncomes.length}',
                        ),
                        _DetailChip(
                          label: 'Miesiecznie',
                          value: _currency(
                            _recurringIncomesController.monthlyIncomeTotal,
                          ),
                        ),
                        _DetailChip(
                          label: 'Nastepna wyplata',
                          value: nextRecurringIncomePayout == null
                              ? 'Brak'
                              : _date(nextRecurringIncomePayout),
                        ),
                      ]),
                      if (_recurringIncomesController.isSyncing) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Uzgadnianie brakujacych miesiecy...',
                          style: TextStyle(color: _mutedTextColor(context)),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ...recurringIncomes.map(
                        (plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RecurringIncomeTile(
                            plan: plan,
                            nextPayoutDate: _recurringIncomesController
                                .nextPayoutDate(plan),
                            onEdit: () => _editRecurringIncome(plan),
                            onDelete: () => _deleteRecurringIncome(plan),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _accountWorkspace({
    required bool compact,
    required UserProfile? profile,
    required bool isProfileLoad,
    required DashboardSnapshot dashboard,
    required List<CategoryBudget> budgets,
    required List<SubscriptionPlan> subscriptions,
  }) {
    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: KeyedSubtree(
        key: ValueKey(_selectedAccountWorkspaceSection),
        child: _accountWorkspaceContent(
          profile: profile,
          isProfileLoad: isProfileLoad,
          dashboard: dashboard,
          budgets: budgets,
          subscriptions: subscriptions,
        ),
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccountWorkspaceNavigationCard(
            selectedSection: _selectedAccountWorkspaceSection,
            onSectionSelected: _selectAccountWorkspaceSection,
          ),
          const SizedBox(height: 18),
          content,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 282,
          child: _AccountWorkspaceNavigationCard(
            selectedSection: _selectedAccountWorkspaceSection,
            onSectionSelected: _selectAccountWorkspaceSection,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(child: content),
      ],
    );
  }

  Widget _accountWorkspaceContent({
    required UserProfile? profile,
    required bool isProfileLoad,
    required DashboardSnapshot dashboard,
    required List<CategoryBudget> budgets,
    required List<SubscriptionPlan> subscriptions,
  }) {
    switch (_selectedAccountWorkspaceSection) {
      case _AccountWorkspaceSection.profile:
        return _profileCard(profile: profile, isProfileLoad: isProfileLoad);
      case _AccountWorkspaceSection.access:
        return _accountAccessCard(profile: profile);
      case _AccountWorkspaceSection.data:
        return _accountDataCard(
          profile: profile,
          dashboard: dashboard,
          budgets: budgets,
          subscriptions: subscriptions,
        );
      case _AccountWorkspaceSection.appearance:
        return _accountAppearanceCard();
    }
  }

  Widget _profileCard({
    required UserProfile? profile,
    required bool isProfileLoad,
  }) {
    final currentProfile = profile ?? _userProfileController.profile;

    return _SectionCard(
      title: 'Dane konta',
      subtitle: 'Nick i adres e-mail profilu.',
      action: FilledButton.icon(
        onPressed: currentProfile == null || _userProfileController.isSaving
            ? null
            : () => _editProfile(currentProfile),
        icon: const Icon(Icons.edit),
        label: Text(
          _userProfileController.isSaving ? 'Zapisywanie...' : 'Edytuj nick',
        ),
      ),
      child: isProfileLoad
          ? const _ProfileSectionSkeleton()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _UserAvatar(
                      displayName:
                          profile?.displayName ??
                          _userProfileController.displayName,
                      size: 68,
                      borderRadius: 22,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.displayName ??
                                _userProfileController.displayName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            profile?.email ?? _userProfileController.email,
                            style: TextStyle(color: _mutedTextColor(context)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DetailChip(
                      label: 'Utworzono',
                      value: currentProfile == null
                          ? 'Brak'
                          : _date(currentProfile.createdAt),
                    ),
                    _DetailChip(
                      label: 'Ostatnie logowanie',
                      value: currentProfile == null
                          ? 'Brak'
                          : _date(currentProfile.lastSignInAt),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _accountAccessCard({required UserProfile? profile}) {
    final currentProfile = profile ?? _userProfileController.profile;

    return _SectionCard(
      title: 'Dostep i logowanie',
      subtitle: 'Status e-maila oraz akcje zwiazane z logowaniem.',
      action: FilledButton.icon(
        onPressed: _openAccountSecurity,
        icon: const Icon(Icons.admin_panel_settings_outlined),
        label: const Text('Bezpieczenstwo konta'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _moduleInsights([
            _DetailChip(
              label: 'Adres e-mail',
              value: _accountEmail(currentProfile),
            ),
            _DetailChip(
              label: 'E-mail zweryfikowany',
              value: _emailVerificationStatusLabel(),
            ),
            _DetailChip(
              label: 'Logowanie',
              value: _accountProviderStatusLabel(),
            ),
          ]),
          const SizedBox(height: 18),
          _emailVerificationStatusCard(),
        ],
      ),
    );
  }

  String _accountEmail(UserProfile? profile) {
    final snapshotEmail = _accountSecuritySnapshot?.email.trim();
    if (snapshotEmail != null && snapshotEmail.isNotEmpty) {
      return snapshotEmail;
    }

    final profileEmail = profile?.email.trim();
    if (profileEmail != null && profileEmail.isNotEmpty) {
      return profileEmail;
    }

    final fallbackEmail = _userProfileController.email.trim();
    return fallbackEmail.isEmpty ? 'Brak' : fallbackEmail;
  }

  String _emailVerificationStatusLabel() {
    if (_isAccountSecurityLoading) {
      return 'Sprawdzanie...';
    }

    if (_accountSecurityError != null || _accountSecuritySnapshot == null) {
      return 'Nieznany';
    }

    return _accountSecuritySnapshot!.emailVerified ? 'Tak' : 'Nie';
  }

  String _accountProviderStatusLabel() {
    if (_isAccountSecurityLoading) {
      return 'Sprawdzanie...';
    }

    final snapshot = _accountSecuritySnapshot;
    if (_accountSecurityError != null || snapshot == null) {
      return 'Nieznane';
    }

    if (snapshot.hasGoogleProvider && snapshot.hasPasswordProvider) {
      return 'Google + haslo';
    }
    if (snapshot.hasGoogleProvider) {
      return 'Google';
    }
    if (snapshot.hasPasswordProvider) {
      return 'E-mail i haslo';
    }

    return snapshot.providerIds.isEmpty
        ? 'Brak danych'
        : snapshot.providerIds.join(', ');
  }

  Widget _emailVerificationStatusCard() {
    if (_isAccountSecurityLoading) {
      return const _SectionStateCard(
        icon: Icons.mark_email_read_outlined,
        title: 'Sprawdzanie e-maila',
        description: 'Pobieram aktualny status weryfikacji adresu e-mail.',
        tone: _SectionStateTone.neutral,
      );
    }

    if (_accountSecurityError != null || _accountSecuritySnapshot == null) {
      return _SectionStateCard(
        icon: Icons.error_outline,
        title: 'Nie udalo sie sprawdzic e-maila',
        description:
            'Odswiez status albo otworz panel bezpieczenstwa, aby pobrac aktualne dane konta.',
        tone: _SectionStateTone.danger,
        actionLabel: 'Odswiez status',
        onAction: _loadAccountSecuritySnapshot,
      );
    }

    if (_accountSecuritySnapshot!.emailVerified) {
      return _SectionStateCard(
        icon: Icons.mark_email_read_outlined,
        title: 'E-mail zweryfikowany',
        description: 'Adres e-mail konta jest potwierdzony.',
        tone: _SectionStateTone.success,
        actionLabel: 'Odswiez status',
        onAction: _loadAccountSecuritySnapshot,
      );
    }

    return _SectionStateCard(
      icon: Icons.mark_email_unread_outlined,
      title: 'E-mail niezweryfikowany',
      description:
          'Adres e-mail nie jest jeszcze potwierdzony. Otworz panel bezpieczenstwa i wyslij link weryfikacyjny.',
      tone: _SectionStateTone.danger,
      actionLabel: 'Zweryfikuj e-mail',
      onAction: _openAccountSecurity,
    );
  }

  Widget _accountDataCard({
    required UserProfile? profile,
    required DashboardSnapshot dashboard,
    required List<CategoryBudget> budgets,
    required List<SubscriptionPlan> subscriptions,
  }) {
    final activeSubscriptionCount = subscriptions
        .where((subscription) => subscription.isActive)
        .length;

    return _SectionCard(
      title: 'Dane i pliki',
      subtitle:
          'Import transakcji i eksport plikow masz tutaj, bez mieszania z danymi tozsamosci konta.',
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: _userProfileController.isSaving
                ? null
                : _importTransactionsCsv,
            icon: const Icon(Icons.file_upload_outlined),
            label: const Text('Import z banku'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _moduleInsights([
            _DetailChip(label: 'Eksport', value: 'CSV i PDF'),
            _DetailChip(label: 'Import', value: 'CSV / XLSX'),
            _DetailChip(
              label: 'Transakcje',
              value: '${dashboard.transactions.length} wpisow',
            ),
            _DetailChip(
              label: 'Moduly w danych',
              value:
                  '${dashboard.transactions.length + budgets.length + activeSubscriptionCount}',
            ),
          ]),
          const SizedBox(height: 18),
          _SettingsTileCard(
            icon: Icons.file_open_outlined,
            title: 'Import wyciagu bankowego',
            description:
                'Wrzuc CSV lub XLSX z banku. Aplikacja rozpozna format, pokaze podsumowanie i pozwoli poprawic kategorie przed zapisem.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _importTransactionsCsv,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Importuj wyciag'),
                ),
                OutlinedButton.icon(
                  onPressed: _openImportCategoryRules,
                  icon: const Icon(Icons.rule_outlined),
                  label: const Text('Reguly kategorii'),
                ),
                OutlinedButton.icon(
                  onPressed: _openTransactionImportHistory,
                  icon: const Icon(Icons.history_outlined),
                  label: const Text('Historia importow'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsTileCard(
            icon: Icons.ios_share_outlined,
            title: 'Eksport danych',
            description:
                'Tu zbierasz pliki wejscia i wyjscia. Eksport opiera sie na aktualnym stanie transakcji, budzetow, celow i inwestycji.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => _exportCsv(
                    profile: profile,
                    dashboard: dashboard,
                    budgets: budgets,
                    goals: dashboard.goals,
                    investments: dashboard.investments,
                    subscriptions: subscriptions,
                  ),
                  icon: const Icon(Icons.table_view),
                  label: const Text('Eksport CSV'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _exportPdf(
                    profile: profile,
                    dashboard: dashboard,
                    budgets: budgets,
                    goals: dashboard.goals,
                    investments: dashboard.investments,
                    subscriptions: subscriptions,
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Eksport PDF'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsTileCard(
            icon: Icons.assessment_outlined,
            title: 'Raporty i archiwum',
            description:
                'Raporty miesieczne i archiwum sa zebrane w osobnym module, zeby panel konta byl prostszy.',
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _selectSection(DashboardSection.reports),
                icon: const Icon(Icons.arrow_forward_outlined),
                label: const Text('Przejdz do raportow'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountAppearanceCard() {
    return _SectionCard(
      title: 'Wyglad i sesja',
      subtitle:
          'Tu ustawiasz motyw interfejsu i zarzadzasz biezaca sesja bez przechodzenia przez osobny ekran.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _moduleInsights([
            _DetailChip(
              label: 'Motyw',
              value: switch (widget.themeMode) {
                ThemeMode.light => 'Jasny',
                ThemeMode.dark => 'Ciemny',
                ThemeMode.system => 'Systemowy',
              },
            ),
            const _DetailChip(label: 'Panel', value: 'Desktop i mobile'),
            const _DetailChip(label: 'Nawigacja', value: '2 poziomy'),
            _DetailChip(
              label: 'Sesja',
              value: widget.onSignOut == null ? 'Tylko odczyt' : 'Aktywna',
            ),
          ]),
          const SizedBox(height: 18),
          _SettingsTileCard(
            icon: Icons.palette_outlined,
            title: 'Wyglad aplikacji',
            description:
                'Motyw zapisuje sie lokalnie. Zmiana dziala od razu dla calego dashboardu i ekranu logowania.',
            child: Align(
              alignment: Alignment.centerLeft,
              child: _ThemeModeToggleGroup(
                themeMode: widget.themeMode,
                isCollapsed: false,
                onThemeModeChanged: widget.onThemeModeChanged,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SettingsTileCard(
            icon: Icons.logout_outlined,
            title: 'Sesja',
            description:
                'Wylogowanie zostaje tutaj, bo to operacja konta, nie osobny modul finansowy.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: widget.onSignOut == null
                      ? null
                      : () => widget.onSignOut!.call(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Wyloguj'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _selectAccountWorkspaceSection(
                    _AccountWorkspaceSection.access,
                  ),
                  icon: const Icon(Icons.security_outlined),
                  label: const Text('Przejdz do dostepu'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportsCard({
    required UserProfile? profile,
    required DashboardSnapshot dashboard,
    required List<CategoryBudget> budgets,
    required List<ReportArchiveEntry> archives,
    required List<MonthlyReport> monthlyReports,
    required List<SubscriptionPlan> subscriptions,
    required bool isArchiveLoad,
    required bool isMonthlyReportLoad,
  }) {
    final reportPreview = _buildCurrentMonthlyReport(
      transactions: dashboard.transactions,
      budgets: budgets,
      goals: dashboard.goals,
      investments: dashboard.investments,
    );
    final savedReport = _monthlyReportsController.reportForPeriod(
      _budgetsController.selectedPeriod,
    );
    final previousReport = _monthlyReportsController.previousReportForPeriod(
      _budgetsController.selectedPeriod,
    );
    final comparison = previousReport == null
        ? null
        : compareMonthlyReports(
            current: savedReport ?? reportPreview,
            previous: previousReport,
          );
    final periodArchives = archives
        .where(
          (archive) =>
              archive.periodStart.year ==
                  _budgetsController.selectedPeriod.year &&
              archive.periodStart.month ==
                  _budgetsController.selectedPeriod.month,
        )
        .toList();

    return _SectionCard(
      title: 'Raporty miesieczne',
      subtitle:
          'Zapisuj miesieczne raporty, porownuj okresy i archiwizuj gotowe pliki.',
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: savedReport?.isClosed == true
                ? null
                : () => _saveMonthlyReport(
                    transactions: dashboard.transactions,
                    budgets: budgets,
                    goals: dashboard.goals,
                    investments: dashboard.investments,
                  ),
            icon: const Icon(Icons.save),
            label: Text(
              savedReport == null ? 'Zapisz raport' : 'Odswiez raport',
            ),
          ),
          OutlinedButton.icon(
            onPressed: savedReport?.isClosed == true
                ? null
                : () => _closeMonthlyReport(
                    transactions: dashboard.transactions,
                    budgets: budgets,
                    goals: dashboard.goals,
                    investments: dashboard.investments,
                  ),
            icon: Icon(
              savedReport?.isClosed == true
                  ? Icons.lock
                  : Icons.lock_clock_outlined,
            ),
            label: Text(
              savedReport?.isClosed == true
                  ? 'Miesiac zamkniety'
                  : 'Zamknij miesiac',
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _moduleInsights([
            _DetailChip(
              label: 'Biezacy status',
              value: savedReport?.isClosed == true ? 'Zamkniety' : 'Otwarty',
            ),
            _DetailChip(
              label: 'Bilans miesiaca',
              value: _signedCurrency(
                (savedReport ?? reportPreview).netCashflow,
              ),
            ),
            _DetailChip(
              label: 'Raporty zapisane',
              value: '${monthlyReports.length}',
            ),
            _DetailChip(label: 'Pliki w archiwum', value: '${archives.length}'),
          ]),
          const SizedBox(height: 18),
          _MonthlyReportPreviewTile(
            periodStart: _budgetsController.selectedPeriod,
            report: reportPreview,
            savedReport: savedReport,
          ),
          const SizedBox(height: 18),
          if (comparison == null)
            _SectionStateCard(
              icon: Icons.compare_arrows_outlined,
              title: 'Brak porownania do poprzedniego miesiaca',
              description:
                  'Zapisz raport za poprzedni miesiac, aby od razu widziec zmiane przychodow, wydatkow i salda.',
            )
          else
            _MonthlyReportComparisonTile(comparison: comparison),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => _archiveMonthlyCsv(
                  profile: profile,
                  dashboard: dashboard,
                  budgets: budgets,
                  goals: dashboard.goals,
                  investments: dashboard.investments,
                  subscriptions: subscriptions,
                ),
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Archiwizuj CSV'),
              ),
              OutlinedButton.icon(
                onPressed: () => _archiveMonthlyPdf(
                  profile: profile,
                  dashboard: dashboard,
                  budgets: budgets,
                  goals: dashboard.goals,
                  investments: dashboard.investments,
                  subscriptions: subscriptions,
                ),
                icon: const Icon(Icons.cloud_done),
                label: const Text('Archiwizuj PDF'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isArchiveLoad)
            const _SimpleListSectionSkeleton(itemCount: 2)
          else if (periodArchives.isEmpty)
            const _SectionStateCard(
              icon: Icons.cloud_queue_outlined,
              title: 'Brak archiwow',
              description:
                  'Dla tego miesiaca nie ma jeszcze zapisanych plikow.',
            )
          else
            Column(
              children: periodArchives
                  .map(
                    (archive) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReportArchiveTile(
                        archive: archive,
                        onOpen: () => _openReportArchive(archive),
                        onDelete: () => _deleteReportArchive(archive),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 18),
          if (isMonthlyReportLoad)
            const _ReportsSectionSkeleton(showPreview: false)
          else if (monthlyReports.isEmpty)
            _SectionStateCard(
              icon: Icons.inventory_2_outlined,
              title: 'Brak raportow miesiecznych',
              description:
                  'Zapisz pierwszy raport, aby miec historie miesiecy i pliki do archiwum.',
              actionLabel: 'Zapisz pierwszy raport',
              onAction: () => _saveMonthlyReport(
                transactions: dashboard.transactions,
                budgets: budgets,
                goals: dashboard.goals,
                investments: dashboard.investments,
              ),
            )
          else
            Column(
              children: monthlyReports
                  .map(
                    (report) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MonthlyReportTile(
                        report: report,
                        isSelectedPeriod:
                            report.periodStart.year ==
                                _budgetsController.selectedPeriod.year &&
                            report.periodStart.month ==
                                _budgetsController.selectedPeriod.month,
                        onDelete: () => _deleteMonthlyReport(report),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _subscriptionsCard(
    List<SubscriptionPlan> subscriptions,
    bool isSubscriptionLoad,
  ) {
    final activeSubscriptions = subscriptions
        .where((subscription) => subscription.isActive)
        .toList();
    final nextBilling = activeSubscriptions.isEmpty
        ? null
        : activeSubscriptions.reduce(
            (left, right) =>
                left.nextBillingDate.isBefore(right.nextBillingDate)
                ? left
                : right,
          );

    return _SectionCard(
      title: 'Subskrypcje',
      subtitle: 'Cykliczne koszty z alertami na zblizajace sie obciazenia.',
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: _importSubscriptionsFile,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Import CSV/XLSX'),
          ),
          FilledButton.icon(
            onPressed: _createSubscription,
            icon: const Icon(Icons.add),
            label: const Text('Dodaj'),
          ),
        ],
      ),
      child: isSubscriptionLoad
          ? const _SimpleListSectionSkeleton(itemCount: 3, showIntroLines: true)
          : subscriptions.isEmpty
          ? _SectionStateCard(
              icon: Icons.subscriptions_outlined,
              title: 'Brak subskrypcji',
              description:
                  'Dodaj pierwsza subskrypcje, aby pilnowac stalych kosztow i terminow obciazen.',
              actionLabel: 'Dodaj subskrypcje',
              onAction: _createSubscription,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _moduleInsights([
                  _DetailChip(
                    label: 'Aktywne',
                    value: '${activeSubscriptions.length}',
                  ),
                  _DetailChip(
                    label: 'Nieaktywne',
                    value:
                        '${subscriptions.length - activeSubscriptions.length}',
                  ),
                  _DetailChip(
                    label: 'Koszt miesieczny',
                    value: _currency(
                      _subscriptionsController.monthlyCommitment,
                    ),
                  ),
                  _DetailChip(
                    label: 'Najblizsze obciazenie',
                    value: nextBilling == null
                        ? 'Brak'
                        : _date(nextBilling.nextBillingDate),
                  ),
                ]),
                const SizedBox(height: 18),
                Text(
                  'Miesieczne obciazenie ${_currency(_subscriptionsController.monthlyCommitment)}',
                ),
                const SizedBox(height: 16),
                ...subscriptions.map(
                  (subscription) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SubscriptionTile(
                      subscription: subscription,
                      onEdit: () => _editSubscription(subscription),
                      onDelete: () => _deleteSubscription(subscription),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _categoriesCard(
    List<FinanceCategory> categories,
    bool isCategoryLoad,
  ) {
    final incomeCategories = categories
        .where((category) => category.type == TransactionType.income)
        .length;
    final expenseCategories = categories
        .where((category) => category.type == TransactionType.expense)
        .length;
    final transferCategories = categories
        .where((category) => category.type == TransactionType.transfer)
        .length;

    return _SectionCard(
      title: 'Kategorie',
      subtitle: 'Kategorie dla transakcji, budzetow i subskrypcji.',
      action: FilledButton.icon(
        onPressed: _createCategory,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj'),
      ),
      child: isCategoryLoad
          ? const _SimpleListSectionSkeleton(itemCount: 4)
          : categories.isEmpty
          ? _SectionStateCard(
              icon: Icons.category_outlined,
              title: 'Brak kategorii',
              description:
                  'Dodaj wlasne kategorie, aby porzadnie oznaczac transakcje, budzety i subskrypcje.',
              actionLabel: 'Dodaj kategorie',
              onAction: _createCategory,
            )
          : Column(
              children: [
                _moduleInsights([
                  _DetailChip(
                    label: 'Wszystkie',
                    value: '${categories.length}',
                  ),
                  _DetailChip(label: 'Przychody', value: '$incomeCategories'),
                  _DetailChip(label: 'Wydatki', value: '$expenseCategories'),
                  _DetailChip(label: 'Transfery', value: '$transferCategories'),
                ]),
                const SizedBox(height: 18),
                ...categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CategoryTile(
                      category: category,
                      canMerge: _categoryMergeCandidates(category).isNotEmpty,
                      usageSummary: _categoryUsageSummary(category),
                      onEdit: () => _editCategory(category),
                      onMerge: () => _mergeCategory(category),
                      onDelete: () => _deleteCategory(category),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _budgetsCard(List<CategoryBudget> budgets, bool isBudgetLoad) {
    final totalLimit = budgets.fold<double>(
      0,
      (total, budget) => total + budget.limit,
    );
    final totalSpent = budgets.fold<double>(
      0,
      (total, budget) => total + budget.spent,
    );
    final overspentCount = budgets
        .where((budget) => budget.limit > 0 && budget.spent > budget.limit)
        .length;
    final nearLimitCount = budgets
        .where(
          (budget) =>
              budget.limit > 0 &&
              budget.spent <= budget.limit &&
              (budget.spent / budget.limit) >= 0.9,
        )
        .length;

    return _SectionCard(
      title: 'Budzety miesieczne',
      subtitle:
          'Limity kategorii liczone z realnych wydatkow z wybranego miesiaca.',
      action: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IconButton(
            onPressed: _previousBudgetMonth,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Poprzedni miesiac',
          ),
          Text(_periodLabel(_budgetsController.selectedPeriod)),
          IconButton(
            onPressed: _nextBudgetMonth,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Nastepny miesiac',
          ),
          FilledButton.icon(
            onPressed: _createBudget,
            icon: const Icon(Icons.add),
            label: const Text('Dodaj'),
          ),
        ],
      ),
      child: isBudgetLoad
          ? const _SimpleListSectionSkeleton(
              itemCount: 3,
              showHeaderChips: true,
            )
          : budgets.isEmpty
          ? _SectionStateCard(
              icon: Icons.pie_chart_outline,
              title: 'Brak budzetow dla tego miesiaca',
              description:
                  'Dodaj pierwszy limit kategorii, aby kontrolowac wydatki w wybranym okresie.',
              actionLabel: 'Dodaj budzet',
              onAction: _createBudget,
            )
          : Column(
              children: [
                _moduleInsights([
                  _DetailChip(
                    label: 'Laczny limit',
                    value: _currency(totalLimit),
                  ),
                  _DetailChip(label: 'Wydane', value: _currency(totalSpent)),
                  _DetailChip(label: 'Przekroczone', value: '$overspentCount'),
                  _DetailChip(label: 'Blisko limitu', value: '$nearLimitCount'),
                ]),
                const SizedBox(height: 18),
                ...budgets.map(
                  (budget) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BudgetTile(
                      budget: budget,
                      onEdit: () => _editBudget(budget),
                      onDelete: () => _deleteBudget(budget),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _goalsCard(
    List<SavingsGoal> goals,
    Map<String, List<FinanceTransaction>> goalContributionHistory,
    bool isGoalLoad,
  ) {
    final showLoading =
        isGoalLoad || _goalContributionPlansController.isLoading;
    final activeContributionPlans =
        _goalContributionPlansController.activePlans;
    final goalsWithActivePlans = goals
        .where(
          (goal) =>
              _goalContributionPlansController.activePlanCountForGoal(goal.id) >
              0,
        )
        .length;
    final plannedMonthlyTotal = activeContributionPlans.fold<double>(
      0,
      (total, plan) => total + plan.monthlyEquivalentAmount,
    );
    final targetTotal = goals.fold<double>(
      0,
      (total, goal) => total + goal.targetAmount,
    );
    final savedTotal = goals.fold<double>(
      0,
      (total, goal) => total + goal.savedAmount,
    );
    final completedCount = goals.where((goal) => goal.progress >= 1).length;
    final activeGoals = goals.where((goal) => goal.progress < 1).toList()
      ..sort((left, right) => left.deadline.compareTo(right.deadline));
    final nearestGoal = activeGoals.isEmpty ? null : activeGoals.first;

    return _SectionCard(
      title: 'Cele oszczednosciowe',
      subtitle:
          'Postep = stan poczatkowy celu + suma powiazanych transakcji. Karta celu pokazuje tez ostatnie wplaty.',
      action: FilledButton.icon(
        onPressed: _createGoal,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj'),
      ),
      child: showLoading
          ? const _SimpleListSectionSkeleton(itemCount: 3)
          : goals.isEmpty
          ? _SectionStateCard(
              icon: Icons.flag_outlined,
              title: 'Brak celow oszczednosciowych',
              description:
                  'Dodaj pierwszy cel, aby sledzic postep, wplaty i prognoze dojscia do kwoty docelowej.',
              actionLabel: 'Dodaj cel',
              onAction: _createGoal,
            )
          : Column(
              children: [
                _moduleInsights([
                  _DetailChip(
                    label: 'Cele aktywne',
                    value: '${goals.length - completedCount}',
                  ),
                  _DetailChip(
                    label: 'Cele ukonczone',
                    value: '$completedCount',
                  ),
                  _DetailChip(
                    label: 'Cel laczny',
                    value: _currency(targetTotal),
                  ),
                  _DetailChip(
                    label: 'Najblizszy termin',
                    value: nearestGoal == null
                        ? 'Brak'
                        : _date(nearestGoal.deadline),
                  ),
                  _DetailChip(
                    label: 'Plany aktywne',
                    value: '${activeContributionPlans.length}',
                  ),
                  _DetailChip(
                    label: 'Tempo mies.',
                    value: plannedMonthlyTotal <= 0
                        ? 'Brak'
                        : _currency(plannedMonthlyTotal),
                  ),
                ]),
                const SizedBox(height: 18),
                if (savedTotal > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Odlozone lacznie ${_currency(savedTotal)} z docelowej kwoty ${_currency(targetTotal)}.',
                        style: TextStyle(color: _mutedTextColor(context)),
                      ),
                    ),
                  ),
                if (goalsWithActivePlans > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$goalsWithActivePlans cel${goalsWithActivePlans == 1 ? '' : 'e'} ma aktywny plan wplat. Automatyczny rytm daje ${_currency(plannedMonthlyTotal)} miesiecznie.',
                        style: TextStyle(color: _mutedTextColor(context)),
                      ),
                    ),
                  ),
                ...goals.map((goal) {
                  final contributionPlans = _goalContributionPlans(goal.id);
                  final nextContributionDate = _nextGoalContributionDate(
                    contributionPlans,
                  );
                  final monthlyContributionPlanTotal = contributionPlans
                      .where((plan) => plan.isActive)
                      .fold<double>(
                        0,
                        (total, plan) => total + plan.monthlyEquivalentAmount,
                      );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GoalTile(
                      goal: goal,
                      startingAmount: _goalStartingAmount(goal.id),
                      contributionTransactions:
                          goalContributionHistory[goal.id] ?? const [],
                      contributionPlans: contributionPlans,
                      nextContributionDate: nextContributionDate,
                      monthlyContributionPlanTotal:
                          monthlyContributionPlanTotal,
                      onViewDetails: () => _openGoalDetails(goal),
                      onAddContribution: () => _createGoalContribution(goal),
                      onManageContributionPlans: () =>
                          _createGoalContributionPlan(goal),
                      onEdit: () => _editGoal(goal),
                      onDelete: () => _deleteGoal(goal),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _investmentsCard(
    DashboardSnapshot dashboard,
    bool isInvestmentLoad,
    DashboardAnalyticsSnapshot analytics,
    List<MonthlyReport> monthlyReports,
    List<PortfolioDailySnapshot> dailyPortfolioSnapshots,
    DateTime? accountCreatedAt,
  ) {
    final holdings = dashboard.investments;
    final groupedHoldings = _groupedInvestmentsByAssetType(holdings);
    final portfolioTrend = _portfolioValueTrendPoints(
      monthlyReports: monthlyReports,
      dailySnapshots: dailyPortfolioSnapshots,
      currentValue: dashboard.investedTotal,
      months: _investmentTrendMonths,
      accountCreatedAt: accountCreatedAt,
    );
    final portfolioTrendLabel = _overviewTrendRangeLabel(
      selectedMonths: _investmentTrendMonths,
      accountCreatedAt: accountCreatedAt,
    );
    final hasDailyPortfolioHistory = dailyPortfolioSnapshots.isNotEmpty;
    final comparableHoldings = holdings
        .where(
          (investment) =>
              investment.lastPriceDate != null ||
              !investment.supportsMarketData,
        )
        .toList();
    final bestHolding = comparableHoldings.isEmpty
        ? null
        : comparableHoldings.reduce(
            (left, right) => left.profit >= right.profit ? left : right,
          );
    final worstHolding = comparableHoldings.isEmpty
        ? null
        : comparableHoldings.reduce(
            (left, right) => left.profit <= right.profit ? left : right,
          );
    final pricedHoldings = holdings
        .where((investment) => investment.lastPriceDate != null)
        .length;
    final showPortfolioProfit = comparableHoldings.isNotEmpty;

    return _SectionCard(
      title: 'Portfel inwestycyjny',
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed:
                holdings.any((investment) => investment.supportsMarketData)
                ? _refreshInvestmentPricesFromAction
                : null,
            icon: const Icon(Icons.refresh),
            label: const Text('Odswiez'),
          ),
          FilledButton.icon(
            onPressed: _createInvestment,
            icon: const Icon(Icons.add),
            label: const Text('Dodaj'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _moduleInsights([
            _DetailChip(label: 'Pozycje', value: '${holdings.length}'),
            _DetailChip(label: 'Z cena', value: '$pricedHoldings'),
            _DetailChip(
              label: 'Najlepsza pozycja',
              value: bestHolding?.displaySymbol ?? 'Brak',
            ),
            _DetailChip(
              label: 'Najslabsza pozycja',
              value: worstHolding?.displaySymbol ?? 'Brak',
            ),
          ]),
          const SizedBox(height: 18),
          Text('Laczna wartosc ${_currency(dashboard.investedTotal)}'),
          if (showPortfolioProfit) ...[
            const SizedBox(height: 6),
            Text('Wynik ${_signedCurrency(dashboard.investmentProfit)}'),
          ],
          if (pricedHoldings > 0 &&
              _investmentsController.lastSuccessfulRefreshAt != null) ...[
            const SizedBox(height: 18),
            _DetailChip(
              label: 'Ostatnia aktualizacja',
              value: _dateTime(_investmentsController.lastSuccessfulRefreshAt!),
            ),
          ],
          if (!isInvestmentLoad && holdings.isNotEmpty) ...[
            const SizedBox(height: 20),
            _AnalyticsPanel(
              title: 'Wartosc portfela w czasie',
              subtitle: hasDailyPortfolioHistory
                  ? 'Na podstawie dziennych zapisow portfela i biezacej wyceny $portfolioTrendLabel'
                  : 'Na podstawie historii raportow i biezacej wyceny $portfolioTrendLabel',
              action: _TrendMonthsToggleGroup(
                selectedMonths: _investmentTrendMonths,
                onMonthsChanged: _setInvestmentTrendMonths,
              ),
              child: _PortfolioValueTrendChart(points: portfolioTrend),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 860;
                if (compact) {
                  return Column(
                    children: [
                      _AnalyticsPanel(
                        title: 'Alokacja portfela',
                        subtitle: 'Biezaca struktura wg wartosci pozycji',
                        child: _PortfolioAllocationList(
                          points: analytics.portfolioAllocations,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _AnalyticsPanel(
                        title: 'Analityka portfela',
                        subtitle: 'Koncentracja, zwrot i wynik pozycji',
                        child: _InvestmentAnalyticsPanel(
                          analytics: analytics.investmentAnalytics,
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _AnalyticsPanel(
                        title: 'Alokacja portfela',
                        subtitle: 'Biezaca struktura wg wartosci pozycji',
                        child: _PortfolioAllocationList(
                          points: analytics.portfolioAllocations,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _AnalyticsPanel(
                        title: 'Analityka portfela',
                        subtitle: 'Koncentracja, zwrot i wynik pozycji',
                        child: _InvestmentAnalyticsPanel(
                          analytics: analytics.investmentAnalytics,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          if (isInvestmentLoad)
            const _SimpleListSectionSkeleton(itemCount: 3, showIntroLines: true)
          else if (dashboard.investments.isEmpty)
            _SectionStateCard(
              icon: Icons.trending_up,
              title: 'Brak pozycji w portfelu',
              description:
                  'Dodaj pierwsze aktywo, aby sledzic wartosc portfela, wynik i historie cen.',
              actionLabel: 'Dodaj inwestycje',
              onAction: _createInvestment,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: groupedHoldings.entries
                  .expand(
                    (entry) => [
                      _InvestmentGroupHeader(
                        title: entry.key.label.toUpperCase(),
                        count: entry.value.length,
                      ),
                      const SizedBox(height: 12),
                      ...entry.value.map(
                        (investment) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _InvestmentTile(
                            investment: investment,
                            onViewDetails: () =>
                                _openInvestmentDetails(investment),
                            onEdit: () => _editInvestment(investment),
                            onDelete: () => _deleteInvestment(investment),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _moduleInsights(List<Widget> chips) {
    return Wrap(spacing: 12, runSpacing: 12, children: chips);
  }

  List<PortfolioValueTrendPoint> _portfolioValueTrendPoints({
    required List<MonthlyReport> monthlyReports,
    required List<PortfolioDailySnapshot> dailySnapshots,
    required double currentValue,
    required int months,
    DateTime? accountCreatedAt,
  }) {
    final reportsByMonth = <String, MonthlyReport>{};

    for (final report in monthlyReports) {
      final monthStart = DateTime(
        report.periodStart.year,
        report.periodStart.month,
      );
      final key = '${monthStart.year}-${monthStart.month}';
      final existing = reportsByMonth[key];
      if (existing == null ||
          report.generatedAt.isAfter(existing.generatedAt)) {
        reportsByMonth[key] = report;
      }
    }

    final now = DateTime.now();
    final normalizedCurrentPeriod = DateTime(now.year, now.month, 1);
    final normalizedAccountCreatedAtMonth = accountCreatedAt == null
        ? null
        : DateTime(accountCreatedAt.year, accountCreatedAt.month, 1);
    final normalizedAccountCreatedAtDay = accountCreatedAt == null
        ? null
        : DateTime(
            accountCreatedAt.year,
            accountCreatedAt.month,
            accountCreatedAt.day,
          );
    final points = <PortfolioValueTrendPoint>[];
    final normalizedNowDate = DateTime(now.year, now.month, now.day);
    final visibleStartMonth = DateTime(
      normalizedCurrentPeriod.year,
      normalizedCurrentPeriod.month - (months - 1),
      1,
    );
    final visibleStartDay =
        normalizedAccountCreatedAtDay != null &&
            normalizedAccountCreatedAtDay.isAfter(visibleStartMonth)
        ? normalizedAccountCreatedAtDay
        : visibleStartMonth;
    final visibleDailySnapshots =
        dailySnapshots.where((snapshot) {
            final snapshotDay = DateTime(
              snapshot.recordedAt.year,
              snapshot.recordedAt.month,
              snapshot.recordedAt.day,
            );
            return !snapshotDay.isBefore(visibleStartDay) &&
                !snapshotDay.isAfter(normalizedNowDate);
          }).toList()
          ..sort((left, right) => left.recordedAt.compareTo(right.recordedAt));

    if (visibleDailySnapshots.isNotEmpty) {
      final hasSnapshotForToday = _isSameDay(
        visibleDailySnapshots.last.recordedAt,
        now,
      );
      final earliestDailyMonth = DateTime(
        visibleDailySnapshots.first.recordedAt.year,
        visibleDailySnapshots.first.recordedAt.month,
        1,
      );

      for (var offset = months - 1; offset >= 0; offset--) {
        final monthStart = DateTime(
          normalizedCurrentPeriod.year,
          normalizedCurrentPeriod.month - offset,
          1,
        );
        if (normalizedAccountCreatedAtMonth != null &&
            monthStart.isBefore(normalizedAccountCreatedAtMonth)) {
          continue;
        }
        if (!monthStart.isBefore(earliestDailyMonth)) {
          continue;
        }

        final key = '${monthStart.year}-${monthStart.month}';
        final report = reportsByMonth[key];
        if (report == null) {
          continue;
        }

        points.add(
          PortfolioValueTrendPoint(
            periodStart: monthStart,
            label: _periodLabel(monthStart),
            axisLabel: _periodLabel(monthStart),
            detailLabel: _dateTime(report.generatedAt),
            value: report.investmentValue,
            isCurrent: false,
          ),
        );
      }

      for (var index = 0; index < visibleDailySnapshots.length; index++) {
        final snapshot = visibleDailySnapshots[index];
        final snapshotDay = DateTime(
          snapshot.recordedAt.year,
          snapshot.recordedAt.month,
          snapshot.recordedAt.day,
        );
        points.add(
          PortfolioValueTrendPoint(
            periodStart: snapshot.recordedAt,
            label: _date(snapshotDay),
            axisLabel: _dailyTrendAxisLabel(
              day: snapshotDay,
              index: index,
              total: visibleDailySnapshots.length,
            ),
            detailLabel: _dateTime(snapshot.recordedAt),
            value: snapshot.value,
            isCurrent: false,
          ),
        );
      }

      points.add(
        PortfolioValueTrendPoint(
          periodStart: now,
          label: 'Teraz',
          axisLabel: 'Teraz',
          axisSecondaryLabel: hasSnapshotForToday ? null : _dayMonthLabel(now),
          detailLabel: _dateTime(now),
          value: currentValue,
          isCurrent: true,
        ),
      );

      return points;
    }

    for (var offset = months - 1; offset >= 0; offset--) {
      final monthStart = DateTime(
        normalizedCurrentPeriod.year,
        normalizedCurrentPeriod.month - offset,
        1,
      );
      if (normalizedAccountCreatedAtMonth != null &&
          monthStart.isBefore(normalizedAccountCreatedAtMonth)) {
        continue;
      }

      final key = '${monthStart.year}-${monthStart.month}';
      final report = reportsByMonth[key];

      if (offset == 0) {
        if (report != null) {
          points.add(
            PortfolioValueTrendPoint(
              periodStart: monthStart,
              label: _periodLabel(monthStart),
              axisLabel: _periodLabel(monthStart),
              detailLabel: _dateTime(report.generatedAt),
              value: report.investmentValue,
              isCurrent: false,
            ),
          );
        }
        points.add(
          PortfolioValueTrendPoint(
            periodStart: now,
            label: 'Teraz',
            axisLabel: 'Teraz',
            axisSecondaryLabel: _dayMonthLabel(now),
            detailLabel: _dateTime(now),
            value: currentValue,
            isCurrent: true,
          ),
        );
        continue;
      }

      points.add(
        PortfolioValueTrendPoint(
          periodStart: monthStart,
          label: _periodLabel(monthStart),
          axisLabel: _periodLabel(monthStart),
          detailLabel: report != null
              ? _dateTime(report.generatedAt)
              : 'Brak raportu za ${_periodLabel(monthStart)}',
          value: report?.investmentValue,
          isCurrent: false,
        ),
      );
    }

    return points;
  }

  String _dailyTrendAxisLabel({
    required DateTime day,
    required int index,
    required int total,
  }) {
    if (total <= 10 || index == 0 || index == total - 1 || day.day == 1) {
      return _dayMonthLabel(day);
    }

    final interval = switch (total) {
      <= 20 => 4,
      <= 45 => 7,
      <= 90 => 10,
      _ => 14,
    };
    if (index % interval == 0) {
      return _dayMonthLabel(day);
    }

    return '';
  }

  String _dayMonthLabel(DateTime day) {
    return '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _overviewTrendRangeLabel({
    required int selectedMonths,
    required DateTime? accountCreatedAt,
  }) {
    if (accountCreatedAt == null) {
      return 'z ostatnich $selectedMonths miesiecy';
    }

    final referenceMonth = DateTime(
      _budgetsController.selectedPeriod.year,
      _budgetsController.selectedPeriod.month,
      1,
    );
    final createdMonth = DateTime(
      accountCreatedAt.year,
      accountCreatedAt.month,
      1,
    );
    final visibleHistoryMonths =
        (referenceMonth.year - createdMonth.year) * 12 +
        referenceMonth.month -
        createdMonth.month +
        1;

    if (visibleHistoryMonths >= selectedMonths) {
      return 'z ostatnich $selectedMonths miesiecy';
    }

    return '$selectedMonths mies. od startu konta';
  }

  Map<InvestmentAssetType, List<InvestmentHolding>>
  _groupedInvestmentsByAssetType(List<InvestmentHolding> holdings) {
    final grouped = <InvestmentAssetType, List<InvestmentHolding>>{};
    const assetOrder = [
      InvestmentAssetType.stock,
      InvestmentAssetType.etf,
      InvestmentAssetType.crypto,
      InvestmentAssetType.bond,
      InvestmentAssetType.fund,
      InvestmentAssetType.other,
    ];
    for (final assetType in assetOrder) {
      final matchingHoldings = holdings
          .where((investment) => investment.assetType == assetType)
          .toList();
      if (matchingHoldings.isNotEmpty) {
        grouped[assetType] = matchingHoldings;
      }
    }
    return grouped;
  }

  double _netForTransactions(List<FinanceTransaction> transactions) {
    return transactions.fold<double>(0, (balanceTotal, transaction) {
      switch (transaction.type) {
        case TransactionType.income:
          return balanceTotal + transaction.amount;
        case TransactionType.expense:
        case TransactionType.transfer:
          return balanceTotal - transaction.amount;
      }
    });
  }

  _TransactionMetricsSnapshot _transactionMetrics(
    List<FinanceTransaction> transactions,
  ) {
    var incomeTotal = 0.0;
    var expenseTotal = 0.0;
    var transferTotal = 0.0;
    var goalLinkedCount = 0;
    var recurringIncomeCount = 0;

    for (final transaction in transactions) {
      switch (transaction.type) {
        case TransactionType.income:
          incomeTotal += transaction.amount;
          break;
        case TransactionType.expense:
          expenseTotal += transaction.amount;
          break;
        case TransactionType.transfer:
          transferTotal += transaction.amount;
          break;
      }

      if (transaction.goalId?.trim().isNotEmpty ?? false) {
        goalLinkedCount++;
      }
      if (transaction.recurringIncomeId?.trim().isNotEmpty ?? false) {
        recurringIncomeCount++;
      }
    }

    return _TransactionMetricsSnapshot(
      incomeTotal: incomeTotal,
      expenseTotal: expenseTotal,
      transferTotal: transferTotal,
      goalLinkedCount: goalLinkedCount,
      recurringIncomeCount: recurringIncomeCount,
    );
  }

  _TransactionExpenseTrendSnapshot _transactionExpenseTrend(
    List<FinanceTransaction> transactions,
  ) {
    final expenseTransactions = transactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .toList();
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final rangeFilter = _transactionsController.rangeFilter;

    if (expenseTransactions.isEmpty) {
      return _TransactionExpenseTrendSnapshot(
        points: const [],
        subtitle: _transactionExpenseTrendSubtitle(
          rangeFilter: rangeFilter,
          trimmedToRecentDays: false,
        ),
        totalExpense: 0,
        activeDayCount: 0,
        averageActiveDayExpense: 0,
        peakPoint: null,
      );
    }

    final groupedExpenses = <DateTime, double>{};
    for (final transaction in expenseTransactions) {
      final day = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      groupedExpenses.update(
        day,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    final sortedDays = groupedExpenses.keys.toList()..sort();
    final earliestDay = sortedDays.first;
    final latestDay = sortedDays.last;
    var rangeStart = earliestDay;
    var rangeEnd = latestDay;
    var trimmedToRecentDays = false;

    switch (rangeFilter) {
      case TransactionRangeFilter.currentMonth:
        rangeStart = DateTime(today.year, today.month, 1);
        rangeEnd = todayDay;
        break;
      case TransactionRangeFilter.last30Days:
        rangeStart = todayDay.subtract(const Duration(days: 29));
        rangeEnd = todayDay;
        break;
      case TransactionRangeFilter.all:
        final spanDays = latestDay.difference(earliestDay).inDays + 1;
        if (spanDays > 21) {
          rangeStart = latestDay.subtract(const Duration(days: 20));
          trimmedToRecentDays = true;
        }
        break;
    }

    final points = <TransactionExpenseTrendPoint>[];
    for (
      var cursor = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
      !cursor.isAfter(rangeEnd);
      cursor = cursor.add(const Duration(days: 1))
    ) {
      points.add(
        TransactionExpenseTrendPoint(
          day: cursor,
          axisLabel: _transactionTrendAxisLabel(
            day: cursor,
            index: points.length,
            total: rangeEnd.difference(rangeStart).inDays + 1,
          ),
          expenseTotal: groupedExpenses[cursor] ?? 0,
        ),
      );
    }

    final activePoints = points
        .where((point) => point.expenseTotal > 0)
        .toList();
    final totalExpense = activePoints.fold<double>(
      0,
      (runningTotal, point) => runningTotal + point.expenseTotal,
    );
    final peakPoint = activePoints.isEmpty
        ? null
        : activePoints.reduce(
            (left, right) =>
                left.expenseTotal >= right.expenseTotal ? left : right,
          );

    return _TransactionExpenseTrendSnapshot(
      points: points,
      subtitle: _transactionExpenseTrendSubtitle(
        rangeFilter: rangeFilter,
        trimmedToRecentDays: trimmedToRecentDays,
      ),
      totalExpense: totalExpense,
      activeDayCount: activePoints.length,
      averageActiveDayExpense: activePoints.isEmpty
          ? 0
          : totalExpense / activePoints.length,
      peakPoint: peakPoint,
    );
  }

  List<_TransactionDayGroup> _groupTransactionsByDay(
    List<FinanceTransaction> transactions,
  ) {
    final groups = <_TransactionDayGroup>[];

    for (final transaction in transactions) {
      final day = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      if (groups.isNotEmpty && _isSameDay(groups.last.day, day)) {
        groups.last.transactions.add(transaction);
        continue;
      }

      groups.add(_TransactionDayGroup(day: day, transactions: [transaction]));
    }

    return groups;
  }

  FinanceTransaction? _largestExpenseTransaction(
    List<FinanceTransaction> transactions,
  ) {
    final expenses = transactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .toList();
    if (expenses.isEmpty) {
      return null;
    }

    return expenses.reduce(
      (left, right) => left.amount >= right.amount ? left : right,
    );
  }

  String? _topExpenseCategory(List<FinanceTransaction> transactions) {
    final totals = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type != TransactionType.expense) {
        continue;
      }

      totals.update(
        transaction.category,
        (currentTotal) => currentTotal + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    if (totals.isEmpty) {
      return null;
    }

    return totals.entries
        .reduce((left, right) => left.value >= right.value ? left : right)
        .key;
  }

  String _transactionDateRangeLabel(List<FinanceTransaction> transactions) {
    if (transactions.isEmpty) {
      return 'Brak';
    }

    final sorted = List<FinanceTransaction>.from(transactions)
      ..sort((left, right) => left.date.compareTo(right.date));
    final first = sorted.first.date;
    final last = sorted.last.date;

    if (_isSameDay(first, last)) {
      return _date(first);
    }

    return '${_date(first)} - ${_date(last)}';
  }

  String _transactionFilterSummary({
    required int visibleCount,
    required int totalCount,
  }) {
    final parts = <String>['Pokazuje $visibleCount z $totalCount transakcji'];
    if (_transactionsController.rangeFilter != TransactionRangeFilter.all) {
      parts.add(
        'zakres ${_transactionRangeFilterLabel(_transactionsController.rangeFilter)}',
      );
    }

    final typeFilter = _transactionsController.typeFilter;
    if (typeFilter != TransactionTypeFilter.all) {
      parts.add('typ ${_transactionTypeFilterLabel(typeFilter)}');
    }

    if (_transactionsController.categoryFilter != null) {
      parts.add('kategoria ${_transactionsController.categoryFilter!}');
    }

    if (_transactionsController.goalFilter != null) {
      parts.add(
        'cel ${_goalName(_transactionsController.goalFilter) ?? 'Usuniety cel'}',
      );
    }

    if (_transactionsController.searchQuery.isNotEmpty) {
      parts.add('szukaj "${_transactionsController.searchQuery}"');
    }

    parts.add(
      'sortowanie ${_transactionSortOptionLabel(_transactionsController.sortOption)}',
    );

    return parts.join(' | ');
  }

  String _transactionExpenseTrendSubtitle({
    required TransactionRangeFilter rangeFilter,
    required bool trimmedToRecentDays,
  }) {
    return switch (rangeFilter) {
      TransactionRangeFilter.currentMonth =>
        'Dzien po dniu od poczatku biezacego miesiaca.',
      TransactionRangeFilter.last30Days => 'Dzien po dniu z ostatnich 30 dni.',
      TransactionRangeFilter.all =>
        trimmedToRecentDays
            ? 'Ostatnie 21 dni z calej historii wydatkow.'
            : 'Dzien po dniu dla calej widocznej historii wydatkow.',
    };
  }

  String _transactionTrendAxisLabel({
    required DateTime day,
    required int index,
    required int total,
  }) {
    if (total <= 10 || index == 0 || index == total - 1 || day.day == 1) {
      return _dayMonthLabel(day);
    }

    final interval = switch (total) {
      <= 20 => 4,
      <= 31 => 5,
      _ => 7,
    };

    if (index % interval == 0) {
      return _dayMonthLabel(day);
    }

    return '';
  }

  String _transactionTypeFilterLabel(TransactionTypeFilter filter) {
    return switch (filter) {
      TransactionTypeFilter.all => 'Wszystkie',
      TransactionTypeFilter.income => 'Przychody',
      TransactionTypeFilter.expense => 'Wydatki',
      TransactionTypeFilter.transfer => 'Transfery',
    };
  }

  String _transactionRangeFilterLabel(TransactionRangeFilter filter) {
    return switch (filter) {
      TransactionRangeFilter.all => 'Calosc',
      TransactionRangeFilter.currentMonth => 'ten miesiac',
      TransactionRangeFilter.last30Days => 'ostatnie 30 dni',
    };
  }

  String _transactionSortOptionLabel(TransactionSortOption option) {
    return switch (option) {
      TransactionSortOption.newest => 'najnowsze',
      TransactionSortOption.oldest => 'najstarsze',
      TransactionSortOption.highestAmount => 'kwota malejaco',
      TransactionSortOption.lowestAmount => 'kwota rosnaco',
    };
  }

  List<CategoryBudget> _budgetSnapshots(List<FinanceTransaction> transactions) {
    final period = _budgetsController.selectedPeriod;

    return _budgetsController.budgets.map((budget) {
      final spent = transactions
          .where(
            (transaction) =>
                transaction.type == TransactionType.expense &&
                transaction.category == budget.category &&
                transaction.date.year == period.year &&
                transaction.date.month == period.month,
          )
          .fold<double>(0, (total, transaction) => total + transaction.amount);

      return budget.copyWith(spent: spent);
    }).toList();
  }

  List<SavingsGoal> _goalSnapshots(
    Map<String, List<FinanceTransaction>> contributionHistory,
  ) {
    return _goalsController.goals.map((goal) {
      final linkedAmount =
          contributionHistory[goal.id]?.fold<double>(
            0,
            (total, transaction) => total + transaction.amount,
          ) ??
          0;
      return goal.copyWith(savedAmount: goal.savedAmount + linkedAmount);
    }).toList();
  }

  Map<String, List<FinanceTransaction>> _goalContributionHistory(
    List<FinanceTransaction> transactions,
  ) {
    final contributionHistory = <String, List<FinanceTransaction>>{};

    for (final transaction in transactions) {
      final goalId = transaction.goalId?.trim();
      if (goalId == null || goalId.isEmpty) {
        continue;
      }

      if (transaction.type == TransactionType.income) {
        continue;
      }

      contributionHistory.putIfAbsent(goalId, () => []).add(transaction);
    }

    for (final history in contributionHistory.values) {
      history.sort((left, right) => right.date.compareTo(left.date));
    }

    return contributionHistory;
  }

  double _goalStartingAmount(String goalId) {
    for (final goal in _goalsController.goals) {
      if (goal.id == goalId) {
        return goal.savedAmount;
      }
    }

    return 0;
  }

  SavingsGoal? _storedGoalById(String goalId) {
    for (final goal in _goalsController.goals) {
      if (goal.id == goalId) {
        return goal;
      }
    }

    return null;
  }

  String? _goalName(String? goalId) {
    if (goalId == null || goalId.trim().isEmpty) {
      return null;
    }

    for (final goal in _goalsController.goals) {
      if (goal.id == goalId) {
        return goal.name;
      }
    }

    return 'Usuniety cel';
  }

  SavingsGoal? _goalSnapshotById(String goalId) {
    final snapshots = _goalSnapshots(
      _goalContributionHistory(_transactionsController.transactions),
    );

    for (final goal in snapshots) {
      if (goal.id == goalId) {
        return goal;
      }
    }

    return null;
  }

  List<FinanceTransaction> _goalContributionTransactions(String goalId) {
    return _goalContributionHistory(
          _transactionsController.transactions,
        )[goalId] ??
        const [];
  }

  List<GoalContributionPlan> _goalContributionPlans(String goalId) {
    return _goalContributionPlansController.plansForGoal(goalId);
  }

  DateTime? _nextGoalContributionDate(List<GoalContributionPlan> plans) {
    return plans
        .where((plan) => plan.isActive)
        .map(_goalContributionPlansController.nextContributionDate)
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (earliest, candidate) =>
              earliest == null || candidate.isBefore(earliest)
              ? candidate
              : earliest,
        );
  }

  List<String> _budgetCategoryNames() {
    return _categoriesController
        .categoriesForType(TransactionType.expense)
        .map((category) => category.name)
        .toList();
  }

  List<String> _availableFilterCategories() {
    final names = {
      ..._categoriesController.categories.map((category) => category.name),
      ..._transactionsController.availableCategories,
    }.toList()..sort();

    return names;
  }

  InvestmentHolding? _investmentById(String investmentId) {
    for (final investment in _investmentsController.investments) {
      if (investment.id == investmentId) {
        return investment;
      }
    }

    return null;
  }

  MonthlyReport _buildCurrentMonthlyReport({
    required List<FinanceTransaction> transactions,
    required List<CategoryBudget> budgets,
    required List<SavingsGoal> goals,
    required List<InvestmentHolding> investments,
  }) {
    return buildMonthlyReport(
      periodStart: _budgetsController.selectedPeriod,
      generatedAt: DateTime.now(),
      transactions: transactions,
      budgets: budgets,
      goals: goals,
      investments: investments,
    );
  }

  Future<void> _saveMonthlyReport({
    required List<FinanceTransaction> transactions,
    required List<CategoryBudget> budgets,
    required List<SavingsGoal> goals,
    required List<InvestmentHolding> investments,
  }) async {
    final report = _buildCurrentMonthlyReport(
      transactions: transactions,
      budgets: budgets,
      goals: goals,
      investments: investments,
    );

    await _runMutation(
      () => _monthlyReportsController.save(report),
      'Zapisano raport miesieczny.',
      errorMapper: _monthlyReportError,
    );
  }

  Future<void> _closeMonthlyReport({
    required List<FinanceTransaction> transactions,
    required List<CategoryBudget> budgets,
    required List<SavingsGoal> goals,
    required List<InvestmentHolding> investments,
  }) async {
    final confirmed = await _confirmDestructiveAction(
      title: 'Zamknac miesiac?',
      message:
          'Raport za okres ${_periodLabel(_budgetsController.selectedPeriod)} zostanie zamkniety. Pozniej nie zaktualizujesz go zwyklym zapisem.',
      confirmLabel: 'Zamknij',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final report = _buildCurrentMonthlyReport(
      transactions: transactions,
      budgets: budgets,
      goals: goals,
      investments: investments,
    );

    await _runMutation(
      () => _monthlyReportsController.close(report),
      'Zamknieto miesiac i zapisano finalny raport.',
      errorMapper: _monthlyReportError,
    );
  }

  Future<void> _deleteMonthlyReport(MonthlyReport report) async {
    final confirmed = await _confirmDestructiveAction(
      title: 'Usunac raport?',
      message:
          'Raport za okres ${_periodLabel(report.periodStart)} zostanie usuniety.',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runMutation(
      () => _monthlyReportsController.delete(report),
      'Usunieto raport miesieczny.',
      errorMapper: _monthlyReportError,
    );
  }

  Future<void> _editProfile(UserProfile profile) async {
    final updatedProfile = await showUserProfileFormSheet(
      context,
      profile: profile,
    );
    if (updatedProfile == null || !mounted) {
      return;
    }

    await _runMutation(
      () async {
        if (updatedProfile.profile.displayName != profile.displayName) {
          await widget.authRepository.updateDisplayName(
            updatedProfile.profile.displayName,
          );
        }
        await _userProfileController.save(updatedProfile.profile);
      },
      'Zapisano nick. Zmiana jest widoczna od razu w panelu konta i w menu.',
      errorMapper: _profileError,
    );
  }

  Future<void> _openAccountSecurity() async {
    await showAccountSecuritySheet(
      context,
      authRepository: widget.authRepository,
    );

    try {
      final snapshot = await widget.authRepository.getAccountSecuritySnapshot();
      if (!mounted) {
        return;
      }

      _setAccountSecuritySnapshot(snapshot);

      if (snapshot.email.trim() != _userProfileController.email.trim()) {
        await _userProfileController.syncIdentity(email: snapshot.email);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _setAccountSecurityError(error);
    }
  }

  Future<void> _exportCsv({
    required UserProfile? profile,
    required DashboardSnapshot dashboard,
    required List<CategoryBudget> budgets,
    required List<SavingsGoal> goals,
    required List<InvestmentHolding> investments,
    required List<SubscriptionPlan> subscriptions,
  }) async {
    final file = _DashboardScreenState._exportService.buildCsv(
      profile: profile,
      transactions: dashboard.transactions,
      budgets: budgets,
      goals: goals,
      investments: investments,
      subscriptions: subscriptions,
      exportedAt: DateTime.now(),
    );

    await _shareExport(file, successMessage: 'Uruchomiono eksport CSV.');
  }

  Future<void> _importTransactionsCsv() async {
    const csvTypeGroup = XTypeGroup(
      label: 'csv-xlsx',
      extensions: <String>['csv', 'txt', 'xlsx'],
    );

    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[csvTypeGroup],
    );
    if (file == null || !mounted) {
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }

      final importCategoryRules = await _loadImportCategoryRules();
      if (!mounted) {
        return;
      }

      final source = _DashboardScreenState._transactionImportService.readRaw(
        bytes,
        fileName: file.name,
      );
      var preview = _DashboardScreenState._transactionImportService.parse(
        bytes: bytes,
        existingTransactions: _transactionsController.transactions,
        availableCategories: _categoriesController.categories,
        importCategoryRules: importCategoryRules,
        fileName: file.name,
      );

      if (_shouldOfferTransactionColumnMapping(preview, source)) {
        final mapping = await showTransactionCsvColumnMappingSheet(
          context,
          source: source,
        );
        if (!mounted) {
          return;
        }

        if (mapping != null) {
          preview = _DashboardScreenState._transactionImportService
              .parseWithColumnMapping(
                source: source,
                mapping: mapping,
                existingTransactions: _transactionsController.transactions,
                availableCategories: _categoriesController.categories,
                importCategoryRules: importCategoryRules,
              );
        }
      }

      final transactionsToImport = await showTransactionCsvImportPreviewSheet(
        context,
        preview: preview,
        availableCategories: _categoriesController.categories,
      );
      if (transactionsToImport == null ||
          !mounted ||
          transactionsToImport.isEmpty) {
        return;
      }

      final learnedRules = _learnImportCategoryRules(
        originalTransactions: preview.transactionsToImport,
        importedTransactions: transactionsToImport,
      );
      final learnedMessage = learnedRules.isEmpty
          ? ''
          : ' Zapamietano ${learnedRules.length} regul kategorii.';

      await _runMutation(
        () async {
          final createdTransactions = await _transactionsController
              .importTransactions(transactionsToImport);
          await _saveLearnedImportCategoryRules(learnedRules);
          await _saveTransactionImportHistory(
            fileName: file.name,
            preview: preview,
            importedTransactions: createdTransactions,
            learnedRuleCount: learnedRules.length,
          );
        },
        'Zaimportowano ${transactionsToImport.length} transakcji z pliku.$learnedMessage',
        errorMapper: (error) =>
            error?.toString() ?? 'Import transakcji nie powiodl sie.',
      );
    } catch (_) {
      _showFileImportFailure(
        'Nie udalo sie przetworzyc pliku transakcji. Sprawdz format CSV/XLSX.',
      );
    }
  }

  Future<List<ImportCategoryRule>> _loadImportCategoryRules() async {
    try {
      return widget.importCategoryRuleRepository.loadRules(widget.userId);
    } catch (_) {
      return const <ImportCategoryRule>[];
    }
  }

  Future<void> _saveLearnedImportCategoryRules(
    List<ImportCategoryRule> rules,
  ) async {
    if (rules.isEmpty) {
      return;
    }

    try {
      await widget.importCategoryRuleRepository.upsertRules(
        userId: widget.userId,
        rules: rules,
      );
    } catch (_) {
      // Import transakcji jest wazniejszy niz lokalne zapamietanie reguly.
    }
  }

  List<ImportCategoryRule> _learnImportCategoryRules({
    required List<FinanceTransaction> originalTransactions,
    required List<FinanceTransaction> importedTransactions,
  }) {
    final ruleById = <String, ImportCategoryRule>{};
    final now = DateTime.now();
    final length = math.min(
      originalTransactions.length,
      importedTransactions.length,
    );

    for (var index = 0; index < length; index++) {
      final original = originalTransactions[index];
      final imported = importedTransactions[index];
      if (original.type != imported.type ||
          original.category == imported.category) {
        continue;
      }

      final rule = ImportCategoryRule.forTransaction(
        transaction: imported.copyWith(title: original.title),
        updatedAt: now,
      );
      if (rule.isUsable) {
        ruleById[rule.id] = rule;
      }
    }

    return List<ImportCategoryRule>.unmodifiable(ruleById.values);
  }

  Future<void> _saveTransactionImportHistory({
    required String fileName,
    required TransactionCsvImportPreview preview,
    required List<FinanceTransaction> importedTransactions,
    required int learnedRuleCount,
  }) async {
    final importedAt = DateTime.now();
    final entry = TransactionImportHistoryEntry(
      id: '${importedAt.microsecondsSinceEpoch}-$fileName',
      sourceName: fileName,
      formatLabel: preview.formatLabel,
      importedAt: importedAt,
      importedCount: importedTransactions.length,
      duplicateCount: preview.duplicateCount,
      issueCount: preview.issues.length,
      expenseCount: importedTransactions
          .where((transaction) => transaction.type == TransactionType.expense)
          .length,
      incomeCount: importedTransactions
          .where((transaction) => transaction.type == TransactionType.income)
          .length,
      transferCount: importedTransactions
          .where((transaction) => transaction.type == TransactionType.transfer)
          .length,
      learnedRuleCount: learnedRuleCount,
      transactionIds: importedTransactions
          .map((transaction) => transaction.id.trim())
          .where((id) => id.isNotEmpty)
          .toList(),
    );

    try {
      await widget.transactionImportHistoryRepository.addEntry(
        userId: widget.userId,
        entry: entry,
      );
    } catch (_) {
      // Historia importu jest pomocnicza; zapis transakcji nie powinien od niej zalezec.
    }
  }

  Future<void> _openImportCategoryRules() async {
    final rules = await _loadImportCategoryRules();
    if (!mounted) {
      return;
    }

    final updatedRules = await showImportCategoryRulesSheet(
      context,
      rules: rules,
      availableCategories: _categoriesController.categories,
    );
    if (updatedRules == null || !mounted) {
      return;
    }

    try {
      await widget.importCategoryRuleRepository.replaceRules(
        userId: widget.userId,
        rules: updatedRules,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedRules.isEmpty
                ? 'Usunieto reguly kategorii.'
                : 'Zapisano ${updatedRules.length} regul kategorii.',
          ),
        ),
      );
    } catch (_) {
      _showFileImportFailure('Nie udalo sie zapisac regul kategorii.');
    }
  }

  Future<void> _openTransactionImportHistory() async {
    List<TransactionImportHistoryEntry> entries;
    try {
      entries = await widget.transactionImportHistoryRepository.loadEntries(
        widget.userId,
      );
    } catch (_) {
      entries = const <TransactionImportHistoryEntry>[];
    }
    if (!mounted) {
      return;
    }

    final action = await showTransactionImportHistorySheet(
      context,
      entries: entries,
    );
    if (action == null || !mounted) {
      return;
    }

    switch (action.type) {
      case TransactionImportHistoryActionType.clear:
        try {
          await widget.transactionImportHistoryRepository.clearEntries(
            widget.userId,
          );
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wyczyszczono historie importow.')),
          );
        } catch (_) {
          _showFileImportFailure('Nie udalo sie wyczyscic historii importow.');
        }
        break;
      case TransactionImportHistoryActionType.undo:
        final entry = action.entry;
        if (entry == null) {
          return;
        }
        await _undoTransactionImport(entry: entry, entries: entries);
        break;
    }
  }

  Future<void> _undoTransactionImport({
    required TransactionImportHistoryEntry entry,
    required List<TransactionImportHistoryEntry> entries,
  }) async {
    final transactionIds = entry.transactionIds
        .map((transactionId) => transactionId.trim())
        .where((transactionId) => transactionId.isNotEmpty)
        .toSet()
        .toList();
    if (transactionIds.isEmpty || !entry.canUndo) {
      _showFileImportFailure(
        'Ten import nie ma danych potrzebnych do cofniecia.',
      );
      return;
    }

    final confirmed = await _confirmDestructiveAction(
      title: 'Cofnac import?',
      message:
          'Zostanie usunietych ${transactionIds.length} transakcji z importu "${entry.sourceName}".',
      confirmLabel: 'Cofnij',
    );
    if (confirmed != true || !mounted) {
      return;
    }

    await _runMutation(
      () async {
        final deletedCount = await _transactionsController
            .deleteTransactionsByIds(transactionIds);
        if (deletedCount == 0) {
          throw StateError('Brak transakcji do usuniecia.');
        }
        final undoneEntry = entry.copyWith(undoneAt: DateTime.now());
        final updatedEntries = entries
            .map((current) => current.id == entry.id ? undoneEntry : current)
            .toList();
        await widget.transactionImportHistoryRepository.replaceEntries(
          userId: widget.userId,
          entries: updatedEntries,
        );
      },
      'Cofnieto import i usunieto ${transactionIds.length} transakcji.',
      errorMapper: (error) =>
          error?.toString() ?? 'Nie udalo sie cofnac importu.',
    );
  }

  void _showFileImportFailure(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _shouldOfferTransactionColumnMapping(
    TransactionCsvImportPreview preview,
    TransactionCsvSourceData source,
  ) {
    if (!_DashboardScreenState._transactionImportService.canOfferColumnMapping(
      source,
    )) {
      return false;
    }

    return preview.validCount == 0 &&
        preview.issues.any(
          (issue) => issue.message.contains('Brakuje wymaganych kolumn'),
        );
  }

  Future<void> _importSubscriptionsFile() async {
    const csvTypeGroup = XTypeGroup(
      label: 'csv-xlsx',
      extensions: <String>['csv', 'txt', 'xlsx'],
    );

    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[csvTypeGroup],
    );
    if (file == null || !mounted) {
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }

      final availableCategories = _budgetCategoryNames();
      final source = _DashboardScreenState._subscriptionImportService.readRaw(
        bytes,
        fileName: file.name,
      );
      var preview = _DashboardScreenState._subscriptionImportService.parse(
        bytes: bytes,
        existingSubscriptions: _subscriptionsController.subscriptions,
        availableCategories: availableCategories,
        fileName: file.name,
      );

      if (_shouldOfferSubscriptionColumnMapping(preview, source)) {
        final mapping = await showSubscriptionCsvColumnMappingSheet(
          context,
          source: source,
        );
        if (!mounted) {
          return;
        }

        if (mapping != null) {
          preview = _DashboardScreenState._subscriptionImportService
              .parseWithColumnMapping(
                source: source,
                mapping: mapping,
                existingSubscriptions: _subscriptionsController.subscriptions,
                availableCategories: availableCategories,
              );
        }
      }

      final subscriptionsToImport = await showSubscriptionCsvImportPreviewSheet(
        context,
        preview: preview,
        availableCategories: availableCategories,
      );
      if (subscriptionsToImport == null ||
          !mounted ||
          subscriptionsToImport.isEmpty) {
        return;
      }

      await _runMutation(
        () async {
          await _subscriptionsController.importSubscriptions(
            subscriptionsToImport,
          );
        },
        'Zaimportowano ${subscriptionsToImport.length} subskrypcji z pliku.',
        errorMapper: (error) =>
            error?.toString() ?? 'Import subskrypcji nie powiodl sie.',
      );
    } catch (_) {
      _showFileImportFailure(
        'Nie udalo sie przetworzyc pliku subskrypcji. Sprawdz format CSV/XLSX.',
      );
    }
  }

  bool _shouldOfferSubscriptionColumnMapping(
    SubscriptionCsvImportPreview preview,
    SubscriptionCsvSourceData source,
  ) {
    if (!_DashboardScreenState._subscriptionImportService.canOfferColumnMapping(
      source,
    )) {
      return false;
    }

    return preview.validCount == 0 &&
        preview.issues.any(
          (issue) => issue.message.contains('Brakuje wymaganych kolumn'),
        );
  }

  Future<void> _exportPdf({
    required UserProfile? profile,
    required DashboardSnapshot dashboard,
    required List<CategoryBudget> budgets,
    required List<SavingsGoal> goals,
    required List<InvestmentHolding> investments,
    required List<SubscriptionPlan> subscriptions,
  }) async {
    final file = await _DashboardScreenState._exportService.buildPdf(
      profile: profile,
      dashboard: dashboard,
      budgets: budgets,
      goals: goals,
      investments: investments,
      subscriptions: subscriptions,
      exportedAt: DateTime.now(),
    );

    await _shareExport(file, successMessage: 'Uruchomiono eksport PDF.');
  }

  Future<void> _archiveMonthlyCsv({
    required UserProfile? profile,
    required DashboardSnapshot dashboard,
    required List<CategoryBudget> budgets,
    required List<SavingsGoal> goals,
    required List<InvestmentHolding> investments,
    required List<SubscriptionPlan> subscriptions,
  }) async {
    final file = _DashboardScreenState._exportService.buildCsv(
      profile: profile,
      transactions: dashboard.transactions,
      budgets: budgets,
      goals: goals,
      investments: investments,
      subscriptions: subscriptions,
      exportedAt: DateTime.now(),
    );

    final reportId = _monthlyReportsController
        .reportForPeriod(_budgetsController.selectedPeriod)
        ?.id;

    await _runMutation(
      () => _reportArchivesController.archiveFile(
        file: file,
        periodStart: _budgetsController.selectedPeriod,
        format: ReportArchiveFormat.csv,
        reportId: reportId,
      ),
      'Zarchiwizowano CSV.',
      errorMapper: _reportArchiveError,
    );
  }

  Future<void> _archiveMonthlyPdf({
    required UserProfile? profile,
    required DashboardSnapshot dashboard,
    required List<CategoryBudget> budgets,
    required List<SavingsGoal> goals,
    required List<InvestmentHolding> investments,
    required List<SubscriptionPlan> subscriptions,
  }) async {
    final file = await _DashboardScreenState._exportService.buildPdf(
      profile: profile,
      dashboard: dashboard,
      budgets: budgets,
      goals: goals,
      investments: investments,
      subscriptions: subscriptions,
      exportedAt: DateTime.now(),
    );

    final reportId = _monthlyReportsController
        .reportForPeriod(_budgetsController.selectedPeriod)
        ?.id;

    await _runMutation(
      () => _reportArchivesController.archiveFile(
        file: file,
        periodStart: _budgetsController.selectedPeriod,
        format: ReportArchiveFormat.pdf,
        reportId: reportId,
      ),
      'Zarchiwizowano PDF.',
      errorMapper: _reportArchiveError,
    );
  }

  Future<void> _deleteReportArchive(ReportArchiveEntry archive) async {
    final confirmed = await _confirmDestructiveAction(
      title: 'Usunac archiwum?',
      message: 'Plik ${archive.filename} zostanie usuniety z archiwum.',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runMutation(
      () => _reportArchivesController.delete(archive),
      'Usunieto archiwum raportu.',
      errorMapper: _reportArchiveError,
    );
  }

  Future<void> _openReportArchive(ReportArchiveEntry archive) async {
    try {
      if (kIsWeb) {
        final downloadUri = await _reportArchiveDownloadUri(archive);
        if (!mounted) {
          return;
        }

        if (downloadUri != null) {
          await launchExternalDownload(downloadUri, filename: archive.filename);
          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uruchomiono pobieranie archiwum.')),
          );
          return;
        }
      }

      final file = await _reportArchivesController.loadFile(archive);
      if (!mounted) {
        return;
      }

      await _shareExport(
        file,
        successMessage: 'Uruchomiono pobieranie archiwum.',
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_reportArchiveError(error))));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_reportArchiveError(error))));
    }
  }

  Future<Uri?> _reportArchiveDownloadUri(ReportArchiveEntry archive) async {
    try {
      final result = await (widget.reportArchiveRepository as dynamic)
          .getArchiveDownloadUri(userId: widget.userId, archive: archive);
      return result is Uri ? result : null;
    } on NoSuchMethodError {
      return null;
    }
  }

  Future<void> _shareExport(
    ExportFilePayload file, {
    required String successMessage,
  }) async {
    try {
      await widget.exportShareGateway.share(file);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udalo sie wyeksportowac pliku.')),
      );
    }
  }

  Future<void> _createSubscription() async {
    final subscription = await showSubscriptionFormSheet(context);
    if (subscription == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _subscriptionsController.save(subscription),
      'Dodano subskrypcje.',
      errorMapper: _subscriptionError,
    );
  }

  Future<void> _editSubscription(SubscriptionPlan subscription) async {
    final updatedSubscription = await showSubscriptionFormSheet(
      context,
      initialSubscription: subscription,
    );
    if (updatedSubscription == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _subscriptionsController.save(updatedSubscription),
      'Zapisano subskrypcje.',
      errorMapper: _subscriptionError,
    );
  }

  Future<void> _deleteSubscription(SubscriptionPlan subscription) async {
    final confirmed = await _confirmDestructiveAction(
      title: 'Usunac subskrypcje?',
      message: 'Subskrypcja "${subscription.name}" zostanie usunieta.',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runMutation(
      () => _subscriptionsController.delete(subscription),
      'Usunieto subskrypcje.',
      errorMapper: _subscriptionError,
    );
  }

  Future<void> _createCategory() async {
    final category = await showCategoryFormSheet(context);
    if (category == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _categoriesController.save(category),
      'Dodano kategorie.',
      errorMapper: _categoryError,
    );
  }

  Future<void> _editCategory(FinanceCategory category) async {
    final updatedCategory = await showCategoryFormSheet(
      context,
      initialCategory: category,
    );
    if (updatedCategory == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _categoriesController.save(updatedCategory),
      'Zapisano kategorie.',
      errorMapper: _categoryError,
    );
  }

  Future<void> _mergeCategory(FinanceCategory category) async {
    final candidates = _categoryMergeCandidates(category);
    if (candidates.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dodaj najpierw druga kategorie typu ${_categoryTypeLabel(category.type).toLowerCase()}, aby scalic dane.',
          ),
        ),
      );
      return;
    }

    final targetCategory = await showCategoryMergeSheet(
      context,
      sourceCategory: category,
      candidateCategories: candidates,
      transactionCount: _transactionUsageCount(category),
      budgetCount: _budgetUsageCount(category),
      subscriptionCount: _subscriptionUsageCount(category),
      recurringIncomeCount: _recurringIncomeUsageCount(category),
    );
    if (targetCategory == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _categoriesController.mergeCategory(
        sourceCategory: category,
        targetCategory: targetCategory,
      ),
      'Scalono kategorie i przepieto dane.',
      errorMapper: _categoryError,
    );
  }

  Future<void> _deleteCategory(FinanceCategory category) async {
    final confirmed = await _confirmDestructiveAction(
      title: 'Usunac kategorie?',
      message:
          'Kategoria "${category.name}" zostanie usunieta z listy wyboru. Jesli chcesz przepiac istniejace dane do innej etykiety, uzyj akcji "Scal".',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runMutation(
      () => _categoriesController.delete(category),
      'Usunieto kategorie.',
      errorMapper: _categoryError,
    );
  }

  Future<void> _previousBudgetMonth() {
    return _budgetsController.previousMonth();
  }

  Future<void> _nextBudgetMonth() {
    return _budgetsController.nextMonth();
  }

  Future<void> _createBudget() async {
    final budget = await showBudgetFormSheet(
      context,
      periodStart: _budgetsController.selectedPeriod,
      availableCategories: _budgetCategoryNames(),
    );
    if (budget == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _budgetsController.save(budget),
      'Dodano budzet.',
      errorMapper: _budgetError,
    );
  }

  Future<void> _editBudget(CategoryBudget budget) async {
    final updatedBudget = await showBudgetFormSheet(
      context,
      periodStart: _budgetsController.selectedPeriod,
      initialBudget: budget,
      availableCategories: _budgetCategoryNames(),
    );
    if (updatedBudget == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _budgetsController.save(updatedBudget),
      'Zapisano budzet.',
      errorMapper: _budgetError,
    );
  }

  Future<void> _deleteBudget(CategoryBudget budget) async {
    final confirmed = await _confirmDestructiveAction(
      title: 'Usunac budzet?',
      message: 'Limit dla kategorii "${budget.category}" zostanie usuniety.',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runMutation(
      () => _budgetsController.delete(budget),
      'Usunieto budzet.',
      errorMapper: _budgetError,
    );
  }

  Future<void> _createGoal() async {
    final goal = await showGoalFormSheet(context);
    if (goal == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _goalsController.save(goal),
      'Dodano cel.',
      errorMapper: _goalError,
    );
  }

  Future<void> _createGoalContribution(SavingsGoal goal) async {
    final transaction = await showTransactionFormSheet(
      context,
      availableCategories: _categoriesController.categories,
      availableGoals: _goalsController.goals,
      presetGoalId: goal.id,
    );
    if (transaction == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _transactionsController.save(transaction),
      'Dodano wplate do celu.',
    );
  }

  Future<void> _createGoalContributionPlan(SavingsGoal goal) async {
    final plan = await showGoalContributionPlanFormSheet(context, goal: goal);
    if (plan == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _goalContributionPlansController.save(plan),
      'Dodano plan wplat.',
      errorMapper: _goalContributionPlanError,
    );
  }

  Future<void> _editGoalContributionPlan(
    SavingsGoal goal,
    GoalContributionPlan plan,
  ) async {
    final updatedPlan = await showGoalContributionPlanFormSheet(
      context,
      goal: goal,
      initialPlan: plan,
    );
    if (updatedPlan == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _goalContributionPlansController.save(updatedPlan),
      'Zapisano plan wplat.',
      errorMapper: _goalContributionPlanError,
    );
  }

  Future<void> _deleteGoalContributionPlan(GoalContributionPlan plan) async {
    final confirmed = await _confirmDestructiveAction(
      title: 'Usunac plan wplat?',
      message:
          'Plan "${plan.name}" zostanie usuniety. Wygenerowane wplaty pozostana w historii.',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runMutation(
      () => _goalContributionPlansController.delete(plan),
      'Usunieto plan wplat.',
      errorMapper: _goalContributionPlanError,
    );
  }

  Future<void> _openGoalDetails(SavingsGoal goal) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GoalDetailsScreen(
          goalId: goal.id,
          listenable: Listenable.merge([
            _goalsController,
            _goalContributionPlansController,
            _transactionsController,
          ]),
          goalById: _goalSnapshotById,
          startingAmountByGoalId: _goalStartingAmount,
          contributionHistoryByGoalId: _goalContributionTransactions,
          contributionPlansByGoalId: _goalContributionPlans,
          nextContributionDateForPlan:
              _goalContributionPlansController.nextContributionDate,
          onAddContribution: () => _createGoalContribution(goal),
          onAddContributionPlan: () => _createGoalContributionPlan(goal),
          onEditContribution: _editTransaction,
          onEditContributionPlan: (plan) => _editGoalContributionPlan(
            _goalSnapshotById(goal.id) ?? goal,
            plan,
          ),
          onDeleteContribution: _deleteTransaction,
          onDeleteContributionPlan: _deleteGoalContributionPlan,
        ),
      ),
    );
  }

  Future<void> _editGoal(SavingsGoal goal) async {
    final storedGoal = _storedGoalById(goal.id) ?? goal;
    final updatedGoal = await showGoalFormSheet(
      context,
      initialGoal: storedGoal,
    );
    if (updatedGoal == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _goalsController.save(updatedGoal),
      'Zapisano cel.',
      errorMapper: _goalError,
    );
  }

  Future<void> _deleteGoal(SavingsGoal goal) async {
    final confirmed = await _confirmDestructiveAction(
      title: 'Usunac cel?',
      message:
          'Cel "${goal.name}" zostanie usuniety razem z planami przyszlych wplat.',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runMutation(
      () async {
        await _goalContributionPlansController.deletePlansForGoal(goal.id);
        await _goalsController.delete(goal);
      },
      'Usunieto cel.',
      errorMapper: _goalError,
    );
  }

  Future<void> _createInvestment() async {
    final investment = await showInvestmentFormSheet(context);
    if (investment == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _investmentsController.save(investment),
      'Dodano lub zaktualizowano pozycje portfela.',
      errorMapper: _investmentError,
    );

    _scheduleInvestmentMarketRefresh(delay: const Duration(milliseconds: 1200));
  }

  Future<void> _refreshInvestmentPrices({
    String? investmentId,
    bool force = false,
    bool rethrowErrors = false,
  }) async {
    await _investmentsController.refreshMarketPrices(
      investmentId: investmentId,
      force: force,
      rethrowErrors: rethrowErrors,
    );
  }

  Future<void> _refreshInvestmentPricesFromAction() async {
    await _runMutation(
      () => _refreshInvestmentPrices(force: true, rethrowErrors: true),
      'Odswiezono kursy.',
      errorMapper: _investmentError,
    );
  }

  void _scheduleInvestmentMarketRefresh({
    String? investmentId,
    Duration delay = const Duration(milliseconds: 350),
    bool force = false,
  }) {
    unawaited(
      Future<void>.delayed(delay, () async {
        if (!mounted) {
          return;
        }

        try {
          await _refreshInvestmentPrices(
            investmentId: investmentId,
            force: force,
            rethrowErrors: force,
          );
        } catch (error) {
          if (!mounted || !force) {
            return;
          }

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_investmentError(error))));
        }
      }),
    );
  }

  Future<void> _openInvestmentDetails(InvestmentHolding investment) {
    if (investment.supportsMarketData) {
      _scheduleInvestmentMarketRefresh(investmentId: investment.id);
    }

    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => InvestmentDetailsScreen(
          userId: widget.userId,
          investmentId: investment.id,
          investmentRepository: widget.investmentRepository,
          listenable: _investmentsController,
          investmentById: _investmentById,
        ),
      ),
    );
  }

  Future<void> _editInvestment(InvestmentHolding investment) async {
    final updatedInvestment = await showInvestmentFormSheet(
      context,
      initialInvestment: investment,
    );
    if (updatedInvestment == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _investmentsController.save(updatedInvestment),
      'Zapisano pozycje portfela.',
      errorMapper: _investmentError,
    );

    if (updatedInvestment.supportsMarketData) {
      _scheduleInvestmentMarketRefresh(
        investmentId: updatedInvestment.id,
        force: true,
      );
    }
  }

  Future<void> _deleteInvestment(InvestmentHolding investment) async {
    final confirmed = await _confirmDestructiveAction(
      title: 'Usunac pozycje?',
      message:
          'Pozycja "${investment.displaySymbol} - ${investment.name}" zostanie usunieta.',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runMutation(
      () => _investmentsController.delete(investment),
      'Usunieto pozycje portfela.',
      errorMapper: _investmentError,
    );
  }

  Future<void> _createTransaction() async {
    final transaction = await showTransactionFormSheet(
      context,
      availableCategories: _categoriesController.categories,
      availableGoals: _goalsController.goals,
    );
    if (transaction == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _transactionsController.save(transaction),
      'Dodano transakcje.',
    );
  }

  Future<void> _editTransaction(FinanceTransaction transaction) async {
    final updated = await showTransactionFormSheet(
      context,
      initialTransaction: transaction,
      availableCategories: _categoriesController.categories,
      availableGoals: _goalsController.goals,
    );
    if (updated == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _transactionsController.save(updated),
      'Zapisano zmiany transakcji.',
    );
  }

  Future<void> _deleteTransaction(FinanceTransaction transaction) async {
    final confirmed = await _confirmDestructiveAction(
      title: 'Usunac transakcje?',
      message: 'Transakcja "${transaction.title}" zostanie usunieta.',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runMutation(
      () => _transactionsController.delete(transaction),
      'Usunieto transakcje.',
    );
  }

  Future<void> _createRecurringIncome() async {
    final plan = await showRecurringIncomeFormSheet(
      context,
      availableCategories: _categoriesController.categories,
    );
    if (plan == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _recurringIncomesController.save(plan),
      'Dodano staly dochod.',
      errorMapper: _recurringIncomeError,
    );
  }

  Future<void> _editRecurringIncome(RecurringIncomePlan plan) async {
    final updatedPlan = await showRecurringIncomeFormSheet(
      context,
      initialPlan: plan,
      availableCategories: _categoriesController.categories,
    );
    if (updatedPlan == null || !mounted) {
      return;
    }

    await _runMutation(
      () => _recurringIncomesController.save(updatedPlan),
      'Zapisano staly dochod.',
      errorMapper: _recurringIncomeError,
    );
  }

  Future<void> _deleteRecurringIncome(RecurringIncomePlan plan) async {
    final confirmed = await _confirmDestructiveAction(
      title: 'Usunac plan dochodu?',
      message:
          'Plan "${plan.name}" zostanie usuniety. Historyczne transakcje pozostana bez zmian.',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runMutation(
      () => _recurringIncomesController.delete(plan),
      'Usunieto plan dochodu.',
      errorMapper: _recurringIncomeError,
    );
  }

  Future<void> _runMutation(
    Future<void> Function() action,
    String successMessage, {
    String Function(Object?) errorMapper = _transactionError,
  }) async {
    try {
      await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMapper(error))));
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMapper(error))));
    }
  }

  Future<bool> _confirmDestructiveAction({
    required String title,
    required String message,
    String confirmLabel = 'Usun',
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DestructiveConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
      ),
    );

    return confirmed ?? false;
  }

  List<FinanceCategory> _categoryMergeCandidates(FinanceCategory category) {
    final candidates =
        _categoriesController.categories
            .where(
              (candidate) =>
                  candidate.id != category.id &&
                  candidate.type == category.type,
            )
            .toList()
          ..sort((left, right) => left.name.compareTo(right.name));
    return candidates;
  }

  int _transactionUsageCount(FinanceCategory category) {
    return _transactionsController.transactions.where((transaction) {
      return transaction.type == category.type &&
          transaction.category == category.name;
    }).length;
  }

  int _budgetUsageCount(FinanceCategory category) {
    if (category.type != TransactionType.expense) {
      return 0;
    }

    return _budgetsController.budgets
        .where((budget) => budget.category == category.name)
        .length;
  }

  int _subscriptionUsageCount(FinanceCategory category) {
    if (category.type != TransactionType.expense) {
      return 0;
    }

    return _subscriptionsController.subscriptions
        .where((subscription) => subscription.category == category.name)
        .length;
  }

  int _recurringIncomeUsageCount(FinanceCategory category) {
    if (category.type != TransactionType.income) {
      return 0;
    }

    return _recurringIncomesController.plans
        .where((plan) => plan.category == category.name)
        .length;
  }

  String _categoryUsageSummary(FinanceCategory category) {
    final parts = <String>['Transakcje ${_transactionUsageCount(category)}'];

    if (category.type == TransactionType.expense) {
      parts.add('Budzety teraz ${_budgetUsageCount(category)}');
      parts.add('Subskrypcje ${_subscriptionUsageCount(category)}');
    } else if (category.type == TransactionType.income) {
      parts.add('Stale dochody ${_recurringIncomeUsageCount(category)}');
    }

    return parts.join(' | ');
  }

  String _categoryTypeLabel(TransactionType type) {
    return switch (type) {
      TransactionType.income => 'Przychod',
      TransactionType.transfer => 'Transfer',
      TransactionType.expense => 'Wydatek',
    };
  }
}

class _TransactionMetricsSnapshot {
  const _TransactionMetricsSnapshot({
    required this.incomeTotal,
    required this.expenseTotal,
    required this.transferTotal,
    required this.goalLinkedCount,
    required this.recurringIncomeCount,
  });

  final double incomeTotal;
  final double expenseTotal;
  final double transferTotal;
  final int goalLinkedCount;
  final int recurringIncomeCount;

  double get netImpact => incomeTotal - expenseTotal - transferTotal;
}

class _TransactionDayGroup {
  _TransactionDayGroup({required this.day, required this.transactions});

  final DateTime day;
  final List<FinanceTransaction> transactions;
}

class _TransactionExpenseTrendSnapshot {
  const _TransactionExpenseTrendSnapshot({
    required this.points,
    required this.subtitle,
    required this.totalExpense,
    required this.activeDayCount,
    required this.averageActiveDayExpense,
    required this.peakPoint,
  });

  final List<TransactionExpenseTrendPoint> points;
  final String subtitle;
  final double totalExpense;
  final int activeDayCount;
  final double averageActiveDayExpense;
  final TransactionExpenseTrendPoint? peakPoint;

  bool get hasExpenseData => points.any((point) => point.expenseTotal > 0);
}
