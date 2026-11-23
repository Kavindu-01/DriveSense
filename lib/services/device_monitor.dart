import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeviceMonitor extends ChangeNotifier {
  static const channel = MethodChannel('drivesense/device');
  Map<String, dynamic> state = {'running': false, 'countdown': -1};
  Map<String, dynamic> settings = {};
  Map<String, dynamic> history = {'trips': [], 'events': []};
  String? error;
  bool ready = false;
  Timer? _timer;
  bool _fetching = false;
  bool _disposed = false;
  int _ticks = 0;
  Future<void> initialize() async {
    await command('settings', onResult: (v) => settings = decode(v));
    await refresh();
    ready = true;
    if (_disposed) return;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => refresh());
  }

  static Map<String, dynamic> decode(dynamic v) =>
      Map<String, dynamic>.from(jsonDecode(v as String) as Map);
  Future<dynamic> command(
    String method, {
    dynamic arguments,
    void Function(dynamic)? onResult,
  }) async {
    try {
      final value = await channel.invokeMethod<dynamic>(method, arguments);
      onResult?.call(value);
      if (method != 'snapshot' && method != 'history' && method != 'settings') {
        error = null;
      }
      if (!_disposed) notifyListeners();
      return value;
    } on PlatformException catch (e) {
      error = e.code;
    } on MissingPluginException {
      error = 'androidOnly';
    } catch (e) {
      error = 'device';
    }
    if (!_disposed) notifyListeners();
    return null;
  }

  Future<void> refresh() async {
    if (_fetching || _disposed) return;
    _fetching = true;
    try {
      await command('snapshot', onResult: (v) => state = decode(v));
      if (_ticks++ % 5 == 0) {
        await command('history', onResult: (v) => history = decode(v));
      }
    } finally {
      _fetching = false;
    }
  }

  Future<void> save(Map<String, dynamic> value) async {
    await command('saveSettings', arguments: jsonEncode(value));
    await command('settings', onResult: (v) => settings = decode(v));
  }

  bool get running => state['running'] == true;
  void previewSetting(String key, Object value) {
    settings = {...settings, key: value};
    if (!_disposed) notifyListeners();
  }

  double number(String key) => (state[key] as num?)?.toDouble() ?? 0;
  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
