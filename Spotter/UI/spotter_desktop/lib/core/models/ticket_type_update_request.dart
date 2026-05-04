class TicketTypeUpdateRequest {
  final String name;
  final double price;
  final int totalQuantity;

  TicketTypeUpdateRequest({
    required this.name,
    required this.price,
    required this.totalQuantity,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'totalQuantity': totalQuantity,
      };
}
