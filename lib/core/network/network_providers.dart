import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_service.dart';
import 'internet_connection_service.dart';
import 'models/network_state.dart';

export 'models/network_state.dart';

/// Provides access to the application's [ConnectivityService].
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return const _TestConnectivityService();
  }
  return ConnectivityServiceImpl();
});

/// Provides access to the application's [InternetConnectionService].
/// Disposes the underlying checker subscription when provider is released.
final internetConnectionServiceProvider = Provider<InternetConnectionService>((
  ref,
) {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return _TestInternetConnectionService();
  }
  final service = InternetConnectionServiceImpl();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream of raw network interface connection types.
final connectivityStreamProvider = StreamProvider<Set<NetworkConnectionType>>((
  ref,
) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});

/// Stream of raw internet data reachability states.
final internetAccessStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(internetConnectionServiceProvider);
  return service.onInternetAccessChanged;
});

/// Reactive coordinator maintaining unified [AudifiNetworkState].
/// Separates local network interface connectivity from genuine internet data reachability.
class NetworkStateNotifier extends Notifier<AudifiNetworkState> {
  StreamSubscription<Set<NetworkConnectionType>>? _connSub;
  StreamSubscription<bool>? _internetSub;

  @override
  AudifiNetworkState build() {
    final connService = ref.watch(connectivityServiceProvider);
    final internetService = ref.watch(internetConnectionServiceProvider);

    _connSub = connService.onConnectivityChanged.listen(_onConnectivityChanged);
    _internetSub = internetService.onInternetAccessChanged.listen(
      _onInternetAccessChanged,
    );

    ref.onDispose(() {
      _connSub?.cancel();
      _connSub = null;
      _internetSub?.cancel();
      _internetSub = null;
    });

    _initialize();
    return AudifiNetworkState.initial;
  }

  Future<void> _initialize() async {
    final connService = ref.read(connectivityServiceProvider);
    final internetService = ref.read(internetConnectionServiceProvider);

    final types = await connService.checkConnectivity();
    if (!ref.mounted) return;

    if (types.contains(NetworkConnectionType.none) || types.isEmpty) {
      state = const AudifiNetworkState(
        status: NetworkStatus.none,
        connectionTypes: {NetworkConnectionType.none},
      );
      return;
    }

    state = AudifiNetworkState(
      status: NetworkStatus.transitioning,
      connectionTypes: types,
    );

    final hasInternet = await internetService.hasInternetAccess();
    if (!ref.mounted) return;

    state = AudifiNetworkState(
      status: hasInternet
          ? NetworkStatus.connectedWithInternet
          : NetworkStatus.connectedWithoutInternet,
      connectionTypes: types,
    );
  }

  Future<void> _onConnectivityChanged(Set<NetworkConnectionType> types) async {
    if (!ref.mounted) return;

    if (types.contains(NetworkConnectionType.none) || types.isEmpty) {
      state = const AudifiNetworkState(
        status: NetworkStatus.none,
        connectionTypes: {NetworkConnectionType.none},
      );
      return;
    }

    // Set transitioning while checking reachability on newly changed interface
    state = AudifiNetworkState(
      status: NetworkStatus.transitioning,
      connectionTypes: types,
    );

    final internetService = ref.read(internetConnectionServiceProvider);
    final hasInternet = await internetService.hasInternetAccess();
    if (!ref.mounted) return;

    state = AudifiNetworkState(
      status: hasInternet
          ? NetworkStatus.connectedWithInternet
          : NetworkStatus.connectedWithoutInternet,
      connectionTypes: types,
    );
  }

  void _onInternetAccessChanged(bool hasInternet) {
    if (!ref.mounted) return;

    // If no network interfaces are available, ignore spurious internet updates
    if (state.status == NetworkStatus.none ||
        state.connectionTypes.contains(NetworkConnectionType.none)) {
      return;
    }

    state = state.copyWith(
      status: hasInternet
          ? NetworkStatus.connectedWithInternet
          : NetworkStatus.connectedWithoutInternet,
    );
  }

  /// Manually re-probes network interface and internet reachability.
  Future<void> refresh() async {
    await _initialize();
  }
}

/// Global provider delivering reactive [AudifiNetworkState].
final networkStateProvider =
    NotifierProvider<NetworkStateNotifier, AudifiNetworkState>(
      NetworkStateNotifier.new,
    );

class _TestConnectivityService implements ConnectivityService {
  const _TestConnectivityService();

  @override
  Future<Set<NetworkConnectionType>> checkConnectivity() async => const {
    NetworkConnectionType.wifi,
  };

  @override
  Stream<Set<NetworkConnectionType>> get onConnectivityChanged =>
      const Stream.empty();
}

class _TestInternetConnectionService implements InternetConnectionService {
  @override
  Future<bool> hasInternetAccess() async => true;

  @override
  Stream<bool> get onInternetAccessChanged => const Stream.empty();

  @override
  void dispose() {}
}
