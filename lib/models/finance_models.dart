enum TransactionType { income, expense, transfer }

enum InvestmentAssetType { stock, etf, bond, fund, crypto, other }

enum SubscriptionBillingCycle { monthly, quarterly, yearly }

enum GoalContributionInterval { monthly, quarterly, yearly }

enum ReportArchiveFormat { csv, pdf }

const _nullableFieldNotProvided = Object();

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.customPhotoUrl,
    required this.createdAt,
    required this.lastSignInAt,
    required this.updatedAt,
  });

  final String userId;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? customPhotoUrl;
  final DateTime createdAt;
  final DateTime lastSignInAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? userId,
    String? displayName,
    String? email,
    Object? photoUrl = _nullableFieldNotProvided,
    Object? customPhotoUrl = _nullableFieldNotProvided,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: identical(photoUrl, _nullableFieldNotProvided)
          ? this.photoUrl
          : photoUrl as String?,
      customPhotoUrl: identical(customPhotoUrl, _nullableFieldNotProvided)
          ? this.customPhotoUrl
          : customPhotoUrl as String?,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FinanceCategory {
  const FinanceCategory({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final TransactionType type;

  bool get isPersisted => id.isNotEmpty;

  FinanceCategory copyWith({String? id, String? name, TransactionType? type}) {
    return FinanceCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }
}

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    this.goalId,
    this.goalContributionPlanId,
    this.recurringIncomeId,
    this.note,
  });

  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? goalId;
  final String? goalContributionPlanId;
  final String? recurringIncomeId;
  final String? note;

  bool get isPersisted => id.isNotEmpty;

  FinanceTransaction copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    DateTime? date,
    TransactionType? type,
    String? goalId,
    Object? goalContributionPlanId = _nullableFieldNotProvided,
    Object? recurringIncomeId = _nullableFieldNotProvided,
    String? note,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      goalId: goalId ?? this.goalId,
      goalContributionPlanId:
          identical(goalContributionPlanId, _nullableFieldNotProvided)
          ? this.goalContributionPlanId
          : goalContributionPlanId as String?,
      recurringIncomeId: identical(recurringIncomeId, _nullableFieldNotProvided)
          ? this.recurringIncomeId
          : recurringIncomeId as String?,
      note: note ?? this.note,
    );
  }
}

class RecurringIncomePlan {
  const RecurringIncomePlan({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.payday,
    required this.startDate,
    required this.isActive,
    this.lastGeneratedMonthKey,
    this.note,
  });

  final String id;
  final String name;
  final String category;
  final double amount;
  final int payday;
  final DateTime startDate;
  final bool isActive;
  final String? lastGeneratedMonthKey;
  final String? note;

  bool get isPersisted => id.isNotEmpty;

  DateTime scheduledDateForMonth(DateTime monthStart) {
    final normalizedMonth = DateTime(monthStart.year, monthStart.month, 1);
    final lastDayOfMonth = DateTime(
      normalizedMonth.year,
      normalizedMonth.month + 1,
      0,
    ).day;
    final clampedPayday = payday.clamp(1, lastDayOfMonth);
    return DateTime(normalizedMonth.year, normalizedMonth.month, clampedPayday);
  }

  RecurringIncomePlan copyWith({
    String? id,
    String? name,
    String? category,
    double? amount,
    int? payday,
    DateTime? startDate,
    bool? isActive,
    Object? lastGeneratedMonthKey = _nullableFieldNotProvided,
    String? note,
  }) {
    return RecurringIncomePlan(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      payday: payday ?? this.payday,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
      lastGeneratedMonthKey:
          identical(lastGeneratedMonthKey, _nullableFieldNotProvided)
          ? this.lastGeneratedMonthKey
          : lastGeneratedMonthKey as String?,
      note: note ?? this.note,
    );
  }
}

class GoalContributionPlan {
  const GoalContributionPlan({
    required this.id,
    required this.goalId,
    required this.name,
    required this.amount,
    required this.interval,
    required this.dayOfMonth,
    required this.startDate,
    required this.isActive,
    this.lastGeneratedPeriodKey,
    this.note,
  });

  final String id;
  final String goalId;
  final String name;
  final double amount;
  final GoalContributionInterval interval;
  final int dayOfMonth;
  final DateTime startDate;
  final bool isActive;
  final String? lastGeneratedPeriodKey;
  final String? note;

  bool get isPersisted => id.isNotEmpty;

  int get intervalMonthCount => switch (interval) {
    GoalContributionInterval.monthly => 1,
    GoalContributionInterval.quarterly => 3,
    GoalContributionInterval.yearly => 12,
  };

  double get monthlyEquivalentAmount => amount / intervalMonthCount;

  DateTime scheduledDateForPeriod(DateTime periodStart) {
    final normalizedPeriod = DateTime(periodStart.year, periodStart.month, 1);
    final lastDayOfMonth = DateTime(
      normalizedPeriod.year,
      normalizedPeriod.month + 1,
      0,
    ).day;
    final clampedDayOfMonth = dayOfMonth.clamp(1, lastDayOfMonth);
    return DateTime(
      normalizedPeriod.year,
      normalizedPeriod.month,
      clampedDayOfMonth,
    );
  }

  GoalContributionPlan copyWith({
    String? id,
    String? goalId,
    String? name,
    double? amount,
    GoalContributionInterval? interval,
    int? dayOfMonth,
    DateTime? startDate,
    bool? isActive,
    Object? lastGeneratedPeriodKey = _nullableFieldNotProvided,
    String? note,
  }) {
    return GoalContributionPlan(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      interval: interval ?? this.interval,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
      lastGeneratedPeriodKey:
          identical(lastGeneratedPeriodKey, _nullableFieldNotProvided)
          ? this.lastGeneratedPeriodKey
          : lastGeneratedPeriodKey as String?,
      note: note ?? this.note,
    );
  }
}

class CategoryBudget {
  const CategoryBudget({
    required this.id,
    required this.category,
    required this.limit,
    required this.spent,
    required this.periodStart,
  });

  final String id;
  final String category;
  final double limit;
  final double spent;
  final DateTime periodStart;

  bool get isPersisted => id.isNotEmpty;

  double get progress {
    if (limit <= 0) {
      return 0;
    }

    return (spent / limit).clamp(0, 1);
  }

  CategoryBudget copyWith({
    String? id,
    String? category,
    double? limit,
    double? spent,
    DateTime? periodStart,
  }) {
    return CategoryBudget(
      id: id ?? this.id,
      category: category ?? this.category,
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
      periodStart: periodStart ?? this.periodStart,
    );
  }
}

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.deadline,
  });

  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime deadline;

  bool get isPersisted => id.isNotEmpty;

  double get progress {
    if (targetAmount <= 0) {
      return 0;
    }

    return (savedAmount / targetAmount).clamp(0, 1);
  }

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
    );
  }
}

class InvestmentHolding {
  const InvestmentHolding({
    required this.id,
    this.assetType = InvestmentAssetType.crypto,
    required this.symbol,
    required this.name,
    required this.units,
    required this.buyPrice,
    required this.currentPrice,
    this.lastPriceUpdateAt,
    this.lastPriceDate,
  });

  final String id;
  final InvestmentAssetType assetType;
  final String symbol;
  final String name;
  final double units;
  final double buyPrice;
  final double currentPrice;
  final DateTime? lastPriceUpdateAt;
  final DateTime? lastPriceDate;

  bool get isPersisted => id.isNotEmpty;

  bool get hasSymbol => symbol.trim().isNotEmpty;

  bool get supportsMarketData => assetType.supportsMarketData && hasSymbol;

  String get displaySymbol => hasSymbol ? symbol.trim() : assetType.shortLabel;

  double get investedValue => units * buyPrice;

  double get currentValue => units * currentPrice;

  double get profit => currentValue - investedValue;

  InvestmentHolding copyWith({
    String? id,
    InvestmentAssetType? assetType,
    String? symbol,
    String? name,
    double? units,
    double? buyPrice,
    double? currentPrice,
    Object? lastPriceUpdateAt = _nullableFieldNotProvided,
    Object? lastPriceDate = _nullableFieldNotProvided,
  }) {
    return InvestmentHolding(
      id: id ?? this.id,
      assetType: assetType ?? this.assetType,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      units: units ?? this.units,
      buyPrice: buyPrice ?? this.buyPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      lastPriceUpdateAt: identical(lastPriceUpdateAt, _nullableFieldNotProvided)
          ? this.lastPriceUpdateAt
          : lastPriceUpdateAt as DateTime?,
      lastPriceDate: identical(lastPriceDate, _nullableFieldNotProvided)
          ? this.lastPriceDate
          : lastPriceDate as DateTime?,
    );
  }
}

class InvestmentPricePoint {
  const InvestmentPricePoint({
    required this.id,
    required this.investmentId,
    required this.closePrice,
    required this.priceDate,
    required this.recordedAt,
  });

  final String id;
  final String investmentId;
  final double closePrice;
  final DateTime priceDate;
  final DateTime recordedAt;

  bool get isPersisted => id.isNotEmpty;

  InvestmentPricePoint copyWith({
    String? id,
    String? investmentId,
    double? closePrice,
    DateTime? priceDate,
    DateTime? recordedAt,
  }) {
    return InvestmentPricePoint(
      id: id ?? this.id,
      investmentId: investmentId ?? this.investmentId,
      closePrice: closePrice ?? this.closePrice,
      priceDate: priceDate ?? this.priceDate,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }
}

class MonthlyReport {
  const MonthlyReport({
    required this.id,
    required this.periodStart,
    required this.generatedAt,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.transferTotal,
    required this.transactionCount,
    required this.budgetCount,
    required this.overspentBudgetCount,
    required this.budgetLimitTotal,
    required this.budgetSpentTotal,
    required this.investmentValue,
    required this.investmentProfit,
    required this.transferRate,
    required this.activeGoals,
    required this.completedGoals,
    required this.atRiskGoals,
    this.topExpenseCategory,
    this.isClosed = false,
    this.closedAt,
  });

  final String id;
  final DateTime periodStart;
  final DateTime generatedAt;
  final double incomeTotal;
  final double expenseTotal;
  final double transferTotal;
  final int transactionCount;
  final int budgetCount;
  final int overspentBudgetCount;
  final double budgetLimitTotal;
  final double budgetSpentTotal;
  final double investmentValue;
  final double investmentProfit;
  final double transferRate;
  final int activeGoals;
  final int completedGoals;
  final int atRiskGoals;
  final String? topExpenseCategory;
  final bool isClosed;
  final DateTime? closedAt;

  bool get isPersisted => id.isNotEmpty;

  double get netCashflow => incomeTotal - expenseTotal - transferTotal;

  double get budgetUsage {
    if (budgetLimitTotal <= 0) {
      return 0;
    }

    return (budgetSpentTotal / budgetLimitTotal).clamp(0, 1);
  }

  MonthlyReport copyWith({
    String? id,
    DateTime? periodStart,
    DateTime? generatedAt,
    double? incomeTotal,
    double? expenseTotal,
    double? transferTotal,
    int? transactionCount,
    int? budgetCount,
    int? overspentBudgetCount,
    double? budgetLimitTotal,
    double? budgetSpentTotal,
    double? investmentValue,
    double? investmentProfit,
    double? transferRate,
    int? activeGoals,
    int? completedGoals,
    int? atRiskGoals,
    String? topExpenseCategory,
    bool? isClosed,
    DateTime? closedAt,
  }) {
    return MonthlyReport(
      id: id ?? this.id,
      periodStart: periodStart ?? this.periodStart,
      generatedAt: generatedAt ?? this.generatedAt,
      incomeTotal: incomeTotal ?? this.incomeTotal,
      expenseTotal: expenseTotal ?? this.expenseTotal,
      transferTotal: transferTotal ?? this.transferTotal,
      transactionCount: transactionCount ?? this.transactionCount,
      budgetCount: budgetCount ?? this.budgetCount,
      overspentBudgetCount: overspentBudgetCount ?? this.overspentBudgetCount,
      budgetLimitTotal: budgetLimitTotal ?? this.budgetLimitTotal,
      budgetSpentTotal: budgetSpentTotal ?? this.budgetSpentTotal,
      investmentValue: investmentValue ?? this.investmentValue,
      investmentProfit: investmentProfit ?? this.investmentProfit,
      transferRate: transferRate ?? this.transferRate,
      activeGoals: activeGoals ?? this.activeGoals,
      completedGoals: completedGoals ?? this.completedGoals,
      atRiskGoals: atRiskGoals ?? this.atRiskGoals,
      topExpenseCategory: topExpenseCategory ?? this.topExpenseCategory,
      isClosed: isClosed ?? this.isClosed,
      closedAt: closedAt ?? this.closedAt,
    );
  }
}

class PortfolioDailySnapshot {
  const PortfolioDailySnapshot({
    required this.id,
    required this.recordedAt,
    required this.value,
  });

  final String id;
  final DateTime recordedAt;
  final double value;

  bool get isPersisted => id.isNotEmpty;

  PortfolioDailySnapshot copyWith({
    String? id,
    DateTime? recordedAt,
    double? value,
  }) {
    return PortfolioDailySnapshot(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      value: value ?? this.value,
    );
  }
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.billingCycle,
    required this.nextBillingDate,
    required this.isActive,
    this.note,
  });

  final String id;
  final String name;
  final String category;
  final double amount;
  final SubscriptionBillingCycle billingCycle;
  final DateTime nextBillingDate;
  final bool isActive;
  final String? note;

  bool get isPersisted => id.isNotEmpty;

  double get monthlyCost {
    switch (billingCycle) {
      case SubscriptionBillingCycle.monthly:
        return amount;
      case SubscriptionBillingCycle.quarterly:
        return amount / 3;
      case SubscriptionBillingCycle.yearly:
        return amount / 12;
    }
  }

  SubscriptionPlan copyWith({
    String? id,
    String? name,
    String? category,
    double? amount,
    SubscriptionBillingCycle? billingCycle,
    DateTime? nextBillingDate,
    bool? isActive,
    String? note,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      billingCycle: billingCycle ?? this.billingCycle,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      isActive: isActive ?? this.isActive,
      note: note ?? this.note,
    );
  }
}

class ReportArchiveEntry {
  const ReportArchiveEntry({
    required this.id,
    required this.reportId,
    required this.filename,
    required this.format,
    required this.periodStart,
    required this.uploadedAt,
    required this.sizeBytes,
    required this.contentType,
    required this.storagePath,
  });

  final String id;
  final String? reportId;
  final String filename;
  final ReportArchiveFormat format;
  final DateTime periodStart;
  final DateTime uploadedAt;
  final int sizeBytes;
  final String contentType;
  final String storagePath;

  bool get isPersisted => id.isNotEmpty;

  ReportArchiveEntry copyWith({
    String? id,
    String? reportId,
    String? filename,
    ReportArchiveFormat? format,
    DateTime? periodStart,
    DateTime? uploadedAt,
    int? sizeBytes,
    String? contentType,
    String? storagePath,
  }) {
    return ReportArchiveEntry(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      filename: filename ?? this.filename,
      format: format ?? this.format,
      periodStart: periodStart ?? this.periodStart,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      contentType: contentType ?? this.contentType,
      storagePath: storagePath ?? this.storagePath,
    );
  }
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.userName,
    required this.transactions,
    required this.budgets,
    required this.goals,
    required this.investments,
  });

  final String userName;
  final List<FinanceTransaction> transactions;
  final List<CategoryBudget> budgets;
  final List<SavingsGoal> goals;
  final List<InvestmentHolding> investments;

  double get incomeTotal => transactions
      .where((transaction) => transaction.type == TransactionType.income)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  double get expenseTotal => transactions
      .where((transaction) => transaction.type == TransactionType.expense)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  double get transferTotal => transactions
      .where((transaction) => transaction.type == TransactionType.transfer)
      .fold(0, (sum, transaction) => sum + transaction.amount);

  double get balance => incomeTotal - expenseTotal - transferTotal;

  double get investedTotal =>
      investments.fold(0, (sum, investment) => sum + investment.currentValue);

  double get investmentProfit =>
      investments.fold(0, (sum, investment) => sum + investment.profit);
}

extension InvestmentAssetTypeX on InvestmentAssetType {
  String get label => switch (this) {
    InvestmentAssetType.stock => 'Akcje',
    InvestmentAssetType.etf => 'ETF',
    InvestmentAssetType.bond => 'Obligacje',
    InvestmentAssetType.fund => 'Fundusze',
    InvestmentAssetType.crypto => 'Krypto',
    InvestmentAssetType.other => 'Inne',
  };

  String get shortLabel => switch (this) {
    InvestmentAssetType.stock => 'AKCJA',
    InvestmentAssetType.etf => 'ETF',
    InvestmentAssetType.bond => 'OBLIG.',
    InvestmentAssetType.fund => 'FUNDUSZ',
    InvestmentAssetType.crypto => 'KRYPTO',
    InvestmentAssetType.other => 'AKTYWO',
  };

  bool get supportsMarketData => switch (this) {
    InvestmentAssetType.crypto => true,
    InvestmentAssetType.stock => false,
    InvestmentAssetType.etf => false,
    InvestmentAssetType.bond => false,
    InvestmentAssetType.fund => false,
    InvestmentAssetType.other => false,
  };

  bool get symbolIsRequired => supportsMarketData;

  String get symbolFieldLabel => switch (this) {
    InvestmentAssetType.stock => 'Symbol (opcjonalnie)',
    InvestmentAssetType.etf => 'Ticker ETF (opcjonalnie)',
    InvestmentAssetType.crypto => 'Ticker / para',
    InvestmentAssetType.bond => 'ISIN / symbol (opcjonalnie)',
    InvestmentAssetType.fund => 'Symbol funduszu (opcjonalnie)',
    InvestmentAssetType.other => 'Symbol (opcjonalnie)',
  };
}
