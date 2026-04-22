import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storify/providers/item_provider.dart';
import 'package:storify/providers/location_provider.dart';
import 'package:storify/services/export_service.dart';
import 'package:storify/services/import_service.dart';
import 'package:storify/services/api_service.dart';
import 'package:storify/l10n/app_localizations.dart';
import 'package:storify/utils/constants.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _exportingCsv = false;
  bool _exportingPdf = false;
  bool _importing = false;

  Future<void> _exportCsv() async {
    setState(() => _exportingCsv = true);
    try {
      final items = context.read<ItemProvider>().items;
      final locations = context.read<LocationProvider>().locations;
      final bytes = await ExportService.exportCsvBytes(items.toList(), locations.toList());
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = await FilePicker.platform.saveFile(
        fileName: 'storify_inventar_$timestamp.csv',
        bytes: bytes,
      );
      if (savedPath != null && mounted) {
        showAppSnackBar(context, AppLocalizations.of(context)!.toastSaved, isSuccess: true);
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppLocalizations.of(context)!.toastError, isError: true);
    } finally {
      if (mounted) setState(() => _exportingCsv = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _exportingPdf = true);
    try {
      final items = context.read<ItemProvider>().items;
      final locations = context.read<LocationProvider>().locations;
      final bytes = await ExportService.exportPdfBytes(items.toList(), locations.toList());
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = await FilePicker.platform.saveFile(
        fileName: 'storify_bericht_$timestamp.pdf',
        bytes: bytes,
      );
      if (savedPath != null && mounted) {
        showAppSnackBar(context, AppLocalizations.of(context)!.toastSaved, isSuccess: true);
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppLocalizations.of(context)!.toastError, isError: true);
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    // Vorschau anzeigen
    List<Map<String, dynamic>> preview;
    try {
      preview = await ExportService.parseCsv(
          await _fileFromPath(path));
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppLocalizations.of(context)!.toastError, isError: true);
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ImportPreviewDialog(rows: preview),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _importing = true);
    final api = context.read<ApiService>();
    final itemProv = context.read<ItemProvider>();
    try {
      final importResult = await ImportService.importFromCsv(
          await _fileFromPath(path), api);
      await itemProv.loadItems();
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        showAppSnackBar(
          context,
          l.toastImportResult(importResult.created, importResult.updated),
          isSuccess: true,
        );
        if (importResult.errors.isNotEmpty) {
          showAppSnackBar(
            context,
            l.toastImportErrors(importResult.errors.length),
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppLocalizations.of(context)!.toastError, isError: true);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<File> _fileFromPath(String path) async => File(path);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppBar(
        title: Text(l.exportTitle,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: l.sectionExport),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.table_chart_outlined,
            title: l.exportCsv,
            subtitle: l.exportCsvDesc,
            iconColor: AppColors.success,
            loading: _exportingCsv,
            onTap: _exportCsv,
          ),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.picture_as_pdf_outlined,
            title: l.exportPdf,
            subtitle: l.exportPdfDesc,
            iconColor: AppColors.error,
            loading: _exportingPdf,
            onTap: _exportPdf,
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: l.sectionImport),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.upload_file_outlined,
            title: l.importCsv,
            subtitle: l.importCsvDesc,
            iconColor: AppColors.info,
            loading: _importing,
            onTap: _importCsv,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: context.colorTextMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final bool loading;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colorBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: loading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: iconColor),
                      )
                    : Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            color: context.colorTextPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            color: context.colorTextMuted, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.colorTextMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportPreviewDialog extends StatelessWidget {
  final List<Map<String, dynamic>> rows;

  const _ImportPreviewDialog({required this.rows});

  @override
  Widget build(BuildContext context) {
    final preview = rows.take(3).toList();
    return AlertDialog(
      title: Text('Import-Vorschau',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${rows.length} Artikel gefunden.',
              style: GoogleFonts.inter(color: context.colorTextSecondary)),
          const SizedBox(height: 12),
          ...preview.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• ${row['bezeichnung'] ?? '?'} (${row['bestand'] ?? 0} Stk.)',
                  style: GoogleFonts.inter(
                      color: context.colorTextPrimary, fontSize: 13),
                ),
              )),
          if (rows.length > 3)
            Text('... und ${rows.length - 3} weitere.',
                style:
                    GoogleFonts.inter(color: context.colorTextMuted, fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Importieren', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
