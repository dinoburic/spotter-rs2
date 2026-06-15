class ApiConstants {
  static final String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5126',
  );

  static const String login = '/api/access/login';
  static const String refresh = '/api/access/refresh';
  static const String logout = '/api/access/logout';
  static const String users = '/api/Users';
  static const String cities = '/api/cities';
  static const String categories = '/api/categories';
  static const String venues = '/api/venues';
  static const String events = '/api/events';
  static const String ticketTypes = '/api/ticket-types';
  static const String orders = '/api/orders';
  static const String tickets = '/api/tickets';
  static const String reviews = '/api/reviews';
  static const String reservations = '/api/reservations';
  static const String notifications = '/api/notifications';
  static const String points = '/api/points';
  static const String badges = '/api/badges';
  static const String waitlist = '/api/waitlist';
}
