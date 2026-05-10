class WaitlistJoinRequest {
  final int eventId;
  final int ticketTypeId;

  WaitlistJoinRequest({
    required this.eventId,
    required this.ticketTypeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'ticketTypeId': ticketTypeId,
    };
  }
}
