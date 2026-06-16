class CityResponse {
  final int id;
  final String name;
  final String country;

  CityResponse({
    required this.id,
    required this.name,
    required this.country,
  });

  factory CityResponse.fromJson(Map<String, dynamic> json) {
    return CityResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      country: json['country'] as String,
    );
  }
}
