class UserSuggestionResponse {
  final int userId;
  final String fullName;
  final String username;
  final String? cityName;
  final int mutualFriendsCount;

  UserSuggestionResponse({
    required this.userId,
    required this.fullName,
    required this.username,
    this.cityName,
    required this.mutualFriendsCount,
  });

  factory UserSuggestionResponse.fromJson(Map<String, dynamic> json) {
    return UserSuggestionResponse(
      userId: json['userId'] as int,
      fullName: json['fullName'] as String,
      username: json['username'] as String,
      cityName: json['cityName'] as String?,
      mutualFriendsCount: json['mutualFriendsCount'] as int,
    );
  }
}
