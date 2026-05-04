class TicketResponse {
  final int id;
  final int userId;
  final String userFullName;
  final int eventId;
  final String eventTitle;
  final String ticketTypeName;
  final String typeName;
  final String qrCodePayload;
  final int status;
  final String statusName;
  final DateTime issuedAt;
  final DateTime? usedAt;

  TicketResponse({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.eventId,
    required this.eventTitle,
    required this.ticketTypeName,
    required this.typeName,
    required this.qrCodePayload,
    required this.status,
    required this.statusName,
    required this.issuedAt,
    this.usedAt,
  });

  factory TicketResponse.fromJson(Map<String, dynamic> json) {
    return TicketResponse(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userFullName: json['userFullName'] as String,
      eventId: json['eventId'] as int,
      eventTitle: json['eventTitle'] as String,
      ticketTypeName: json['ticketTypeName'] as String,
      typeName: json['typeName'] as String,
      qrCodePayload: json['qrCodePayload'] as String,
      status: json['status'] as int,
      statusName: json['statusName'] as String,
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      usedAt: json['usedAt'] != null
          ? DateTime.parse(json['usedAt'] as String)
          : null,
    );
  }
}
