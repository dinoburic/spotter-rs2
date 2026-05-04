class UserUpdateRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final int? cityId;

  UserUpdateRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.cityId,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'cityId': cityId,
      };
}
