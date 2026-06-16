class CityRequest {
  final String name;
  final String country;

  CityRequest({
    required this.name,
    required this.country,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'country': country,
      };
}
