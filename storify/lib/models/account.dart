// Data model for an API account (multi-account support)
class AppAccount {
  final String name;
  final String baseUrl;
  final String apiKey;
  final bool isActive;

  const AppAccount({
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    this.isActive = false,
  });

  factory AppAccount.fromJson(Map<String, dynamic> json) {
    return AppAccount(
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      apiKey: json['apiKey'] as String,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'isActive': isActive,
    };
  }

  AppAccount copyWith({
    String? name,
    String? baseUrl,
    String? apiKey,
    bool? isActive,
  }) {
    return AppAccount(
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() => name;
}
