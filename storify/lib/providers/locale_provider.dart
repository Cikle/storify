import 'package:flutter/material.dart';
import 'package:storify/services/storage_service.dart';

// Verwaltet die App-Sprache (Deutsch / Englisch)
class LocaleProvider extends ChangeNotifier {
  final StorageService _storage;
  Locale? _locale;

  LocaleProvider(this._storage) : _locale = _storage.loadLocale() ?? const Locale('en');

  Locale? get locale => _locale;

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    await _storage.saveLocale(locale);
    notifyListeners();
  }
}
