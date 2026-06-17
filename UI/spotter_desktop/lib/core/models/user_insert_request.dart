class UserInsertRequest {
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String password;
  final String confirmPassword;
  final int? cityId;
  final String? phoneNumber;

  UserInsertRequest({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.cityId,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'cityId': cityId,
        'phoneNumber': phoneNumber,
      };
}
