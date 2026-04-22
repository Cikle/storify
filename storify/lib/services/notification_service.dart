import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:storify/models/item.dart';
import 'package:storify/services/storage_service.dart';

// Manages local push notifications for low-stock items
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'low_stock';
  static const _channelName = 'Low stock';
  static const _groupKey = 'storify_low_stock';
  static const _summaryId = 0;

  // Must be called once in main() after WidgetsFlutterBinding.ensureInitialized()
  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Permission is requested separately with an explanation
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Warnings when item stock falls below the threshold',
      importance: Importance.defaultImportance,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Request iOS permission (call after in-app explanation)
  Future<bool> requestIosPermission() async {
    final result = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return result ?? false;
  }

  // Checks all items for low stock and fires notifications.
  // Items already notified are not notified again.
  Future<void> checkLowStock(
      List<Item> items, StorageService storage) async {
    final lowStockItems = items.where((i) => i.isLowStock).toList();
    final alreadyNotified = storage.loadNotifiedItems();

    // Remove items that have recovered from the notified set
    final recoveredIds =
        alreadyNotified.where((id) => !items.any((i) => i.id == id && i.isLowStock));
    final updatedNotified = Set<int>.from(alreadyNotified)
      ..removeAll(recoveredIds);

    // Newly critical items (not yet notified)
    final newlyLowStock =
        lowStockItems.where((i) => !updatedNotified.contains(i.id)).toList();

    if (newlyLowStock.isNotEmpty) {
      await _fireGroupedNotification(newlyLowStock);
      updatedNotified.addAll(newlyLowStock.map((i) => i.id));
    }

    await storage.saveNotifiedItems(updatedNotified);
  }

  Future<void> _fireGroupedNotification(List<Item> items) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription:
          'Warnings when item stock falls below the threshold',
      groupKey: _groupKey,
      styleInformation: InboxStyleInformation(
        items.map((i) => '${i.name}: ${i.quantity} pcs.').toList(),
        summaryText:
            '${items.length} items with critical stock',
      ),
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      setAsGroupSummary: false,
    );

    // Individual notification for each item
    for (final item in items) {
      final id = item.id % 10000 + 1; // unique notification ID
      await _plugin.show(
        id,
        'Low stock: ${item.name}',
        'Only ${item.quantity} left in stock',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            groupKey: _groupKey,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    }

    // Summary notification (Android)
    if (items.length > 1) {
      await _plugin.show(
        _summaryId,
        'Storify – Low stock',
        '${items.length} items have critical stock',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            groupKey: _groupKey,
            setAsGroupSummary: true,
            styleInformation: androidDetails.styleInformation,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
      );
    }
  }
}
