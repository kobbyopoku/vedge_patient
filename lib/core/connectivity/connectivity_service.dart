import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simplified connectivity status — the UI only cares whether we're online.
enum ConnectivityStatus { online, offline, unknown }

/// Stream of connectivity changes. Wraps `connectivity_plus` so call sites
/// stay package-agnostic.
class ConnectivityService {
  ConnectivityService(this._connectivity) {
    _connectivity.onConnectivityChanged.listen(_handle);
    _connectivity.checkConnectivity().then(_handle);
  }

  final Connectivity _connectivity;
  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _last = ConnectivityStatus.unknown;
  ConnectivityStatus get current => _last;
  Stream<ConnectivityStatus> get stream => _controller.stream;

  void _handle(List<ConnectivityResult> results) {
    final next = results.any((r) => r != ConnectivityResult.none)
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;
    if (next != _last) {
      _last = next;
      _controller.add(next);
    }
  }

  void dispose() => _controller.close();
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final svc = ConnectivityService(Connectivity());
  ref.onDispose(svc.dispose);
  return svc;
});

/// Stream provider for the offline pill etc.
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final svc = ref.watch(connectivityServiceProvider);
  return Stream<ConnectivityStatus>.multi((c) {
    c.add(svc.current);
    final sub = svc.stream.listen(c.add);
    c.onCancel = sub.cancel;
  });
});

/// Convenience boolean — true when we definitely know we're offline.
final isOfflineProvider = Provider<bool>((ref) {
  final s = ref.watch(connectivityStatusProvider).valueOrNull;
  return s == ConnectivityStatus.offline;
});
