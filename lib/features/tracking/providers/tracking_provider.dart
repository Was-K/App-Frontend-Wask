import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../shared/models/app_models.dart';

class TrackingWaypoint {
  const TrackingWaypoint({
    required this.lat,
    required this.lng,
    required this.streetLabel,
  });

  final double lat;
  final double lng;
  final String streetLabel;
}

class TrackingProvider extends ChangeNotifier {
  static const Duration initialDuration = Duration(minutes: 30);

  /// Ruta realista en Lima: Av. Arequipa -> Av. Petit Thouars -> Jr. Risso / Destino
  static const List<TrackingWaypoint> limaRoute = <TrackingWaypoint>[
    TrackingWaypoint(
      lat: -12.1095,
      lng: -77.0315,
      streetLabel: 'Av. Arequipa 3890 (Licoreria Origen)',
    ),
    TrackingWaypoint(
      lat: -12.1058,
      lng: -77.0328,
      streetLabel: 'Av. Arequipa & Av. Aramburu',
    ),
    TrackingWaypoint(
      lat: -12.1032,
      lng: -77.0318,
      streetLabel: 'Av. Petit Thouars · San Isidro',
    ),
    TrackingWaypoint(
      lat: -12.1005,
      lng: -77.0326,
      streetLabel: 'Av. Petit Thouars & Javier Prado',
    ),
    TrackingWaypoint(
      lat: -12.0985,
      lng: -77.0345,
      streetLabel: 'Jr. Risso / Destino · Lince',
    ),
  ];

  Duration _remaining = const Duration(minutes: 24);
  double _routeProgress = 0.15;
  String? _backendStatus;
  String? _trackedOrderId;
  String? _trackedStoreName;
  Timer? _timer;

  Duration get remaining => _remaining;
  double get routeProgress => _routeProgress;
  String? get backendStatus => _backendStatus;
  String? get trackedOrderId => _trackedOrderId;
  String? get trackedStoreName => _trackedStoreName;
  bool get isCancelled => _backendStatus == 'CANCELLED';
  bool get isFree =>
      _remaining == Duration.zero && _routeProgress < 1.0 && !isCancelled;
  bool get isDelivered => _routeProgress >= 1.0 && !isCancelled;

  void syncWithOrder(OrderRecord? order) {
    if (order == null) {
      return;
    }
    _trackedOrderId = order.id;
    _trackedStoreName = order.storeName;
    final upper = order.status.trim().toUpperCase();
    _backendStatus = upper;

    switch (upper) {
      case 'DELIVERED':
      case 'ENTREGADO':
        _routeProgress = 1.0;
        _remaining = Duration.zero;
        _timer?.cancel();
        break;
      case 'SHIPPED':
      case 'EN_CAMINO':
        if (_routeProgress < 0.65 || _routeProgress >= 1.0) {
          _routeProgress = 0.65;
        }
        if (_remaining > const Duration(minutes: 12) ||
            _remaining == Duration.zero) {
          _remaining = const Duration(minutes: 10);
        }
        break;
      case 'PROCESSING':
      case 'PROCESANDO':
        _routeProgress = 0.28;
        if (_remaining == Duration.zero) {
          _remaining = const Duration(minutes: 18);
        }
        break;
      case 'CANCELLED':
        _routeProgress = 0.0;
        _remaining = Duration.zero;
        _timer?.cancel();
        break;
      case 'PENDING':
      case 'APPROVED':
      default:
        _routeProgress = 0.08;
        if (_remaining == Duration.zero) {
          _remaining = const Duration(minutes: 24);
        }
        break;
    }
    notifyListeners();
  }

  String get formattedTime {
    final minutes =
        _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int get currentStepIndex {
    switch (_backendStatus) {
      case 'DELIVERED':
      case 'ENTREGADO':
        return 3;
      case 'SHIPPED':
      case 'EN_CAMINO':
        return 2;
      case 'PROCESSING':
      case 'PROCESANDO':
        return 1;
      case 'PENDING':
      case 'APPROVED':
        return _routeProgress >= 0.30 ? 2 : (_routeProgress >= 0.12 ? 1 : 0);
      default:
        break;
    }
    if (_routeProgress >= 0.99) {
      return 3;
    }
    if (_routeProgress >= 0.30) {
      return 2;
    }
    if (_routeProgress >= 0.10) {
      return 1;
    }
    return 0;
  }

  String get currentStatusLabel {
    if (isCancelled) {
      return 'Pedido cancelado';
    }
    switch (currentStepIndex) {
      case 3:
        return 'Pedido entregado en destino';
      case 2:
        return 'Motorizado en camino';
      case 1:
        return 'Preparando tu pedido en tienda';
      case 0:
      default:
        return 'Pedido confirmado en tienda';
    }
  }

  String get currentStreetLabel {
    final segCount = limaRoute.length - 1;
    final scaled = (_routeProgress.clamp(0.0, 1.0)) * segCount;
    final idx = scaled.round().clamp(0, limaRoute.length - 1);
    return limaRoute[idx].streetLabel;
  }

  ({double lat, double lng}) get currentPosition {
    final t = _routeProgress.clamp(0.0, 1.0);
    final segCount = limaRoute.length - 1;
    if (t >= 1.0) {
      final last = limaRoute.last;
      return (lat: last.lat, lng: last.lng);
    }
    final scaled = t * segCount;
    final index = scaled.floor().clamp(0, segCount - 1);
    final localT = scaled - index;
    final a = limaRoute[index];
    final b = limaRoute[index + 1];
    return (
      lat: a.lat + (b.lat - a.lat) * localT,
      lng: a.lng + (b.lng - a.lng) * localT,
    );
  }

  void startCountdown() {
    _timer?.cancel();
    if (_remaining == Duration.zero && _routeProgress < 1.0) {
      _remaining = initialDuration;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining > Duration.zero) {
        _remaining -= const Duration(seconds: 1);
        notifyListeners();
        return;
      }

      timer.cancel();
      notifyListeners();
    });
    notifyListeners();
  }

  void advanceDeliveryDemo() {
    if (_routeProgress >= 1.0) {
      resetAndStart();
      return;
    }

    _routeProgress = (_routeProgress + 0.25).clamp(0.0, 1.0);
    final remainingMinutes = ((1.0 - _routeProgress) * 24).round();
    _remaining = Duration(minutes: remainingMinutes);
    if (_routeProgress >= 1.0) {
      _timer?.cancel();
    }
    notifyListeners();
  }

  void resetAndStart() {
    _routeProgress = 0.15;
    _remaining = const Duration(minutes: 24);
    startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
