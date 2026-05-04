class UserResponse {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String role;
  final int? cityId;
  final String? cityName;
  final bool isActive;
  final DateTime createdAt;
  final String? phoneNumber;

  UserResponse({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.role,
    this.cityId,
    this.cityName,
    required this.isActive,
    required this.createdAt,
    this.phoneNumber,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      cityId: json['cityId'] as int?,
      cityName: json['cityName'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  String get fullName => '$firstName $lastName';
}
