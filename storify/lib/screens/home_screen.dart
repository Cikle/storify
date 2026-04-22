import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storify/models/item.dart';
import 'package:storify/providers/item_provider.dart';
import 'package:storify/providers/location_provider.dart';
import 'package:storify/screens/barcode_scanner_screen.dart';
import 'package:storify/screens/dashboard_screen.dart';
import 'package:storify/screens/inventory_list_screen.dart';
import 'package:storify/screens/item_form_screen.dart';
import 'package:storify/screens/location_list_screen.dart';
import 'package:storify/screens/settings_screen.dart';
import 'package:storify/services/sync_service.dart';
import 'package:storify/services/update_service.dart';
import 'package:storify/l10n/app_localizations.dart';
import 'package:storify/utils/constants.dart';
import 'package:storify/widgets/barcode_match_sheet.dart';

/// Haupt-Screen mit Bottom Navigation Bar (4 Tabs + zentraler Scan-Button)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // 0=Dashboard, 1=Inventar, 2=Standorte, 3=Einstellungen
  int _currentIndex = 0;
  Timer? _refreshTimer;

  final List<Widget> _screens = const [
    DashboardScreen(),
    InventoryListScreen(),
    LocationListScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadItems();
      context.read<LocationProvider>().loadLocations();
      _startRefreshTimer();
      _checkForUpdate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Sofort aktualisieren wenn App wieder sichtbar wird
      context.read<ItemProvider>().loadItems(silent: true);
      context.read<LocationProvider>().loadLocations(silent: true);
      _startRefreshTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopRefreshTimer();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: kRefreshIntervalSeconds),
      (_) {
        if (mounted) {
          context.read<ItemProvider>().loadItems(silent: true);
          context.read<LocationProvider>().loadLocations(silent: true);
        }
      },
    );
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _checkForUpdate() async {
    final newVersion =
        await UpdateService.instance.fetchLatestVersionIfNewer();
    if (newVersion == null || !mounted) return;
    _showUpdateDialog(newVersion);
  }

  void _showUpdateDialog(String newVersion) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colorCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Update available',
          style: GoogleFonts.inter(
              color: context.colorTextPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Version $newVersion is available.\nOpen the release page to download?',
          style: GoogleFonts.inter(color: context.colorTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Later',
              style: GoogleFonts.inter(color: context.colorTextMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              UpdateService.instance.openReleasesPage();
            },
            child: Text(
              'Download',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openScanner() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result == null || result.isEmpty || !mounted) return;

    final provider = context.read<ItemProvider>();
    final matches =
        provider.items.where((i) => i.barcode == result).toList();

    if (matches.isNotEmpty && mounted) {
      await _showBarcodeMatchSheet(result, matches);
    } else if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ItemFormScreen(initialBarcode: result),
        ),
      );
    }
  }

  Future<void> _showBarcodeMatchSheet(
      String barcode, List<Item> matches) async {
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
            await context.read<ItemProvider>().updateItem(
                  item.id,
                  item.copyWith(quantity: item.quantity + 1),
                );
            if (mounted) {
              showAppSnackBar(
                context,
                AppLocalizations.of(context)!.toastStockUpdated,
                isSuccess: true,
              );
            }
          } catch (e) {
            if (mounted) showAppSnackBar(context, AppLocalizations.of(context)!.toastError, isError: true);
          }
        },
        onSubtractStock: (item) async {
          Navigator.pop(ctx);
          if (item.quantity <= 0) return;
          try {
            await context.read<ItemProvider>().updateItem(
                  item.id,
                  item.copyWith(quantity: item.quantity - 1),
                );
            if (mounted) {
              showAppSnackBar(
                context,
                AppLocalizations.of(context)!.toastStockUpdated,
                isSuccess: true,
              );
            }
          } catch (e) {
            if (mounted) showAppSnackBar(context, AppLocalizations.of(context)!.toastError, isError: true);
          }
        },
        onTransfer: (item, newLocationId, quantity) async {
          Navigator.pop(ctx);
          try {
            final locations = context.read<LocationProvider>().locations;
            final newLocation =
                locations.where((l) => l.id == newLocationId).firstOrNull;
            await context.read<ItemProvider>().transferItem(
              item,
              newLocationId,
              newLocation?.name,
              quantity,
            );
            if (mounted) {
              showAppSnackBar(
                context,
                AppLocalizations.of(context)!.toastTransferred,
                isSuccess: true,
              );
            }
          } catch (e) {
            if (mounted) showAppSnackBar(context, AppLocalizations.of(context)!.toastError, isError: true);
          }
        },
        onPrefillForm: (item) {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItemFormScreen(
                initialBarcode: barcode,
                initialLocationId: item.locationId,
              ),
            ),
          );
        },
        onIgnore: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItemFormScreen(initialBarcode: barcode),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final l = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.colorBorder)),
        color: context.colorCard,
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: l.navDashboard,
                selected: _currentIndex == 0,
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  setState(() => _currentIndex = 0);
                },
              ),
              _NavItem(
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2,
                label: l.navInventory,
                selected: _currentIndex == 1,
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  setState(() => _currentIndex = 1);
                },
              ),
              // Zentraler Scan-Button mit Sync-Badge
              Expanded(
                child: GestureDetector(
                  onTap: _openScanner,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Consumer<SyncService>(
                        builder: (_, sync, __) => Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(80),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.qr_code_scanner,
                                color: Colors.black,
                                size: 24,
                              ),
                            ),
                            if (sync.pendingCount > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: AppColors.warning,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${sync.pendingCount}',
                                    style: GoogleFonts.inter(
                                      color: Colors.black,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.warehouse_outlined,
                activeIcon: Icons.warehouse,
                label: l.navLocations,
                selected: _currentIndex == 2,
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  setState(() => _currentIndex = 2);
                },
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: l.navSettings,
                selected: _currentIndex == 3,
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  setState(() => _currentIndex = 3);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : context.colorTextMuted;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
