class UserUpdateRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final int cityId;

  UserUpdateRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    required this.cityId,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'cityId': cityId,
    };
  }
}
