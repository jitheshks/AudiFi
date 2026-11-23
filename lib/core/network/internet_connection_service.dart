import 'dart:async';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Contract for checking and observing actual internet data reachability.
abstract interface class InternetConnectionService {
  /// Actively checks whether the device can reach the public internet.
  Future<bool> hasInternetAccess();

  /// Reactive stream of boolean internet reachability changes.
  Stream<bool> get onInternetAccessChanged;

  /// Releases resources and cancels active subscriptions.
  void dispose();
}

/// Production implementation of [InternetConnectionService] backed by `internet_connection_checker_plus`.
class InternetConnectionServiceImpl implements InternetConnectionService {
  final InternetConnection _checker;
  StreamSubscription<InternetStatus>? _statusSubscription;
  final StreamController<bool> _accessController =
      StreamController<bool>.broadcast();

  InternetConnectionServiceImpl({InternetConnection? checker})
    : _checker = checker ?? InternetConnection() {
    _statusSubscription = _checker.onStatusChange.listen(
      (status) {
        final isConnected = status == InternetStatus.connected;
        if (!_accessController.isClosed) {
          _accessController.add(isConnected);
        }
      },
      onError: (_) {
        if (!_accessController.isClosed) {
          _accessController.add(false);
        }
      },
    );
  }

  @override
  Future<bool> hasInternetAccess() async {
    try {
      return await _checker.hasInternetAccess;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onInternetAccessChanged => _accessController.stream;

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _accessController.close();
  }
}
