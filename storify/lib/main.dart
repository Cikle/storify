import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storify/l10n/app_localizations.dart';
import 'package:storify/providers/item_provider.dart';
import 'package:storify/providers/locale_provider.dart';
import 'package:storify/providers/location_provider.dart';
import 'package:storify/providers/theme_provider.dart';
import 'package:storify/screens/home_screen.dart';
import 'package:storify/screens/setup_screen.dart';
import 'package:storify/services/api_service.dart';
import 'package:storify/services/notification_service.dart';
import 'package:storify/services/storage_service.dart';
import 'package:storify/services/sync_service.dart';
import 'package:storify/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  try {
    await NotificationService.instance.init();
  } catch (_) {}
  final storage = await StorageService.getInstance();
  final api = ApiService(storage);
  final sync = SyncService(storage, api);

  bool showSetup = !storage.isConfigured;

  if (!showSetup) {
    try {
      await ApiService.checkConnectionWith(
        storage.getApiBaseUrl(),
        storage.getApiKey(),
      );
    } catch (_) {
      showSetup = true;
    }
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider<SyncService>.value(value: sync),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(storage),
        ),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider(storage),
        ),
        ChangeNotifierProvider(
          create: (_) => ItemProvider(api, storage, sync),
        ),
        ChangeNotifierProvider(
          create: (_) => LocationProvider(api, storage, sync),
        ),
      ],
      child: StorifyApp(showSetup: showSetup),
    ),
  );
}

class StorifyApp extends StatelessWidget {
  final bool showSetup;

  const StorifyApp({super.key, this.showSetup = false});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (_, themeProv, localeProv, __) => MaterialApp(
        title: 'Storify',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: themeProv.mode,
        locale: localeProv.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: showSetup ? const SetupScreen() : const HomeScreen(),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.appBar,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withAlpha(40),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
        secondaryLabelStyle: GoogleFonts.inter(
            color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        bodyLarge: GoogleFonts.inter(color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.inter(color: AppColors.textPrimary),
        bodySmall: GoogleFonts.inter(color: AppColors.textSecondary),
        titleLarge:
            GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        titleMedium:
            GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        labelLarge:
            GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    final base = ThemeData.light();
    const lightBg = Color(0xFFF5F5F7);
    const lightCard = Color(0xFFFFFFFF);
    const lightSurface = Color(0xFFEEEEF0);
    const lightBorder = Color(0xFFDDDDE0);
    const lightText = Color(0xFF111827);
    const lightTextSec = Color(0xFF6B7280);
    const lightTextMuted = Color(0xFF9CA3AF);

    return base.copyWith(
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: lightCard,
        error: AppColors.error,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: lightText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightCard,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: lightBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: lightTextSec),
        hintStyle: const TextStyle(color: lightTextMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
      ),
      dividerTheme: const DividerThemeData(color: lightBorder),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurface,
        selectedColor: AppColors.primary.withAlpha(40),
        labelStyle: GoogleFonts.inter(color: lightTextSec, fontSize: 13),
        secondaryLabelStyle: GoogleFonts.inter(
            color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
        side: const BorderSide(color: lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        bodyLarge: GoogleFonts.inter(color: lightText),
        bodyMedium: GoogleFonts.inter(color: lightText),
        bodySmall: GoogleFonts.inter(color: lightTextSec),
        titleLarge:
            GoogleFonts.inter(color: lightText, fontWeight: FontWeight.w700),
        titleMedium:
            GoogleFonts.inter(color: lightText, fontWeight: FontWeight.w600),
        labelLarge:
            GoogleFonts.inter(color: lightText, fontWeight: FontWeight.w600),
      ),
    );
  }
}
