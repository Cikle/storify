import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storify/models/item.dart';
import 'package:storify/providers/item_provider.dart';
import 'package:storify/providers/location_provider.dart';
import 'package:storify/screens/item_detail_screen.dart';
import 'package:storify/screens/item_form_screen.dart';
import 'package:storify/l10n/app_localizations.dart';
import 'package:storify/utils/constants.dart';

// Inventory list with search and filter
class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  int _filterIndex = 0; // 0=All, 1=Category, 2=Location, 3=Critical
  String? _selectedCategory;
  int? _selectedLocationId;

  List<String> _filterLabels(AppLocalizations l) =>
      [l.filterAll, l.fieldCategory, l.fieldLocation, l.statCritical];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.inventoryTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ItemFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.inter(color: context.colorTextPrimary),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchItemHint,
          prefixIcon: Icon(Icons.search, color: context.colorTextMuted),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: context.colorTextMuted),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
        ),
        onChanged: (v) => setState(() => _query = v),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer2<ItemProvider, LocationProvider>(
      builder: (context, itemProv, locProv, _) {
        final labels = _filterLabels(AppLocalizations.of(context)!);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: labels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                String label = labels[i];
                if (i == 1 && _selectedCategory != null) {
                  label = _selectedCategory!;
                } else if (i == 2 && _selectedLocationId != null) {
                  final loc = locProv.locations.firstWhere(
                    (l) => l.id == _selectedLocationId,
                    orElse: () => locProv.locations.first,
                  );
                  label = loc.name;
                }
                return ChoiceChip(
                  label: Text(label),
                  selected: _filterIndex == i,
                  onSelected: (_) => _onFilterTap(i, itemProv, locProv),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _onFilterTap(int index, ItemProvider itemProv, LocationProvider locProv) {
    if (index == 0) {
      setState(() {
        _filterIndex = 0;
        _selectedCategory = null;
        _selectedLocationId = null;
      });
    } else if (index == 3) {
      setState(() {
        _filterIndex = 3;
        _selectedCategory = null;
        _selectedLocationId = null;
      });
    } else if (index == 1) {
      _pickCategory(itemProv.categories);
    } else if (index == 2) {
      _pickLocation(locProv.locations);
    }
  }

  void _pickCategory(List<String> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colorCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
                  color: ctx.colorBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(ctx)!.chooseCategory,
              style: GoogleFonts.inter(
                color: ctx.colorTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...categories.map((k) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(k,
                      style: GoogleFonts.inter(color: ctx.colorTextPrimary)),
                  trailing: _selectedCategory == k
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _filterIndex = 1;
                      _selectedCategory = k;
                      _selectedLocationId = null;
                    });
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _pickLocation(List<dynamic> locations) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colorCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
                  color: ctx.colorBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(ctx)!.chooseLocation,
              style: GoogleFonts.inter(
                color: ctx.colorTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...locations.map((l) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.name,
                      style: GoogleFonts.inter(color: ctx.colorTextPrimary)),
                  trailing: _selectedLocationId == l.id
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _filterIndex = 2;
                      _selectedLocationId = l.id;
                      _selectedCategory = null;
                    });
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return Consumer2<ItemProvider, LocationProvider>(
      builder: (context, itemProv, locProv, _) {
        if (itemProv.isLoading && itemProv.items.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final filtered = itemProv.filterItems(
          query: _query,
          category: _filterIndex == 1 ? _selectedCategory : null,
          locationId: _filterIndex == 2 ? _selectedLocationId : null,
          onlyLowStock: _filterIndex == 3,
        );

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.noItemsFound,
              style: GoogleFonts.inter(color: context.colorTextSecondary),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => itemProv.loadItems(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _buildItemCard(context, filtered[i]),
          ),
        );
      },
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
            // Stock badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.isLowStock
                    ? context.colorLowStockBg
                    : AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '${item.quantity}',
                style: GoogleFonts.inter(
                  color: item.isLowStock
                      ? AppColors.warning
                      : AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                  if (item.locationName != null)
                    Text(
                      item.locationName!,
                      style: GoogleFonts.inter(
                        color: context.colorTextMuted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            // Quick stock controls
            _QuantityControls(item: item),
          ],
        ),
      ),
    );
  }
}

// +/- buttons per item — own widget so only this part rebuilds
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
            color: enabled ? AppColors.primary.withAlpha(60) : context.colorBorder,
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
