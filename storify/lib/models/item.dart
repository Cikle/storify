import 'package:storify/utils/constants.dart';

// Data model for an item (table: items)
class Item {
  final int id;
  final String name;
  final String description;
  final String category;
  final String? barcode;
  final int quantity;
  final int locationId;
  final String? locationName; // joined from the API response
  final DateTime? expiryDate;

  const Item({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.barcode,
    required this.quantity,
    required this.locationId,
    this.locationName,
    this.expiryDate,
  });

  // true if stock is below threshold
  bool get isLowStock => quantity < kLowStockThreshold;

  // true if expiration date is in the past
  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  // true if expiration date is within the next kExpiringSoonDays days
  bool get isExpiringSoon =>
      expiryDate != null &&
      !isExpired &&
      expiryDate!
          .isBefore(DateTime.now().add(Duration(days: kExpiringSoonDays)));

  // JSON → Item (API response)
  factory Item.fromJson(Map<String, dynamic> json) {
    DateTime? expiryDate;
    final expiryRaw = json['expiry_date'];
    if (expiryRaw != null && expiryRaw.toString().isNotEmpty) {
      expiryDate = DateTime.tryParse(expiryRaw.toString());
    }

    return Item(
      id: int.parse(json['id'].toString()),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      barcode: json['barcode'] as String?,
      quantity: int.parse(json['quantity'].toString()),
      locationId: int.parse(json['location_id'].toString()),
      locationName: json['location_name'] as String?,
      expiryDate: expiryDate,
    );
  }

  // Item → JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
      'quantity': quantity,
      'location_id': locationId,
      if (expiryDate != null)
        'expiry_date': expiryDate!.toIso8601String().substring(0, 10),
    };
  }

  Item copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    String? barcode,
    int? quantity,
    int? locationId,
    String? locationName,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
    );
  }
}
