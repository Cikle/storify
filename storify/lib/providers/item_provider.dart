import 'package:flutter/foundation.dart';
import 'package:storify/models/item.dart';
import 'package:storify/services/api_service.dart';
import 'package:storify/services/notification_service.dart';
import 'package:storify/services/storage_service.dart';
import 'package:storify/services/sync_service.dart';

// Item list state (Provider)
class ItemProvider extends ChangeNotifier {
  final ApiService _api;
  final StorageService _storage;
  final SyncService _sync;

  List<Item> _items = [];
  bool _isLoading = false;
  bool _isSilentRefresh = false;
  String? _error;
  bool _isOffline = false;

  // Temp ID → real ID after sync (locally created items have negative IDs)
  final Map<int, int> _tempIdMap = {};

  ItemProvider(this._api, this._storage, this._sync);

  List<Item> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading && !_isSilentRefresh;
  String? get error => _error;
  bool get isOffline => _isOffline;
  bool get hasPendingSync => _sync.pendingCount > 0;

  List<Item> get lowStockItems =>
      _items.where((i) => i.isLowStock).toList();

  List<Item> get expiringItems =>
      _items.where((i) => i.isExpiringSoon || i.isExpired).toList()
        ..sort((a, b) {
          if (a.expiryDate == null) return 1;
          if (b.expiryDate == null) return -1;
          return a.expiryDate!.compareTo(b.expiryDate!);
        });

  // Combined search + filter
  List<Item> filterItems({
    String query = '',
    String? category,
    int? locationId,
    bool onlyLowStock = false,
  }) {
    return _items.where((item) {
      final matchQuery = query.isEmpty ||
          item.name.toLowerCase().contains(query.toLowerCase()) ||
          (item.category?.toLowerCase().contains(query.toLowerCase()) ?? false);
      final matchCategory =
          category == null || item.category == category;
      final matchLocation =
          locationId == null || item.locationId == locationId;
      final matchLowStock = !onlyLowStock || item.isLowStock;
      return matchQuery && matchCategory && matchLocation && matchLowStock;
    }).toList();
  }

  List<String> get categories =>
      _items.map((i) => i.category).whereType<String>().toSet().toList()..sort();

  // Show cache first, then refresh from API in background (US-6)
  Future<void> loadItems({bool silent = false}) async {
    // 1. Show local cache immediately (offline support NFA-03)
    final cached = _storage.loadItemsCache();
    if (cached.isNotEmpty && !silent) {
      _items = cached.map(Item.fromJson).toList();
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
      final fresh = await _api.getItems();
      _items = fresh;
      _isOffline = false;
      _error = null;
      // Update cache after successful load
      await _storage.saveItemsCache(fresh.map((i) => _itemToMap(i)).toList());
      // Check low-stock notifications (fire-and-forget)
      NotificationService.instance.checkLowStock(_items, _storage);
    } on ApiException catch (e) {
      _isOffline = false;
      _error = e.message;
    } catch (_) {
      // Network error / timeout → offline mode
      _isOffline = true;
      if (_items.isEmpty) {
        _error = 'No connection – no local data available.';
      }
    } finally {
      _isLoading = false;
      _isSilentRefresh = false;
      notifyListeners();
    }
  }

  Future<void> createItem(Item item) async {
    if (_isOffline || !_sync.isOnline) {
      // Offline: optimistically add + enqueue
      final tempId = -DateTime.now().millisecondsSinceEpoch;
      final tempItem = item.copyWith(id: tempId);
      _items.add(tempItem);
      await _updateCache();
      notifyListeners();

      await _sync.enqueue(SyncOperation(
        id: SyncService.generateId(),
        type: 'create',
        endpoint: '/items/',
        method: 'POST',
        payload: item.toJson(),
        timestamp: DateTime.now().toIso8601String(),
        entityType: 'item',
      ));
      return;
    }

    try {
      final created = await _api.createItem(item);
      _items.add(created);
      await _updateCache();
      notifyListeners();
    } catch (e) {
      if (e is! ApiException) _isOffline = true;
      rethrow;
    }
  }

  Future<void> updateItem(int id, Item item) async {
    // Resolve temp ID if present
    final realId = _tempIdMap[id] ?? id;

    if (_isOffline || !_sync.isOnline) {
      // Optimistic update
      final index = _items.indexWhere((i) => i.id == id);
      if (index != -1) {
        _items[index] = item.copyWith(id: id);
        await _updateCache();
        notifyListeners();
      }

      // Check if only the stock count changed
      final original = index != -1 ? _items[index] : null;
      final onlyQuantityChanged = original != null &&
          original.name == item.name &&
          original.category == item.category &&
          original.locationId == item.locationId;

      if (onlyQuantityChanged) {
        final delta = item.quantity - (original.quantity);
        await _sync.enqueue(SyncOperation(
          id: SyncService.generateId(),
          type: 'update',
          endpoint: '/items/$realId/',
          method: 'PUT',
          payload: item.toJson(),
          deltaQuantity: delta,
          timestamp: DateTime.now().toIso8601String(),
          entityType: 'item',
        ));
      } else {
        await _sync.enqueue(SyncOperation(
          id: SyncService.generateId(),
          type: 'update',
          endpoint: '/items/$realId/',
          method: 'PUT',
          payload: item.toJson(),
          timestamp: DateTime.now().toIso8601String(),
          entityType: 'item',
        ));
      }
      return;
    }

    try {
      final updated = await _api.updateItem(realId, item);
      final index = _items.indexWhere((i) => i.id == id);
      if (index != -1) _items[index] = updated;
      await _updateCache();
      notifyListeners();
    } catch (e) {
      if (e is! ApiException) _isOffline = true;
      rethrow;
    }
  }

  Future<void> deleteItem(int id) async {
    final realId = _tempIdMap[id] ?? id;

    if (_isOffline || !_sync.isOnline) {
      _items.removeWhere((i) => i.id == id);
      await _updateCache();
      notifyListeners();

      if (realId > 0) {
        // Negative IDs were never sent to the server → no delete needed
        await _sync.enqueue(SyncOperation(
          id: SyncService.generateId(),
          type: 'delete',
          endpoint: '/items/$realId/',
          method: 'DELETE',
          timestamp: DateTime.now().toIso8601String(),
          entityType: 'item',
        ));
      }
      return;
    }

    try {
      await _api.deleteItem(realId);
      _items.removeWhere((i) => i.id == id);
      await _updateCache();
      notifyListeners();
    } catch (e) {
      if (e is! ApiException) _isOffline = true;
      rethrow;
    }
  }

  /// Transfers [quantity] units of [source] to [targetLocationId].
  /// - If quantity >= source.quantity: moves the entire item (updates locationId).
  /// - If quantity < source.quantity: reduces source stock, then merges into an
  ///   existing item with the same name at the target location (if found) or
  ///   creates a new item there.
  Future<void> transferItem(
    Item source,
    int targetLocationId,
    String? targetLocationName,
    int quantity,
  ) async {
    if (quantity <= 0) return;
    final qty = quantity.clamp(1, source.quantity);

    if (qty >= source.quantity) {
      // Full transfer: just move the item
      await updateItem(
        source.id,
        source.copyWith(
          locationId: targetLocationId,
          locationName: targetLocationName,
        ),
      );
    } else {
      // Partial transfer: reduce source first
      await updateItem(source.id, source.copyWith(quantity: source.quantity - qty));

      // Look for an existing item with the same name at the target location
      final existing = _items.where(
        (i) =>
            i.id != source.id &&
            i.locationId == targetLocationId &&
            i.name.toLowerCase() == source.name.toLowerCase(),
      ).firstOrNull;

      if (existing != null) {
        // Merge: add quantity to existing item
        await updateItem(existing.id, existing.copyWith(quantity: existing.quantity + qty));
      } else {
        // No match: create new item at target, carrying all fields from source
        await createItem(Item(
          id: 0,
          name: source.name,
          description: source.description,
          category: source.category,
          barcode: source.barcode,
          quantity: qty,
          locationId: targetLocationId,
          locationName: targetLocationName,
          expiryDate: source.expiryDate,
          unit: source.unit,
          criticalThreshold: source.criticalThreshold,
          warningDays: source.warningDays,
          packSize: source.packSize,
          photoUrl: source.photoUrl,
        ));
      }
    }
  }

  Future<void> _updateCache() async {
    await _storage.saveItemsCache(_items.map(_itemToMap).toList());
  }

  Map<String, dynamic> _itemToMap(Item i) => {
    'id': i.id,
    'name': i.name,
    'description': i.description,
    'category': i.category,
    'barcode': i.barcode,
    'quantity': i.quantity,
    'location_id': i.locationId,
    'location_name': i.locationName,
    if (i.expiryDate != null)
      'expiry_date': i.expiryDate!.toIso8601String().substring(0, 10),
    if (i.unit != null) 'unit': i.unit,
    if (i.criticalThreshold != null) 'critical_threshold': i.criticalThreshold,
    if (i.warningDays != null) 'warning_days': i.warningDays,
    if (i.packSize != null) 'pack_size': i.packSize,
    if (i.photoUrl != null) 'photo_url': i.photoUrl,
  };
}
