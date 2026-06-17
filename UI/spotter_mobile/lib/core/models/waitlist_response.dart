class WaitlistEntryResponse {
  final int id;
  final int eventId;
  final String eventTitle;
  final int ticketTypeId;
  final String ticketTypeName;
  final int userId;
  final String userFullName;
  final int position;
  final bool isNotified;
  final DateTime? notifiedAt;
  final DateTime createdAt;

  WaitlistEntryResponse({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.ticketTypeId,
    required this.ticketTypeName,
    required this.userId,
    required this.userFullName,
    required this.position,
    required this.isNotified,
    this.notifiedAt,
    required this.createdAt,
  });

  factory WaitlistEntryResponse.fromJson(Map<String, dynamic> json) {
    return WaitlistEntryResponse(
      id: json['id'] as int,
      eventId: json['eventId'] as int,
      eventTitle: json['eventTitle'] as String,
      ticketTypeId: json['ticketTypeId'] as int,
      ticketTypeName: json['ticketTypeName'] as String,
      userId: json['userId'] as int,
      userFullName: json['userFullName'] as String,
      position: json['position'] as int,
      isNotified: json['isNotified'] as bool,
      notifiedAt: json['notifiedAt'] != null
          ? DateTime.parse(json['notifiedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
