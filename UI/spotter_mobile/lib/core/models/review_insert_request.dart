class ReviewInsertRequest {
  final int eventId;
  final int rating;
  final String? comment;

  ReviewInsertRequest({
    required this.eventId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'rating': rating,
      if (comment != null) 'comment': comment,
    };
  }
}
