class RecommendationResponse {
  final int eventId;
  final String title;
  final String categoryName;
  final String categoryColorHex;
  final String? coverImageUrl;
  final DateTime startsAt;
  final String venueName;
  final String cityName;
  final double score;
  final String explanation;

  RecommendationResponse({
    required this.eventId,
    required this.title,
    required this.categoryName,
    required this.categoryColorHex,
    this.coverImageUrl,
    required this.startsAt,
    required this.venueName,
    required this.cityName,
    required this.score,
    required this.explanation,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationResponse(
      eventId: json['eventId'] as int,
      title: json['title'] as String,
      categoryName: json['categoryName'] as String,
      categoryColorHex: json['categoryColorHex'] as String,
      coverImageUrl: json['coverImageUrl'] as String?,
      startsAt: DateTime.parse(json['startsAt'] as String),
      venueName: json['venueName'] as String,
      cityName: json['cityName'] as String,
      score: (json['score'] as num).toDouble(),
      explanation: json['explanation'] as String,
    );
  }
}
