class ReservationResponse {
  final int id;
  final int eventId;
  final String eventTitle;
  final int ticketTypeId;
  final String ticketTypeName;
  final int quantity;
  final int userId;
  final String userFullName;
  final int status;
  final String statusName;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? auditNote;
  final DateTime createdAt;
  final DateTime? expiresAt;

  ReservationResponse({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.ticketTypeId,
    required this.ticketTypeName,
    required this.quantity,
    required this.userId,
    required this.userFullName,
    required this.status,
    required this.statusName,
    this.approvedByName,
    this.approvedAt,
    this.auditNote,
    required this.createdAt,
    this.expiresAt,
  });

  factory ReservationResponse.fromJson(Map<String, dynamic> json) {
    return ReservationResponse(
      id: json['id'] as int,
      eventId: json['eventId'] as int,
      eventTitle: json['eventTitle'] as String? ?? '',
      ticketTypeId: json['ticketTypeId'] as int? ?? 0,
      ticketTypeName: json['ticketTypeName'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      userId: json['userId'] as int,
      userFullName: json['userFullName'] as String? ?? '',
      status: json['status'] as int,
      statusName: json['statusName'] as String? ?? '',
      approvedByName: json['approvedByName'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      auditNote: json['auditNote'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }
}
