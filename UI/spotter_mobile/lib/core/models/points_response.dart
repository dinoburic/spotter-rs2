class PointsBalanceResponse {
  final int balance;
  final int totalEarned;
  final int totalRedeemed;

  PointsBalanceResponse({
    required this.balance,
    required this.totalEarned,
    required this.totalRedeemed,
  });

  factory PointsBalanceResponse.fromJson(Map<String, dynamic> json) {
    return PointsBalanceResponse(
      balance: json['balance'] as int,
      totalEarned: json['totalEarned'] as int,
      totalRedeemed: json['totalRedeemed'] as int,
    );
  }
}

class SpotterPointsResponse {
  final int id;
  final int userId;
  final int delta;
  final int source;
  final String sourceName;
  final int? referenceId;
  final DateTime createdAt;

  SpotterPointsResponse({
    required this.id,
    required this.userId,
    required this.delta,
    required this.source,
    required this.sourceName,
    this.referenceId,
    required this.createdAt,
  });

  factory SpotterPointsResponse.fromJson(Map<String, dynamic> json) {
    return SpotterPointsResponse(
      id: json['id'] as int,
      userId: json['userId'] as int,
      delta: json['delta'] as int,
      source: json['source'] as int,
      sourceName: json['sourceName'] as String,
      referenceId: json['referenceId'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
