class ApiConstants {
  static final String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5126',
  );

  static const String login = '/api/access/login';
  static const String register = '/api/access/register';
  static const String refresh = '/api/access/refresh';
  static const String logout = '/api/access/logout';
  static const String events = '/api/events';
  static const String categories = '/api/categories';
  static const String venues = '/api/venues';
  static const String cities = '/api/cities';
  static const String ticketTypes = '/api/ticket-types';
  static const String orders = '/api/orders';
  static const String tickets = '/api/tickets';
  static const String reservations = '/api/reservations';
  static const String favorites = '/api/favorites';
  static const String notifications = '/api/notifications';
  static const String reviews = '/api/reviews';
  static const String points = '/api/points';
  static const String badges = '/api/badges';
  static const String waitlist = '/api/waitlist';
  static const String recommendations = '/api/recommendations';
  static const String users = '/api/Users';
  static const String payments = '/api/payments';
}
