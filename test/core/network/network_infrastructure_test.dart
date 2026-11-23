import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audifi/core/network/connectivity_service.dart';
import 'package:audifi/core/network/internet_connection_service.dart';
import 'package:audifi/core/network/network_providers.dart';

class FakeConnectivityService implements ConnectivityService {
  final StreamController<Set<NetworkConnectionType>> _controller =
      StreamController<Set<NetworkConnectionType>>.broadcast();

  Set<NetworkConnectionType> currentTypes;

  FakeConnectivityService({
    this.currentTypes = const {NetworkConnectionType.wifi},
  });

  @override
  Future<Set<NetworkConnectionType>> checkConnectivity() async => currentTypes;

  @override
  Stream<Set<NetworkConnectionType>> get onConnectivityChanged =>
      _controller.stream;

  void emit(Set<NetworkConnectionType> types) {
    currentTypes = types;
    _controller.add(types);
  }

  void dispose() {
    _controller.close();
  }
}

class FakeInternetConnectionService implements InternetConnectionService {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  bool currentAccess;
  bool isDisposed = false;

  FakeInternetConnectionService({this.currentAccess = true});

  @override
  Future<bool> hasInternetAccess() async => currentAccess;

  @override
  Stream<bool> get onInternetAccessChanged => _controller.stream;

  void emit(bool hasAccess) {
    currentAccess = hasAccess;
    _controller.add(hasAccess);
  }

  @override
  void dispose() {
    isDisposed = true;
    _controller.close();
  }
}

void main() {
  group('AudifiNetworkState Model Tests', () {
    test(
      'exposes correct flags and descriptions for connectedWithInternet',
      () {
        const state = AudifiNetworkState(
          status: NetworkStatus.connectedWithInternet,
          connectionTypes: {NetworkConnectionType.wifi},
        );

        expect(state.hasInternet, isTrue);
        expect(state.isConnected, isTrue);
        expect(state.isOffline, isFalse);
        expect(state.isTransitioning, isFalse);
        expect(state.isWifi, isTrue);
        expect(state.isMobile, isFalse);
        expect(state.description, 'Wi-Fi (Online)');
      },
    );

    test(
      'exposes correct flags and descriptions for connectedWithoutInternet',
      () {
        const state = AudifiNetworkState(
          status: NetworkStatus.connectedWithoutInternet,
          connectionTypes: {NetworkConnectionType.mobile},
        );

        expect(state.hasInternet, isFalse);
        expect(state.isConnected, isTrue);
        expect(state.isOffline, isTrue);
        expect(state.isMobile, isTrue);
        expect(state.description, 'Cellular (No Internet)');
      },
    );

    test('exposes correct flags for no network connection', () {
      const state = AudifiNetworkState.disconnected;

      expect(state.status, NetworkStatus.none);
      expect(state.hasInternet, isFalse);
      expect(state.isConnected, isFalse);
      expect(state.isOffline, isTrue);
      expect(state.description, 'No network connection');
    });

    test('handles transitioning and multiple connection types correctly', () {
      const state = AudifiNetworkState(
        status: NetworkStatus.transitioning,
        connectionTypes: {
          NetworkConnectionType.wifi,
          NetworkConnectionType.vpn,
        },
      );

      expect(state.isTransitioning, isTrue);
      expect(state.isWifi, isTrue);
      expect(state.isVpn, isTrue);
      expect(state.description, 'Connecting...');
    });

    test('supports value equality, hashCode, and copyWith', () {
      const s1 = AudifiNetworkState(
        status: NetworkStatus.connectedWithInternet,
        connectionTypes: {NetworkConnectionType.ethernet},
      );

      final s2 = s1.copyWith();
      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));

      final s3 = s1.copyWith(status: NetworkStatus.connectedWithoutInternet);
      expect(s1, isNot(equals(s3)));
      expect(s3.isEthernet, isTrue);
      expect(s1.toString(), contains('connectedWithInternet'));
    });
  });

  group('ConnectivityServiceImpl.mapResults Tests', () {
    test('maps all connectivity plugin results to Audifi connection types', () {
      expect(ConnectivityServiceImpl.mapResults([ConnectivityResult.wifi]), {
        NetworkConnectionType.wifi,
      });
      expect(ConnectivityServiceImpl.mapResults([ConnectivityResult.mobile]), {
        NetworkConnectionType.mobile,
      });
      expect(
        ConnectivityServiceImpl.mapResults([ConnectivityResult.ethernet]),
        {NetworkConnectionType.ethernet},
      );
      expect(ConnectivityServiceImpl.mapResults([ConnectivityResult.vpn]), {
        NetworkConnectionType.vpn,
      });
      expect(
        ConnectivityServiceImpl.mapResults([ConnectivityResult.bluetooth]),
        {NetworkConnectionType.bluetooth},
      );
      expect(
        ConnectivityServiceImpl.mapResults([ConnectivityResult.satellite]),
        {NetworkConnectionType.other},
      );
      expect(ConnectivityServiceImpl.mapResults([ConnectivityResult.other]), {
        NetworkConnectionType.other,
      });
      expect(ConnectivityServiceImpl.mapResults([ConnectivityResult.none]), {
        NetworkConnectionType.none,
      });
    });

    test('maps empty list to none', () {
      expect(ConnectivityServiceImpl.mapResults([]), {
        NetworkConnectionType.none,
      });
    });

    test('handles multiple simultaneous connections and cleans up none', () {
      final multi = ConnectivityServiceImpl.mapResults([
        ConnectivityResult.wifi,
        ConnectivityResult.vpn,
        ConnectivityResult.none,
      ]);

      expect(multi, {NetworkConnectionType.wifi, NetworkConnectionType.vpn});
      expect(multi.contains(NetworkConnectionType.none), isFalse);
    });
  });

  group('NetworkStateNotifier & Riverpod Providers Tests', () {
    late FakeConnectivityService fakeConn;
    late FakeInternetConnectionService fakeInternet;
    late ProviderContainer container;

    setUp(() {
      fakeConn = FakeConnectivityService(
        currentTypes: {NetworkConnectionType.wifi},
      );
      fakeInternet = FakeInternetConnectionService(currentAccess: true);
      container = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(fakeConn),
          internetConnectionServiceProvider.overrideWithValue(fakeInternet),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakeConn.dispose();
      fakeInternet.dispose();
    });

    test('initializes and verifies connectedWithInternet when interfaces and internet are present', () async {
      final initial = container.read(networkStateProvider);
      expect(initial.status, NetworkStatus.unknown);

      // Wait for async _initialize to complete
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final resolved = container.read(networkStateProvider);
      expect(resolved.status, NetworkStatus.connectedWithInternet);
      expect(resolved.hasInternet, isTrue);
      expect(resolved.isWifi, isTrue);
    });

    test('initializes to connectedWithoutInternet when interface is active but internet access is false', () async {
      fakeInternet.currentAccess = false;

      final testContainer = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(fakeConn),
          internetConnectionServiceProvider.overrideWithValue(fakeInternet),
        ],
      );
      addTearDown(testContainer.dispose);

      // Eagerly trigger build so _initialize begins
      testContainer.read(networkStateProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final state = testContainer.read(networkStateProvider);
      expect(state.status, NetworkStatus.connectedWithoutInternet);
      expect(state.hasInternet, isFalse);
      expect(state.isConnected, isTrue);
    });

    test(
      'transitions immediately to none when interface disconnects',
      () async {
        container.read(networkStateProvider);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(container.read(networkStateProvider).hasInternet, isTrue);

        fakeConn.emit({NetworkConnectionType.none});
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final state = container.read(networkStateProvider);
        expect(state.status, NetworkStatus.none);
        expect(state.isConnected, isFalse);
        expect(state.hasInternet, isFalse);
      },
    );

    test('updates state when internet reachability drops while interface remains connected', () async {
      container.read(networkStateProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(container.read(networkStateProvider).hasInternet, isTrue);

      // Internet drops (e.g. captive portal or DNS failure)
      fakeInternet.emit(false);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = container.read(networkStateProvider);
      expect(state.status, NetworkStatus.connectedWithoutInternet);
      expect(state.hasInternet, isFalse);
      expect(state.isConnected, isTrue);
      expect(state.isWifi, isTrue);

      // Internet returns
      fakeInternet.emit(true);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final restored = container.read(networkStateProvider);
      expect(restored.status, NetworkStatus.connectedWithInternet);
      expect(restored.hasInternet, isTrue);
    });

    test('manual refresh re-checks connectivity and internet status', () async {
      container.read(networkStateProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      fakeConn.currentTypes = {NetworkConnectionType.mobile};
      fakeInternet.currentAccess = true;

      await container.read(networkStateProvider.notifier).refresh();

      final state = container.read(networkStateProvider);
      expect(state.status, NetworkStatus.connectedWithInternet);
      expect(state.isMobile, isTrue);
    });

    test('connectivityStreamProvider and internetAccessStreamProvider expose streams correctly', () async {
      final connEvents = <Set<NetworkConnectionType>>[];
      final internetEvents = <bool>[];

      final subConn = container.listen(
        connectivityStreamProvider,
        (_, next) => next.whenData(connEvents.add),
      );
      final subInternet = container.listen(
        internetAccessStreamProvider,
        (_, next) => next.whenData(internetEvents.add),
      );
      addTearDown(() {
        subConn.close();
        subInternet.close();
      });

      fakeConn.emit({NetworkConnectionType.ethernet});
      fakeInternet.emit(false);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(
        connEvents.any((s) => s.contains(NetworkConnectionType.ethernet)),
        isTrue,
      );
      expect(internetEvents, contains(false));
    });
  });
}
