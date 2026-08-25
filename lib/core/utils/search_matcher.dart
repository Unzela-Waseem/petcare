abstract final class SearchMatcher {
  static bool matches(String query, Iterable<String?> fields) {
    final terms = _normalize(
      query,
    ).split(' ').where((term) => term.isNotEmpty).toList();
    if (terms.isEmpty) return true;

    final searchable = fields.whereType<String>().map(_normalize).join(' ');
    return terms.every(searchable.contains);
  }

  static String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}
