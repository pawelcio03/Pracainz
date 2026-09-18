import 'package:flutter/material.dart';

import '../../../core/validation/finance_input_sanitizer.dart';
import '../../../core/validation/input_validation_exception.dart';
import '../../../core/presentation/app_bottom_sheet.dart';
import '../../../models/finance_models.dart';
import '../domain/bond_presets.dart';

const _selectableInvestmentAssetTypes = [
  InvestmentAssetType.crypto,
  InvestmentAssetType.etf,
  InvestmentAssetType.bond,
  InvestmentAssetType.fund,
  InvestmentAssetType.other,
];

Future<InvestmentHolding?> showInvestmentFormSheet(
  BuildContext context, {
  InvestmentHolding? initialInvestment,
}) {
  return showAppBottomSheet<InvestmentHolding>(
    context,
    builder: (context) =>
        _InvestmentFormSheet(initialInvestment: initialInvestment),
  );
}

class _InvestmentFormSheet extends StatefulWidget {
  const _InvestmentFormSheet({this.initialInvestment});

  final InvestmentHolding? initialInvestment;

  @override
  State<_InvestmentFormSheet> createState() => _InvestmentFormSheetState();
}

class _InvestmentFormSheetState extends State<_InvestmentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _symbolController;
  late final TextEditingController _nameController;
  late final TextEditingController _unitsController;
  late final TextEditingController _buyPriceController;
  late final TextEditingController _currentPriceController;
  late InvestmentAssetType _selectedAssetType;
  late BondMarketPreset _selectedBondMarket;
  BondInstrumentPreset? _selectedBondPreset;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialInvestment;
    _selectedAssetType = initial?.assetType ?? InvestmentAssetType.crypto;
    _symbolController = TextEditingController(text: initial?.symbol ?? '');
    _nameController = TextEditingController(text: initial?.name ?? '');
    _unitsController = TextEditingController(
      text: initial == null ? '' : _formatAmount(initial.units),
    );
    _buyPriceController = TextEditingController(
      text: initial == null ? '' : _formatAmount(initial.buyPrice),
    );
    _currentPriceController = TextEditingController(
      text: initial == null ? '' : _formatAmount(initial.currentPrice),
    );
    _initializeBondSelection(initial);
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _nameController.dispose();
    _unitsController.dispose();
    _buyPriceController.dispose();
    _currentPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialInvestment != null;
    final usesMarketData = _selectedAssetType.supportsMarketData;
    final isBond = _selectedAssetType == InvestmentAssetType.bond;
    final usesBondPreset =
        isBond && _selectedBondMarket != BondMarketPreset.custom;

    return AppBottomSheetFrame(
      bottomBar: appBottomSheetPrimaryActionButton(
        context,
        onPressed: _submit,
        label: isEditing ? 'Zapisz pozycje' : 'Dodaj pozycje',
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edytuj pozycje' : 'Dodaj pozycje',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isBond
                  ? usesBondPreset
                        ? 'Wybierasz rynek i serie obligacji. Nazwa oraz symbol zostana uzupelnione automatycznie.'
                        : 'Dla niestandardowej obligacji mozesz wpisac wlasny symbol i nazwe.'
                  : usesMarketData
                  ? 'Dla krypto zapisujesz pare w walucie wyceny, np. BTCPLN albo BTC/PLN. Aplikacja moze automatycznie odswiezyc kurs z publicznego feedu, a cene nadal mozesz wpisac recznie.'
                  : 'Dla ETF, obligacji, funduszy i innych aktywow cena biezaca jest wpisywana recznie. Symbol nie jest wymagany.',
              style: appBottomSheetDescriptionStyle(context),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<InvestmentAssetType>(
              initialValue: _selectedAssetType,
              decoration: const InputDecoration(labelText: 'Typ aktywa'),
              items: _selectableInvestmentAssetTypes
                  .followedBy(
                    _selectableInvestmentAssetTypes.contains(_selectedAssetType)
                        ? const <InvestmentAssetType>[]
                        : [_selectedAssetType],
                  )
                  .map(
                    (type) => DropdownMenuItem<InvestmentAssetType>(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedAssetType = value;
                  if (value == InvestmentAssetType.bond) {
                    _ensureBondPresetSelection();
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            if (isBond) ...[
              DropdownButtonFormField<BondMarketPreset>(
                initialValue: _selectedBondMarket,
                decoration: const InputDecoration(labelText: 'Rynek obligacji'),
                items: BondMarketPreset.values
                    .map(
                      (market) => DropdownMenuItem<BondMarketPreset>(
                        value: market,
                        child: Text(market.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedBondMarket = value;
                    if (value == BondMarketPreset.custom) {
                      _selectedBondPreset = null;
                    } else {
                      final presets = bondPresetsForMarket(value);
                      _selectedBondPreset = presets.isEmpty
                          ? null
                          : presets.first;
                      _syncBondPresetFields();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              if (usesBondPreset) ...[
                DropdownButtonFormField<BondInstrumentPreset>(
                  initialValue: _selectedBondPreset,
                  decoration: const InputDecoration(
                    labelText: 'Seria / rodzaj obligacji',
                  ),
                  items: bondPresetsForMarket(_selectedBondMarket)
                      .map(
                        (preset) => DropdownMenuItem<BondInstrumentPreset>(
                          value: preset,
                          child: Text(preset.optionLabel),
                        ),
                      )
                      .toList(),
                  validator: (value) {
                    if (value == null) {
                      return 'Wybierz rodzaj obligacji.';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedBondPreset = value;
                      _syncBondPresetFields();
                    });
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.surfaceContainerHigh
                        : const Color(0xFFF8F7F3),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    _selectedBondPreset == null
                        ? 'Wybierz serie obligacji.'
                        : 'Zapiszemy ${_selectedBondPreset!.displayName} z symbolem ${_selectedBondPreset!.code}.',
                    style: appBottomSheetDescriptionStyle(context),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
            if (!usesBondPreset) ...[
              TextFormField(
                controller: _symbolController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 32,
                decoration: InputDecoration(
                  labelText: _selectedAssetType.symbolFieldLabel,
                  hintText: usesMarketData
                      ? 'Np. BTCPLN, BTC/PLN, ETHPLN'
                      : null,
                ),
                validator: (value) {
                  try {
                    FinanceInputSanitizer.normalizeInvestmentSymbolInput(
                      value ?? '',
                      fieldLabel: _selectedAssetType.symbolFieldLabel,
                      required: _selectedAssetType.symbolIsRequired,
                    );
                  } on InputValidationException catch (error) {
                    return error.message;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Nazwa aktywa'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Podaj nazwe aktywa.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _unitsController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              maxLength: 16,
              decoration: const InputDecoration(labelText: 'Liczba jednostek'),
              validator: (value) {
                final parsed = _parseAmount(value);
                if (parsed == null || parsed <= 0) {
                  return 'Podaj dodatnia liczbe jednostek.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _buyPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              maxLength: 16,
              decoration: InputDecoration(
                labelText: usesMarketData
                    ? 'Cena zakupu za jednostke'
                    : 'Wartosc zakupu za jednostke',
              ),
              validator: (value) {
                final parsed = _parseAmount(value);
                if (parsed == null || parsed < 0) {
                  return 'Podaj poprawna cene zakupu.';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currentPriceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              maxLength: 16,
              decoration: InputDecoration(
                labelText: usesMarketData
                    ? 'Aktualna cena za jednostke (opcjonalnie)'
                    : 'Aktualna cena za jednostke',
                helperText: usesMarketData
                    ? 'Puste pole zostawi wycene do automatycznego odswiezenia.'
                    : 'Puste pole przyjmie cene zakupu.',
              ),
              validator: (value) {
                final normalized = value?.trim() ?? '';
                if (normalized.isEmpty) {
                  return null;
                }

                final parsed = _parseAmount(value);
                if (parsed == null || parsed < 0) {
                  return 'Podaj poprawna cene biezaca.';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surfaceContainerHigh
                    : const Color(0xFFF8F7F3),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                usesMarketData
                    ? 'Automatyczny feed dziala tylko dla krypto. Reczna cena nadpisze biezaca wycene do czasu kolejnego odswiezenia.'
                    : 'Dla tego typu aktywa nie pobieramy automatycznych kursow. Reczna cena jest biezaca wycena pozycji.',
                style: appBottomSheetDescriptionStyle(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final normalizedSymbol =
        _selectedAssetType == InvestmentAssetType.bond &&
            _selectedBondMarket != BondMarketPreset.custom
        ? (_selectedBondPreset?.code ?? '')
        : _normalizeManualSymbol();
    final resolvedName =
        _selectedAssetType == InvestmentAssetType.bond &&
            _selectedBondMarket != BondMarketPreset.custom
        ? (_selectedBondPreset?.displayName ?? '')
        : _nameController.text.trim();
    final buyPrice = _parseAmount(_buyPriceController.text)!;
    final pricingSnapshot = _resolvePricingSnapshot(
      assetType: _selectedAssetType,
      normalizedSymbol: normalizedSymbol,
      buyPrice: buyPrice,
      rawCurrentPrice: _currentPriceController.text,
    );

    Navigator.of(context).pop(
      InvestmentHolding(
        id: widget.initialInvestment?.id ?? '',
        assetType: _selectedAssetType,
        symbol: normalizedSymbol,
        name: resolvedName,
        units: _parseAmount(_unitsController.text)!,
        buyPrice: buyPrice,
        currentPrice: pricingSnapshot.currentPrice,
        lastPriceUpdateAt: pricingSnapshot.lastPriceUpdateAt,
        lastPriceDate: pricingSnapshot.lastPriceDate,
      ),
    );
  }

  void _initializeBondSelection(InvestmentHolding? initial) {
    if (initial?.assetType != InvestmentAssetType.bond) {
      _selectedBondMarket = BondMarketPreset.poland;
      final presets = bondPresetsForMarket(_selectedBondMarket);
      _selectedBondPreset = presets.isEmpty ? null : presets.first;
      return;
    }

    final preset = findBondPresetByCode(initial!.symbol);
    if (preset != null) {
      _selectedBondMarket = preset.market;
      _selectedBondPreset = preset;
      _syncBondPresetFields();
      return;
    }

    _selectedBondMarket = BondMarketPreset.custom;
    _selectedBondPreset = null;
  }

  void _ensureBondPresetSelection() {
    if (_selectedBondMarket == BondMarketPreset.custom) {
      return;
    }

    final presets = bondPresetsForMarket(_selectedBondMarket);
    _selectedBondPreset ??= presets.isEmpty ? null : presets.first;
    _syncBondPresetFields();
  }

  void _syncBondPresetFields() {
    final preset = _selectedBondPreset;
    if (preset == null) {
      return;
    }

    _symbolController.text = preset.code;
    _nameController.text = preset.displayName;
  }

  _InvestmentPricingSnapshot _resolvePricingSnapshot({
    required InvestmentAssetType assetType,
    required String normalizedSymbol,
    required double buyPrice,
    required String rawCurrentPrice,
  }) {
    final trimmedCurrentPrice = rawCurrentPrice.trim();
    final manualCurrentPrice = trimmedCurrentPrice.isEmpty
        ? null
        : _parseAmount(trimmedCurrentPrice);

    if (manualCurrentPrice == null) {
      final initialInvestment = widget.initialInvestment;
      final shouldPreserveCurrentPrice =
          initialInvestment != null &&
          initialInvestment.assetType == assetType &&
          _normalizeStoredSymbol(initialInvestment) == normalizedSymbol &&
          initialInvestment.lastPriceDate != null;
      if (shouldPreserveCurrentPrice) {
        return _InvestmentPricingSnapshot(
          currentPrice: initialInvestment.currentPrice,
          lastPriceUpdateAt: initialInvestment.lastPriceUpdateAt,
          lastPriceDate: initialInvestment.lastPriceDate,
        );
      }

      return _InvestmentPricingSnapshot(
        currentPrice: buyPrice,
        lastPriceUpdateAt: null,
        lastPriceDate: null,
      );
    }

    final initialInvestment = widget.initialInvestment;
    final hasSameInvestmentIdentity =
        initialInvestment != null &&
        initialInvestment.assetType == assetType &&
        _normalizeStoredSymbol(initialInvestment) == normalizedSymbol;
    final carriesStaleInitialCurrentPrice =
        initialInvestment != null &&
        !hasSameInvestmentIdentity &&
        (manualCurrentPrice - initialInvestment.currentPrice).abs() < 0.0001;
    if (carriesStaleInitialCurrentPrice) {
      return _InvestmentPricingSnapshot(
        currentPrice: buyPrice,
        lastPriceUpdateAt: null,
        lastPriceDate: null,
      );
    }

    final mirrorsInitialBuyPrice =
        hasSameInvestmentIdentity &&
        (initialInvestment.currentPrice - initialInvestment.buyPrice).abs() <
            0.0001 &&
        (manualCurrentPrice - initialInvestment.currentPrice).abs() < 0.0001;
    if (mirrorsInitialBuyPrice) {
      return _InvestmentPricingSnapshot(
        currentPrice: buyPrice,
        lastPriceUpdateAt: null,
        lastPriceDate: null,
      );
    }

    final preservesExistingManualOrMarketPrice =
        hasSameInvestmentIdentity &&
        (initialInvestment.currentPrice - manualCurrentPrice).abs() < 0.0001;
    if (preservesExistingManualOrMarketPrice) {
      return _InvestmentPricingSnapshot(
        currentPrice: manualCurrentPrice,
        lastPriceUpdateAt: initialInvestment.lastPriceUpdateAt,
        lastPriceDate: initialInvestment.lastPriceDate,
      );
    }

    final now = DateTime.now();
    return _InvestmentPricingSnapshot(
      currentPrice: manualCurrentPrice,
      lastPriceUpdateAt: now,
      lastPriceDate: DateTime(now.year, now.month, now.day),
    );
  }

  double? _parseAmount(String? rawValue) {
    if (rawValue == null) {
      return null;
    }

    final normalized = rawValue.trim().replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  String _formatAmount(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _normalizeManualSymbol() {
    return FinanceInputSanitizer.normalizeInvestmentSymbolInput(
      _symbolController.text,
      fieldLabel: _selectedAssetType.symbolFieldLabel,
      required: _selectedAssetType.symbolIsRequired,
    );
  }

  String _normalizeStoredSymbol(InvestmentHolding investment) {
    try {
      return FinanceInputSanitizer.normalizeInvestmentSymbolInput(
        investment.symbol,
        fieldLabel: investment.assetType.symbolFieldLabel,
        required: false,
      );
    } on InputValidationException {
      return investment.symbol.trim().toUpperCase();
    }
  }
}

class _InvestmentPricingSnapshot {
  const _InvestmentPricingSnapshot({
    required this.currentPrice,
    required this.lastPriceUpdateAt,
    required this.lastPriceDate,
  });

  final double currentPrice;
  final DateTime? lastPriceUpdateAt;
  final DateTime? lastPriceDate;
}
