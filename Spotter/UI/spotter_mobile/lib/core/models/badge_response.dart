class BadgeResponse {
  final int id;
  final String name;
  final String description;
  final String? iconUrl;

  BadgeResponse({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
  });

  factory BadgeResponse.fromJson(Map<String, dynamic> json) {
    return BadgeResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String?,
    );
  }
}

class UserBadgeResponse {
  final int id;
  final int badgeId;
  final String badgeName;
  final String badgeDescription;
  final String? badgeIconUrl;
  final DateTime earnedAt;

  UserBadgeResponse({
    required this.id,
    required this.badgeId,
    required this.badgeName,
    required this.badgeDescription,
    this.badgeIconUrl,
    required this.earnedAt,
  });

  factory UserBadgeResponse.fromJson(Map<String, dynamic> json) {
    return UserBadgeResponse(
      id: json['id'] as int,
      badgeId: json['badgeId'] as int,
      badgeName: json['badgeName'] as String,
      badgeDescription: json['badgeDescription'] as String,
      badgeIconUrl: json['badgeIconUrl'] as String?,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
    );
  }
}
