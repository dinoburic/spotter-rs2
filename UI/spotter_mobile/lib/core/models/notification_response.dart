class NotificationResponse {
  final int id;
  final int userId;
  final String title;
  final String body;
  final int type;
  final String typeName;
  final int? referenceId;
  final bool isRead;
  final DateTime createdAt;

  NotificationResponse({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.typeName,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    int? refId;
    if (json['referenceId'] != null) {
      if (json['referenceId'] is int) {
        refId = json['referenceId'] as int;
      } else if (json['referenceId'] is String) {
        refId = int.tryParse(json['referenceId'] as String);
      }
    }

    return NotificationResponse(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as int,
      typeName: json['typeName'] as String,
      referenceId: refId,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
