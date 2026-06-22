class SystemSettingResponse {
  final String key;
  final String value;
  final String? description;
  final DateTime? updatedAt;

  SystemSettingResponse({
    required this.key,
    required this.value,
    this.description,
    this.updatedAt,
  });

  factory SystemSettingResponse.fromJson(Map<String, dynamic> json) {
    return SystemSettingResponse(
      key: json['key'] as String,
      value: json['value'] as String,
      description: json['description'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}
