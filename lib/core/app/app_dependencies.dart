import '../../features/budgets/data/firestore_budget_repository.dart';
import '../../features/budgets/domain/budget_repository.dart';
import '../../features/categories/data/firestore_category_repository.dart';
import '../../features/categories/domain/category_repository.dart';
import '../../features/export/data/share_plus_export_share_gateway.dart';
import '../../features/export/domain/export_share_gateway.dart';
import '../../features/auth/data/firebase_auth_repository.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/goal_contribution_plans/data/firestore_goal_contribution_plan_repository.dart';
import '../../features/goal_contribution_plans/domain/goal_contribution_plan_repository.dart';
import '../../features/goals/data/firestore_goal_repository.dart';
import '../../features/goals/domain/goal_repository.dart';
import '../../features/investments/data/firebase_functions_investment_quote_service.dart';
import '../../features/investments/data/firestore_investment_repository.dart';
import '../../features/investments/domain/investment_repository.dart';
import '../../features/investments/domain/investment_quote_service.dart';
import '../../features/monthly_reports/data/firestore_monthly_report_repository.dart';
import '../../features/monthly_reports/domain/monthly_report_repository.dart';
import '../../features/portfolio_snapshots/data/firestore_portfolio_snapshot_repository.dart';
import '../../features/portfolio_snapshots/domain/portfolio_snapshot_repository.dart';
import '../../features/profile/data/firestore_user_profile_repository.dart';
import '../../features/profile/domain/user_profile_repository.dart';
import '../../features/recurring_incomes/data/firestore_recurring_income_repository.dart';
import '../../features/recurring_incomes/domain/recurring_income_repository.dart';
import '../../features/report_archives/data/firebase_report_archive_repository.dart';
import '../../features/report_archives/domain/report_archive_repository.dart';
import '../../features/subscriptions/data/firestore_subscription_repository.dart';
import '../../features/subscriptions/domain/subscription_repository.dart';
import '../../features/transaction_import/data/shared_preferences_import_category_rule_repository.dart';
import '../../features/transaction_import/data/shared_preferences_transaction_import_history_repository.dart';
import '../../features/transaction_import/domain/import_category_rule_repository.dart';
import '../../features/transaction_import/domain/transaction_import_history_repository.dart';
import '../../features/transactions/data/firestore_transaction_repository.dart';
import '../../features/transactions/domain/transaction_repository.dart';
import '../firebase/firebase_bootstrap.dart';
import 'theme_preferences_repository.dart';

class AppDependencies {
  const AppDependencies({
    this.bootstrap = FirebaseBootstrap.initialize,
    this.authRepository = const FirebaseAuthRepository(),
    this.budgetRepository = const FirestoreBudgetRepository(),
    this.categoryRepository = const FirestoreCategoryRepository(),
    this.exportShareGateway = const SharePlusExportShareGateway(),
    this.goalContributionPlanRepository =
        const FirestoreGoalContributionPlanRepository(),
    this.goalRepository = const FirestoreGoalRepository(),
    this.investmentRepository = const FirestoreInvestmentRepository(),
    this.investmentQuoteService =
        const FirebaseFunctionsInvestmentQuoteService(),
    this.monthlyReportRepository = const FirestoreMonthlyReportRepository(),
    this.portfolioSnapshotRepository =
        const FirestorePortfolioSnapshotRepository(),
    this.reportArchiveRepository = const FirebaseReportArchiveRepository(),
    this.recurringIncomeRepository = const FirestoreRecurringIncomeRepository(),
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

  final Future<FirebaseBootstrapResult> Function() bootstrap;
  final AuthRepository authRepository;
  final BudgetRepository budgetRepository;
  final CategoryRepository categoryRepository;
  final ExportShareGateway exportShareGateway;
  final GoalContributionPlanRepository goalContributionPlanRepository;
  final GoalRepository goalRepository;
  final InvestmentRepository investmentRepository;
  final InvestmentQuoteService investmentQuoteService;
  final MonthlyReportRepository monthlyReportRepository;
  final PortfolioSnapshotRepository portfolioSnapshotRepository;
  final ReportArchiveRepository reportArchiveRepository;
  final RecurringIncomeRepository recurringIncomeRepository;
  final SubscriptionRepository subscriptionRepository;
  final ImportCategoryRuleRepository importCategoryRuleRepository;
  final TransactionImportHistoryRepository transactionImportHistoryRepository;
  final ThemePreferencesRepository themePreferencesRepository;
  final TransactionRepository transactionRepository;
  final UserProfileRepository userProfileRepository;
}
