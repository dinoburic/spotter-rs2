class ReservationInsertRequest {
  final int eventId;
  final int ticketTypeId;
  final int quantity;
  final String? note;

  ReservationInsertRequest({
    required this.eventId,
    required this.ticketTypeId,
    this.quantity = 1,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'ticketTypeId': ticketTypeId,
      'quantity': quantity,
      if (note != null) 'note': note,
    };
  }
}
