class CategoryResponse {
  final int id;
  final String name;
  final String colorHex;
  final String? iconSlug;

  CategoryResponse({
    required this.id,
    required this.name,
    required this.colorHex,
    this.iconSlug,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      colorHex: json['colorHex'] as String,
      iconSlug: json['iconSlug'] as String?,
    );
  }
}
