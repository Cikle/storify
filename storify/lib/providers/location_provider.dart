import 'package:flutter/foundation.dart';
import 'package:storify/models/location.dart';
import 'package:storify/services/api_service.dart';
import 'package:storify/services/storage_service.dart';
import 'package:storify/services/sync_service.dart';

// Location list state (Provider)
class LocationProvider extends ChangeNotifier {
  final ApiService _api;
  final StorageService _storage;
  final SyncService _sync;

  List<Location> _locations = [];
  bool _isLoading = false;
  bool _isSilentRefresh = false;
  String? _error;
  bool _isOffline = false;

  LocationProvider(this._api, this._storage, this._sync);

  List<Location> get locations => List.unmodifiable(_locations);
  bool get isLoading => _isLoading && !_isSilentRefresh;
  String? get error => _error;
  bool get isOffline => _isOffline;

  // Show cache first, then refresh from API in background
  Future<void> loadLocations({bool silent = false}) async {
    // 1. Show local cache immediately
    final cached = _storage.loadLocationsCache();
    if (cached.isNotEmpty && !silent) {
      _locations = cached.map(Location.fromJson).toList();
      notifyListeners();
    }

    // 2. Request API in background
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    } else {
      _isSilentRefresh = true;
    }

    try {
      final fresh = await _api.getLocations();
      _locations = fresh;
      _isOffline = false;
      _error = null;
      await _updateCache();
    } on ApiException catch (e) {
      _isOffline = false;
      _error = e.message;
    } catch (_) {
      _isOffline = true;
      if (_locations.isEmpty) {
        _error = 'No connection – no local data available.';
      }
    } finally {
      _isLoading = false;
      _isSilentRefresh = false;
      notifyListeners();
    }
  }

  Future<void> createLocation(Location location) async {
    if (_isOffline || !_sync.isOnline) {
      final tempId = -DateTime.now().millisecondsSinceEpoch;
      final tempLocation = location.copyWith(id: tempId);
      _locations.add(tempLocation);
      await _updateCache();
      notifyListeners();

      await _sync.enqueue(SyncOperation(
        id: SyncService.generateId(),
        type: 'create',
        endpoint: '/locations/',
        method: 'POST',
        payload: location.toJson(),
        timestamp: DateTime.now().toIso8601String(),
        entityType: 'location',
      ));
      return;
    }

    try {
      final created = await _api.createLocation(location);
      _locations.add(created);
      await _updateCache();
      notifyListeners();
    } catch (e) {
      if (e is! ApiException) _isOffline = true;
      rethrow;
    }
  }

  Future<void> updateLocation(int id, Location location) async {
    if (_isOffline || !_sync.isOnline) {
      final index = _locations.indexWhere((l) => l.id == id);
      if (index != -1) {
        _locations[index] = location.copyWith(id: id);
        await _updateCache();
        notifyListeners();
      }
      await _sync.enqueue(SyncOperation(
        id: SyncService.generateId(),
        type: 'update',
        endpoint: '/locations/$id/',
        method: 'PUT',
        payload: location.toJson(),
        timestamp: DateTime.now().toIso8601String(),
        entityType: 'location',
      ));
      return;
    }

    try {
      final updated = await _api.updateLocation(id, location);
      final index = _locations.indexWhere((l) => l.id == id);
      if (index != -1) _locations[index] = updated;
      await _updateCache();
      notifyListeners();
    } catch (e) {
      if (e is! ApiException) _isOffline = true;
      rethrow;
    }
  }

  Future<void> deleteLocation(int id) async {
    if (_isOffline || !_sync.isOnline) {
      _locations.removeWhere((l) => l.id == id);
      await _updateCache();
      notifyListeners();

      if (id > 0) {
        await _sync.enqueue(SyncOperation(
          id: SyncService.generateId(),
          type: 'delete',
          endpoint: '/locations/$id/',
          method: 'DELETE',
          timestamp: DateTime.now().toIso8601String(),
          entityType: 'location',
        ));
      }
      return;
    }

    try {
      await _api.deleteLocation(id);
      _locations.removeWhere((l) => l.id == id);
      await _updateCache();
      notifyListeners();
    } catch (e) {
      if (e is! ApiException) _isOffline = true;
      rethrow;
    }
  }

  Future<void> _updateCache() async {
    await _storage.saveLocationsCache(
      _locations
          .map((l) => {
                'id': l.id,
                'name': l.name,
                'description': l.description,
              })
          .toList(),
    );
  }
}
