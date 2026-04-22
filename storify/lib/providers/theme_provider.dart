import 'package:flutter/material.dart';
import 'package:storify/services/storage_service.dart';

// Verwaltet den Theme-Modus (Hell / Dunkel / System)
class ThemeProvider extends ChangeNotifier {
  final StorageService _storage;
  ThemeMode _mode;

  ThemeProvider(this._storage) : _mode = _storage.loadThemeMode();

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    await _storage.saveThemeMode(mode);
    notifyListeners();
  }
}
