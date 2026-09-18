import '../../models/finance_models.dart';
import 'input_validation_exception.dart';

class FinanceInputSanitizer {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _urlPattern = RegExp(r'^https?://\S+$');
  static final RegExp _symbolPattern = RegExp(r'^[A-Z0-9._-]+$');
  static final RegExp _symbolSeparatorPattern = RegExp(r'[/\s]+');
  static final RegExp _whitespacePattern = RegExp(r'\s+');

  static String normalizeEmail(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty || normalized.length > 120) {
      throw const InputValidationException(
        'Adres e-mail musi miec od 1 do 120 znakow.',
      );
    }
    if (!_emailPattern.hasMatch(normalized)) {
      throw const InputValidationException(
        'Adres e-mail ma niepoprawny format.',
      );
    }
    return normalized;
  }

  static String normalizeDisplayName(String value) {
    final normalized = normalizeSingleLine(
      value,
      fieldLabel: 'Nazwa profilu',
      minLength: 2,
      maxLength: 60,
    );
    return normalized;
  }

  static String normalizeSingleLine(
    String value, {
    required String fieldLabel,
    int minLength = 1,
    required int maxLength,
    bool uppercase = false,
  }) {
    var normalized = value.trim().replaceAll(_whitespacePattern, ' ');
    if (uppercase) {
      normalized = normalized.toUpperCase();
    }
    if (normalized.length < minLength || normalized.length > maxLength) {
      throw InputValidationException(
        '$fieldLabel musi miec od $minLength do $maxLength znakow.',
      );
    }
    return normalized;
  }

  static String normalizeInvestmentSymbolInput(
    String value, {
    required String fieldLabel,
    required bool required,
  }) {
    return _normalizeInvestmentSymbol(
      value,
      fieldLabel: fieldLabel,
      required: required,
    );
  }

  static String? normalizeOptionalNote(
    String? value, {
    int maxLength = 280,
    String fieldLabel = 'Notatka',
  }) {
    if (value == null) {
      return null;
    }

    final normalized = value
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map((line) => line.trimRight())
        .join('\n')
        .trim();

    if (normalized.isEmpty) {
      return null;
    }

    if (normalized.length > maxLength) {
      throw InputValidationException(
        '$fieldLabel moze miec maksymalnie $maxLength znakow.',
      );
    }

    return normalized;
  }

  static String? normalizeOptionalId(
    String? value, {
    required String fieldLabel,
    int maxLength = 128,
  }) {
    if (value == null) {
      return null;
    }

    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    if (normalized.length > maxLength) {
      throw InputValidationException(
        '$fieldLabel moze miec maksymalnie $maxLength znakow.',
      );
    }

    return normalized;
  }

  static String? normalizeOptionalUrl(
    String? value, {
    required String fieldLabel,
    int maxLength = 500,
  }) {
    if (value == null) {
      return null;
    }

    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    if (normalized.length > maxLength || !_urlPattern.hasMatch(normalized)) {
      throw InputValidationException(
        '$fieldLabel musi byc poprawnym adresem http lub https.',
      );
    }

    return normalized;
  }

  static FinanceCategory sanitizeCategory(FinanceCategory category) {
    return FinanceCategory(
      id: category.id,
      name: normalizeSingleLine(
        category.name,
        fieldLabel: 'Nazwa kategorii',
        maxLength: 40,
      ),
      type: category.type,
    );
  }

  static FinanceTransaction sanitizeTransaction(
    FinanceTransaction transaction,
  ) {
    _validatePositiveAmount(transaction.amount, fieldLabel: 'Kwota transakcji');

    return FinanceTransaction(
      id: transaction.id,
      title: normalizeSingleLine(
        transaction.title,
        fieldLabel: 'Nazwa transakcji',
        maxLength: 80,
      ),
      category: normalizeSingleLine(
        transaction.category,
        fieldLabel: 'Kategoria transakcji',
        maxLength: 40,
      ),
      amount: transaction.amount,
      date: _normalizeDate(transaction.date, fieldLabel: 'Data transakcji'),
      type: transaction.type,
      goalId: normalizeOptionalId(transaction.goalId, fieldLabel: 'Id celu'),
      goalContributionPlanId: normalizeOptionalId(
        transaction.goalContributionPlanId,
        fieldLabel: 'Id planu wplaty celu',
      ),
      recurringIncomeId: normalizeOptionalId(
        transaction.recurringIncomeId,
        fieldLabel: 'Id stalego dochodu',
      ),
      note: normalizeOptionalNote(
        transaction.note,
        fieldLabel: 'Opis transakcji',
      ),
    );
  }

  static GoalContributionPlan sanitizeGoalContributionPlan(
    GoalContributionPlan plan,
  ) {
    _validatePositiveAmount(plan.amount, fieldLabel: 'Kwota planu wplaty');

    if (plan.dayOfMonth < 1 || plan.dayOfMonth > 31) {
      throw const InputValidationException(
        'Dzien planowanej wplaty musi byc z zakresu 1-31.',
      );
    }

    return GoalContributionPlan(
      id: plan.id,
      goalId: normalizeSingleLine(
        plan.goalId,
        fieldLabel: 'Id celu planu wplaty',
        maxLength: 128,
      ),
      name: normalizeSingleLine(
        plan.name,
        fieldLabel: 'Nazwa planu wplaty',
        maxLength: 80,
      ),
      amount: plan.amount,
      interval: plan.interval,
      dayOfMonth: plan.dayOfMonth,
      startDate: _normalizeDate(
        plan.startDate,
        fieldLabel: 'Data startu planu wplaty',
      ),
      isActive: plan.isActive,
      lastGeneratedPeriodKey: _normalizeOptionalMonthKey(
        plan.lastGeneratedPeriodKey,
      ),
      note: normalizeOptionalNote(
        plan.note,
        fieldLabel: 'Notatka planu wplaty',
      ),
    );
  }

  static RecurringIncomePlan sanitizeRecurringIncomePlan(
    RecurringIncomePlan plan,
  ) {
    _validatePositiveAmount(plan.amount, fieldLabel: 'Kwota stalego dochodu');

    if (plan.payday < 1 || plan.payday > 31) {
      throw const InputValidationException(
        'Dzien wyplaty musi byc z zakresu 1-31.',
      );
    }

    return RecurringIncomePlan(
      id: plan.id,
      name: normalizeSingleLine(
        plan.name,
        fieldLabel: 'Nazwa stalego dochodu',
        maxLength: 80,
      ),
      category: normalizeSingleLine(
        plan.category,
        fieldLabel: 'Kategoria stalego dochodu',
        maxLength: 40,
      ),
      amount: plan.amount,
      payday: plan.payday,
      startDate: _normalizeDate(
        plan.startDate,
        fieldLabel: 'Data startu stalego dochodu',
      ),
      isActive: plan.isActive,
      lastGeneratedMonthKey: _normalizeOptionalMonthKey(
        plan.lastGeneratedMonthKey,
      ),
      note: normalizeOptionalNote(
        plan.note,
        fieldLabel: 'Notatka stalego dochodu',
      ),
    );
  }

  static CategoryBudget sanitizeBudget(CategoryBudget budget) {
    _validatePositiveAmount(budget.limit, fieldLabel: 'Limit budzetu');
    _validateNonNegativeAmount(
      budget.spent,
      fieldLabel: 'Wykorzystanie budzetu',
    );

    return CategoryBudget(
      id: budget.id,
      category: normalizeSingleLine(
        budget.category,
        fieldLabel: 'Kategoria budzetu',
        maxLength: 40,
      ),
      limit: budget.limit,
      spent: budget.spent,
      periodStart: DateTime(budget.periodStart.year, budget.periodStart.month),
    );
  }

  static SavingsGoal sanitizeGoal(SavingsGoal goal) {
    _validatePositiveAmount(
      goal.targetAmount,
      fieldLabel: 'Kwota docelowa celu',
    );
    _validateNonNegativeAmount(
      goal.savedAmount,
      fieldLabel: 'Stan poczatkowy celu',
    );

    return SavingsGoal(
      id: goal.id,
      name: normalizeSingleLine(
        goal.name,
        fieldLabel: 'Nazwa celu',
        maxLength: 80,
      ),
      targetAmount: goal.targetAmount,
      savedAmount: goal.savedAmount,
      deadline: _normalizeDate(goal.deadline, fieldLabel: 'Termin celu'),
    );
  }

  static InvestmentHolding sanitizeInvestment(InvestmentHolding investment) {
    _validatePositiveAmount(investment.units, fieldLabel: 'Liczba jednostek');
    _validateNonNegativeAmount(investment.buyPrice, fieldLabel: 'Cena zakupu');
    _validateNonNegativeAmount(
      investment.currentPrice,
      fieldLabel: 'Cena biezaca',
    );

    final symbol = _normalizeInvestmentSymbol(
      investment.symbol,
      fieldLabel: investment.assetType.symbolFieldLabel,
      required: investment.assetType.symbolIsRequired,
    );

    return InvestmentHolding(
      id: investment.id,
      assetType: investment.assetType,
      symbol: symbol,
      name: normalizeSingleLine(
        investment.name,
        fieldLabel: 'Nazwa aktywa',
        maxLength: 80,
      ),
      units: investment.units,
      buyPrice: investment.buyPrice,
      currentPrice: investment.currentPrice,
      lastPriceUpdateAt: investment.lastPriceUpdateAt,
      lastPriceDate: investment.lastPriceDate,
    );
  }

  static SubscriptionPlan sanitizeSubscription(SubscriptionPlan subscription) {
    _validatePositiveAmount(
      subscription.amount,
      fieldLabel: 'Kwota subskrypcji',
    );

    return SubscriptionPlan(
      id: subscription.id,
      name: normalizeSingleLine(
        subscription.name,
        fieldLabel: 'Nazwa subskrypcji',
        maxLength: 80,
      ),
      category: normalizeSingleLine(
        subscription.category,
        fieldLabel: 'Kategoria subskrypcji',
        maxLength: 40,
      ),
      amount: subscription.amount,
      billingCycle: subscription.billingCycle,
      nextBillingDate: _normalizeDate(
        subscription.nextBillingDate,
        fieldLabel: 'Data kolejnego obciazenia',
      ),
      isActive: subscription.isActive,
      note: normalizeOptionalNote(
        subscription.note,
        fieldLabel: 'Notatka subskrypcji',
      ),
    );
  }

  static UserProfile sanitizeUserProfile(UserProfile profile) {
    return UserProfile(
      userId: profile.userId,
      displayName: normalizeDisplayName(profile.displayName),
      email: normalizeEmail(profile.email),
      photoUrl: normalizeOptionalUrl(
        profile.photoUrl,
        fieldLabel: 'Avatar dostawcy',
      ),
      customPhotoUrl: normalizeOptionalUrl(
        profile.customPhotoUrl,
        fieldLabel: 'Wlasny avatar',
      ),
      createdAt: profile.createdAt,
      lastSignInAt: profile.lastSignInAt,
      updatedAt: profile.updatedAt,
    );
  }

  static DateTime _normalizeDate(DateTime value, {required String fieldLabel}) {
    if (value.year < 2000 || value.year > 2100) {
      throw InputValidationException(
        '$fieldLabel jest poza dozwolonym zakresem.',
      );
    }
    return value;
  }

  static void _validatePositiveAmount(
    double value, {
    required String fieldLabel,
  }) {
    if (value <= 0 || value >= 100000000) {
      throw InputValidationException(
        '$fieldLabel musi byc dodatnia i mniejsza niz 100000000.',
      );
    }
  }

  static void _validateNonNegativeAmount(
    double value, {
    required String fieldLabel,
  }) {
    if (value < 0 || value >= 100000000) {
      throw InputValidationException(
        '$fieldLabel musi byc nieujemna i mniejsza niz 100000000.',
      );
    }
  }

  static String _normalizeInvestmentSymbol(
    String value, {
    required String fieldLabel,
    required bool required,
  }) {
    final normalized = value.trim().toUpperCase().replaceAll(
      _symbolSeparatorPattern,
      '',
    );
    if (normalized.isEmpty) {
      if (required) {
        throw InputValidationException('$fieldLabel jest wymagany.');
      }

      return '';
    }

    if (normalized.length > 24 || !_symbolPattern.hasMatch(normalized)) {
      throw InputValidationException(
        '$fieldLabel moze zawierac tylko litery, cyfry, kropke, myslnik, podkreslenie lub separator / i maksymalnie 24 znaki.',
      );
    }

    return normalized;
  }

  static String? _normalizeOptionalMonthKey(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }

    if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(normalized)) {
      throw const InputValidationException(
        'Klucz miesiaca musi miec format RRRR-MM.',
      );
    }

    return normalized;
  }
}
