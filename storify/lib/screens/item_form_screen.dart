import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:storify/models/item.dart';
import 'package:storify/models/location.dart';
import 'package:storify/providers/item_provider.dart';
import 'package:storify/providers/location_provider.dart';
import 'package:storify/screens/barcode_scanner_screen.dart';
import 'package:storify/services/api_service.dart';
import 'package:storify/services/storage_service.dart';
import 'package:storify/l10n/app_localizations.dart';
import 'package:storify/utils/constants.dart';
import 'package:storify/widgets/barcode_match_sheet.dart';

const _kUnits = [
  'Gramm',
  'Packung',
  'Rollen',
  'Stück',
  'Flaschen',
  'Dosen',
  'Tuben',
];

// Item form – item == null → create new, otherwise edit
class ItemFormScreen extends StatefulWidget {
  final Item? item;
  final int? initialLocationId;
  final String? initialBarcode;

  const ItemFormScreen({
    super.key,
    this.item,
    this.initialLocationId,
    this.initialBarcode,
  });

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _categoryCtrl;
  final FocusNode _categoryFocusNode = FocusNode();
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _criticalThresholdCtrl;
  late final TextEditingController _warningDaysCtrl;
  late final TextEditingController _packSizeCtrl;
  int? _selectedLocationId;
  DateTime? _expiryDate;
  String? _selectedUnit;
  File? _pickedPhoto;
  String? _existingPhotoUrl;
  bool _isSaving = false;
  bool _isDirty = false;

  final _imagePicker = ImagePicker();

  bool get _isEditMode => widget.item != null;

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _nameCtrl = TextEditingController(text: i?.name ?? '');
    _descriptionCtrl = TextEditingController(text: i?.description ?? '');
    _categoryCtrl = TextEditingController(text: i?.category ?? '');
    _barcodeCtrl = TextEditingController(text: i?.barcode ?? widget.initialBarcode ?? '');
    _quantityCtrl = TextEditingController(text: i != null ? '${i.quantity}' : '1');
    _criticalThresholdCtrl = TextEditingController(
        text: i?.criticalThreshold != null ? '${i!.criticalThreshold}' : '');
    _warningDaysCtrl = TextEditingController(
        text: i?.warningDays != null ? '${i!.warningDays}' : '');
    _packSizeCtrl = TextEditingController(
        text: i?.packSize != null ? '${i!.packSize}' : '');
    _selectedLocationId = i?.locationId ?? widget.initialLocationId;
    _expiryDate = i?.expiryDate;
    _selectedUnit = i?.unit;
    _existingPhotoUrl = i?.photoUrl;

    for (final c in [_nameCtrl, _descriptionCtrl, _categoryCtrl, _barcodeCtrl,
                     _quantityCtrl, _criticalThresholdCtrl, _warningDaysCtrl, _packSizeCtrl]) {
      c.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _descriptionCtrl, _categoryCtrl, _barcodeCtrl,
                     _quantityCtrl, _criticalThresholdCtrl, _warningDaysCtrl, _packSizeCtrl]) {
      c.removeListener(_markDirty);
      c.dispose();
    }
    _categoryFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = context.watch<LocationProvider>().locations;
    final l = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: ctx.colorCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: ctx.colorBorder),
            ),
            title: Text(l.unsavedChangesTitle,
                style: GoogleFonts.inter(
                    color: ctx.colorTextPrimary, fontWeight: FontWeight.w700)),
            content: Text(l.unsavedChangesBody,
                style: GoogleFonts.inter(color: ctx.colorTextSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.btnCancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.btnDiscard),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_isEditMode ? l.editItem : l.newItem),
            if (_isDirty) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_isDirty && !_isSaving)
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: l.btnSave,
              onPressed: _save,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo picker at top
            _buildPhotoSection(),
            const SizedBox(height: 14),
            _buildField(
              controller: _nameCtrl,
              label: '${l.fieldName} *',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.fieldRequired : null,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _descriptionCtrl,
              label: l.fieldDescription,
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            _buildCategoryField(),
            const SizedBox(height: 14),
            _buildUnitDropdown(),
            if (_selectedUnit != null) ...[
              const SizedBox(height: 14),
              _buildField(
                controller: _packSizeCtrl,
                label: l.fieldPackSize,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
            const SizedBox(height: 14),
            _buildBarcodeField(),
            const SizedBox(height: 14),
            _buildQuantityField(),
            const SizedBox(height: 14),
            _buildLocationDropdown(locations),
            const SizedBox(height: 14),
            _buildExpiryField(),
            const SizedBox(height: 14),
            _buildField(
              controller: _warningDaysCtrl,
              label: l.fieldWarningDays,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _criticalThresholdCtrl,
              label: l.fieldCriticalThreshold,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 28),
            _buildSaveButton(),
          ],
        ),
      ),
    ), // Scaffold
    ); // PopScope
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(color: context.colorTextPrimary),
      decoration: InputDecoration(labelText: label),
      validator: validator,
    );
  }

  Widget _buildCategoryField() {
    final l = AppLocalizations.of(context)!;
    final categories = context.read<ItemProvider>().categories;

    return RawAutocomplete<String>(
      textEditingController: _categoryCtrl,
      focusNode: _categoryFocusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final input = textEditingValue.text.toLowerCase();
        if (input.isEmpty) return const Iterable<String>.empty();
        return categories.where((c) => c.toLowerCase().contains(input));
      },
      onSelected: (String selection) {
        setState(() => _categoryCtrl.text = selection);
        _categoryFocusNode.unfocus();
      },
      fieldViewBuilder: (ctx, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: GoogleFonts.inter(color: context.colorTextPrimary),
          decoration: InputDecoration(labelText: l.fieldCategory),
        );
      },
      optionsViewBuilder: (ctx, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: ctx.colorCard,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final option = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    title: Text(
                      option,
                      style: GoogleFonts.inter(color: ctx.colorTextPrimary),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnitDropdown() {
    final l = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String?>(
      value: _selectedUnit,
      dropdownColor: context.colorCard,
      style: GoogleFonts.inter(color: context.colorTextPrimary),
      decoration: InputDecoration(labelText: l.fieldUnit),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(
            l.labelNoUnit,
            style: GoogleFonts.inter(color: context.colorTextMuted),
          ),
        ),
        ..._kUnits.map(
          (u) => DropdownMenuItem<String?>(
            value: u,
            child: Text(u),
          ),
        ),
      ],
      onChanged: (v) { setState(() => _selectedUnit = v); _markDirty(); },
    );
  }

  Widget _buildPhotoSection() {
    final l = AppLocalizations.of(context)!;
    final hasPhoto = _pickedPhoto != null || _existingPhotoUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPhoto) ...[
          GestureDetector(
            onTap: () => _openPhotoFullscreen(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _pickedPhoto != null
                  ? Image.file(
                      _pickedPhoto!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      _buildPhotoUrl(context, _existingPhotoUrl!),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: context.colorCard,
                        child: Icon(Icons.broken_image_outlined,
                            color: context.colorTextMuted, size: 48),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.colorBorder),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                label: Text(
                  hasPhoto ? l.fieldPhoto : l.btnAddPhoto,
                  style: GoogleFonts.inter(color: context.colorTextPrimary),
                ),
                onPressed: () => _pickPhoto(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.colorBorder),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () => _pickPhoto(ImageSource.gallery),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
              ),
            ),
            if (hasPhoto) ...[
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withAlpha(80)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: _removePhoto,
                  child:
                      const Icon(Icons.delete_outline, color: AppColors.error),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _buildPhotoUrl(BuildContext context, String relPath) {
    final base =
        context.read<StorageService>().getApiBaseUrl().replaceAll(RegExp(r'/api/?$'), '');
    return '$base/$relPath';
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _pickedPhoto = File(picked.path);
    });
    _markDirty();
  }

  void _removePhoto() {
    setState(() {
      _pickedPhoto = null;
      _existingPhotoUrl = null;
    });
    _markDirty();
  }

  void _openPhotoFullscreen(BuildContext context) {
    final image = _pickedPhoto != null
        ? Image.file(_pickedPhoto!, fit: BoxFit.contain)
        : Image.network(_buildPhotoUrl(context, _existingPhotoUrl!),
            fit: BoxFit.contain);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(child: InteractiveViewer(child: image)),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _barcodeCtrl,
            style: GoogleFonts.inter(color: context.colorTextPrimary),
            decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.fieldBarcode),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 56,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.colorBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _openScanner,
            child: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 56,
          width: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              side: BorderSide(color: context.colorBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final current = int.tryParse(_quantityCtrl.text) ?? 0;
              if (current > 0) {
                setState(() => _quantityCtrl.text = '${current - 1}');
              }
            },
            child: Icon(Icons.remove, color: context.colorTextSecondary, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _quantityCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: context.colorTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            decoration: InputDecoration(
                labelText: '${AppLocalizations.of(context)!.fieldStock} *'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? AppLocalizations.of(context)!.fieldRequired
                : null,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 56,
          width: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              side: BorderSide(color: context.colorBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final current = int.tryParse(_quantityCtrl.text) ?? 0;
              setState(() => _quantityCtrl.text = '${current + 1}');
            },
            child: const Icon(Icons.add, color: AppColors.primary, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationDropdown(List<Location> locations) {
    final l = AppLocalizations.of(context)!;
    return DropdownButtonFormField<int>(
      initialValue: _selectedLocationId,
      dropdownColor: context.colorCard,
      style: GoogleFonts.inter(color: context.colorTextPrimary),
      decoration: InputDecoration(labelText: '${l.fieldLocation} *'),
      items: locations
          .map(
            (l) => DropdownMenuItem(
              value: l.id,
              child: Text(l.name),
            ),
          )
          .toList(),
      onChanged: (v) { setState(() => _selectedLocationId = v); _markDirty(); },
      validator: (v) =>
          v == null ? AppLocalizations.of(context)!.mustSelectLocation : null,
    );
  }

  Widget _buildSaveButton() {
    final l = AppLocalizations.of(context)!;
    return ElevatedButton(
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
    );
  }

  // Open scanner and check if the barcode is already in use
  Future<void> _openScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result == null || result.isEmpty) return;

    if (!mounted) return;
    final provider = context.read<ItemProvider>();
    final matches = provider.items
        .where((i) => i.barcode == result && i.id != (widget.item?.id ?? 0))
        .toList();

    if (matches.isNotEmpty && mounted) {
      await _showBarcodeMatchSheet(result, matches);
    } else {
      setState(() => _barcodeCtrl.text = result);
    }
  }

  Future<void> _showBarcodeMatchSheet(String barcode, List<Item> matches) async {
    final itemProv = context.read<ItemProvider>();
    final locProv = context.read<LocationProvider>();
    await showModalBottomSheet(
      context: context,
      backgroundColor: context.colorCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => BarcodeMatchSheet(
        barcode: barcode,
        matches: matches,
        onAddStock: (item) async {
          Navigator.pop(ctx);
          try {
            await itemProv.updateItem(
              item.id,
              item.copyWith(quantity: item.quantity + 1),
            );
            if (mounted) {
              showAppSnackBar(
                context,
                AppLocalizations.of(context)!.toastStockUpdated,
                isSuccess: true,
              );
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) {
              showAppSnackBar(context, AppLocalizations.of(context)!.toastError,
                  isError: true);
            }
          }
        },
        onSubtractStock: (item) async {
          Navigator.pop(ctx);
          if (item.quantity <= 0) return;
          try {
            await itemProv.updateItem(
              item.id,
              item.copyWith(quantity: item.quantity - 1),
            );
            if (mounted) {
              showAppSnackBar(
                context,
                AppLocalizations.of(context)!.toastStockUpdated,
                isSuccess: true,
              );
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) {
              showAppSnackBar(context, AppLocalizations.of(context)!.toastError,
                  isError: true);
            }
          }
        },
        onTransfer: (item, newLocationId, quantity) async {
          Navigator.pop(ctx);
          try {
            final newLocation =
                locProv.locations.where((l) => l.id == newLocationId).firstOrNull;
            await itemProv.transferItem(
              item,
              newLocationId,
              newLocation?.name,
              quantity,
            );
            if (mounted) {
              showAppSnackBar(
                  context, AppLocalizations.of(context)!.toastTransferred,
                  isSuccess: true);
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) {
              showAppSnackBar(context, AppLocalizations.of(context)!.toastError,
                  isError: true);
            }
          }
        },
        onPrefillForm: (item) {
          Navigator.pop(ctx);
          setState(() {
            _barcodeCtrl.text = barcode;
            _nameCtrl.text = item.name;
            _descriptionCtrl.text = item.description ?? '';
            _categoryCtrl.text = item.category ?? '';
          });
        },
        onIgnore: () {
          Navigator.pop(ctx);
          setState(() => _barcodeCtrl.text = barcode);
        },
      ),
    );
  }

  Widget _buildExpiryField() {
    final l = AppLocalizations.of(context)!;
    final formatted = _expiryDate == null
        ? l.labelNoDate
        : '${_expiryDate!.day.toString().padLeft(2, '0')}.${_expiryDate!.month.toString().padLeft(2, '0')}.${_expiryDate!.year}';
    return InkWell(
      onTap: _pickExpiry,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(labelText: l.fieldExpiry),
        child: Row(
          children: [
            Expanded(
              child: Text(
                formatted,
                style: GoogleFonts.inter(
                  color: _expiryDate == null
                      ? context.colorTextMuted
                      : context.colorTextPrimary,
                ),
              ),
            ),
            if (_expiryDate != null)
              GestureDetector(
                onTap: () { setState(() => _expiryDate = null); _markDirty(); },
                child:
                    Icon(Icons.clear, size: 18, color: context.colorTextMuted),
              )
            else
              Icon(Icons.calendar_today_outlined,
                  size: 18, color: context.colorTextMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) { setState(() => _expiryDate = picked); _markDirty(); }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final categoryValue =
          _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim();
      final descValue = _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim();
      final packSize = int.tryParse(_packSizeCtrl.text.trim());
      final criticalThreshold =
          int.tryParse(_criticalThresholdCtrl.text.trim());
      final warningDays = int.tryParse(_warningDaysCtrl.text.trim());

      final itemData = Item(
        id: widget.item?.id ?? 0,
        name: _nameCtrl.text.trim(),
        description: descValue,
        category: categoryValue,
        barcode: _barcodeCtrl.text.trim().isEmpty
            ? null
            : _barcodeCtrl.text.trim(),
        quantity: int.parse(_quantityCtrl.text.trim()),
        locationId: _selectedLocationId!,
        expiryDate: _expiryDate,
        unit: _selectedUnit,
        criticalThreshold: criticalThreshold,
        warningDays: warningDays,
        packSize: packSize,
        photoUrl: _pickedPhoto != null ? null : _existingPhotoUrl,
      );

      final provider = context.read<ItemProvider>();
      final api = context.read<ApiService>();
      int savedItemId;

      if (_isEditMode) {
        await provider.updateItem(widget.item!.id, itemData);
        savedItemId = widget.item!.id;
      } else {
        await provider.createItem(itemData);
        // Find newly created item by name + location to get real ID
        final matches = provider.items
            .where((i) =>
                i.name == itemData.name &&
                i.locationId == itemData.locationId)
            .toList();
        savedItemId = matches.isNotEmpty ? matches.last.id : 0;
      }

      // Phase 2: upload new photo if picked (only when we have a real server ID)
      if (_pickedPhoto != null && savedItemId > 0) {
        try {
          await api.uploadItemPhoto(savedItemId, _pickedPhoto!.path);
          await provider.loadItems(silent: true);
        } catch (_) {
          if (mounted) {
            showAppSnackBar(context, AppLocalizations.of(context)!.toastPhotoUploadFailed, isError: true);
          }
        }
      } else if (_pickedPhoto == null && _existingPhotoUrl == null && _isEditMode) {
        // User removed the existing photo
        try {
          await api.deleteItemPhoto(savedItemId);
          await provider.loadItems(silent: true);
        } catch (_) {}
      }

      _isDirty = false;
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
