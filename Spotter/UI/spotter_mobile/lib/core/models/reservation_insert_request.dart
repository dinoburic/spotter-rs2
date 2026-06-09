class ReservationInsertRequest {
  final int eventId;
  final String? note;

  ReservationInsertRequest({
    required this.eventId,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      if (note != null) 'note': note,
    };
  }
}
