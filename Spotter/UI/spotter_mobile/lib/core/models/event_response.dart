class EventResponse {
  final int id;
  final String title;
  final String? description;
  final int categoryId;
  final String categoryName;
  final String categoryColorHex;
  final int venueId;
  final String venueName;
  final String? venueAddress;
  final int? cityId;
  final String? cityName;
  final int organizerId;
  final String organizerName;
  final DateTime startsAt;
  final DateTime endsAt;
  final int status;
  final String statusName;
  final int totalCapacity;
  final int availableCapacity;
  final String? coverImageUrl;
  final double? venueLatitude;
  final double? venueLongitude;
  final bool venueGeocodingPending;

  EventResponse({
    required this.id,
    required this.title,
    this.description,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColorHex,
    required this.venueId,
    required this.venueName,
    this.venueAddress,
    this.cityId,
    this.cityName,
    required this.organizerId,
    required this.organizerName,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.statusName,
    required this.totalCapacity,
    required this.availableCapacity,
    this.coverImageUrl,
    this.venueLatitude,
    this.venueLongitude,
    required this.venueGeocodingPending,
  });

  factory EventResponse.fromJson(Map<String, dynamic> json) {
    return EventResponse(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      categoryColorHex: json['categoryColorHex'] as String,
      venueId: json['venueId'] as int,
      venueName: json['venueName'] as String,
      venueAddress: json['venueAddress'] as String?,
      cityId: json['cityId'] as int?,
      cityName: json['cityName'] as String?,
      organizerId: json['organizerId'] as int,
      organizerName: json['organizerName'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      status: json['status'] as int,
      statusName: json['statusName'] as String,
      totalCapacity: json['totalCapacity'] as int,
      availableCapacity: json['availableCapacity'] as int,
      coverImageUrl: json['coverImageUrl'] as String?,
      venueLatitude: (json['venueLatitude'] as num?)?.toDouble(),
      venueLongitude: (json['venueLongitude'] as num?)?.toDouble(),
      venueGeocodingPending: json['venueGeocodingPending'] as bool? ?? false,
    );
  }
}
