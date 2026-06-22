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
  final DateTime? eventStartsAt;
  final String? venueName;
  final String? cityName;

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
    this.eventStartsAt,
    this.venueName,
    this.cityName,
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
      eventStartsAt: json['eventStartsAt'] != null
          ? DateTime.parse(json['eventStartsAt'] as String)
          : null,
      venueName: json['venueName'] as String?,
      cityName: json['cityName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userFullName': userFullName,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'ticketTypeName': ticketTypeName,
      'typeName': typeName,
      'qrCodePayload': qrCodePayload,
      'status': status,
      'statusName': statusName,
      'issuedAt': issuedAt.toIso8601String(),
      'usedAt': usedAt?.toIso8601String(),
      'eventStartsAt': eventStartsAt?.toIso8601String(),
      'venueName': venueName,
      'cityName': cityName,
    };
  }
}
