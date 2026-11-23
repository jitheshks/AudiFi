/// Enumerates the primary network availability states.
enum NetworkStatus {
  /// Initial or unverified state before any probe completes.
  unknown,

  /// Device has no active network interface connected (airplane mode, Wi-Fi & cellular off).
  none,

  /// Active interface exists, but internet access check is in-flight.
  transitioning,

  /// Interface connected (e.g. Wi-Fi, Mobile), but internet is unreachable (e.g. captive portal or DNS failure).
  connectedWithoutInternet,

  /// Interface connected and verified live access to the public internet.
  connectedWithInternet,
}

/// Normalized connection transport technologies supported by AudiFi.
enum NetworkConnectionType {
  wifi,
  mobile,
  ethernet,
  vpn,
  bluetooth,
  other,
  none,
}

/// Immutable snapshot of the device's global network and internet reachability.
class AudifiNetworkState {
  final NetworkStatus status;
  final Set<NetworkConnectionType> connectionTypes;

  const AudifiNetworkState({
    required this.status,
    this.connectionTypes = const {},
  });

  /// True when public internet access is verified and reachable.
  bool get hasInternet => status == NetworkStatus.connectedWithInternet;

  /// True when at least one network interface is active, regardless of internet access.
  bool get isConnected =>
      status == NetworkStatus.connectedWithInternet ||
      status == NetworkStatus.connectedWithoutInternet;

  /// True when device has no network interfaces or internet cannot be reached.
  bool get isOffline => !hasInternet;

  /// True while network interfaces are transitioning or probing reachability.
  bool get isTransitioning => status == NetworkStatus.transitioning;

  /// Transport helpers
  bool get isWifi => connectionTypes.contains(NetworkConnectionType.wifi);
  bool get isMobile => connectionTypes.contains(NetworkConnectionType.mobile);
  bool get isEthernet =>
      connectionTypes.contains(NetworkConnectionType.ethernet);
  bool get isVpn => connectionTypes.contains(NetworkConnectionType.vpn);

  /// Human-friendly description (e.g. "Wi-Fi (Online)", "Cellular (No Internet)", "No network connection").
  String get description {
    switch (status) {
      case NetworkStatus.unknown:
        return 'Checking network...';
      case NetworkStatus.none:
        return 'No network connection';
      case NetworkStatus.transitioning:
        return 'Connecting...';
      case NetworkStatus.connectedWithoutInternet:
        final types = _formatTypes();
        return types.isNotEmpty ? '$types (No Internet)' : 'No Internet';
      case NetworkStatus.connectedWithInternet:
        final types = _formatTypes();
        return types.isNotEmpty ? '$types (Online)' : 'Online';
    }
  }

  String _formatTypes() {
    return connectionTypes
        .where((t) => t != NetworkConnectionType.none)
        .map((t) {
          switch (t) {
            case NetworkConnectionType.wifi:
              return 'Wi-Fi';
            case NetworkConnectionType.mobile:
              return 'Cellular';
            case NetworkConnectionType.ethernet:
              return 'Ethernet';
            case NetworkConnectionType.vpn:
              return 'VPN';
            case NetworkConnectionType.bluetooth:
              return 'Bluetooth';
            case NetworkConnectionType.other:
              return 'Other';
            case NetworkConnectionType.none:
              return '';
          }
        })
        .where((s) => s.isNotEmpty)
        .join(', ');
  }

  static const initial = AudifiNetworkState(
    status: NetworkStatus.unknown,
    connectionTypes: {},
  );

  static const disconnected = AudifiNetworkState(
    status: NetworkStatus.none,
    connectionTypes: {NetworkConnectionType.none},
  );

  AudifiNetworkState copyWith({
    NetworkStatus? status,
    Set<NetworkConnectionType>? connectionTypes,
  }) {
    return AudifiNetworkState(
      status: status ?? this.status,
      connectionTypes: connectionTypes ?? this.connectionTypes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudifiNetworkState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          connectionTypes.length == other.connectionTypes.length &&
          connectionTypes.containsAll(other.connectionTypes);

  @override
  int get hashCode => Object.hash(status, Object.hashAll(connectionTypes));

  @override
  String toString() =>
      'AudifiNetworkState(status: $status, types: $connectionTypes)';
}
