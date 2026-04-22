import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storify/models/item.dart';
import 'package:storify/providers/item_provider.dart';
import 'package:storify/screens/item_form_screen.dart';
import 'package:storify/l10n/app_localizations.dart';
import 'package:storify/utils/constants.dart';

// Detail view for a single item
class ItemDetailScreen extends StatefulWidget {
  final Item item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late int _quantity;
  bool _adjusting = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.item.quantity;
  }

  Future<void> _adjustQuantity(int delta) async {
    if (_adjusting) return;
    final newVal = _quantity + delta;
    if (newVal < 0) return;
    HapticFeedback.lightImpact();
    setState(() {
      _quantity = newVal;
      _adjusting = true;
    });
    try {
      await context.read<ItemProvider>().updateItem(
            widget.item.id,
            widget.item.copyWith(quantity: newVal),
          );
    } catch (e) {
      if (mounted) {
        setState(() => _quantity = widget.item.quantity);
        showAppSnackBar(context, AppLocalizations.of(context)!.toastError, isError: true);
      }
    } finally {
      if (mounted) setState(() => _adjusting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveItem = context
        .watch<ItemProvider>()
        .items
        .firstWhere((i) => i.id == widget.item.id, orElse: () => widget.item);

    if (!_adjusting && liveItem.quantity != _quantity) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _quantity = liveItem.quantity);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(liveItem.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItemFormScreen(item: liveItem),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outlined, color: AppColors.error),
            onPressed: () => _confirmDelete(context, liveItem),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (liveItem.isExpired) _buildExpiryBanner(expired: true),
          if (!liveItem.isExpired && liveItem.isExpiringSoon)
            _buildExpiryBanner(expired: false),
          if (liveItem.isLowStock) _buildLowStockBanner(),
          _buildHeaderCard(liveItem),
          const SizedBox(height: 12),
          _buildQuantityCard(),
          const SizedBox(height: 12),
          _buildDetailCard(liveItem),
        ],
      ),
    );
  }

  Widget _buildExpiryBanner({required bool expired}) {
    final color = expired ? AppColors.error : AppColors.warning;
    final bg = expired
        ? AppColors.error.withAlpha(20)
        : context.colorLowStockBg;
    final icon = expired ? Icons.error_outline : Icons.schedule_outlined;
    final l = AppLocalizations.of(context)!;
    final label = expired ? l.bannerExpiredItem : l.bannerExpiringSoon;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colorLowStockBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Text(
            AppLocalizations.of(context)!.bannerLowStockDetail(kLowStockThreshold),
            style: GoogleFonts.inter(
              color: AppColors.warning,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Item item) {
    final color = _categoryColor(item.category);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colorBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(_categoryIcon(item.category), color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.inter(
                    color: context.colorTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Chip(label: item.category, color: color),
                    if (item.locationName != null) ...[
                      const SizedBox(width: 6),
                      _Chip(
                        label: item.locationName!,
                        color: context.colorTextSecondary,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityCard() {
    final isLow = _quantity < kLowStockThreshold;
    final color = isLow ? AppColors.warning : AppColors.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLow ? AppColors.warning.withAlpha(80) : context.colorBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.fieldStock,
            style: GoogleFonts.inter(
              color: context.colorTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LargeStepButton(
                icon: Icons.remove,
                enabled: _quantity > 0 && !_adjusting,
                onTap: () => _adjustQuantity(-1),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text(
                  '$_quantity',
                  key: ValueKey(_quantity),
                  style: GoogleFonts.inter(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 52,
                  ),
                ),
              ),
              _LargeStepButton(
                icon: Icons.add,
                enabled: !_adjusting,
                onTap: () => _adjustQuantity(1),
                color: AppColors.primary,
              ),
            ],
          ),
          if (_adjusting)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: color),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(Item item) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorBorder),
      ),
      child: Column(
        children: [
          _buildRow(AppLocalizations.of(context)!.fieldDescription, item.description),
          _buildDivider(),
          _buildRow(AppLocalizations.of(context)!.fieldCategory, item.category),
          _buildDivider(),
          _buildRow(
            AppLocalizations.of(context)!.fieldLocation,
            item.locationName ?? 'ID ${item.locationId}',
          ),
          if (item.barcode != null && item.barcode!.isNotEmpty) ...[
            _buildDivider(),
            _buildRow(AppLocalizations.of(context)!.fieldBarcode, item.barcode!),
          ],
          if (item.expiryDate != null) ...[
            _buildDivider(),
            _buildExpiryRow(item),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                  color: context.colorTextSecondary, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: valueColor ?? context.colorTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryRow(Item item) {
    final d = item.expiryDate!;
    final formatted =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    Color color;
    IconData icon;
    if (item.isExpired) {
      color = AppColors.error;
      icon = Icons.error_outline;
    } else if (item.isExpiringSoon) {
      color = AppColors.warning;
      icon = Icons.schedule_outlined;
    } else {
      color = AppColors.success;
      icon = Icons.event_available_outlined;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              AppLocalizations.of(context)!.fieldExpiry,
              style: GoogleFonts.inter(
                  color: context.colorTextSecondary, fontSize: 14),
            ),
          ),
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            formatted,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, color: context.colorBorder, indent: 16);

  void _confirmDelete(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.colorCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: ctx.colorBorder),
        ),
        title: Text(AppLocalizations.of(ctx)!.deleteItemTitle,
            style: GoogleFonts.inter(
                color: ctx.colorTextPrimary, fontWeight: FontWeight.w700)),
        content: Text(AppLocalizations.of(ctx)!.deleteItemConfirm(item.name),
            style: GoogleFonts.inter(color: ctx.colorTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.btnCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              HapticFeedback.heavyImpact();
              try {
                await context.read<ItemProvider>().deleteItem(item.id);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  showAppSnackBar(context, AppLocalizations.of(context)!.toastError, isError: true);
                }
              }
            },
            child: Text(AppLocalizations.of(ctx)!.btnDelete),
          ),
        ],
      ),
    );
  }
}

class _LargeStepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final Color color;

  const _LargeStepButton({
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: enabled ? color.withAlpha(20) : context.colorBorder.withAlpha(40),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? color.withAlpha(60) : context.colorBorder,
          ),
        ),
        child: Icon(icon, size: 24,
            color: enabled ? color : context.colorTextMuted),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

Color _categoryColor(String category) {
  final colors = [
    AppColors.primary,
    AppColors.info,
    const Color(0xFFA78BFA),
    const Color(0xFFF97316),
    const Color(0xFFF43F5E),
    const Color(0xFF14B8A6),
  ];
  return colors[category.hashCode.abs() % colors.length];
}

IconData _categoryIcon(String category) {
  final k = category.toLowerCase();
  if (k.contains('elektro')) return Icons.electrical_services_outlined;
  if (k.contains('werkzeug') || k.contains('tool')) return Icons.build_outlined;
  if (k.contains('büro') || k.contains('office')) return Icons.work_outline; // matches both German and English category names
  if (k.contains('lebens') || k.contains('food')) return Icons.fastfood_outlined;
  if (k.contains('medizin') || k.contains('health')) {
    return Icons.medical_services_outlined;
  }
  if (k.contains('sport')) return Icons.sports_outlined;
  if (k.contains('buch') || k.contains('book')) return Icons.menu_book_outlined;
  return Icons.category_outlined;
}
