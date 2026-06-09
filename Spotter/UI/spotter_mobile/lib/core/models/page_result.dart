class PageResult<T> {
  final List<T> items;
  final int? totalCount;

  PageResult({
    required this.items,
    this.totalCount,
  });

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PageResult(
      items: (json['items'] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int?,
    );
  }
}
