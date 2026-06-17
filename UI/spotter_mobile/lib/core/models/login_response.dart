class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final int userId;
  final String username;
  final String role;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.username,
    required this.role,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      userId: json['userId'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
    );
  }
}
