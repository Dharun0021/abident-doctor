import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.at,
    required this.read,
  });

  final String id;
  final String title;
  final String message;
  final DateTime at;
  final bool read;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'at': at.toIso8601String(),
      'read': read,
    };
  }

  static NotificationItem fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      at: DateTime.tryParse(json['at']?.toString() ?? '') ?? DateTime.now(),
      read: json['read'] == true,
    );
  }
}

class NotificationStore {
  NotificationStore._();

  static const String _storageKey = 'doctor_notifications';
  static final StreamController<List<NotificationItem>> _streamController =
      StreamController<List<NotificationItem>>.broadcast();
  static List<NotificationItem> _notifications = [];

  static Stream<List<NotificationItem>> get stream => _streamController.stream;
  static List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey) ?? <String>[];
    _notifications = rawList
        .map((item) => NotificationItem.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
    _streamController.add(List.unmodifiable(_notifications));
  }

  static Future<void> addNotification(NotificationItem notification) async {
    _notifications = [notification, ..._notifications];
    await _save();
    _streamController.add(List.unmodifiable(_notifications));
  }

  static Future<void> markRead(String id) async {
    _notifications = _notifications
        .map((item) => item.id == id ? NotificationItem(id: item.id, title: item.title, message: item.message, at: item.at, read: true) : item)
        .toList();
    await _save();
    _streamController.add(List.unmodifiable(_notifications));
  }

  static Future<void> markAllRead() async {
    _notifications = _notifications
        .map((item) => NotificationItem(id: item.id, title: item.title, message: item.message, at: item.at, read: true))
        .toList();
    await _save();
    _streamController.add(List.unmodifiable(_notifications));
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _notifications.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_storageKey, rawList);
  }
}
