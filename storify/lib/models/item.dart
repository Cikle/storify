import 'package:storify/utils/constants.dart';

// Data model for an item (table: items)
class Item {
  final int id;
  final String name;
  final String? description;
  final String? category;
  final String? barcode;
  final int quantity;
  final int locationId;
  final String? locationName;
  final DateTime? expiryDate;
  final String? unit;
  final int? criticalThreshold;
  final int? warningDays;
  final int? packSize;
  final String? photoUrl;

  const Item({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.barcode,
    required this.quantity,
    required this.locationId,
    this.locationName,
    this.expiryDate,
    this.unit,
    this.criticalThreshold,
    this.warningDays,
    this.packSize,
    this.photoUrl,
  });

  // true if stock is below threshold (per-item override or global constant)
  bool get isLowStock => quantity < (criticalThreshold ?? kLowStockThreshold);

  // true if expiration date is in the past
  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  // true if expiration date is within warning window (per-item or global)
  bool get isExpiringSoon =>
      expiryDate != null &&
      !isExpired &&
      expiryDate!.isBefore(
        DateTime.now().add(Duration(days: warningDays ?? kExpiringSoonDays)),
      );

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
      description: json['description'] as String?,
      category: json['category'] as String?,
      barcode: json['barcode'] as String?,
      quantity: int.parse(json['quantity'].toString()),
      locationId: int.parse(json['location_id'].toString()),
      locationName: json['location_name'] as String?,
      expiryDate: expiryDate,
      unit: json['unit'] as String?,
      criticalThreshold: json['critical_threshold'] != null
          ? int.tryParse(json['critical_threshold'].toString())
          : null,
      warningDays: json['warning_days'] != null
          ? int.tryParse(json['warning_days'].toString())
          : null,
      packSize: json['pack_size'] != null
          ? int.tryParse(json['pack_size'].toString())
          : null,
      photoUrl: json['photo_url'] as String?,
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
      if (unit != null && unit!.isNotEmpty) 'unit': unit,
      if (criticalThreshold != null) 'critical_threshold': criticalThreshold,
      if (warningDays != null) 'warning_days': warningDays,
      if (packSize != null) 'pack_size': packSize,
      // photo_url is managed exclusively via the /photo endpoint, not PUT
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
    String? unit,
    int? criticalThreshold,
    int? warningDays,
    int? packSize,
    String? photoUrl,
    bool clearPhotoUrl = false,
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
      unit: unit ?? this.unit,
      criticalThreshold: criticalThreshold ?? this.criticalThreshold,
      warningDays: warningDays ?? this.warningDays,
      packSize: packSize ?? this.packSize,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
    );
  }
}
