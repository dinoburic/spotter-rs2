class VenueResponse {
  final int id;
  final String name;
  final String address;
  final int cityId;
  final String cityName;
  final double? latitude;
  final double? longitude;
  final bool geocodingPending;

  VenueResponse({
    required this.id,
    required this.name,
    required this.address,
    required this.cityId,
    required this.cityName,
    this.latitude,
    this.longitude,
    required this.geocodingPending,
  });

  factory VenueResponse.fromJson(Map<String, dynamic> json) {
    return VenueResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      cityId: json['cityId'] as int,
      cityName: json['cityName'] as String,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      geocodingPending: json['geocodingPending'] as bool? ?? false,
    );
  }
}
