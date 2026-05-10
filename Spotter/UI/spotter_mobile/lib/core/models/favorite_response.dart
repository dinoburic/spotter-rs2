class FavoriteResponse {
  final int id;
  final int eventId;
  final String eventTitle;
  final String? eventCoverImageUrl;
  final String categoryName;
  final String categoryColorHex;
  final String venueName;
  final String? cityName;
  final DateTime eventStartsAt;
  final DateTime createdAt;

  FavoriteResponse({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    this.eventCoverImageUrl,
    required this.categoryName,
    required this.categoryColorHex,
    required this.venueName,
    this.cityName,
    required this.eventStartsAt,
    required this.createdAt,
  });

  factory FavoriteResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteResponse(
      id: json['id'] as int,
      eventId: json['eventId'] as int,
      eventTitle: json['eventTitle'] as String,
      eventCoverImageUrl: json['eventCoverImageUrl'] as String?,
      categoryName: json['categoryName'] as String,
      categoryColorHex: json['categoryColorHex'] as String,
      venueName: json['venueName'] as String,
      cityName: json['cityName'] as String?,
      eventStartsAt: DateTime.parse(json['eventStartsAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
