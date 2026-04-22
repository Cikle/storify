import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:storify/models/item.dart';
import 'package:storify/models/location.dart';

// Exports inventory data as CSV or PDF, and parses CSV for import
class ExportService {
  ExportService._();

  // CSV header row
  static const _headers = [
    'id',
    'name',
    'description',
    'category',
    'barcode',
    'quantity',
    'location_id',
    'location_name',
    'expiry_date',
  ];

  // Exports all items as a CSV file (UTF-8 with BOM for Excel)
  static Future<File> exportCsv(
      List<Item> items, List<Location> locations) async {
    final rows = <List<dynamic>>[_headers];
    for (final item in items) {
      rows.add([
        item.id,
        item.name,
        item.description,
        item.category,
        item.barcode ?? '',
        item.quantity,
        item.locationId,
        item.locationName ?? '',
        item.expiryDate != null
            ? item.expiryDate!.toIso8601String().substring(0, 10)
            : '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    // UTF-8 BOM so Excel on Windows reads special characters correctly
    final content = '﻿$csv';

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/storify_inventory_$timestamp.csv');
    await file.writeAsString(content, encoding: utf8);
    return file;
  }

  // Exports all items as a PDF report
  static Future<File> exportPdf(
      List<Item> items, List<Location> locations) async {
    final doc = pw.Document();

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

    const primaryColor = PdfColor.fromInt(0xFF3ECF8E);
    const lightGray = PdfColor.fromInt(0xFFF5F5F7);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Storify – Inventory Report',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  dateStr,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${items.length} items · ${locations.length} locations',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.Divider(color: primaryColor, thickness: 1.5),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Category', 'Location', 'Quantity', 'Expiry date'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: primaryColor),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
            oddRowDecoration: const pw.BoxDecoration(color: lightGray),
            data: items.map((item) => [
              item.name,
              item.category,
              item.locationName ?? '',
              '${item.quantity} pcs.',
              item.expiryDate != null
                  ? '${item.expiryDate!.day.toString().padLeft(2, '0')}.${item.expiryDate!.month.toString().padLeft(2, '0')}.${item.expiryDate!.year}'
                  : '–',
            ]).toList(),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/storify_report_$timestamp.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  // Returns CSV content as bytes (for FilePicker.saveFile)
  static Future<Uint8List> exportCsvBytes(
      List<Item> items, List<Location> locations) async {
    final rows = <List<dynamic>>[_headers];
    for (final item in items) {
      rows.add([
        item.id,
        item.name,
        item.description,
        item.category,
        item.barcode ?? '',
        item.quantity,
        item.locationId,
        item.locationName ?? '',
        item.expiryDate != null
            ? item.expiryDate!.toIso8601String().substring(0, 10)
            : '',
      ]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    final content = '﻿$csv';
    return Uint8List.fromList(utf8.encode(content));
  }

  // Returns PDF content as bytes (for FilePicker.saveFile)
  static Future<Uint8List> exportPdfBytes(
      List<Item> items, List<Location> locations) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    const primaryColor = PdfColor.fromInt(0xFF3ECF8E);
    const lightGray = PdfColor.fromInt(0xFFF5F5F7);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Storify – Inventory Report',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text(dateStr, style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text('${items.length} items · ${locations.length} locations',
                style: const pw.TextStyle(fontSize: 11)),
            pw.Divider(color: primaryColor, thickness: 1.5),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Category', 'Location', 'Quantity', 'Expiry date'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: primaryColor),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
            oddRowDecoration: const pw.BoxDecoration(color: lightGray),
            data: items.map((item) => [
              item.name,
              item.category,
              item.locationName ?? '',
              '${item.quantity} pcs.',
              item.expiryDate != null
                  ? '${item.expiryDate!.day.toString().padLeft(2, '0')}.${item.expiryDate!.month.toString().padLeft(2, '0')}.${item.expiryDate!.year}'
                  : '–',
            ]).toList(),
          ),
        ],
      ),
    );
    return await doc.save();
  }

  // Parses a CSV file and returns the rows as maps
  static Future<List<Map<String, dynamic>>> parseCsv(File file) async {
    final content = await file.readAsString(encoding: utf8);
    // Strip BOM if present
    final cleaned =
        content.startsWith('﻿') ? content.substring(1) : content;

    final rows = const CsvToListConverter().convert(cleaned);
    if (rows.isEmpty) throw Exception('CSV is empty.');

    // Treat first row as header
    final headers = rows.first.map((h) => h.toString().trim().toLowerCase()).toList();
    final result = <Map<String, dynamic>>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      final map = <String, dynamic>{};
      for (int j = 0; j < headers.length && j < row.length; j++) {
        map[headers[j]] = row[j];
      }

      // Validate required fields
      if ((map['name'] ?? '').toString().trim().isEmpty) {
        throw Exception('Row ${i + 1}: "name" is missing.');
      }

      result.add(map);
    }

    return result;
  }
}
