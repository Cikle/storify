// Data model for a location (table: locations)
class Location {
  final int id;
  final String name;
  final String? description;

  const Location({
    required this.id,
    required this.name,
    this.description,
  });

  // JSON → Location
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: int.parse(json['id'].toString()),
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  // Location → JSON for API
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
    };
  }

  Location copyWith({
    int? id,
    String? name,
    String? description,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  @override
  String toString() => name;
}
