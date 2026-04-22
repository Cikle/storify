import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storify/models/item.dart';
import 'package:storify/models/location.dart';
import 'package:storify/providers/location_provider.dart';
import 'package:storify/l10n/app_localizations.dart';
import 'package:storify/utils/constants.dart';

/// Bottom sheet shown when a scanned barcode matches existing items.
class BarcodeMatchSheet extends StatelessWidget {
  final String barcode;
  final List<Item> matches;
  final Future<void> Function(Item) onAddStock;
  final Future<void> Function(Item) onSubtractStock;
  // quantity = number of items to transfer (may be < item.quantity for partial)
  final Future<void> Function(Item, int newLocationId, int quantity) onTransfer;
  final void Function(Item) onPrefillForm;
  final VoidCallback onIgnore;

  const BarcodeMatchSheet({
    super.key,
    required this.barcode,
    required this.matches,
    required this.onAddStock,
    required this.onSubtractStock,
    required this.onTransfer,
    required this.onPrefillForm,
    required this.onIgnore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_rounded,
                    color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.barcodeAlreadyExists,
                      style: GoogleFonts.inter(
                        color: context.colorTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      barcode,
                      style: GoogleFonts.inter(
                          color: context.colorTextMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...matches.map((item) => _MatchCard(
                item: item,
                onAddStock: () => onAddStock(item),
                onSubtractStock: () => onSubtractStock(item),
                onTransfer: (newLocationId, quantity) =>
                    onTransfer(item, newLocationId, quantity),
                onPrefillForm: () => onPrefillForm(item),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.colorBorder),
                foregroundColor: context.colorTextSecondary,
              ),
              onPressed: onIgnore,
              child: Text(AppLocalizations.of(context)!.actionCreateNew),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Item item;
  final VoidCallback onAddStock;
  final VoidCallback onSubtractStock;
  final Future<void> Function(int newLocationId, int quantity) onTransfer;
  final VoidCallback onPrefillForm;

  const _MatchCard({
    required this.item,
    required this.onAddStock,
    required this.onSubtractStock,
    required this.onTransfer,
    required this.onPrefillForm,
  });

  Future<void> _showTransferSheet(BuildContext context) async {
    final locations = context.read<LocationProvider>().locations
        .where((l) => l.id != item.locationId)
        .toList();

    await showModalBottomSheet(
      context: context,
      backgroundColor: context.colorCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TransferSheet(
        locations: locations,
        maxQuantity: item.quantity,
        onSelect: onTransfer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item info row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.inter(
                        color: context.colorTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(item.category,
                        style: GoogleFonts.inter(
                            color: context.colorTextSecondary, fontSize: 12)),
                    if (item.locationName != null)
                      Text(item.locationName!,
                          style: GoogleFonts.inter(
                              color: context.colorTextMuted, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isLowStock
                      ? context.colorLowStockBg
                      : AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l.labelPieces(item.quantity),
                  style: GoogleFonts.inter(
                    color: item.isLowStock
                        ? AppColors.warning
                        : AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action row 1: +1 / -1
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onAddStock,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(l.actionAddStock),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: item.quantity > 0 ? onSubtractStock : null,
                  icon: const Icon(Icons.remove, size: 16),
                  label: Text(l.actionSubtractStock),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning.withAlpha(30),
                    foregroundColor: AppColors.warning,
                    disabledBackgroundColor: context.colorSurface,
                    disabledForegroundColor: context.colorTextMuted,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Action row 2: Transfer / New location
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showTransferSheet(context),
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: Text(l.actionTransfer),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.info),
                    foregroundColor: AppColors.info,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPrefillForm,
                  icon: const Icon(Icons.warehouse_outlined, size: 16),
                  label: Text(l.actionNewLocation),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.colorBorder),
                    foregroundColor: context.colorTextSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Transfer sheet: pick target location ──────────────────────────────────────

class _TransferSheet extends StatelessWidget {
  final List<Location> locations;
  final int maxQuantity;
  final Future<void> Function(int newLocationId, int quantity) onSelect;

  const _TransferSheet({
    required this.locations,
    required this.maxQuantity,
    required this.onSelect,
  });

  Future<void> _handleLocationTap(BuildContext context, Location loc) async {
    if (maxQuantity <= 1) {
      // Nothing to choose — move the single item immediately
      Navigator.pop(context);
      await onSelect(loc.id, maxQuantity < 1 ? 1 : maxQuantity);
      return;
    }

    // Show quantity dialog over the sheet
    final quantity = await showDialog<int>(
      context: context,
      builder: (ctx) => _QuantityDialog(
        max: maxQuantity,
        locationName: loc.name,
      ),
    );

    if (quantity != null && context.mounted) {
      Navigator.pop(context);
      await onSelect(loc.id, quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: context.colorBorder,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.transferTitle,
            style: GoogleFonts.inter(
              color: context.colorTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          if (locations.isEmpty)
            Text(l.noOtherLocations,
                style: GoogleFonts.inter(color: context.colorTextMuted))
          else
            ...locations.map((loc) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.warehouse_outlined,
                      color: AppColors.primary),
                  title: Text(loc.name,
                      style: GoogleFonts.inter(
                          color: context.colorTextPrimary,
                          fontWeight: FontWeight.w500)),
                  subtitle: loc.description != null
                      ? Text(loc.description!,
                          style: GoogleFonts.inter(
                              color: context.colorTextMuted, fontSize: 12))
                      : null,
                  onTap: () => _handleLocationTap(context, loc),
                )),
        ],
      ),
    );
  }
}

// ── Quantity picker dialog ─────────────────────────────────────────────────────

class _QuantityDialog extends StatefulWidget {
  final int max;
  final String locationName;

  const _QuantityDialog({required this.max, required this.locationName});

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  late int _qty;

  @override
  void initState() {
    super.initState();
    _qty = 1;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: context.colorCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colorBorder),
      ),
      title: Text(
        l.transferQuantityTitle,
        style: GoogleFonts.inter(
          color: context.colorTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '→ ${widget.locationName}',
            style: GoogleFonts.inter(
              color: context.colorTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepBtn(
                icon: Icons.remove,
                enabled: _qty > 1,
                onTap: () => setState(() => _qty--),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Text(
                    '$_qty',
                    style: GoogleFonts.inter(
                      color: context.colorTextPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '/ ${widget.max}',
                    style: GoogleFonts.inter(
                      color: context.colorTextMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              _StepBtn(
                icon: Icons.add,
                enabled: _qty < widget.max,
                onTap: () => setState(() => _qty++),
                color: AppColors.primary,
              ),
            ],
          ),
          // "All" shortcut
          if (widget.max > 1) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _qty = widget.max),
              child: Text(
                '${l.filterAll} (${widget.max})',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.btnCancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _qty),
          child: Text(l.transferConfirmBtn),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final Color color;

  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled ? color.withAlpha(20) : context.colorBorder.withAlpha(40),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? color.withAlpha(60) : context.colorBorder,
          ),
        ),
        child: Icon(icon, size: 20,
            color: enabled ? color : context.colorTextMuted),
      ),
    );
  }
}
