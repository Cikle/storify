import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:storify/services/api_service.dart';
import 'package:storify/services/storage_service.dart';

// A single offline operation in the queue
class SyncOperation {
  final String id; // unique ID (timestamp-based)
  final String type; // 'create' | 'update' | 'delete'
  final String endpoint; // e.g. '/items/' or '/items/42/'
  final String method; // 'POST' | 'PUT' | 'DELETE'
  final Map<String, dynamic>? payload; // body for POST/PUT (null for delta-only)
  final int? deltaQuantity; // stock changes only: additive delta
  final String timestamp; // ISO-8601 for ordering
  final String entityType; // 'item' | 'location' (sync order)

  const SyncOperation({
    required this.id,
    required this.type,
    required this.endpoint,
    required this.method,
    this.payload,
    this.deltaQuantity,
    required this.timestamp,
    required this.entityType,
  });

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      type: json['type'] as String,
      endpoint: json['endpoint'] as String,
      method: json['method'] as String,
      payload: json['payload'] as Map<String, dynamic>?,
      deltaQuantity: json['deltaQuantity'] as int?,
      timestamp: json['timestamp'] as String,
      entityType: json['entityType'] as String? ?? 'item',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'endpoint': endpoint,
      'method': method,
      if (payload != null) 'payload': payload,
      if (deltaQuantity != null) 'deltaQuantity': deltaQuantity,
      'timestamp': timestamp,
      'entityType': entityType,
    };
  }
}

// Result of a sync run
class SyncResult {
  final int synced;
  final int failed;

  const SyncResult({required this.synced, required this.failed});
}

// Manages offline operations and syncs them when reconnected
class SyncService extends ChangeNotifier {
  final StorageService _storage;
  final ApiService _api;

  bool _isOnline = true;
  bool _isProcessing = false;
  List<SyncOperation> _queue = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  SyncService(this._storage, this._api) {
    _loadQueue();
    _initConnectivity();
  }

  bool get isOnline => _isOnline;
  bool get isProcessing => _isProcessing;
  int get pendingCount => _queue.length;
  List<SyncOperation> get queue => List.unmodifiable(_queue);

  void _loadQueue() {
    final raw = _storage.loadSyncQueue();
    _queue = raw.map(SyncOperation.fromJson).toList();
  }

  Future<void> _saveQueue() async {
    await _storage.saveSyncQueue(_queue.map((op) => op.toJson()).toList());
  }

  void _initConnectivity() {
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((results) async {
      final wasOffline = !_isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      notifyListeners();
      // Process queue on reconnect
      if (wasOffline && _isOnline && _queue.isNotEmpty) {
        await processQueue();
      }
    });

    // Check initial connectivity
    Connectivity().checkConnectivity().then((results) {
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      notifyListeners();
    });
  }

  // Enqueue an operation
  Future<void> enqueue(SyncOperation op) async {
    _queue.add(op);
    await _saveQueue();
    notifyListeners();
  }

  // Process the queue (called on reconnect and manually)
  Future<SyncResult> processQueue() async {
    if (_isProcessing || _queue.isEmpty) {
      return const SyncResult(synced: 0, failed: 0);
    }

    _isProcessing = true;
    notifyListeners();

    int synced = 0;
    int failed = 0;

    // Sort: location creates first (items may reference location IDs)
    final sorted = [..._queue]..sort((a, b) {
        if (a.entityType == 'location' && b.entityType == 'item') return -1;
        if (a.entityType == 'item' && b.entityType == 'location') return 1;
        return a.timestamp.compareTo(b.timestamp);
      });

    for (final op in sorted) {
      try {
        await _executeOperation(op);
        _queue.removeWhere((q) => q.id == op.id);
        await _saveQueue();
        synced++;
        notifyListeners();
      } catch (_) {
        // Network error → abort, remaining ops stay in queue
        failed++;
        break;
      }
    }

    _isProcessing = false;
    notifyListeners();
    return SyncResult(synced: synced, failed: failed);
  }

  Future<void> _executeOperation(SyncOperation op) async {
    if (op.deltaQuantity != null && op.method == 'PUT') {
      // Additive stock delta: fetch current value and apply delta
      final itemIdStr = op.endpoint.replaceAll(RegExp(r'[^0-9]'), '');
      final itemId = int.tryParse(itemIdStr);
      if (itemId != null) {
        try {
          final currentItem = await _api.getItem(itemId);
          final newQuantity = currentItem.quantity + op.deltaQuantity!;
          final updatedPayload = {
            ...op.payload ?? {},
            'quantity': newQuantity < 0 ? 0 : newQuantity,
          };
          await _api.rawRequest(
            method: op.method,
            endpoint: op.endpoint,
            body: updatedPayload,
          );
          return;
        } on ApiException catch (e) {
          // 404 = item already deleted → ignore
          if (e.statusCode == 404) return;
          rethrow;
        }
      }
    }

    if (op.method == 'DELETE') {
      try {
        await _api.rawRequest(method: op.method, endpoint: op.endpoint);
      } on ApiException catch (e) {
        if (e.statusCode == 404) return; // Already deleted → OK
        rethrow;
      }
      return;
    }

    await _api.rawRequest(
      method: op.method,
      endpoint: op.endpoint,
      body: op.payload,
    );
  }

  // Generates a unique ID
  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
