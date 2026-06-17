class TicketTypeInsertRequest {
  final int eventId;
  final String name;
  final double price;
  final int totalQuantity;
  final int typeEnum;

  TicketTypeInsertRequest({
    required this.eventId,
    required this.name,
    required this.price,
    required this.totalQuantity,
    required this.typeEnum,
  });

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'name': name,
        'price': price,
        'totalQuantity': totalQuantity,
        'typeEnum': typeEnum,
      };
}
