import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storify/providers/item_provider.dart';
import 'package:storify/providers/locale_provider.dart';
import 'package:storify/providers/location_provider.dart';
import 'package:storify/providers/theme_provider.dart';
import 'package:storify/screens/accounts_screen.dart';
import 'package:storify/screens/export_screen.dart';
import 'package:storify/services/api_service.dart';
import 'package:storify/services/storage_service.dart';
import 'package:storify/l10n/app_localizations.dart';
import 'package:storify/utils/constants.dart';

/// Einstellungen-Screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlCtrl;
  late final TextEditingController _keyCtrl;
  bool _keyObscured = true;
  bool _isBusy = false;
  bool _connectionOk = false;
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    final storage = context.read<StorageService>();
    _urlCtrl = TextEditingController(text: storage.getApiBaseUrl());
    _keyCtrl = TextEditingController(text: storage.getApiKey());
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final localeProv = context.watch<LocaleProvider>();

    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Konten ──────────────────────────────────────────────────────
          _buildSectionLabel(l.settingsSectionAccounts),
          const SizedBox(height: 8),
          _buildNavTile(
            icon: Icons.manage_accounts_outlined,
            label: l.settingsManageAccounts,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountsScreen()),
            ),
          ),

          const SizedBox(height: 24),
          // ── API-Verbindung (aktives Konto) ───────────────────────────────
          _buildSectionLabel(l.settingsSectionApi),
          const SizedBox(height: 8),
          TextFormField(
            controller: _urlCtrl,
            style: GoogleFonts.inter(color: context.colorTextPrimary),
            keyboardType: TextInputType.url,
            autocorrect: false,
            onChanged: (_) => setState(() {
              _connectionOk = false;
              _statusMessage = null;
            }),
            decoration: InputDecoration(
              labelText: l.settingsApiUrl,
              hintText: 'https://yourdomain.com/storify/api',
              prefixIcon: Icon(Icons.link, color: context.colorTextMuted),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _keyCtrl,
            style: GoogleFonts.inter(color: context.colorTextPrimary),
            autocorrect: false,
            obscureText: _keyObscured,
            onChanged: (_) => setState(() {
              _connectionOk = false;
              _statusMessage = null;
            }),
            decoration: InputDecoration(
              labelText: l.settingsApiKey,
              hintText: 'Secret key for the API',
              prefixIcon: Icon(Icons.key, color: context.colorTextMuted),
              suffixIcon: IconButton(
                icon: Icon(
                  _keyObscured ? Icons.visibility_off : Icons.visibility,
                  color: context.colorTextMuted,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _keyObscured = !_keyObscured),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_statusMessage != null) ...[
            _buildStatusBanner(),
            const SizedBox(height: 14),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isBusy ? null : _checkConnection,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.colorBorder),
                foregroundColor: context.colorTextPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isBusy
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 16, width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Text(l.checkingConnection, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                      ],
                    )
                  : Text(l.btnCheckConnection,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isBusy || !_connectionOk) ? null : _saveSettings,
              child: Text(l.btnSaveReload),
            ),
          ),

          const SizedBox(height: 24),
          // ── Design ──────────────────────────────────────────────────────
          _buildSectionLabel(l.settingsSectionTheme),
          const SizedBox(height: 8),
          _buildThemeSelector(themeProv, l),

          const SizedBox(height: 24),
          // ── Sprache ──────────────────────────────────────────────────────
          _buildSectionLabel(l.settingsSectionLanguage),
          const SizedBox(height: 8),
          _buildLanguageSelector(localeProv, l),

          const SizedBox(height: 24),
          // ── Daten ────────────────────────────────────────────────────────
          _buildSectionLabel(l.settingsSectionData),
          const SizedBox(height: 8),
          _buildNavTile(
            icon: Icons.import_export_outlined,
            label: l.settingsExportImport,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExportScreen()),
            ),
          ),

          const SizedBox(height: 24),
          // ── About ────────────────────────────────────────────────────────
          _buildSectionLabel(l.settingsAbout),
          const SizedBox(height: 8),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        color: context.colorTextMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: context.colorCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colorBorder),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(
                        color: context.colorTextPrimary,
                        fontWeight: FontWeight.w500)),
              ),
              Icon(Icons.chevron_right, color: context.colorTextMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (_statusIsError ? AppColors.error : AppColors.primary).withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (_statusIsError ? AppColors.error : AppColors.primary).withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _statusIsError ? Icons.error_outline : Icons.check_circle_outline,
            color: _statusIsError ? AppColors.error : AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage!,
              style: GoogleFonts.inter(
                color: _statusIsError ? AppColors.error : AppColors.primary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(ThemeProvider themeProv, AppLocalizations l) {
    final options = [
      (ThemeMode.system, l.themeSystem, Icons.brightness_auto_outlined),
      (ThemeMode.light, l.themeLight, Icons.light_mode_outlined),
      (ThemeMode.dark, l.themeDark, Icons.dark_mode_outlined),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorBorder),
      ),
      child: Row(
        children: options.map((opt) {
          final (mode, label, icon) = opt;
          final selected = themeProv.mode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => themeProv.setMode(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(icon,
                        color: selected ? Colors.black : context.colorTextMuted,
                        size: 18),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        color: selected ? Colors.black : context.colorTextMuted,
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguageSelector(LocaleProvider localeProv, AppLocalizations l) {
    final options = [
      (const Locale('de'), l.languageGerman, '🇩🇪'),
      (const Locale('en'), l.languageEnglish, '🇬🇧'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorBorder),
      ),
      child: Row(
        children: options.map((opt) {
          final (locale, label, flag) = opt;
          final selected = localeProv.locale?.languageCode == locale.languageCode;
          return Expanded(
            child: GestureDetector(
              onTap: () => localeProv.setLocale(locale),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        color: selected ? Colors.black : context.colorTextMuted,
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('App', 'Storify'),
          _buildInfoRow('Version', '1.0.0'),
          _buildInfoRow('Autor', 'cikle'),
          _buildInfoRow('Backend', 'PHP REST-API + MySQL'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: GoogleFonts.inter(
                    color: context.colorTextSecondary, fontSize: 13)),
          ),
          Text(value,
              style: GoogleFonts.inter(
                  color: context.colorTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _checkConnection() async {
    final url = _urlCtrl.text.trim();
    final key = _keyCtrl.text.trim();
    if (url.isEmpty || key.isEmpty) {
      setState(() {
        _statusMessage = 'Bitte URL und API-Key eingeben.';
        _statusIsError = true;
        _connectionOk = false;
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _statusMessage = null;
      _connectionOk = false;
    });

    final storage = context.read<StorageService>();
    try {
      final cleanUrl = url.replaceAll(RegExp(r'/$'), '');
      await ApiService.checkConnectionWith(cleanUrl, key);

      final active = storage.getActiveAccount();
      if (active != null) {
        await storage.updateAccount(active['name'] as String, cleanUrl, key);
      } else {
        await storage.addAccount('Default', cleanUrl, key);
      }
      if (mounted) {
        setState(() {
          _connectionOk = true;
          _statusIsError = false;
          _statusMessage = 'Verbindung erfolgreich. API erreichbar.';
          _isBusy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        setState(() {
          _isBusy = false;
          _connectionOk = false;
          _statusIsError = true;
          _statusMessage = msg.contains('401') || msg.contains('API key')
              ? 'Invalid API key. Please check the key.'
              : 'Error: $msg';
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isBusy = true);
    final itemProv = context.read<ItemProvider>();
    final locProv = context.read<LocationProvider>();
    try {
      await itemProv.loadItems();
      await locProv.loadLocations();
      if (mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.toastSaved,
          isSuccess: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
}
