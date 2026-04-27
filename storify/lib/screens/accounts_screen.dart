import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storify/providers/item_provider.dart';
import 'package:storify/providers/location_provider.dart';
import 'package:storify/services/api_service.dart';
import 'package:storify/services/storage_service.dart';
import 'package:storify/services/sync_service.dart';
import 'package:storify/l10n/app_localizations.dart';
import 'package:storify/screens/setup_screen.dart';
import 'package:storify/utils/constants.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<Map<String, dynamic>> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _loadAccounts() {
    final storage = context.read<StorageService>();
    setState(() => _accounts = storage.loadAccounts());
  }

  Future<void> _switchAccount(String name) async {
    final sync = context.read<SyncService>();
    final storage = context.read<StorageService>();
    final items = context.read<ItemProvider>();
    final locations = context.read<LocationProvider>();
    if (sync.pendingCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Pending changes',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Text(
            '${sync.pendingCount} changes have not been synced yet. Switch anyway?',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Switch anyway',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await storage.setActiveAccount(name);
    await storage.clearDataCaches();
    if (mounted) {
      items.loadItems();
      locations.loadLocations();
      _loadAccounts();
      showAppSnackBar(context, AppLocalizations.of(context)!.toastAccountSwitched, isSuccess: true);
    }
  }

  Future<void> _deleteAccount(String name) async {
    final storage = context.read<StorageService>();
    final isActive = storage.getActiveAccount()?['name'] == name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete account?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          isActive
              ? 'This is your active account. Deleting it will log you out and clear all cached data.'
              : 'Really delete account "$name"?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await storage.deleteAccount(name);

    if (!mounted) return;

    final hasAccounts = storage.loadAccounts().isNotEmpty;
    if (isActive || !hasAccounts) {
      await storage.clearDataCaches();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SetupScreen()),
          (_) => false,
        );
      }
    } else {
      _loadAccounts();
    }
  }

  void _showAddAccountSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AccountSheet(
        onSaved: () {
          if (mounted) _loadAccounts();
        },
      ),
    );
  }

  void _showEditAccountSheet(Map<String, dynamic> account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AccountSheet(
        editName: account['name'] as String,
        initialUrl: account['baseUrl'] as String,
        initialKey: account['apiKey'] as String,
        onSaved: () {
          if (mounted) {
            _loadAccounts();
            // If this was the active account, reload data with new credentials
            final storage = context.read<StorageService>();
            final active = storage.getActiveAccount();
            if (active != null) {
              context.read<ItemProvider>().loadItems();
              context.read<LocationProvider>().loadLocations();
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeAccount = context.read<StorageService>().getActiveAccount();
    final activeName = activeAccount?['name'] as String? ?? '';

    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppBar(
        title: Text('Accounts', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: _accounts.isEmpty
          ? Center(
              child: Text('No accounts configured yet.',
                  style: GoogleFonts.inter(color: context.colorTextMuted)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _accounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final account = _accounts[index];
                final name = account['name'] as String;
                final isActive = name == activeName;
                return _AccountTile(
                  name: name,
                  baseUrl: account['baseUrl'] as String,
                  isActive: isActive,
                  onSwitch: isActive ? null : () => _switchAccount(name),
                  onEdit: () => _showEditAccountSheet(account),
                  onDelete: () => _deleteAccount(name),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAccountSheet,
        icon: const Icon(Icons.add),
        label: Text('Add account', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final String name;
  final String baseUrl;
  final bool isActive;
  final VoidCallback? onSwitch;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountTile({
    required this.name,
    required this.baseUrl,
    required this.isActive,
    this.onSwitch,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.primary : context.colorBorder,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withAlpha(25)
                  : context.colorSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_circle_outlined,
              color: isActive ? AppColors.primary : context.colorTextMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        color: context.colorTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Active',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  baseUrl,
                  style: GoogleFonts.inter(
                      color: context.colorTextMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Edit button — always visible
          IconButton(
            icon: Icon(Icons.edit_outlined, color: context.colorTextSecondary, size: 20),
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
          if (!isActive)
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
              tooltip: 'Switch',
              onPressed: onSwitch,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── Unified add/edit sheet ────────────────────────────────────────────────────

class _AccountSheet extends StatefulWidget {
  /// When non-null, we're in edit mode for the given account name.
  final String? editName;
  final String initialUrl;
  final String initialKey;
  final VoidCallback onSaved;

  const _AccountSheet({
    this.editName,
    this.initialUrl = '',
    this.initialKey = '',
    required this.onSaved,
  });

  bool get isEditMode => editName != null;

  @override
  State<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<_AccountSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _keyCtrl;
  bool _keyObscured = true;
  bool _testing = false;
  bool _tested = false;
  bool _testSuccess = false;
  String? _testMessage;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.editName ?? '');
    _urlCtrl = TextEditingController(text: widget.initialUrl);
    _keyCtrl = TextEditingController(text: widget.initialKey);
    // In edit mode with existing credentials, pre-mark as tested so Save is enabled
    if (widget.isEditMode && widget.initialUrl.isNotEmpty && widget.initialKey.isNotEmpty) {
      _tested = true;
      _testSuccess = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  void _onCredentialsChanged() {
    // Reset test result when user changes URL or key
    if (_tested) {
      setState(() {
        _tested = false;
        _testSuccess = false;
        _testMessage = null;
      });
    }
  }

  Future<void> _testConnection() async {
    final url = _urlCtrl.text.trim();
    final key = _keyCtrl.text.trim();
    if (url.isEmpty || key.isEmpty) {
      setState(() {
        _tested = true;
        _testSuccess = false;
        _testMessage = 'URL and key are required.';
      });
      return;
    }

    setState(() => _testing = true);
    try {
      await ApiService.checkConnectionWith(url, key);
      setState(() {
        _testSuccess = true;
        _testMessage = 'Connection successful.';
      });
    } on ApiException catch (e) {
      setState(() {
        _testSuccess = false;
        _testMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _testSuccess = false;
        _testMessage = 'Connection failed.';
      });
    } finally {
      setState(() {
        _testing = false;
        _tested = true;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final url = _urlCtrl.text.trim();
    final key = _keyCtrl.text.trim();
    if (name.isEmpty || url.isEmpty || key.isEmpty) return;

    final storage = context.read<StorageService>();
    if (widget.isEditMode) {
      await storage.updateAccountFull(widget.editName!, name, url, key);
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        showAppSnackBar(context, AppLocalizations.of(context)!.toastAccountSaved, isSuccess: true);
      }
    } else {
      await storage.addAccount(name, url, key);
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        showAppSnackBar(context, AppLocalizations.of(context)!.toastAccountSaved, isSuccess: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.isEditMode;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + bottomInset),
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
            isEdit ? 'Edit account' : 'Add account',
            style: GoogleFonts.inter(
                color: context.colorTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18),
          ),
          const SizedBox(height: 20),
          _field(_nameCtrl, 'Account name', Icons.badge_outlined),
          const SizedBox(height: 12),
          _field(_urlCtrl, 'API-URL', Icons.link, onChanged: (_) => _onCredentialsChanged()),
          const SizedBox(height: 12),
          _field(_keyCtrl, 'API-Key', Icons.key_outlined,
              obscure: _keyObscured,
              suffixIcon: IconButton(
                icon: Icon(
                  _keyObscured ? Icons.visibility_off : Icons.visibility,
                  color: context.colorTextMuted,
                  size: 18,
                ),
                onPressed: () => setState(() => _keyObscured = !_keyObscured),
              ),
              onChanged: (_) => _onCredentialsChanged()),
          const SizedBox(height: 16),
          if (_tested)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _testSuccess
                    ? AppColors.success.withAlpha(20)
                    : AppColors.error.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _testSuccess ? AppColors.success : AppColors.error),
              ),
              child: Row(
                children: [
                  Icon(
                    _testSuccess
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: _testSuccess ? AppColors.success : AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_testMessage ?? '',
                        style: GoogleFonts.inter(
                            color: _testSuccess
                                ? AppColors.success
                                : AppColors.error,
                            fontSize: 13)),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _testing ? null : _testConnection,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.colorBorder),
                    foregroundColor: context.colorTextSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Test connection', style: GoogleFonts.inter()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _testSuccess ? _save : null,
                  child: Text(
                    isEdit ? 'Save' : 'Add',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool obscure = false,
    Widget? suffixIcon,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      onChanged: onChanged,
      style: GoogleFonts.inter(color: context.colorTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: context.colorTextMuted, size: 18),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
