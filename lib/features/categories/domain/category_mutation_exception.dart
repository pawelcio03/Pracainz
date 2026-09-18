class CategoryMutationException implements Exception {
  const CategoryMutationException(this.message);

  final String message;

  @override
  String toString() => message;
}
