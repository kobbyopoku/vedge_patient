import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PostHog-style `track()` interface (per spec §3 Q11). The destination is
/// open in v1 — events are buffered to SharedPreferences and printed in
/// debug builds. A future Phase E task can wire a real provider (PostHog,
/// Mixpanel, internal warehouse) without touching call sites.
///
/// All call sites should use [TelemetryService.track] directly; never inline
/// `print` for analytics.
abstract class TelemetryService {
  Future<void> track(String event, [Map<String, Object?> props = const {}]);

  /// Flushes the local buffer (used by ops to inspect what's queued).
  Future<List<Map<String, Object?>>> drainBuffer();
}

class _BufferedTelemetryService implements TelemetryService {
  static const _bufferKey = 'vedge.telemetry.buffer.v1';
  static const _maxEvents = 200;

  @override
  Future<void> track(String event, [Map<String, Object?> props = const {}]) async {
    final entry = <String, Object?>{
      'event': event,
      'props': props,
      'ts': DateTime.now().toIso8601String(),
    };
    if (kDebugMode) {
      // Helpful for verifying instrumentation in `flutter run` logs without
      // shipping a real backend yet.
      // ignore: avoid_print
      print('[telemetry] $event ${jsonEncode(props)}');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_bufferKey) ?? const <String>[];
      final next = [...raw, jsonEncode(entry)];
      if (next.length > _maxEvents) {
        next.removeRange(0, next.length - _maxEvents);
      }
      await prefs.setStringList(_bufferKey, next);
    } catch (_) {
      // Telemetry must never crash the app.
    }
  }

  @override
  Future<List<Map<String, Object?>>> drainBuffer() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_bufferKey) ?? const <String>[];
    await prefs.remove(_bufferKey);
    return raw
        .map((s) => jsonDecode(s))
        .whereType<Map>()
        .map((m) => m.cast<String, Object?>())
        .toList(growable: false);
  }
}

final telemetryProvider = Provider<TelemetryService>((ref) {
  return _BufferedTelemetryService();
});
