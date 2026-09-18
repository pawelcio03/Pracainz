import '../../../models/finance_models.dart';
import '../../transaction_import/domain/import_category_rule.dart';
import 'category_presets.dart';

class ImportCategorySuggester {
  const ImportCategorySuggester._();

  static String resolveTransactionCategory({
    required TransactionType type,
    required Iterable<FinanceCategory> availableCategories,
    required String title,
    String? rawCategory,
    String? note,
    Iterable<ImportCategoryRule> importCategoryRules = const [],
  }) {
    final categories = categoriesForTypeOrFallback(
      availableCategories,
      type,
    ).map((category) => category.name).toList();
    final raw = rawCategory?.trim() ?? '';
    final combinedText = [
      raw,
      title,
      note ?? '',
    ].where((value) => value.trim().isNotEmpty).join(' ');

    final exactMatch = _matchExistingCategory(raw, categories);
    if (exactMatch != null) {
      return exactMatch;
    }

    final ruleMatch = _ruleMatch(
      type: type,
      rules: importCategoryRules,
      title: title,
      rawCategory: raw,
      note: note,
      categories: categories,
    );
    if (ruleMatch != null) {
      return ruleMatch;
    }

    final keywordMatch = _keywordMatch(
      categories: categories,
      text: combinedText,
      defaults: switch (type) {
        TransactionType.income => _incomeKeywords,
        TransactionType.expense => _expenseKeywords,
        TransactionType.transfer => _transferKeywords,
      },
    );
    if (keywordMatch != null) {
      return keywordMatch;
    }

    if (raw.isNotEmpty) {
      return raw;
    }

    return switch (type) {
      TransactionType.income => _canonicalize(
        categories: categories,
        fallback: 'Dodatkowy dochod',
      ),
      TransactionType.expense => _canonicalize(
        categories: categories,
        fallback: 'Inne',
      ),
      TransactionType.transfer => _canonicalize(
        categories: categories,
        fallback: goalContributionCategory,
      ),
    };
  }

  static String resolveSubscriptionCategory({
    required Iterable<String> availableCategories,
    required String name,
    String? rawCategory,
    String? note,
  }) {
    final categories = availableCategories.isEmpty
        ? categoryNamesForTypeOrFallback(const [], TransactionType.expense)
        : availableCategories.toList();
    final raw = rawCategory?.trim() ?? '';
    final combinedText = [
      raw,
      name,
      note ?? '',
    ].where((value) => value.trim().isNotEmpty).join(' ');

    final exactMatch = _matchExistingCategory(raw, categories);
    if (exactMatch != null) {
      return exactMatch;
    }

    final keywordMatch = _keywordMatch(
      categories: categories,
      text: combinedText,
      defaults: _subscriptionKeywords,
    );
    if (keywordMatch != null) {
      return keywordMatch;
    }

    if (raw.isNotEmpty) {
      return raw;
    }

    return _canonicalize(categories: categories, fallback: 'Subskrypcje');
  }

  static String? _matchExistingCategory(
    String rawCategory,
    List<String> categories,
  ) {
    if (rawCategory.trim().isEmpty) {
      return null;
    }

    final normalizedRaw = _normalize(rawCategory);
    for (final category in categories) {
      if (_normalize(category) == normalizedRaw) {
        return category;
      }
    }

    return null;
  }

  static String? _ruleMatch({
    required TransactionType type,
    required Iterable<ImportCategoryRule> rules,
    required String title,
    required String rawCategory,
    required String? note,
    required List<String> categories,
  }) {
    for (final rule in rules) {
      if (!rule.matches(
        transactionType: type,
        title: title,
        rawCategory: rawCategory,
        note: note,
      )) {
        continue;
      }

      return _canonicalize(categories: categories, fallback: rule.category);
    }

    return null;
  }

  static String? _keywordMatch({
    required List<String> categories,
    required String text,
    required Map<String, List<String>> defaults,
  }) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) {
      return null;
    }

    for (final entry in defaults.entries) {
      final matches = entry.value.any(normalized.contains);
      if (matches) {
        return _canonicalize(categories: categories, fallback: entry.key);
      }
    }

    return null;
  }

  static String _canonicalize({
    required List<String> categories,
    required String fallback,
  }) {
    final normalizedFallback = _normalize(fallback);
    for (final category in categories) {
      if (_normalize(category) == normalizedFallback) {
        return category;
      }
    }

    return fallback;
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ą', 'a')
        .replaceAll('ć', 'c')
        .replaceAll('ę', 'e')
        .replaceAll('ł', 'l')
        .replaceAll('ń', 'n')
        .replaceAll('ó', 'o')
        .replaceAll('ś', 's')
        .replaceAll('ź', 'z')
        .replaceAll('ż', 'z');
  }

  static const Map<String, List<String>> _incomeKeywords = {
    'Praca': [
      'pensja',
      'wynagrodzenie',
      'salary',
      'payroll',
      'etat',
      'umowa',
      'premia',
      'bonus',
      'faktura',
    ],
    'Dodatkowy dochod': [
      'freelance',
      'sprzedaz',
      'olx',
      'refund',
      'zwrot',
      'cashback',
      'odsetki',
      'dywidenda',
    ],
  };

  static const Map<String, List<String>> _expenseKeywords = {
    'Jedzenie': [
      'biedronka',
      'lidl',
      'kaufland',
      'zabka',
      'auchan',
      'carrefour',
      'market',
      'sklep',
      'restaur',
      'glovo',
      'uber eats',
      'pyszne',
      'kawa',
      'coffee',
      'jedzenie',
      'food',
    ],
    'Transport': [
      'orlen',
      'shell',
      'bp',
      'circle k',
      'uber',
      'bolt',
      'taxi',
      'paliwo',
      'pkp',
      'mpk',
      'tramwaj',
      'autobus',
      'bilet',
      'parking',
      'transport',
    ],
    'Dom': [
      'czynsz',
      'media markt',
      'ikea',
      'leroy',
      'obi',
      'rachunek',
      'prad',
      'woda',
      'gaz',
      'internet',
      'dom',
    ],
    'Rozrywka': [
      'kino',
      'teatr',
      'steam',
      'playstation',
      'xbox',
      'koncert',
      'rozrywka',
    ],
    'Zdrowie': [
      'apteka',
      'lekarz',
      'dentysta',
      'medicover',
      'luxmed',
      'zdrowie',
    ],
    'Subskrypcje': [
      'netflix',
      'spotify',
      'youtube',
      'disney',
      'hbo',
      'prime',
      'subskrypc',
      'abonament',
    ],
    'Inwestycje': [
      'xtb',
      'degiro',
      'etf',
      'akcje',
      'obligac',
      'broker',
      'inwest',
    ],
  };

  static const Map<String, List<String>> _transferKeywords = {
    goalContributionCategory: [
      'oszczed',
      'savings',
      'skarbonka',
      'cel',
      'poduszka',
    ],
  };

  static const Map<String, List<String>> _subscriptionKeywords = {
    'Rozrywka': [
      'netflix',
      'spotify',
      'youtube',
      'disney',
      'hbo',
      'prime',
      'tidal',
    ],
    'Praca': [
      'adobe',
      'figma',
      'github',
      'jetbrains',
      'chatgpt',
      'notion',
      'slack',
      'office',
      'microsoft',
    ],
    'Zdrowie': ['medicover', 'luxmed', 'gym', 'silownia', 'fitness'],
    'Subskrypcje': [
      'icloud',
      'google one',
      'dropbox',
      'hosting',
      'vpn',
      'domena',
      'subskrypc',
      'abonament',
    ],
  };
}
