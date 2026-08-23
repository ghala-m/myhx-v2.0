import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A single queued write that will be replayed against Firestore once the
/// device is back online.
class PendingOperation {
  final String id;
  final String type; // addPatient | updatePatient | deletePatient | createReport
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  PendingOperation({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingOperation.fromJson(Map<String, dynamic> json) =>
      PendingOperation(
        id: json['id'] as String,
        type: json['type'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

enum SyncState { idle, syncing, synced, error }

/// Offline-first cache + outbox.
///
/// * Caches any JSON-serialisable collection under a key so screens can render
///   instantly (and while offline).
/// * Queues writes made while offline and replays them via [registerHandler]
///   callbacks when connectivity returns.
class OfflineService with ChangeNotifier {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  static const _queueKey = 'offline_queue_v1';
  static const _cachePrefix = 'offline_cache_';

  final Map<String, Future<void> Function(Map<String, dynamic>)> _handlers = {};
  final List<PendingOperation> _queue = [];

  bool _online = true;
  SyncState _syncState = SyncState.idle;
  String? _lastError;
  StreamSubscription? _connectivitySub;

  bool get isOnline => _online;
  bool get isOffline => !_online;
  SyncState get syncState => _syncState;
  String? get lastError => _lastError;
  int get pendingCount => _queue.length;
  bool get hasPending => _queue.isNotEmpty;

  /// Call once from `main()` after `WidgetsFlutterBinding.ensureInitialized()`.
  Future<void> init() async {
    await _loadQueue();
    final result = await Connectivity().checkConnectivity();
    _online = await _resolveOnline(result);

    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) async {
      final wasOffline = !_online;
      _online = await _resolveOnline(result);
      notifyListeners();
      if (wasOffline && _online) {
        // Fire and forget – UI observes [syncState].
        unawaited(sync());
      }
    });
    notifyListeners();
  }

  /// Connectivity plugin reports the radio/interface state only, and on
  /// simulators it frequently reports `none` while the machine is perfectly
  /// online. So whenever the plugin claims we're offline we double-check with a
  /// real, tiny network request before telling the user anything.
  Future<bool> _resolveOnline(dynamic result) async {
    if (_isConnected(result)) return true;
    return _hasRealInternet();
  }

  Future<bool> _hasRealInternet() async {
    try {
      final res = await http
          .head(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode >= 200 && res.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  /// Re-checks connectivity on demand (used by the offline banner's retry).
  Future<void> refreshConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    final wasOffline = !_online;
    _online = await _resolveOnline(result);
    notifyListeners();
    if (wasOffline && _online) unawaited(sync());
  }

  bool _isConnected(dynamic result) {
    if (result is List) {
      return result.any((r) => r != ConnectivityResult.none);
    }
    return result != ConnectivityResult.none;
  }

  /// Register how a queued operation type should be replayed.
  void registerHandler(
    String type,
    Future<void> Function(Map<String, dynamic> payload) handler,
  ) {
    _handlers[type] = handler;
  }

  // ---------------------------------------------------------------- caching

  Future<void> cacheList(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_cachePrefix$key', jsonEncode(items));
  }

  Future<List<Map<String, dynamic>>> readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_cachePrefix$key');
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_cachePrefix$key');
  }

  // ----------------------------------------------------------------- outbox

  Future<void> enqueue(String type, Map<String, dynamic> payload) async {
    _queue.add(PendingOperation(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    ));
    await _persistQueue();
    notifyListeners();
    if (_online) unawaited(sync());
  }

  Future<void> sync() async {
    if (_queue.isEmpty || _syncState == SyncState.syncing || !_online) return;

    _syncState = SyncState.syncing;
    _lastError = null;
    notifyListeners();

    final failed = <PendingOperation>[];
    for (final op in List<PendingOperation>.from(_queue)) {
      final handler = _handlers[op.type];
      if (handler == null) continue; // drop unknown op types
      try {
        await handler(op.payload);
      } catch (e) {
        _lastError = e.toString();
        failed.add(op);
      }
    }

    _queue
      ..clear()
      ..addAll(failed);
    await _persistQueue();

    _syncState = failed.isEmpty ? SyncState.synced : SyncState.error;
    notifyListeners();
  }

  Future<void> _loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _queue
        ..clear()
        ..addAll(decoded.map(
            (e) => PendingOperation.fromJson(Map<String, dynamic>.from(e))));
    } catch (_) {
      // Corrupted queue – start clean rather than blocking the app.
    }
  }

  Future<void> _persistQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _queueKey, jsonEncode(_queue.map((o) => o.toJson()).toList()));
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
