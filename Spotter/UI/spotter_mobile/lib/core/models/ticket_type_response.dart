class TicketTypeResponse {
  final int id;
  final int eventId;
  final String eventTitle;
  final String name;
  final double price;
  final int totalQuantity;
  final int soldQuantity;
  final int availableQuantity;
  final int typeEnum;
  final String typeName;

  TicketTypeResponse({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.name,
    required this.price,
    required this.totalQuantity,
    required this.soldQuantity,
    required this.availableQuantity,
    required this.typeEnum,
    required this.typeName,
  });

  factory TicketTypeResponse.fromJson(Map<String, dynamic> json) {
    return TicketTypeResponse(
      id: json['id'] as int,
      eventId: json['eventId'] as int,
      eventTitle: json['eventTitle'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      totalQuantity: json['totalQuantity'] as int,
      soldQuantity: json['soldQuantity'] as int,
      availableQuantity: json['availableQuantity'] as int,
      typeEnum: json['typeEnum'] as int,
      typeName: json['typeName'] as String,
    );
  }
}
