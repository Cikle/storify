import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storify/models/location.dart';
import 'package:storify/providers/location_provider.dart';
import 'package:storify/l10n/app_localizations.dart';
import 'package:storify/utils/constants.dart';

// Location form – location == null → create new, otherwise edit
class LocationFormScreen extends StatefulWidget {
  final Location? location;

  const LocationFormScreen({super.key, this.location});

  @override
  State<LocationFormScreen> createState() => _LocationFormScreenState();
}

class _LocationFormScreenState extends State<LocationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  bool _isSaving = false;

  bool get _isEditMode => widget.location != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.location?.name ?? '',
    );
    _descCtrl = TextEditingController(
      text: widget.location?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l.editLocation : l.newLocation),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              style: GoogleFonts.inter(color: context.colorTextPrimary),
              decoration: InputDecoration(
                labelText: '${l.fieldLocationName} *',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.fieldRequired : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              style: GoogleFonts.inter(color: context.colorTextPrimary),
              decoration: InputDecoration(
                labelText: l.fieldDescription,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(_isEditMode ? l.btnSave : l.btnCreate),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final locationData = Location(
        id: widget.location?.id ?? 0,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
      );

      final prov = context.read<LocationProvider>();
      if (_isEditMode) {
        await prov.updateLocation(widget.location!.id, locationData);
      } else {
        await prov.createLocation(locationData);
      }

      if (mounted) {
        FocusScope.of(context).unfocus();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: context.colorCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: context.colorBorder),
            ),
            title: Text(
              AppLocalizations.of(context)!.errorSaveTitle,
              style: GoogleFonts.inter(
                color: context.colorTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              e.toString(),
              style: GoogleFonts.inter(color: context.colorTextSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
