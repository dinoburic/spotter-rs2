class CategoryRequest {
  final String name;
  final String colorHex;
  final String? iconSlug;

  CategoryRequest({
    required this.name,
    required this.colorHex,
    this.iconSlug,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'colorHex': colorHex,
        'iconSlug': iconSlug,
      };
}
