import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storify/models/item.dart';
import 'package:storify/models/location.dart';
import 'package:storify/providers/item_provider.dart';
import 'package:storify/providers/location_provider.dart';
import 'package:storify/screens/barcode_scanner_screen.dart';
import 'package:storify/l10n/app_localizations.dart';
import 'package:storify/utils/constants.dart';
import 'package:storify/widgets/barcode_match_sheet.dart';

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
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _quantityCtrl;
  int? _selectedLocationId;
  DateTime? _expiryDate;
  bool _isSaving = false;

  bool get _isEditMode => widget.item != null;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _nameCtrl = TextEditingController(text: i?.name ?? '');
    _descriptionCtrl = TextEditingController(text: i?.description ?? '');
    _categoryCtrl = TextEditingController(text: i?.category ?? '');
    _barcodeCtrl = TextEditingController(text: i?.barcode ?? widget.initialBarcode ?? '');
    _quantityCtrl = TextEditingController(text: i != null ? '${i.quantity}' : '1');
    _selectedLocationId = i?.locationId ?? widget.initialLocationId;
    _expiryDate = i?.expiryDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _categoryCtrl.dispose();
    _barcodeCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = context.watch<LocationProvider>().locations;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l.editItem : l.newItem),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildField(
              controller: _nameCtrl,
              label: '${l.fieldName} *',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.fieldRequired : null,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _descriptionCtrl,
              label: '${l.fieldDescription} *',
              maxLines: 3,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.fieldRequired : null,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _categoryCtrl,
              label: '${l.fieldCategory} *',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l.fieldRequired : null,
            ),
            const SizedBox(height: 14),
            _buildBarcodeField(),
            const SizedBox(height: 14),
            _buildQuantityField(),
            const SizedBox(height: 14),
            _buildLocationDropdown(locations),
            const SizedBox(height: 14),
            _buildExpiryField(),
            const SizedBox(height: 28),
            _buildSaveButton(),
          ],
        ),
      ),
    );
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

  Widget _buildBarcodeField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _barcodeCtrl,
            style: GoogleFonts.inter(color: context.colorTextPrimary),
            decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldBarcode),
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
            decoration: InputDecoration(labelText: '${AppLocalizations.of(context)!.fieldStock} *'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? AppLocalizations.of(context)!.fieldRequired : null,
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
      onChanged: (v) => setState(() => _selectedLocationId = v),
      validator: (v) => v == null ? AppLocalizations.of(context)!.mustSelectLocation : null,
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
    // Exclude the current item's ID (don't flag its own barcode as a duplicate when editing)
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
            if (mounted) showAppSnackBar(context, AppLocalizations.of(context)!.toastError, isError: true);
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
            if (mounted) showAppSnackBar(context, AppLocalizations.of(context)!.toastError, isError: true);
          }
        },
        onTransfer: (item, newLocationId, quantity) async {
          Navigator.pop(ctx);
          try {
            final newLocation = locProv.locations
                .where((l) => l.id == newLocationId)
                .firstOrNull;
            await itemProv.transferItem(
              item,
              newLocationId,
              newLocation?.name,
              quantity,
            );
            if (mounted) {
              showAppSnackBar(context, AppLocalizations.of(context)!.toastTransferred,
                  isSuccess: true);
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) showAppSnackBar(context, AppLocalizations.of(context)!.toastError, isError: true);
          }
        },
        onPrefillForm: (item) {
          Navigator.pop(ctx);
          setState(() {
            _barcodeCtrl.text = barcode;
            _nameCtrl.text = item.name;
            _descriptionCtrl.text = item.description;
            _categoryCtrl.text = item.category;
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
    final formatted = _expiryDate == null
        ? 'No date'
        : '${_expiryDate!.day.toString().padLeft(2, '0')}.${_expiryDate!.month.toString().padLeft(2, '0')}.${_expiryDate!.year}';
    return InkWell(
      onTap: _pickExpiry,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldExpiry),
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
                onTap: () => setState(() => _expiryDate = null),
                child: Icon(Icons.clear, size: 18, color: context.colorTextMuted),
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
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final itemData = Item(
        id: widget.item?.id ?? 0,
        name: _nameCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        barcode: _barcodeCtrl.text.trim().isEmpty
            ? null
            : _barcodeCtrl.text.trim(),
        quantity: int.parse(_quantityCtrl.text.trim()),
        locationId: _selectedLocationId!,
        expiryDate: _expiryDate,
      );

      final provider = context.read<ItemProvider>();
      if (_isEditMode) {
        await provider.updateItem(widget.item!.id, itemData);
      } else {
        await provider.createItem(itemData);
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
              'Error saving',
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
