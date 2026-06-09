class EventUpdateRequest {
  final String title;
  final String? description;
  final int categoryId;
  final int venueId;
  final DateTime startsAt;
  final DateTime endsAt;
  final int totalCapacity;
  final String? coverImageUrl;

  EventUpdateRequest({
    required this.title,
    this.description,
    required this.categoryId,
    required this.venueId,
    required this.startsAt,
    required this.endsAt,
    required this.totalCapacity,
    this.coverImageUrl,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'venueId': venueId,
        'startsAt': startsAt.toIso8601String(),
        'endsAt': endsAt.toIso8601String(),
        'totalCapacity': totalCapacity,
        'coverImageUrl': coverImageUrl,
      };
}
