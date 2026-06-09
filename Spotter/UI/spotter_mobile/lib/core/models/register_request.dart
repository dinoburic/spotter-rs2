class RegisterRequest {
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String password;
  final String? phoneNumber;
  final int cityId;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.password,
    this.phoneNumber,
    required this.cityId,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      'password': password,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'cityId': cityId,
    };
  }
}
