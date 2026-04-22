import 'dart:io';
import 'package:storify/models/item.dart';
import 'package:storify/services/api_service.dart';
import 'package:storify/services/export_service.dart';

// Result of a CSV import
class ImportResult {
  final int created;
  final int updated;
  final List<String> errors;

  const ImportResult({
    required this.created,
    required this.updated,
    required this.errors,
  });
}

// Imports items from a CSV file via the API
class ImportService {
  ImportService._();

  static Future<ImportResult> importFromCsv(
      File file, ApiService api) async {
    final rows = await ExportService.parseCsv(file);
    int created = 0;
    int updated = 0;
    final errors = <String>[];

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      try {
        final idRaw = row['id'];
        final id = idRaw != null && idRaw.toString().isNotEmpty
            ? int.tryParse(idRaw.toString())
            : null;

        final name = row['name']?.toString().trim() ?? '';
        final description = row['description']?.toString().trim() ?? '';
        final category = row['category']?.toString().trim() ?? 'General';
        final barcode = row['barcode']?.toString().trim();
        final quantity = int.tryParse(row['quantity']?.toString() ?? '0') ?? 0;
        final locationId =
            int.tryParse(row['location_id']?.toString() ?? '1') ?? 1;
        final expiryRaw = row['expiry_date']?.toString().trim();
        final expiryDate =
            expiryRaw != null && expiryRaw.isNotEmpty
                ? DateTime.tryParse(expiryRaw)
                : null;

        final item = Item(
          id: id ?? 0,
          name: name,
          description: description,
          category: category,
          barcode: barcode?.isNotEmpty == true ? barcode : null,
          quantity: quantity,
          locationId: locationId,
          expiryDate: expiryDate,
        );

        if (id != null && id > 0) {
          // Update existing item
          await api.updateItem(id, item);
          updated++;
        } else {
          // Create new item
          await api.createItem(item);
          created++;
        }
      } on ApiException catch (e) {
        errors.add('Row ${i + 2}: ${e.message}');
      } catch (e) {
        errors.add('Row ${i + 2}: $e');
      }
    }

    return ImportResult(created: created, updated: updated, errors: errors);
  }
}
