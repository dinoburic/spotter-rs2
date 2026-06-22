class SystemSettingUpdateRequest {
  final String value;

  SystemSettingUpdateRequest({required this.value});

  Map<String, dynamic> toJson() => {'value': value};
}
