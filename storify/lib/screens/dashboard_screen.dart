import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storify/providers/item_provider.dart';
import 'package:storify/providers/location_provider.dart';
import 'package:storify/l10n/app_localizations.dart';
import 'package:storify/screens/barcode_scanner_screen.dart';
import 'package:storify/screens/item_detail_screen.dart';
import 'package:storify/screens/item_form_screen.dart';
import 'package:storify/screens/location_detail_screen.dart';
import 'package:storify/screens/location_list_screen.dart';
import 'package:storify/utils/constants.dart';

// Dashboard – statistics, quick actions, critical items
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  Future<void> _openScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result == null || result.isEmpty || !mounted) return;
    final provider = context.read<ItemProvider>();
    final matches = provider.items.where((i) => i.barcode == result).toList();
    if (matches.isNotEmpty && mounted) {
      // Show first match directly
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailScreen(item: matches.first)),
      );
    } else if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ItemFormScreen(initialBarcode: result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Storify',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Consumer2<ItemProvider, LocationProvider>(
        builder: (context, itemProv, locProv, _) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await itemProv.loadItems();
              await locProv.loadLocations();
            },
            child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  children: [
                    if (itemProv.isOffline) _buildOfflineBanner(context),
                    _buildStatRow(context, itemProv, locProv),
                    const SizedBox(height: 24),
                    _buildSectionTitle(AppLocalizations.of(context)!.sectionQuickActions),
                    const SizedBox(height: 10),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    _buildSectionTitle(AppLocalizations.of(context)!.sectionTopLocations),
                    const SizedBox(height: 8),
                    _buildTopLocations(context, itemProv, locProv),
                    const SizedBox(height: 24),
                    _buildSectionTitle(AppLocalizations.of(context)!.sectionLowStock),
                    const SizedBox(height: 8),
                    if (itemProv.lowStockItems.isEmpty)
                      _buildEmptyCard(AppLocalizations.of(context)!.noCriticalItems)
                    else
                      ...itemProv.lowStockItems.map(
                        (item) => _buildLowStockCard(context, item),
                      ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(AppLocalizations.of(context)!.sectionExpiring),
                    const SizedBox(height: 8),
                    if (itemProv.expiringItems.isEmpty)
                      _buildEmptyCard(AppLocalizations.of(context)!.noExpiringItems)
                    else
                      ...itemProv.expiringItems.map(
                        (item) => _buildExpiryCard(context, item),
                      ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(AppLocalizations.of(context)!.sectionRecent),
                    const SizedBox(height: 8),
                    if (itemProv.items.isEmpty)
                      _buildEmptyCard(AppLocalizations.of(context)!.noItemsYet)
                    else
                      ..._buildRecentItems(context, itemProv),
                  ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Text(
            AppLocalizations.of(context)!.offlineBannerShort,
            style: GoogleFonts.inter(color: AppColors.warning, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, ItemProvider itemProv, LocationProvider locProv) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.inventory_2_outlined,
            label: l.statArticles,
            value: '${itemProv.items.length}',
            valueColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.warehouse_outlined,
            label: l.statLocations,
            value: '${locProv.locations.length}',
            valueColor: AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.warning_amber_outlined,
            label: l.statCritical,
            value: '${itemProv.lowStockItems.length}',
            valueColor: itemProv.lowStockItems.isNotEmpty
                ? AppColors.warning
                : const Color(0xFF14B8A6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final color = valueColor ?? AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored accent stripe on the left
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color.withAlpha(180), size: 18),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: context.colorTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.qr_code_scanner,
                label: l.actionScan,
                color: AppColors.primary,
                onTap: _openScanner,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_box_outlined,
                label: l.newItem,
                color: AppColors.info,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ItemFormScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _QuickActionCard(
          icon: Icons.warehouse_outlined,
          label: l.locationsTitle,
          color: const Color(0xFFA78BFA),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LocationListScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildTopLocations(
    BuildContext context,
    ItemProvider itemProv,
    LocationProvider locProv,
  ) {
    if (locProv.locations.isEmpty) {
      return _buildEmptyCard(AppLocalizations.of(context)!.noLocationsYet);
    }

    // Sort locations by item count (most first), show up to 4
    final sorted = [...locProv.locations];
    sorted.sort((a, b) {
      final ca = itemProv.filterItems(locationId: a.id).length;
      final cb = itemProv.filterItems(locationId: b.id).length;
      return cb.compareTo(ca);
    });
    final top = sorted.take(4).toList();

    // Build rows adaptively: always 2 per row; last row with odd count = full width
    final rows = <Widget>[];
    for (var i = 0; i < top.length; i += 2) {
      final isLast = i + 2 >= top.length;
      final hasOdd = isLast && top.length.isOdd;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < top.length ? 10 : 0),
          child: hasOdd
              ? _buildLocationTile(context, top[i], itemProv, fullWidth: true)
              : Row(
                  children: [
                    Expanded(
                      child: _buildLocationTile(context, top[i], itemProv),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildLocationTile(context, top[i + 1], itemProv),
                    ),
                  ],
                ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildLocationTile(
    BuildContext context,
    location,
    ItemProvider itemProv, {
    bool fullWidth = false,
  }) {
    final count = itemProv.filterItems(locationId: location.id).length;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationDetailScreen(location: location),
        ),
      ),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: context.colorCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colorBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warehouse_outlined,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    location.name,
                    style: GoogleFonts.inter(
                      color: context.colorTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppLocalizations.of(context)!.locationItemCount(count),
                    style: GoogleFonts.inter(
                      color: context.colorTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecentItems(BuildContext context, ItemProvider prov) {
    // Last 5 items from the list (newest first via reversed)
    final recent = prov.items.reversed.take(5).toList();
    return recent.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 300 + i * 80),
        curve: Curves.easeOut,
        builder: (context, val, child) => Opacity(
          opacity: val,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - val)),
            child: child,
          ),
        ),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colorCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colorBorder),
            ),
            child: Row(
              children: [
                // Category color circle
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _categoryColor(item.category ?? '').withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _categoryIcon(item.category ?? ''),
                    color: _categoryColor(item.category ?? ''),
                    size: 18,
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
                          fontSize: 14,
                        ),
                      ),
                      if (item.category != null || item.locationName != null)
                        Text(
                          [
                            if (item.category != null && item.category!.isNotEmpty) item.category!,
                            if (item.locationName != null) item.locationName!,
                          ].join(' · '),
                          style: GoogleFonts.inter(
                            color: context.colorTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.isLowStock
                        ? context.colorLowStockBg
                        : AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.quantity}',
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
          ),
        ),
      );
    }).toList();
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: context.colorTextPrimary,
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorBorder),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(color: context.colorTextSecondary, fontSize: 14),
      ),
    );
  }

  Widget _buildLowStockCard(BuildContext context, item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colorLowStockBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withAlpha(80)),
        ),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${item.quantity}',
                style: GoogleFonts.inter(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
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
                    ),
                  ),
                  if (item.category != null && item.category!.isNotEmpty)
                    Text(
                      item.category!,
                      style: GoogleFonts.inter(
                        color: context.colorTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: context.colorTextMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryCard(BuildContext context, item) {
    final isExpired = item.isExpired as bool;
    final color = isExpired ? AppColors.error : AppColors.warning;
    final bg = isExpired
        ? AppColors.error.withAlpha(15)
        : context.colorLowStockBg;
    final icon = isExpired ? Icons.error_outline : Icons.schedule_outlined;
    final d = item.expiryDate as DateTime;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name as String,
                    style: GoogleFonts.inter(
                      color: context.colorTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isExpired
                        ? AppLocalizations.of(context)!.expiredOn(dateStr)
                        : AppLocalizations.of(context)!.expiresOn(dateStr),
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.colorTextMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: widget.color.withAlpha(18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color.withAlpha(60)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 22),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  color: widget.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Returns a color based on the category name
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

/// Returns an icon based on the category name
IconData _categoryIcon(String category) {
  final k = category.toLowerCase();
  if (k.contains('elektro')) return Icons.electrical_services_outlined;
  if (k.contains('werkzeug') || k.contains('tool')) return Icons.build_outlined;
  if (k.contains('büro') || k.contains('office')) return Icons.work_outline; // matches both German and English category names
  if (k.contains('lebens') || k.contains('food')) return Icons.fastfood_outlined;
  if (k.contains('medizin') || k.contains('health')) return Icons.medical_services_outlined;
  if (k.contains('sport')) return Icons.sports_outlined;
  if (k.contains('buch') || k.contains('book')) return Icons.menu_book_outlined;
  return Icons.category_outlined;
}
