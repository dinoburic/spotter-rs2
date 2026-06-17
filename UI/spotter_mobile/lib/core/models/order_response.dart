import 'order_item_response.dart';

class OrderResponse {
  final int id;
  final int eventId;
  final String eventTitle;
  final int userId;
  final String userFullName;
  final DateTime createdAt;
  final int status;
  final String statusName;
  final double totalAmount;
  final int spotterPointsRedeemed;
  final double discountApplied;
  final List<OrderItemResponse> items;

  OrderResponse({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.userId,
    required this.userFullName,
    required this.createdAt,
    required this.status,
    required this.statusName,
    required this.totalAmount,
    required this.spotterPointsRedeemed,
    required this.discountApplied,
    required this.items,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      id: json['id'] as int,
      eventId: json['eventId'] as int,
      eventTitle: json['eventTitle'] as String,
      userId: json['userId'] as int,
      userFullName: json['userFullName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as int,
      statusName: json['statusName'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      spotterPointsRedeemed: json['spotterPointsRedeemed'] as int? ?? 0,
      discountApplied: (json['discountApplied'] as num?)?.toDouble() ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemResponse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
