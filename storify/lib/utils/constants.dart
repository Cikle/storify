import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colors for the dark theme
class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0E1016);
  static const Color surface = Color(0xFF181818);
  static const Color card = Color(0xFF1F1F1F);
  static const Color appBar = Color(0xFF1A1A1F);

  // Accent
  static const Color primary = Color(0xFF3ECF8E); // Neon green
  static const Color primaryDark = Color(0xFF2BA870);

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);

  // Status
  static const Color error = Color(0xFFF87171);
  static const Color warning = Color(0xFFFBBF24);
  static const Color info = Color(0xFF60A5FA);
  static const Color success = Color(0xFF3ECF8E);

  // Borders
  static const Color border = Color(0xFF2F2F35);
  static const Color borderFocus = Color(0xFF3ECF8E);

  // Low stock highlight
  static const Color lowStock = Color(0xFFFBBF24);
  static const Color lowStockBg = Color(0xFF2D2500);
}

// Defaults – overridden in settings
const String kDefaultApiBaseUrl = 'https://yourdomain.com/storify/api';
const String kApiBaseUrlKey = 'api_base_url';
const String kApiKeyKey = 'api_key';
const String kItemsCacheKey = 'items_cache';
const String kLocationsCacheKey = 'locations_cache';

// Offline-Sync-Warteschlange
const String kSyncQueueKey = 'sync_queue';

// Bereits benachrichtigte Low-Stock-Artikel (Set von IDs)
const String kNotifiedItemsKey = 'notified_items';

// Multi-Account-Keys
const String kAccountsKey = 'accounts';

// Theme + Sprache
const String kThemeModeKey = 'theme_mode';
const String kLocaleKey = 'locale';

// Auto-Refresh-Intervall in Sekunden
const int kRefreshIntervalSeconds = 30;

// ab diesem Wert gilt ein Artikel als kritisch
const int kLowStockThreshold = 5;

// ab diesem Zeitraum gilt ein Ablaufdatum als "bald ablaufend"
const int kExpiringSoonDays = 7;

// Aktiver Overlay-Eintrag – wird vor jedem neuen Snackbar entfernt
OverlayEntry? _currentSnackBarEntry;

// Show snackbar: red=error, green=success, blue=info
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isSuccess = false,
}) {
  final color = isError
      ? AppColors.error
      : isSuccess
          ? AppColors.success
          : AppColors.info;

  final icon = isError
      ? Icons.error_outline
      : isSuccess
          ? Icons.check_circle_outline
          : Icons.info_outline;

  // Dismiss any existing snackbar immediately
  _currentSnackBarEntry?.remove();
  _currentSnackBarEntry = null;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _AppSnackBar(
      message: message,
      color: color,
      icon: icon,
      onDismiss: () {
        entry.remove();
        if (_currentSnackBarEntry == entry) {
          _currentSnackBarEntry = null;
        }
      },
    ),
  );

  _currentSnackBarEntry = entry;
  Overlay.of(context).insert(entry);
}

// animierter Snackbar als Overlay-Widget
class _AppSnackBar extends StatefulWidget {
  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback onDismiss;

  const _AppSnackBar({
    required this.message,
    required this.color,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_AppSnackBar> createState() => _AppSnackBarState();
}

// Adaptive colors — read from context to support light and dark mode
extension AppColorsExt on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  Color get colorBackground    => _isDark ? const Color(0xFF0E1016) : const Color(0xFFF5F5F7);
  Color get colorSurface       => _isDark ? const Color(0xFF181818) : const Color(0xFFEEEEF0);
  Color get colorCard          => _isDark ? const Color(0xFF1F1F1F) : Colors.white;
  Color get colorAppBar        => _isDark ? const Color(0xFF1A1A1F) : Colors.white;
  Color get colorBorder        => _isDark ? const Color(0xFF2F2F35) : const Color(0xFFDDDDE0);
  Color get colorTextPrimary   => _isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
  Color get colorTextSecondary => _isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
  Color get colorTextMuted     => _isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF);
  Color get colorLowStockBg    => _isDark ? const Color(0xFF2D2500) : const Color(0xFFFFF8E1);
}

class _AppSnackBarState extends State<_AppSnackBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) _ctrl.reverse().then((_) { if (mounted) widget.onDismiss(); });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 8,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Opacity(
            opacity: _opacity.value,
            child: Transform.translate(
              offset: Offset(_slide.value, 0), // slides in from right
              child: child,
            ),
          ),
          child: Builder(
            builder: (ctx) => ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ctx.colorCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.color.withAlpha(120)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(60),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: widget.color, size: 14),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: GoogleFonts.inter(
                          color: ctx.colorTextPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
