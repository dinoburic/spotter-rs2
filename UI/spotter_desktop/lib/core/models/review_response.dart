class ReviewResponse {
  final int id;
  final int eventId;
  final String eventTitle;
  final int userId;
  final String userFullName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  ReviewResponse({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.userId,
    required this.userFullName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      id: json['id'] as int,
      eventId: json['eventId'] as int,
      eventTitle: json['eventTitle'] as String,
      userId: json['userId'] as int,
      userFullName: json['userFullName'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
