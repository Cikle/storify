import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storify/models/item.dart';
import 'package:storify/models/location.dart';
import 'package:storify/providers/item_provider.dart';
import 'package:storify/screens/item_detail_screen.dart';
import 'package:storify/screens/item_form_screen.dart';
import 'package:storify/screens/location_form_screen.dart';
import 'package:storify/l10n/app_localizations.dart';
import 'package:storify/utils/constants.dart';

// Shows all items at a specific location
class LocationDetailScreen extends StatelessWidget {
  final Location location;

  const LocationDetailScreen({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(location.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LocationFormScreen(location: location),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemFormScreen(initialLocationId: location.id),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: Consumer<ItemProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading && prov.items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final items = prov.filterItems(locationId: location.id);

          if (items.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => prov.loadItems(),
              child: ListView(
                children: [
                  const SizedBox(height: 60),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: context.colorCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colorBorder),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.noItemsAtLocation,
                        style: GoogleFonts.inter(
                          color: context.colorTextSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => prov.loadItems(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _buildItemCard(context, items[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Item item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: context.colorCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isLowStock
                ? AppColors.warning.withAlpha(80)
                : context.colorBorder,
          ),
        ),
        child: Row(
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
                  Text(
                    item.category,
                    style: GoogleFonts.inter(
                      color: context.colorTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Stock badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: item.isLowStock
                    ? context.colorLowStockBg
                    : AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${item.quantity}',
                style: GoogleFonts.inter(
                  color: item.isLowStock
                      ? AppColors.warning
                      : AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _QuantityControls(item: item),
          ],
        ),
      ),
    );
  }
}

class _QuantityControls extends StatefulWidget {
  final Item item;
  const _QuantityControls({required this.item});

  @override
  State<_QuantityControls> createState() => _QuantityControlsState();
}

class _QuantityControlsState extends State<_QuantityControls> {
  bool _loading = false;

  Future<void> _adjust(int delta) async {
    if (_loading) return;
    final newQuantity = widget.item.quantity + delta;
    if (newQuantity < 0) return;
    setState(() => _loading = true);
    try {
      await context.read<ItemProvider>().updateItem(
            widget.item.id,
            widget.item.copyWith(quantity: newQuantity),
          );
    } catch (e) {
      if (mounted) showAppSnackBar(context, AppLocalizations.of(context)!.toastError, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 72,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove,
          onPressed: widget.item.quantity > 0 ? () => _adjust(-1) : null,
        ),
        const SizedBox(width: 4),
        _StepButton(
          icon: Icons.add,
          onPressed: () => _adjust(1),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _StepButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withAlpha(20)
              : context.colorBorder.withAlpha(60),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                enabled ? AppColors.primary.withAlpha(60) : context.colorBorder,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.primary : context.colorTextMuted,
        ),
      ),
    );
  }
}
