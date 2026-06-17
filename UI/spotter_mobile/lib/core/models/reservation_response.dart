class ReservationResponse {
  final int id;
  final int eventId;
  final String eventTitle;
  final int userId;
  final String userFullName;
  final int status;
  final String statusName;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? auditNote;
  final DateTime createdAt;

  ReservationResponse({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.userId,
    required this.userFullName,
    required this.status,
    required this.statusName,
    this.approvedByName,
    this.approvedAt,
    this.auditNote,
    required this.createdAt,
  });

  factory ReservationResponse.fromJson(Map<String, dynamic> json) {
    return ReservationResponse(
      id: json['id'] as int,
      eventId: json['eventId'] as int,
      eventTitle: json['eventTitle'] as String,
      userId: json['userId'] as int,
      userFullName: json['userFullName'] as String,
      status: json['status'] as int,
      statusName: json['statusName'] as String,
      approvedByName: json['approvedByName'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      auditNote: json['auditNote'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
