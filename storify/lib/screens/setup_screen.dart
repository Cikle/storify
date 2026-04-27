import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storify/providers/item_provider.dart';
import 'package:storify/providers/locale_provider.dart';
import 'package:storify/providers/location_provider.dart';
import 'package:storify/screens/home_screen.dart';
import 'package:storify/services/api_service.dart';
import 'package:storify/services/storage_service.dart';
import 'package:storify/l10n/app_localizations.dart';
import 'package:storify/utils/constants.dart';

// Erster Start: Benutzer gibt API-URL und Key ein, dann Verbindungstest
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();

  bool _urlObscured = false;
  bool _keyObscured = true;
  bool _isChecking = false;
  bool _connectionOk = false;
  String? _errorMessage;

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final localeProv = context.watch<LocaleProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language toggle — top right
                Align(
                  alignment: Alignment.centerRight,
                  child: _LanguageToggle(localeProv: localeProv),
                ),
                const SizedBox(height: 20),

                // App name + tagline
                Text(
                  'Storify',
                  style: GoogleFonts.inter(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.setupTagline,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: context.colorTextSecondary,
                  ),
                ),
                const SizedBox(height: 48),

                Text(
                  l.setupSectionTitle,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.colorTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.setupSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: context.colorTextSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // URL field
                      TextFormField(
                        controller: _urlCtrl,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        obscureText: _urlObscured,
                        style: GoogleFonts.inter(color: context.colorTextPrimary),
                        decoration: InputDecoration(
                          labelText: l.settingsApiUrl,
                          hintText: l.setupUrlHint,
                          prefixIcon: Icon(Icons.link, color: context.colorTextMuted),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _urlObscured ? Icons.visibility_off : Icons.visibility,
                              color: context.colorTextMuted,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _urlObscured = !_urlObscured),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return l.setupValidUrl;
                          if (!v.trim().startsWith('http')) return l.setupValidUrlHttp;
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // API key field
                      TextFormField(
                        controller: _keyCtrl,
                        autocorrect: false,
                        obscureText: _keyObscured,
                        style: GoogleFonts.inter(color: context.colorTextPrimary),
                        decoration: InputDecoration(
                          labelText: l.settingsApiKey,
                          prefixIcon: Icon(Icons.key, color: context.colorTextMuted),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _keyObscured ? Icons.visibility_off : Icons.visibility,
                              color: context.colorTextMuted,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _keyObscured = !_keyObscured),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l.setupValidKey : null,
                      ),
                      const SizedBox(height: 20),

                      // Error banner
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withAlpha(80)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.inter(color: AppColors.error, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Success banner
                      if (_connectionOk) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withAlpha(80)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l.setupSuccessDetail,
                                  style: GoogleFonts.inter(color: AppColors.primary, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Check connection button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isChecking ? null : _checkConnection,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.colorBorder),
                            foregroundColor: context.colorTextPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isChecking
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(l.checkingConnection,
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                                  ],
                                )
                              : Text(l.btnCheckConnection,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                        ),
                      ),

                      // Open app button — only after successful check
                      if (_connectionOk) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _enterApp,
                            child: Text(l.btnOpenApp,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 48),
                // Info hint
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.colorSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.colorBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: context.colorTextMuted, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l.setupInfoText,
                          style: GoogleFonts.inter(
                            color: context.colorTextMuted,
                            fontSize: 12,
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
      ),
    );
  }

  Future<void> _checkConnection() async {
    if (!_formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context)!;

    setState(() {
      _isChecking = true;
      _connectionOk = false;
      _errorMessage = null;
    });

    final storage = context.read<StorageService>();

    try {
      final url = _urlCtrl.text.trim().replaceAll(RegExp(r'/$'), '');
      final key = _keyCtrl.text.trim();

      await ApiService.checkConnectionWith(url, key);

      final accounts = storage.loadAccounts();
      if (accounts.isEmpty) {
        await storage.addAccount('Default', url, key);
      } else {
        final active = storage.getActiveAccount();
        if (active != null) {
          await storage.updateAccount(active['name'] as String, url, key);
        } else {
          await storage.addAccount('Default', url, key);
        }
      }

      if (mounted) {
        setState(() {
          _connectionOk = true;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        setState(() {
          _isChecking = false;
          _connectionOk = false;
          _errorMessage = (msg.contains('401') || msg.contains('API key'))
              ? l.setupErrorInvalidKey
              : l.errorConnection;
        });
      }
    }
  }

  Future<void> _enterApp() async {
    final itemProv = context.read<ItemProvider>();
    final locProv = context.read<LocationProvider>();

    await locProv.loadLocations();
    await itemProv.loadItems();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }
}

// Compact DE / EN pill toggle
class _LanguageToggle extends StatelessWidget {
  final LocaleProvider localeProv;

  const _LanguageToggle({required this.localeProv});

  @override
  Widget build(BuildContext context) {
    const options = [
      (Locale('en'), '🇬🇧', 'EN'),
      (Locale('de'), '🇩🇪', 'DE'),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colorBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final (locale, flag, code) = opt;
          final selected = localeProv.locale?.languageCode == locale.languageCode;
          return GestureDetector(
            onTap: () => localeProv.setLocale(locale),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(flag, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(
                    code,
                    style: GoogleFonts.inter(
                      color: selected ? Colors.black : context.colorTextMuted,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
