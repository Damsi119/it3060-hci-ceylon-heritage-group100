import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/notification_item.dart';
import 'api_client.dart';
import 'notification_service.dart';

class NotificationCenter extends ChangeNotifier {
  NotificationCenter._();

  static final NotificationCenter instance = NotificationCenter._();
  static const Duration _refreshInterval = Duration(seconds: 8);

  final NotificationService _service = NotificationService.instance;

  Timer? _timer;
  List<NotificationItem> _items = [];
  String? _error;
  bool _loading = false;
  bool _fetching = false;
  bool _started = false;

  List<NotificationItem> get items => List.unmodifiable(_items);
  String? get error => _error;
  bool get loading => _loading;
  bool get isStarted => _started;
  int get unreadCount => _items.where((item) => !item.read).length;

  Future<void> start() async {
    if (_started) return;

    _started = true;
    await refresh(showLoader: true);

    _timer = Timer.periodic(
      _refreshInterval,
      (_) => refresh(showLoader: false),
    );
  }

  void stop({bool clear = false}) {
    _timer?.cancel();
    _timer = null;
    _started = false;
    _fetching = false;
    _loading = false;
    _error = null;

    if (clear) {
      _items = [];
    }

    notifyListeners();
  }

  Future<void> refresh({bool showLoader = false}) async {
    if (_fetching) return;

    _fetching = true;
    if (showLoader) {
      _loading = true;
      notifyListeners();
    }

    try {
      final items = await _service.getNotifications();
      _items = items;
      _error = null;
    } on ApiException catch (error) {
      _error = error.message;
      if (error.statusCode == 401 || error.statusCode == 403) {
        stop(clear: true);
        return;
      }
    } catch (error) {
      _error = '$error';
    } finally {
      _fetching = false;
      if (showLoader) {
        _loading = false;
      }
      notifyListeners();
    }
  }

  Future<void> markRead(int id) async {
    await _service.markRead(id);
    await refresh();
  }

  Future<void> markAllRead() async {
    await _service.markAllRead();
    await refresh();
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    await refresh();
  }
}
