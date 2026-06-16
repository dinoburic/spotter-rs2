class OrderInsertRequest {
  final int eventId;
  final List<OrderItemRequest> items;
  final int spotterPointsToRedeem;

  OrderInsertRequest({
    required this.eventId,
    required this.items,
    this.spotterPointsToRedeem = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'items': items.map((e) => e.toJson()).toList(),
      'spotterPointsToRedeem': spotterPointsToRedeem,
    };
  }
}

class OrderItemRequest {
  final int ticketTypeId;
  final int quantity;

  OrderItemRequest({
    required this.ticketTypeId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'ticketTypeId': ticketTypeId,
      'quantity': quantity,
    };
  }
}
