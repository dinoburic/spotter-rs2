class OrderItemResponse {
  final int id;
  final int ticketTypeId;
  final String ticketTypeName;
  final String typeName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  OrderItemResponse({
    required this.id,
    required this.ticketTypeId,
    required this.ticketTypeName,
    required this.typeName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItemResponse.fromJson(Map<String, dynamic> json) {
    return OrderItemResponse(
      id: json['id'] as int,
      ticketTypeId: json['ticketTypeId'] as int,
      ticketTypeName: json['ticketTypeName'] as String,
      typeName: json['typeName'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }
}
