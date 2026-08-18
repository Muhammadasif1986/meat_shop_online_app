import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../network/response_utils.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _lastSeenKey = 'last_seen_notification_id';
  static const String _channelId = 'shop_notifications';
  static const String _channelName = 'Shop Notifications';
  static const String _channelDesc = 'Notifications from Abdul Ghaffar Meat Shop';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Timer? _timer;
  bool _initialized = false;
  String? _lastSeenId;

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  Future<void> startPolling() async {
    await init();
    if (_timer != null) return;
    final prefs = await SharedPreferences.getInstance();
    _lastSeenId = prefs.getString(_lastSeenKey);
    _checkOnce();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkOnce());
    if (kDebugMode) debugPrint('[notify] polling started');
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    if (kDebugMode) debugPrint('[notify] polling stopped');
  }

  Future<void> _checkOnce() async {
    try {
      final api = ApiClient();
      final response = await api.get(ApiConstants.notifications);
      final items = extractList(response.data);
      if (items.isEmpty) return;

      final first = items.first as Map<String, dynamic>;
      final firstId = first['id'] as String?;
      if (firstId == null || firstId == _lastSeenId) return;

      if (_lastSeenId == null) {
        _lastSeenId = firstId;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastSeenKey, firstId);
        return;
      }

      for (final raw in items.reversed) {
        final item = raw as Map<String, dynamic>;
        final id = item['id'] as String?;
        if (id == null || id == _lastSeenId) break;
        final title = item['title'] as String? ?? 'Notification';
        final body = item['body'] as String? ?? '';
        await _show(title, body, id.hashCode);
      }

      _lastSeenId = firstId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSeenKey, firstId);
    } catch (e) {
      if (kDebugMode) debugPrint('[notify] poll error: $e');
    }
  }

  Future<void> _show(String title, String body, int id) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(id, title, body, details);
  }
}