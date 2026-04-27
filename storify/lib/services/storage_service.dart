import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/utils/constants.dart';

// Lokaler Speicher (SharedPreferences) – Konten, Offline-Cache, Theme, Sprache
class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    await _instance!._migrateIfNeeded();
    return _instance!;
  }

  // ── Migration: Legacy-URL/Key → erster Account ──────────────────────────
  Future<void> _migrateIfNeeded() async {
    final accountsRaw = _prefs?.getString(kAccountsKey);
    // Only skip if accounts key exists AND has at least one account
    if (accountsRaw != null) {
      final existing = jsonDecode(accountsRaw) as List? ?? [];
      if (existing.isNotEmpty) return;
    }

    final legacyUrl = _prefs?.getString(kApiBaseUrlKey);
    final legacyKey = _prefs?.getString(kApiKeyKey);
    if (legacyUrl != null &&
        legacyUrl.isNotEmpty &&
        legacyUrl != kDefaultApiBaseUrl &&
        legacyKey != null &&
        legacyKey.isNotEmpty) {
      final accounts = [
        {
          'name': 'Standard',
          'baseUrl': legacyUrl,
          'apiKey': legacyKey,
          'isActive': true,
        }
      ];
      await _prefs?.setString(kAccountsKey, jsonEncode(accounts));
      await _prefs?.remove(kApiBaseUrlKey);
      await _prefs?.remove(kApiKeyKey);
    }
  }

  // ── Konten ───────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> loadAccounts() {
    final raw = _prefs?.getString(kAccountsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> saveAccounts(List<Map<String, dynamic>> accounts) async {
    await _prefs?.setString(kAccountsKey, jsonEncode(accounts));
  }

  Map<String, dynamic>? getActiveAccount() {
    final accounts = loadAccounts();
    try {
      return accounts.firstWhere((a) => a['isActive'] == true);
    } catch (_) {
      return accounts.isNotEmpty ? accounts.first : null;
    }
  }

  Future<void> setActiveAccount(String name) async {
    final accounts = loadAccounts();
    final updated = accounts.map((a) {
      return {...a, 'isActive': a['name'] == name};
    }).toList();
    await saveAccounts(updated);
  }

  Future<void> addAccount(
      String name, String baseUrl, String apiKey) async {
    final accounts = loadAccounts();
    // Erster Account wird automatisch aktiv
    final isFirst = accounts.isEmpty;
    accounts.add({
      'name': name,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'isActive': isFirst,
    });
    await saveAccounts(accounts);
  }

  Future<void> deleteAccount(String name) async {
    var accounts = loadAccounts();
    accounts.removeWhere((a) => a['name'] == name);
    // Wenn kein aktiver Account mehr → ersten aktivieren
    if (accounts.isNotEmpty &&
        !accounts.any((a) => a['isActive'] == true)) {
      accounts[0] = {...accounts[0], 'isActive': true};
    }
    await saveAccounts(accounts);
  }

  Future<void> updateAccount(
      String name, String baseUrl, String apiKey) async {
    final accounts = loadAccounts();
    final idx = accounts.indexWhere((a) => a['name'] == name);
    if (idx != -1) {
      accounts[idx] = {
        ...accounts[idx],
        'baseUrl': baseUrl,
        'apiKey': apiKey,
      };
      await saveAccounts(accounts);
    }
  }

  // Full account update including rename
  Future<void> updateAccountFull(
      String oldName, String newName, String baseUrl, String apiKey) async {
    final accounts = loadAccounts();
    final idx = accounts.indexWhere((a) => a['name'] == oldName);
    if (idx != -1) {
      accounts[idx] = {
        ...accounts[idx],
        'name': newName,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
      };
      await saveAccounts(accounts);
    }
  }

  // ── API-URL / Key (liest aus aktivem Konto) ──────────────────────────────

  String getApiBaseUrl() {
    final account = getActiveAccount();
    if (account != null) return account['baseUrl'] as String? ?? kDefaultApiBaseUrl;
    return _prefs?.getString(kApiBaseUrlKey) ?? kDefaultApiBaseUrl;
  }

  Future<void> setApiBaseUrl(String url) async {
    await _prefs?.setString(kApiBaseUrlKey, url);
  }

  String getApiKey() {
    final account = getActiveAccount();
    if (account != null) return account['apiKey'] as String? ?? '';
    return _prefs?.getString(kApiKeyKey) ?? '';
  }

  Future<void> setApiKey(String key) async {
    await _prefs?.setString(kApiKeyKey, key);
  }

  bool get isConfigured {
    final account = getActiveAccount();
    if (account != null) {
      final url = account['baseUrl'] as String? ?? '';
      final key = account['apiKey'] as String? ?? '';
      return url.isNotEmpty && url != kDefaultApiBaseUrl && key.isNotEmpty;
    }
    // Legacy fallback
    final url = _prefs?.getString(kApiBaseUrlKey) ?? '';
    final key = _prefs?.getString(kApiKeyKey) ?? '';
    return url != kDefaultApiBaseUrl && url.isNotEmpty && key.isNotEmpty;
  }

  // ── Inventar-Cache ───────────────────────────────────────────────────────

  Future<void> saveItemsCache(List<Map<String, dynamic>> items) async {
    final jsonString = jsonEncode(items);
    await _prefs?.setString(kItemsCacheKey, jsonString);
  }

  List<Map<String, dynamic>> loadItemsCache() {
    final jsonString = _prefs?.getString(kItemsCacheKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  // ── Standorte-Cache ──────────────────────────────────────────────────────

  Future<void> saveLocationsCache(
      List<Map<String, dynamic>> locations) async {
    final jsonString = jsonEncode(locations);
    await _prefs?.setString(kLocationsCacheKey, jsonString);
  }

  List<Map<String, dynamic>> loadLocationsCache() {
    final jsonString = _prefs?.getString(kLocationsCacheKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  // ── Cache leeren (beim Kontowechsel) ─────────────────────────────────────

  Future<void> clearDataCaches() async {
    await _prefs?.remove(kItemsCacheKey);
    await _prefs?.remove(kLocationsCacheKey);
  }

  // ── Offline-Sync-Queue ───────────────────────────────────────────────────

  List<Map<String, dynamic>> loadSyncQueue() {
    final raw = _prefs?.getString(kSyncQueueKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> saveSyncQueue(List<Map<String, dynamic>> queue) async {
    await _prefs?.setString(kSyncQueueKey, jsonEncode(queue));
  }

  // ── Low-Stock-Benachrichtigungs-Set ──────────────────────────────────────

  Set<int> loadNotifiedItems() {
    final raw = _prefs?.getString(kNotifiedItemsKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => e as int).toSet();
  }

  Future<void> saveNotifiedItems(Set<int> ids) async {
    await _prefs?.setString(kNotifiedItemsKey, jsonEncode(ids.toList()));
  }

  // ── Theme ────────────────────────────────────────────────────────────────

  ThemeMode loadThemeMode() {
    final raw = _prefs?.getString(kThemeModeKey);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.dark; // Standard: Dark
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await _prefs?.setString(kThemeModeKey, value);
  }

  // ── Sprache ──────────────────────────────────────────────────────────────

  Locale? loadLocale() {
    final raw = _prefs?.getString(kLocaleKey);
    if (raw == null || raw.isEmpty) return const Locale('de');
    return Locale(raw);
  }

  Future<void> saveLocale(Locale? locale) async {
    if (locale == null) {
      await _prefs?.remove(kLocaleKey);
    } else {
      await _prefs?.setString(kLocaleKey, locale.languageCode);
    }
  }
}
