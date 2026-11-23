import 'package:connectivity_plus/connectivity_plus.dart';

import 'models/network_state.dart';

/// Contract for monitoring local network interface changes.
abstract interface class ConnectivityService {
  /// Probes current network interfaces and returns active connection types.
  Future<Set<NetworkConnectionType>> checkConnectivity();

  /// Stream of network interface changes emitted by the operating system.
  Stream<Set<NetworkConnectionType>> get onConnectivityChanged;
}

/// Production implementation of [ConnectivityService] backed by `connectivity_plus`.
class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityServiceImpl({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  @override
  Future<Set<NetworkConnectionType>> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return mapResults(results);
    } catch (_) {
      return {NetworkConnectionType.none};
    }
  }

  @override
  Stream<Set<NetworkConnectionType>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged
        .map(mapResults)
        .distinct((a, b) => a.length == b.length && a.containsAll(b));
  }

  /// Maps plugin [ConnectivityResult] values to application-owned [NetworkConnectionType]s.
  static Set<NetworkConnectionType> mapResults(
    List<ConnectivityResult> results,
  ) {
    if (results.isEmpty) {
      return {NetworkConnectionType.none};
    }

    final set = <NetworkConnectionType>{};
    for (final r in results) {
      switch (r) {
        case ConnectivityResult.wifi:
          set.add(NetworkConnectionType.wifi);
        case ConnectivityResult.mobile:
          set.add(NetworkConnectionType.mobile);
        case ConnectivityResult.ethernet:
          set.add(NetworkConnectionType.ethernet);
        case ConnectivityResult.vpn:
          set.add(NetworkConnectionType.vpn);
        case ConnectivityResult.bluetooth:
          set.add(NetworkConnectionType.bluetooth);
        case ConnectivityResult.satellite:
        case ConnectivityResult.other:
          set.add(NetworkConnectionType.other);
        case ConnectivityResult.none:
          set.add(NetworkConnectionType.none);
      }
    }

    // If none was reported alongside other types, remove none
    if (set.length > 1 && set.contains(NetworkConnectionType.none)) {
      set.remove(NetworkConnectionType.none);
    }

    return set;
  }
}
