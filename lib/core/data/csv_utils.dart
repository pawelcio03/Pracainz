class CsvUtils {
  const CsvUtils._();

  static List<List<String>> parseRows(String source) {
    if (source.isEmpty) {
      return const <List<String>>[];
    }

    final delimiter = _detectDelimiter(source);
    final rows = <List<String>>[];
    final currentRow = <String>[];
    var cellBuffer = StringBuffer();
    var inQuotes = false;

    void pushCell() {
      currentRow.add(cellBuffer.toString());
      cellBuffer = StringBuffer();
    }

    void pushRow() {
      pushCell();
      rows.add(List<String>.from(currentRow));
      currentRow.clear();
    }

    for (var index = 0; index < source.length; index++) {
      final char = source[index];

      if (char == '"') {
        final nextIsQuote =
            index + 1 < source.length && source[index + 1] == '"';
        if (inQuotes && nextIsQuote) {
          cellBuffer.write('"');
          index++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (!inQuotes && char == delimiter) {
        pushCell();
        continue;
      }

      if (!inQuotes && (char == '\n' || char == '\r')) {
        if (char == '\r' &&
            index + 1 < source.length &&
            source[index + 1] == '\n') {
          index++;
        }
        pushRow();
        continue;
      }

      cellBuffer.write(char);
    }

    if (cellBuffer.isNotEmpty || currentRow.isNotEmpty) {
      pushRow();
    }

    return rows;
  }

  static String normalizeHeader(String value) {
    final ascii = _stripDiacritics(value).toLowerCase();
    return ascii.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  static String _detectDelimiter(String source) {
    final candidates = <String>[',', ';', '\t'];
    var chosen = ',';
    var bestCount = -1;

    for (final candidate in candidates) {
      final count = _countDelimiterInSample(source, candidate);
      if (count > bestCount) {
        chosen = candidate;
        bestCount = count;
      }
    }

    return chosen;
  }

  static int _countDelimiterInSample(String source, String delimiter) {
    final lines = source.split(RegExp(r'\r\n|\n|\r'));
    var checkedLines = 0;
    var count = 0;

    for (final line in lines) {
      if (line.trim().isEmpty) {
        continue;
      }

      count += _countDelimiterOutsideQuotes(line, delimiter);
      checkedLines++;
      if (checkedLines >= 12) {
        break;
      }
    }

    return count;
  }

  static int _countDelimiterOutsideQuotes(String input, String delimiter) {
    var count = 0;
    var inQuotes = false;

    for (var index = 0; index < input.length; index++) {
      final char = input[index];
      if (char == '"') {
        final nextIsQuote = index + 1 < input.length && input[index + 1] == '"';
        if (inQuotes && nextIsQuote) {
          index++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (!inQuotes && char == delimiter) {
        count++;
      }
    }

    return count;
  }

  static String _stripDiacritics(String value) {
    const replacements = <String, String>{
      '\u0105': 'a',
      '\u0104': 'a',
      '\u0107': 'c',
      '\u0106': 'c',
      '\u0119': 'e',
      '\u0118': 'e',
      '\u0142': 'l',
      '\u0141': 'l',
      '\u0144': 'n',
      '\u0143': 'n',
      '\u00f3': 'o',
      '\u00d3': 'o',
      '\u015b': 's',
      '\u015a': 's',
      '\u017a': 'z',
      '\u0179': 'z',
      '\u017c': 'z',
      '\u017b': 'z',
    };

    return value.split('').map((char) => replacements[char] ?? char).join();
  }
}
