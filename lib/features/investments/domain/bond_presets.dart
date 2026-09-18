enum BondMarketPreset { poland, eurozone, usa, china, custom }

class BondInstrumentPreset {
  const BondInstrumentPreset({
    required this.market,
    required this.code,
    required this.displayName,
  });

  final BondMarketPreset market;
  final String code;
  final String displayName;

  String get optionLabel => '$code - $displayName';
}

const List<BondInstrumentPreset> bondInstrumentPresets = [
  BondInstrumentPreset(
    market: BondMarketPreset.poland,
    code: 'OTS',
    displayName: 'Obligacje Skarbowe 3M',
  ),
  BondInstrumentPreset(
    market: BondMarketPreset.poland,
    code: 'ROR',
    displayName: 'Obligacje Skarbowe 1R',
  ),
  BondInstrumentPreset(
    market: BondMarketPreset.poland,
    code: 'DOR',
    displayName: 'Obligacje Skarbowe 2R',
  ),
  BondInstrumentPreset(
    market: BondMarketPreset.poland,
    code: 'TOS',
    displayName: 'Obligacje Skarbowe 3R',
  ),
  BondInstrumentPreset(
    market: BondMarketPreset.poland,
    code: 'COI',
    displayName: 'Obligacje Skarbowe 4R',
  ),
  BondInstrumentPreset(
    market: BondMarketPreset.poland,
    code: 'EDO',
    displayName: 'Obligacje Skarbowe 10R',
  ),
  BondInstrumentPreset(
    market: BondMarketPreset.eurozone,
    code: 'BUND',
    displayName: 'German Bund',
  ),
  BondInstrumentPreset(
    market: BondMarketPreset.eurozone,
    code: 'OAT',
    displayName: 'French OAT',
  ),
  BondInstrumentPreset(
    market: BondMarketPreset.eurozone,
    code: 'BTP',
    displayName: 'Italian BTP',
  ),
  BondInstrumentPreset(
    market: BondMarketPreset.eurozone,
    code: 'BONOS',
    displayName: 'Spanish Bonos',
  ),
  BondInstrumentPreset(
    market: BondMarketPreset.usa,
    code: 'TBILL',
    displayName: 'US Treasury Bills',
  ),
  BondInstrumentPreset(
    market: BondMarketPreset.usa,
    code: 'TNOTE',
    displayName: 'US Treasury Notes',
  ),
  BondInstrumentPreset(
    market: BondMarketPreset.usa,
    code: 'TBOND',
    displayName: 'US Treasury Bonds',
  ),
  BondInstrumentPreset(
    market: BondMarketPreset.usa,
    code: 'TIPS',
    displayName: 'US Treasury Inflation-Protected Securities',
  ),
  BondInstrumentPreset(
    market: BondMarketPreset.china,
    code: 'CGB',
    displayName: 'China Government Bond',
  ),
  BondInstrumentPreset(
    market: BondMarketPreset.china,
    code: 'CDB',
    displayName: 'China Development Bank Bond',
  ),
  BondInstrumentPreset(
    market: BondMarketPreset.china,
    code: 'ADBC',
    displayName: 'Agricultural Development Bank Bond',
  ),
  BondInstrumentPreset(
    market: BondMarketPreset.china,
    code: 'EXIM',
    displayName: 'China Exim Bank Bond',
  ),
];

List<BondInstrumentPreset> bondPresetsForMarket(BondMarketPreset market) {
  return bondInstrumentPresets
      .where((preset) => preset.market == market)
      .toList();
}

BondInstrumentPreset? findBondPresetByCode(String code) {
  final normalizedCode = code.trim().toUpperCase();
  if (normalizedCode.isEmpty) {
    return null;
  }

  for (final preset in bondInstrumentPresets) {
    if (preset.code == normalizedCode) {
      return preset;
    }
  }

  return null;
}

extension BondMarketPresetX on BondMarketPreset {
  String get label => switch (this) {
    BondMarketPreset.poland => 'Polska',
    BondMarketPreset.eurozone => 'Strefa euro',
    BondMarketPreset.usa => 'USA',
    BondMarketPreset.china => 'Chiny',
    BondMarketPreset.custom => 'Inne',
  };
}
