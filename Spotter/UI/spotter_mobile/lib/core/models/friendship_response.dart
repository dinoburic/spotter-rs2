class FriendshipResponse {
  final int id;
  final int requesterId;
  final String requesterName;
  final int addresseeId;
  final String addresseeName;
  final int status;
  final String statusName;
  final DateTime requestedAt;
  final DateTime? respondedAt;

  FriendshipResponse({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.addresseeId,
    required this.addresseeName,
    required this.status,
    required this.statusName,
    required this.requestedAt,
    this.respondedAt,
  });

  factory FriendshipResponse.fromJson(Map<String, dynamic> json) {
    return FriendshipResponse(
      id: json['id'] as int,
      requesterId: json['requesterId'] as int,
      requesterName: json['requesterName'] as String,
      addresseeId: json['addresseeId'] as int,
      addresseeName: json['addresseeName'] as String,
      status: json['status'] as int,
      statusName: json['statusName'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
    );
  }
}
