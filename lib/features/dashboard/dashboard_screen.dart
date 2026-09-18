import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../auth/data/firebase_auth_repository.dart';
import '../auth/domain/account_security_snapshot.dart';
import '../auth/domain/auth_repository.dart';
import '../auth/presentation/account_security_sheet.dart';
import '../../models/finance_models.dart';
import 'dashboard_analytics.dart';
import '../budgets/application/budgets_controller.dart';
import '../budgets/data/firestore_budget_repository.dart';
import '../budgets/domain/budget_repository.dart';
import '../budgets/presentation/budget_form_sheet.dart';
import '../categories/application/categories_controller.dart';
import '../categories/data/firestore_category_repository.dart';
import '../categories/domain/category_mutation_exception.dart';
import '../categories/domain/category_repository.dart';
import '../categories/presentation/category_form_sheet.dart';
import '../categories/presentation/category_merge_sheet.dart';
import '../export/application/finance_export_service.dart';
import '../export/data/share_plus_export_share_gateway.dart';
import '../export/domain/export_share_gateway.dart';
import '../goal_contribution_plans/application/goal_contribution_plans_controller.dart';
import '../goal_contribution_plans/data/memory_goal_contribution_plan_repository.dart';
import '../goal_contribution_plans/domain/goal_contribution_plan_repository.dart';
import '../goal_contribution_plans/presentation/goal_contribution_plan_form_sheet.dart';
import '../goals/application/goals_controller.dart';
import '../goals/data/firestore_goal_repository.dart';
import '../goals/domain/goal_repository.dart';
import '../goals/presentation/goal_details_screen.dart';
import '../goals/presentation/goal_form_sheet.dart';
import '../investments/application/investments_controller.dart';
import '../investments/data/firebase_functions_investment_quote_service.dart';
import '../investments/data/firestore_investment_repository.dart';
import '../investments/domain/investment_quote_service.dart';
import '../investments/domain/investment_repository.dart';
import '../investments/presentation/investment_details_screen.dart';
import '../investments/presentation/investment_form_sheet.dart';
import '../monthly_reports/application/monthly_report_builder.dart';
import '../monthly_reports/application/monthly_report_comparison.dart';
import '../monthly_reports/application/monthly_reports_controller.dart';
import '../monthly_reports/data/firestore_monthly_report_repository.dart';
import '../monthly_reports/domain/monthly_report_mutation_exception.dart';
import '../monthly_reports/domain/monthly_report_repository.dart';
import '../portfolio_snapshots/application/portfolio_snapshots_controller.dart';
import '../portfolio_snapshots/domain/portfolio_snapshot_repository.dart';
import '../../core/app/theme_preferences_repository.dart';
import '../../core/formatting/display_number_formatter.dart';
import '../../core/platform/external_download_launcher.dart';
import '../../core/presentation/app_bottom_sheet.dart';
import '../../core/validation/input_validation_exception.dart';
import '../profile/application/user_profile_controller.dart';
import '../profile/data/firestore_user_profile_repository.dart';
import '../profile/domain/user_profile_repository.dart';
import '../profile/presentation/user_profile_form_sheet.dart';
import '../report_archives/application/report_archives_controller.dart';
import '../report_archives/data/firebase_report_archive_repository.dart';
import '../report_archives/domain/report_archive_repository.dart';
import '../recurring_incomes/application/recurring_incomes_controller.dart';
import '../recurring_incomes/data/memory_recurring_income_repository.dart';
import '../recurring_incomes/domain/recurring_income_repository.dart';
import '../recurring_incomes/presentation/recurring_income_form_sheet.dart';
import '../subscription_import/application/subscription_csv_import_service.dart';
import '../subscription_import/domain/subscription_csv_import_preview.dart';
import '../subscription_import/domain/subscription_csv_source_data.dart';
import '../subscription_import/presentation/subscription_csv_column_mapping_sheet.dart';
import '../subscription_import/presentation/subscription_csv_import_preview_sheet.dart';
import '../subscriptions/application/subscriptions_controller.dart';
import '../subscriptions/data/firestore_subscription_repository.dart';
import '../subscriptions/domain/subscription_repository.dart';
import '../subscriptions/presentation/subscription_form_sheet.dart';
import '../transaction_import/application/transaction_csv_import_service.dart';
import '../transaction_import/data/shared_preferences_import_category_rule_repository.dart';
import '../transaction_import/data/shared_preferences_transaction_import_history_repository.dart';
import '../transaction_import/domain/import_category_rule.dart';
import '../transaction_import/domain/import_category_rule_repository.dart';
import '../transaction_import/domain/transaction_csv_import_preview.dart';
import '../transaction_import/domain/transaction_csv_source_data.dart';
import '../transaction_import/domain/transaction_import_history_entry.dart';
import '../transaction_import/domain/transaction_import_history_repository.dart';
import '../transaction_import/presentation/import_category_rules_sheet.dart';
import '../transaction_import/presentation/transaction_csv_column_mapping_sheet.dart';
import '../transaction_import/presentation/transaction_csv_import_preview_sheet.dart';
import '../transaction_import/presentation/transaction_import_history_sheet.dart';
import '../transactions/application/transactions_controller.dart';
import '../transactions/data/firestore_transaction_repository.dart';
import '../transactions/domain/transaction_repository.dart';
import '../transactions/presentation/transaction_form_sheet.dart';

part 'dashboard_screen_content.dart';
part 'dashboard_screen_widgets.dart';

enum DashboardSection {
  overview,
  transactions,
  budgets,
  goals,
  investments,
  subscriptions,
  reports,
  categories,
  account,
}

enum _AccountWorkspaceSection { profile, access, data, appearance }

const _compactPrimarySections = <DashboardSection>[
  DashboardSection.overview,
  DashboardSection.transactions,
  DashboardSection.budgets,
  DashboardSection.goals,
];

const _dashboardSectionGroups = <_DashboardSectionGroup>[
  _DashboardSectionGroup(
    title: 'Start',
    sections: <DashboardSection>[DashboardSection.overview],
  ),
  _DashboardSectionGroup(
    title: 'Finanse',
    sections: <DashboardSection>[
      DashboardSection.transactions,
      DashboardSection.budgets,
      DashboardSection.goals,
      DashboardSection.investments,
      DashboardSection.subscriptions,
    ],
  ),
  _DashboardSectionGroup(
    title: 'Dane',
    sections: <DashboardSection>[
      DashboardSection.reports,
      DashboardSection.categories,
    ],
  ),
  _DashboardSectionGroup(
    title: 'Konto',
    sections: <DashboardSection>[DashboardSection.account],
  ),
];

class _DashboardSectionGroup {
  const _DashboardSectionGroup({required this.title, required this.sections});

  final String title;
  final List<DashboardSection> sections;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.userId,
    required this.themeMode,
    required this.onThemeModeChanged,
    this.authRepository = const FirebaseAuthRepository(),
    this.userName,
    this.userEmail,
    this.userPhotoUrl,
    this.onSignOut,
    this.budgetRepository = const FirestoreBudgetRepository(),
    this.categoryRepository = const FirestoreCategoryRepository(),
    this.exportShareGateway = const SharePlusExportShareGateway(),
    this.goalContributionPlanRepository =
        const MemoryGoalContributionPlanRepository(),
    this.goalRepository = const FirestoreGoalRepository(),
    this.investmentRepository = const FirestoreInvestmentRepository(),
    this.investmentQuoteService =
        const FirebaseFunctionsInvestmentQuoteService(),
    this.monthlyReportRepository = const FirestoreMonthlyReportRepository(),
    this.dailyPortfolioSnapshotRepository,
    this.reportArchiveRepository = const FirebaseReportArchiveRepository(),
    this.recurringIncomeRepository = const MemoryRecurringIncomeRepository(),
    this.subscriptionRepository = const FirestoreSubscriptionRepository(),
    this.importCategoryRuleRepository =
        const SharedPreferencesImportCategoryRuleRepository(),
    this.transactionImportHistoryRepository =
        const SharedPreferencesTransactionImportHistoryRepository(),
    this.themePreferencesRepository =
        const SharedPreferencesThemePreferencesRepository(),
    this.transactionRepository = const FirestoreTransactionRepository(),
    this.userProfileRepository = const FirestoreUserProfileRepository(),
  });

  final String userId;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final AuthRepository authRepository;
  final String? userName;
  final String? userEmail;
  final String? userPhotoUrl;
  final Future<void> Function()? onSignOut;
  final BudgetRepository budgetRepository;
  final CategoryRepository categoryRepository;
  final ExportShareGateway exportShareGateway;
  final GoalContributionPlanRepository goalContributionPlanRepository;
  final GoalRepository goalRepository;
  final InvestmentRepository investmentRepository;
  final InvestmentQuoteService investmentQuoteService;
  final MonthlyReportRepository monthlyReportRepository;
  final PortfolioSnapshotRepository? dailyPortfolioSnapshotRepository;
  final ReportArchiveRepository reportArchiveRepository;
  final RecurringIncomeRepository recurringIncomeRepository;
  final SubscriptionRepository subscriptionRepository;
  final ImportCategoryRuleRepository importCategoryRuleRepository;
  final TransactionImportHistoryRepository transactionImportHistoryRepository;
  final ThemePreferencesRepository themePreferencesRepository;
  final TransactionRepository transactionRepository;
  final UserProfileRepository userProfileRepository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const FinanceExportService _exportService = FinanceExportService();
  static const SubscriptionCsvImportService _subscriptionImportService =
      SubscriptionCsvImportService();
  static const TransactionCsvImportService _transactionImportService =
      TransactionCsvImportService();

  late BudgetsController _budgetsController;
  late CategoriesController _categoriesController;
  late GoalContributionPlansController _goalContributionPlansController;
  late GoalsController _goalsController;
  late InvestmentsController _investmentsController;
  late MonthlyReportsController _monthlyReportsController;
  PortfolioSnapshotsController? _portfolioSnapshotsController;
  late RecurringIncomesController _recurringIncomesController;
  late ReportArchivesController _reportArchivesController;
  late final ScrollController _sectionScrollController;
  late SubscriptionsController _subscriptionsController;
  late TransactionsController _transactionsController;
  late UserProfileController _userProfileController;
  late final TextEditingController _searchController;
  final Map<String, double> _sectionScrollOffsets = <String, double>{};
  AccountSecuritySnapshot? _accountSecuritySnapshot;
  Object? _accountSecurityError;
  bool _isAccountSecurityLoading = false;
  int _accountSecurityRequestId = 0;
  DashboardSection _selectedSection = DashboardSection.overview;
  _AccountWorkspaceSection _selectedAccountWorkspaceSection =
      _AccountWorkspaceSection.profile;
  int _overviewTrendMonths = 6;
  int _investmentTrendMonths = 6;
  bool? _sidebarCollapsedOverride;

  @override
  void initState() {
    super.initState();
    _budgetsController = _buildBudgetsController();
    _categoriesController = _buildCategoriesController();
    _goalContributionPlansController = _buildGoalContributionPlansController();
    _goalsController = _buildGoalsController();
    _investmentsController = _buildInvestmentsController();
    _monthlyReportsController = _buildMonthlyReportsController();
    _portfolioSnapshotsController = _buildPortfolioSnapshotsController();
    _recurringIncomesController = _buildRecurringIncomesController();
    _reportArchivesController = _buildReportArchivesController();
    _subscriptionsController = _buildSubscriptionsController();
    _transactionsController = _buildTransactionsController();
    _userProfileController = _buildUserProfileController();
    _sectionScrollController = ScrollController()
      ..addListener(_rememberCurrentScrollOffset);
    _searchController = TextEditingController();
    _restoreSidebarPreference();
    _loadAccountSecuritySnapshot();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final userChanged = oldWidget.userId != widget.userId;
    if (userChanged || oldWidget.budgetRepository != widget.budgetRepository) {
      _budgetsController.dispose();
      _budgetsController = _buildBudgetsController();
    }

    if (userChanged ||
        oldWidget.categoryRepository != widget.categoryRepository) {
      _categoriesController.dispose();
      _categoriesController = _buildCategoriesController();
    }

    if (userChanged ||
        oldWidget.goalContributionPlanRepository !=
            widget.goalContributionPlanRepository ||
        oldWidget.transactionRepository != widget.transactionRepository) {
      _goalContributionPlansController.dispose();
      _goalContributionPlansController =
          _buildGoalContributionPlansController();
    }

    if (userChanged || oldWidget.goalRepository != widget.goalRepository) {
      _goalsController.dispose();
      _goalsController = _buildGoalsController();
    }

    if (userChanged ||
        oldWidget.investmentRepository != widget.investmentRepository ||
        oldWidget.investmentQuoteService != widget.investmentQuoteService) {
      _investmentsController.dispose();
      _investmentsController = _buildInvestmentsController();
    }

    if (userChanged ||
        oldWidget.monthlyReportRepository != widget.monthlyReportRepository) {
      _monthlyReportsController.dispose();
      _monthlyReportsController = _buildMonthlyReportsController();
    }

    if (userChanged ||
        oldWidget.dailyPortfolioSnapshotRepository !=
            widget.dailyPortfolioSnapshotRepository) {
      _portfolioSnapshotsController?.dispose();
      _portfolioSnapshotsController = _buildPortfolioSnapshotsController();
    }

    if (userChanged ||
        oldWidget.recurringIncomeRepository !=
            widget.recurringIncomeRepository ||
        oldWidget.transactionRepository != widget.transactionRepository) {
      _recurringIncomesController.dispose();
      _recurringIncomesController = _buildRecurringIncomesController();
    }

    if (userChanged ||
        oldWidget.reportArchiveRepository != widget.reportArchiveRepository) {
      _reportArchivesController.dispose();
      _reportArchivesController = _buildReportArchivesController();
    }

    if (userChanged ||
        oldWidget.subscriptionRepository != widget.subscriptionRepository) {
      _subscriptionsController.dispose();
      _subscriptionsController = _buildSubscriptionsController();
    }

    if (userChanged ||
        oldWidget.transactionRepository != widget.transactionRepository) {
      _transactionsController.dispose();
      _transactionsController = _buildTransactionsController();
    }

    if (userChanged ||
        oldWidget.userProfileRepository != widget.userProfileRepository ||
        oldWidget.userName != widget.userName ||
        oldWidget.userEmail != widget.userEmail ||
        oldWidget.userPhotoUrl != widget.userPhotoUrl) {
      _userProfileController.dispose();
      _userProfileController = _buildUserProfileController();
    }

    if (userChanged || oldWidget.authRepository != widget.authRepository) {
      _accountSecuritySnapshot = null;
      _accountSecurityError = null;
      _loadAccountSecuritySnapshot();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _budgetsController.dispose();
    _categoriesController.dispose();
    _goalContributionPlansController.dispose();
    _goalsController.dispose();
    _investmentsController.dispose();
    _monthlyReportsController.dispose();
    _portfolioSnapshotsController?.dispose();
    _recurringIncomesController.dispose();
    _reportArchivesController.dispose();
    _subscriptionsController.dispose();
    _transactionsController.dispose();
    _userProfileController.dispose();
    _sectionScrollController
      ..removeListener(_rememberCurrentScrollOffset)
      ..dispose();
    super.dispose();
  }

  Future<void> _restoreSidebarPreference() async {
    bool? savedValue;
    try {
      savedValue = await widget.themePreferencesRepository
          .loadSidebarCollapsed();
    } catch (_) {
      savedValue = null;
    }

    if (!mounted || savedValue == null) {
      return;
    }

    setState(() {
      _sidebarCollapsedOverride = savedValue;
    });
  }

  void _setSidebarCollapsed(bool value) {
    if (_sidebarCollapsedOverride == value) {
      return;
    }

    setState(() {
      _sidebarCollapsedOverride = value;
    });

    widget.themePreferencesRepository
        .saveSidebarCollapsed(value)
        .catchError((_) {});
  }

  Future<void> _loadAccountSecuritySnapshot() async {
    final requestId = ++_accountSecurityRequestId;
    setState(() {
      _isAccountSecurityLoading = true;
      _accountSecurityError = null;
    });

    try {
      final snapshot = await widget.authRepository.getAccountSecuritySnapshot();
      if (!mounted || requestId != _accountSecurityRequestId) {
        return;
      }

      setState(() {
        _accountSecuritySnapshot = snapshot;
        _accountSecurityError = null;
        _isAccountSecurityLoading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _accountSecurityRequestId) {
        return;
      }

      setState(() {
        _accountSecurityError = error;
        _isAccountSecurityLoading = false;
      });
    }
  }

  void _setAccountSecuritySnapshot(AccountSecuritySnapshot snapshot) {
    setState(() {
      _accountSecuritySnapshot = snapshot;
      _accountSecurityError = null;
      _isAccountSecurityLoading = false;
    });
  }

  void _setAccountSecurityError(Object error) {
    setState(() {
      _accountSecurityError = error;
      _isAccountSecurityLoading = false;
    });
  }

  void _rememberCurrentScrollOffset() {
    if (!_sectionScrollController.hasClients) {
      return;
    }

    _sectionScrollOffsets[_selectedScrollScopeKey] =
        _sectionScrollController.offset;
  }

  void _restoreScrollOffsetForSelectedSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sectionScrollController.hasClients) {
        return;
      }

      final savedOffset = _sectionScrollOffsets[_selectedScrollScopeKey] ?? 0;
      final targetOffset = math.min(
        savedOffset,
        _sectionScrollController.position.maxScrollExtent,
      );

      if ((_sectionScrollController.offset - targetOffset).abs() < 1) {
        return;
      }

      _sectionScrollController.jumpTo(targetOffset);
    });
  }

  String get _selectedScrollScopeKey {
    if (_selectedSection != DashboardSection.account) {
      return _selectedSection.name;
    }

    return '${_selectedSection.name}-${_selectedAccountWorkspaceSection.name}';
  }

  String get _selectedContentTransitionKey => _selectedScrollScopeKey;

  BudgetsController _buildBudgetsController() {
    return BudgetsController(
      repository: widget.budgetRepository,
      userId: widget.userId,
    );
  }

  CategoriesController _buildCategoriesController() {
    return CategoriesController(
      repository: widget.categoryRepository,
      userId: widget.userId,
    );
  }

  GoalsController _buildGoalsController() {
    return GoalsController(
      repository: widget.goalRepository,
      userId: widget.userId,
    );
  }

  GoalContributionPlansController _buildGoalContributionPlansController() {
    return GoalContributionPlansController(
      repository: widget.goalContributionPlanRepository,
      transactionRepository: widget.transactionRepository,
      userId: widget.userId,
    );
  }

  InvestmentsController _buildInvestmentsController() {
    return InvestmentsController(
      repository: widget.investmentRepository,
      quoteService: widget.investmentQuoteService,
      userId: widget.userId,
    );
  }

  MonthlyReportsController _buildMonthlyReportsController() {
    return MonthlyReportsController(
      repository: widget.monthlyReportRepository,
      userId: widget.userId,
    );
  }

  PortfolioSnapshotsController? _buildPortfolioSnapshotsController() {
    final repository = widget.dailyPortfolioSnapshotRepository;
    if (repository == null) {
      return null;
    }

    return PortfolioSnapshotsController(
      repository: repository,
      userId: widget.userId,
    );
  }

  RecurringIncomesController _buildRecurringIncomesController() {
    return RecurringIncomesController(
      repository: widget.recurringIncomeRepository,
      transactionRepository: widget.transactionRepository,
      userId: widget.userId,
    );
  }

  ReportArchivesController _buildReportArchivesController() {
    return ReportArchivesController(
      repository: widget.reportArchiveRepository,
      userId: widget.userId,
    );
  }

  SubscriptionsController _buildSubscriptionsController() {
    return SubscriptionsController(
      repository: widget.subscriptionRepository,
      userId: widget.userId,
    );
  }

  TransactionsController _buildTransactionsController() {
    return TransactionsController(
      repository: widget.transactionRepository,
      userId: widget.userId,
    );
  }

  UserProfileController _buildUserProfileController() {
    return UserProfileController(
      repository: widget.userProfileRepository,
      userId: widget.userId,
      fallbackDisplayName: widget.userName ?? '',
      fallbackEmail: widget.userEmail ?? '',
      fallbackPhotoUrl: widget.userPhotoUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _transactionsController,
        _budgetsController,
        _categoriesController,
        _goalContributionPlansController,
        _goalsController,
        _investmentsController,
        _monthlyReportsController,
        ...?_portfolioSnapshotsController == null
            ? null
            : [_portfolioSnapshotsController!],
        _recurringIncomesController,
        _reportArchivesController,
        _subscriptionsController,
        _userProfileController,
      ]),
      builder: (context, _) {
        final transactions = _transactionsController.transactions;
        final goalContributionHistory = _goalContributionHistory(transactions);
        final goals = _goalSnapshots(goalContributionHistory);
        final investments = _investmentsController.investments;
        final visibleTransactions = _transactionsController.visibleTransactions;
        final budgets = _budgetSnapshots(transactions);
        final categories = _categoriesController.categories;
        final monthlyReports = _monthlyReportsController.reports;
        final dailyPortfolioSnapshots =
            _portfolioSnapshotsController?.snapshots ?? const [];
        final archives = _reportArchivesController.archives;
        final profile = _userProfileController.profile;
        final displayName = _userProfileController.displayName;
        final email = _userProfileController.email;
        final recurringIncomes = _recurringIncomesController.plans;
        final subscriptions = _subscriptionsController.subscriptions;
        unawaited(
          _recurringIncomesController.syncTransactions(
            _transactionsController.transactions,
          ),
        );
        unawaited(
          _goalContributionPlansController.syncTransactions(
            transactions: _transactionsController.transactions,
            goals: goals,
          ),
        );
        final analytics = DashboardAnalyticsSnapshot.fromData(
          transactions: transactions,
          investments: investments,
          goals: goals,
          referenceMonth: _budgetsController.selectedPeriod,
          months: _overviewTrendMonths,
          accountCreatedAt: profile?.createdAt,
        );
        final alerts = buildDashboardAlerts(
          referenceMonth: _budgetsController.selectedPeriod,
          budgets: budgets,
          goals: goals,
          subscriptions: subscriptions,
          investmentAnalytics: analytics.investmentAnalytics,
        );
        final dashboard = DashboardSnapshot(
          userName: displayName,
          transactions: transactions,
          budgets: budgets,
          goals: goals,
          investments: investments,
        );
        final screenWidth = MediaQuery.of(context).size.width;
        final compact = screenWidth < 980;
        final sidebarCollapsed = !compact
            ? (_sidebarCollapsedOverride ?? screenWidth < 1260)
            : false;
        final sidebarWidth = sidebarCollapsed ? 96.0 : 280.0;
        final isInitialLoad =
            _transactionsController.isLoading && transactions.isEmpty;
        final isBudgetLoad =
            _budgetsController.isLoading && _budgetsController.budgets.isEmpty;
        final isCategoryLoad =
            _categoriesController.isLoading && categories.isEmpty;
        final isGoalLoad = _goalsController.isLoading && goals.isEmpty;
        final isInvestmentLoad =
            _investmentsController.isLoading && investments.isEmpty;
        final isMonthlyReportLoad =
            _monthlyReportsController.isLoading && monthlyReports.isEmpty;
        final isRecurringIncomeLoad =
            _recurringIncomesController.isLoading && recurringIncomes.isEmpty;
        final isArchiveLoad =
            _reportArchivesController.isLoading && archives.isEmpty;
        final isProfileLoad =
            _userProfileController.isLoading && profile == null;
        final isSubscriptionLoad =
            _subscriptionsController.isLoading && subscriptions.isEmpty;
        final sectionVisual = _sectionVisual(_selectedSection);

        final contentChildren = [
          ..._buildErrorBanners(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_selectedContentTransitionKey),
              child: _buildSectionContent(
                compact: compact,
                profile: profile,
                categories: categories,
                dashboard: dashboard,
                budgets: budgets,
                goalContributionHistory: goalContributionHistory,
                archives: archives,
                monthlyReports: monthlyReports,
                dailyPortfolioSnapshots: dailyPortfolioSnapshots,
                recurringIncomes: recurringIncomes,
                subscriptions: subscriptions,
                analytics: analytics,
                alerts: alerts,
                isInitialLoad: isInitialLoad,
                isProfileLoad: isProfileLoad,
                isBudgetLoad: isBudgetLoad,
                isCategoryLoad: isCategoryLoad,
                isGoalLoad: isGoalLoad,
                isArchiveLoad: isArchiveLoad,
                isInvestmentLoad: isInvestmentLoad,
                isMonthlyReportLoad: isMonthlyReportLoad,
                isRecurringIncomeLoad: isRecurringIncomeLoad,
                isSubscriptionLoad: isSubscriptionLoad,
                visibleTransactions: visibleTransactions,
                email: email,
              ),
            ),
          ),
        ];

        return Scaffold(
          floatingActionButton: _sectionActionButton(),
          bottomNavigationBar: compact
              ? _CompactNavigationBar(
                  selectedSection: _selectedSection,
                  onSectionSelected: _selectSection,
                  onMorePressed: () => _showCompactSectionsSheet(
                    displayName: displayName,
                    email: email,
                  ),
                )
              : null,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, compact ? 12 : 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!compact) ...[
                    SizedBox(
                      width: sidebarWidth,
                      child: _SidebarNavigation(
                        displayName: displayName,
                        email: email,
                        isCollapsed: sidebarCollapsed,
                        selectedSection: _selectedSection,
                        themeMode: widget.themeMode,
                        onSectionSelected: _selectSection,
                        onThemeModeChanged: widget.onThemeModeChanged,
                        onToggleCollapsed: () {
                          _setSidebarCollapsed(!sidebarCollapsed);
                        },
                        onSignOut: widget.onSignOut,
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ContentTopBar(
                          compact: compact,
                          title: _sectionTitle(_selectedSection),
                          subtitle: _sectionSubtitle(_selectedSection),
                          visual: sectionVisual,
                          onMenuPressed: compact
                              ? () => _showCompactSectionsSheet(
                                  displayName: displayName,
                                  email: email,
                                )
                              : null,
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: SingleChildScrollView(
                            key: ValueKey(
                              'section-scroll-$_selectedScrollScopeKey',
                            ),
                            controller: _sectionScrollController,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1120,
                                ),
                                child: _SectionSurfaceFrame(
                                  visual: sectionVisual,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: contentChildren,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectSection(DashboardSection section) {
    if (_selectedSection == section) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    _rememberCurrentScrollOffset();

    setState(() {
      _selectedSection = section;
    });

    _restoreScrollOffsetForSelectedSection();

    if (section == DashboardSection.investments) {
      _scheduleInvestmentMarketRefresh();
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _selectAccountWorkspaceSection(_AccountWorkspaceSection section) {
    if (_selectedAccountWorkspaceSection == section) {
      return;
    }

    _rememberCurrentScrollOffset();

    setState(() {
      _selectedAccountWorkspaceSection = section;
    });

    _restoreScrollOffsetForSelectedSection();
  }

  void _setOverviewTrendMonths(int months) {
    if (_overviewTrendMonths == months) {
      return;
    }

    setState(() {
      _overviewTrendMonths = months;
    });
  }

  void _setInvestmentTrendMonths(int months) {
    if (_investmentTrendMonths == months) {
      return;
    }

    setState(() {
      _investmentTrendMonths = months;
    });
  }
}
