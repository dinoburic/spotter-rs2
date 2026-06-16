class UserResponse {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final int cityId;
  final String cityName;
  final String role;
  final int spotterPointsBalance;
  final DateTime createdAt;

  UserResponse({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    required this.cityId,
    required this.cityName,
    required this.role,
    required this.spotterPointsBalance,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as int,
      username: json['username'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      cityId: json['cityId'] as int,
      cityName: json['cityName'] as String,
      role: json['role'] as String,
      spotterPointsBalance: json['spotterPointsBalance'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
