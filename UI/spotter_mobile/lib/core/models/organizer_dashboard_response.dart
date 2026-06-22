class OrganizerDashboardResponse {
  final double totalRevenue;
  final int totalTicketsSold;
  final int activeEventsCount;
  final int totalEventsCount;
  final List<MonthlyRevenueItem> monthlyRevenue;
  final List<TopEventItem> topEvents;

  OrganizerDashboardResponse({
    required this.totalRevenue,
    required this.totalTicketsSold,
    required this.activeEventsCount,
    required this.totalEventsCount,
    required this.monthlyRevenue,
    required this.topEvents,
  });

  factory OrganizerDashboardResponse.fromJson(Map<String, dynamic> json) {
    return OrganizerDashboardResponse(
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalTicketsSold: json['totalTicketsSold'] as int,
      activeEventsCount: json['activeEventsCount'] as int,
      totalEventsCount: json['totalEventsCount'] as int,
      monthlyRevenue: (json['monthlyRevenue'] as List<dynamic>)
          .map((e) => MonthlyRevenueItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      topEvents: (json['topEvents'] as List<dynamic>)
          .map((e) => TopEventItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MonthlyRevenueItem {
  final int year;
  final int month;
  final String monthName;
  final double revenue;
  final int ticketsSold;

  MonthlyRevenueItem({
    required this.year,
    required this.month,
    required this.monthName,
    required this.revenue,
    required this.ticketsSold,
  });

  factory MonthlyRevenueItem.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenueItem(
      year: json['year'] as int,
      month: json['month'] as int,
      monthName: json['monthName'] as String,
      revenue: (json['revenue'] as num).toDouble(),
      ticketsSold: json['ticketsSold'] as int,
    );
  }
}

class TopEventItem {
  final int eventId;
  final String title;
  final int ticketsSold;
  final double revenue;

  TopEventItem({
    required this.eventId,
    required this.title,
    required this.ticketsSold,
    required this.revenue,
  });

  factory TopEventItem.fromJson(Map<String, dynamic> json) {
    return TopEventItem(
      eventId: json['eventId'] as int,
      title: json['title'] as String,
      ticketsSold: json['ticketsSold'] as int,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}
