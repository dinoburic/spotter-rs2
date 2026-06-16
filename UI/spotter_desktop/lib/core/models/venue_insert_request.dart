class VenueInsertRequest {
  final String name;
  final String address;
  final int cityId;
  final double? latitude;
  final double? longitude;

  VenueInsertRequest({
    required this.name,
    required this.address,
    required this.cityId,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'cityId': cityId,
        'latitude': latitude,
        'longitude': longitude,
      };
}
