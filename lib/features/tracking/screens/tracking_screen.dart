import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/models/app_models.dart';
import '../../shared/providers/app_state_provider.dart';
import '../../shared/widgets/wask_osm_map.dart';
import '../providers/tracking_provider.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, this.initialOrder});

  final OrderRecord? initialOrder;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  static const double _defaultCenterLat = -12.104;
  static const double _defaultCenterLng = -77.033;
  static const int _defaultZoom = 15;
  static const int _minZoom = 13;
  static const int _maxZoom = 18;

  double _centerLat = _defaultCenterLat;
  double _centerLng = _defaultCenterLng;
  int _zoom = _defaultZoom;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final trackingProvider = context.read<TrackingProvider>();
      final appState = context.read<AppStateProvider>();
      if (widget.initialOrder != null) {
        trackingProvider.syncWithOrder(widget.initialOrder);
      } else if (appState.orders.isNotEmpty &&
          trackingProvider.trackedOrderId == null) {
        final active = appState.orders.firstWhere(
          (o) => !const {'DELIVERED', 'ENTREGADO', 'CANCELLED'}
              .contains(o.status.trim().toUpperCase()),
          orElse: () => appState.orders.first,
        );
        trackingProvider.syncWithOrder(active);
      } else if (!AppConfig.enableMocks && appState.isAuthenticated) {
        _refreshActiveOrder(silent: true);
      }
      trackingProvider.startCountdown();
      if (!AppConfig.enableMocks && appState.isAuthenticated) {
        _pollTimer = Timer.periodic(
          const Duration(seconds: 10),
          (_) => _refreshActiveOrder(silent: true),
        );
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshActiveOrder({bool silent = false}) async {
    if (!mounted) {
      return;
    }
    final appState = context.read<AppStateProvider>();
    if (AppConfig.enableMocks || !appState.isAuthenticated) {
      return;
    }
    await appState.loadOrders();
    if (!mounted) {
      return;
    }
    final tp = context.read<TrackingProvider>();
    final orders = appState.orders;
    if (orders.isEmpty) {
      return;
    }
    final targetId = tp.trackedOrderId ?? widget.initialOrder?.id;
    OrderRecord? matched;
    if (targetId != null && targetId.isNotEmpty) {
      for (final o in orders) {
        if (o.id == targetId) {
          matched = o;
          break;
        }
      }
    }
    matched ??= orders.firstWhere(
      (o) => !const {'DELIVERED', 'ENTREGADO', 'CANCELLED'}
          .contains(o.status.trim().toUpperCase()),
      orElse: () => orders.first,
    );
    tp.syncWithOrder(matched);
    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado: ${tp.currentStatusLabel}'),
        ),
      );
    }
  }

  void _recenterMap() {
    setState(() {
      _centerLat = _defaultCenterLat;
      _centerLng = _defaultCenterLng;
      _zoom = _defaultZoom;
    });
  }

  void _changeZoom(int delta) {
    setState(() {
      _zoom = (_zoom + delta).clamp(_minZoom, _maxZoom);
    });
  }

  void _panByPixels(Offset delta) {
    final updated = WaskWebMercator.panCoordinates(
      centerLat: _centerLat,
      centerLng: _centerLng,
      zoom: _zoom,
      deltaPixels: delta,
    );
    setState(() {
      _centerLat = updated.lat;
      _centerLng = updated.lng;
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackingProvider = context.watch<TrackingProvider>();
    final selectedAddr = context.watch<AppStateProvider>().selectedAddress;
    final destinationLabel =
        selectedAddr?.formatted ?? 'Jr. Risso / Destino · Lince';
    final originPinLabel =
        (trackingProvider.trackedStoreName ?? '').trim().isNotEmpty
            ? trackingProvider.trackedStoreName!
            : 'Licorería';
    final destDistrict = selectedAddr?.district.trim() ?? '';
    final destinationPinLabel =
        destDistrict.isNotEmpty ? 'Entrega · $destDistrict' : 'Tu entrega';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento en Tiempo Real'),
        actions: [
          IconButton(
            tooltip: 'Actualizar estado del pedido',
            onPressed: _refreshActiveOrder,
            icon: const Icon(Icons.sync_rounded),
          ),
          IconButton(
            tooltip: 'Centrar ruta Lima',
            onPressed: _recenterMap,
            icon: const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 860;
          final mapPane = WaskOsmMap(
            centerLat: _centerLat,
            centerLng: _centerLng,
            zoom: _zoom,
            onPanDelta: _panByPixels,
            onZoomIn: _zoom < _maxZoom ? () => _changeZoom(1) : null,
            onZoomOut: _zoom > _minZoom ? () => _changeZoom(-1) : null,
            onRecenter: _recenterMap,
            bottomLeftBanner: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.82),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: WaskColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.navigation_rounded,
                    size: 14,
                    color: WaskColors.energyOrange,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      trackingProvider.currentStreetLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            overlayBuilder: (context, viewportSize, topLeftWorld, zoom) {
              final projectedPoints = TrackingProvider.limaRoute
                  .map(
                    (wp) => WaskWebMercator.latLngToScreen(
                      wp.lat,
                      wp.lng,
                      zoom,
                      topLeftWorld,
                    ),
                  )
                  .toList();

              return <Widget>[
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: trackingProvider.routeProgress),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedProgress, _) {
                    final driverOffset = _interpolateScreenPoint(
                      projectedPoints,
                      animatedProgress,
                    );

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _OsmRoutePainter(
                                points: projectedPoints,
                                progress: animatedProgress,
                              ),
                            ),
                          ),
                        ),
                        _PinMarker(
                          offset: projectedPoints.first,
                          label: originPinLabel,
                          color: WaskColors.electricBlue,
                          icon: Icons.storefront_rounded,
                        ),
                        _PinMarker(
                          offset: projectedPoints.last,
                          label: destinationPinLabel,
                          color: WaskColors.emerald,
                          icon: Icons.home_rounded,
                        ),
                        _MotorizadoMarker(offset: driverOffset),
                      ],
                    );
                  },
                ),
              ];
            },
          );

          final infoPane = _TrackingDetailsPanel(
            trackingProvider: trackingProvider,
            destinationLabel: destinationLabel,
            onRefreshStatus: () => _refreshActiveOrder(silent: false),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: mapPane),
                SizedBox(
                  width: 390,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: WaskColors.canvas,
                      border: Border(
                        left: BorderSide(color: WaskColors.border),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: infoPane,
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              Expanded(flex: 5, child: mapPane),
              Expanded(
                flex: 6,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: WaskColors.canvas,
                    border: Border(
                      top: BorderSide(color: WaskColors.border),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    child: infoPane,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Offset _interpolateScreenPoint(List<Offset> points, double progress) {
    final t = progress.clamp(0.0, 1.0);
    final segCount = points.length - 1;
    if (segCount <= 0) {
      return points.first;
    }
    if (t >= 1.0) {
      return points.last;
    }
    final scaled = t * segCount;
    final idx = scaled.floor().clamp(0, segCount - 1);
    final localT = scaled - idx;
    return Offset.lerp(points[idx], points[idx + 1], localT) ?? points.last;
  }
}

class _TrackingDetailsPanel extends StatelessWidget {
  const _TrackingDetailsPanel({
    required this.trackingProvider,
    required this.destinationLabel,
    required this.onRefreshStatus,
  });

  final TrackingProvider trackingProvider;
  final String destinationLabel;
  final VoidCallback onRefreshStatus;

  @override
  Widget build(BuildContext context) {
    final step = trackingProvider.currentStepIndex;
    const steps = <String>[
      'Confirmado',
      'Preparando',
      'En camino',
      'Entregado',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trackingProvider.currentStatusLabel,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if ((trackingProvider.trackedOrderId ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Pedido ${trackingProvider.trackedOrderId}${trackingProvider.trackedStoreName != null ? ' · ${trackingProvider.trackedStoreName}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WaskColors.iceBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    'Destino: $destinationLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WaskColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: WaskColors.energyOrange.withOpacity(0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: WaskColors.energyOrange.withOpacity(0.5),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'ETA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: WaskColors.secondaryText,
                    ),
                  ),
                  Text(
                    trackingProvider.isDelivered
                        ? '00:00'
                        : trackingProvider.formattedTime,
                    style: const TextStyle(
                      color: WaskColors.energyOrange,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFeatures: <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(steps.length, (i) {
            final active = i <= step;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < steps.length - 1 ? 6 : 0),
                child: Column(
                  children: [
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: active
                            ? (step == 3
                                ? WaskColors.emerald
                                : WaskColors.electricBlue)
                            : WaskColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      steps[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active
                            ? WaskColors.primaryText
                            : WaskColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: WaskColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WaskColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: WaskColors.electricBlue.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delivery_dining_rounded,
                  color: WaskColors.iceBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Carlos Mendoza',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Placa 4821-9B · Motorizado WAS-K',
                      style: TextStyle(
                        color: WaskColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Contactar soporte del pedido',
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (dlgCtx) => AlertDialog(
                      backgroundColor: WaskColors.surface,
                      title: const Text('Soporte WASK Piloto'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Si necesitas coordinar la entrega con el repartidor o la tienda, escribe o llama al soporte piloto:',
                            style: TextStyle(fontSize: 13),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'WhatsApp / Telefono: +51 999 888 777',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: WaskColors.emerald,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            await Clipboard.setData(
                              const ClipboardData(text: '999888777'),
                            );
                            if (dlgCtx.mounted) {
                              Navigator.pop(dlgCtx);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Numero 999 888 777 copiado.'),
                                ),
                              );
                            }
                          },
                          child: const Text('Copiar numero'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dlgCtx),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: WaskColors.emerald.withOpacity(0.16),
                  foregroundColor: WaskColors.emerald,
                ),
                icon: const Icon(Icons.call_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if ((trackingProvider.trackedOrderId ?? '').isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRefreshStatus,
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Actualizar estado ahora'),
            ),
          )
        else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: trackingProvider.advanceDeliveryDemo,
              icon: Icon(
                trackingProvider.isDelivered
                    ? Icons.replay_rounded
                    : Icons.fast_forward_rounded,
              ),
              label: Text(
                trackingProvider.isDelivered
                    ? 'Reiniciar simulacion de ruta'
                    : 'Simular avance de motorizado',
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: trackingProvider.resetAndStart,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reiniciar contador'),
            ),
          ),
        ],
      ],
    );
  }
}

class _PinMarker extends StatelessWidget {
  const _PinMarker({
    required this.offset,
    required this.label,
    required this.color,
    required this.icon,
  });

  final Offset offset;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx - 16,
      top: offset.dy - 36,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.7)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 17, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotorizadoMarker extends StatelessWidget {
  const _MotorizadoMarker({required this.offset});

  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx - 22,
      top: offset.dy - 22,
      child: IgnorePointer(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: WaskColors.energyOrange.withOpacity(0.28),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: WaskColors.energyOrange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _OsmRoutePainter extends CustomPainter {
  const _OsmRoutePainter({
    required this.points,
    required this.progress,
  });

  final List<Offset> points;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final fullPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      fullPath.lineTo(points[i].dx, points[i].dy);
    }

    final casingPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fullPath, casingPaint);

    final plannedPaint = Paint()
      ..color = WaskColors.electricBlue
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fullPath, plannedPaint);

    final t = progress.clamp(0.0, 1.0);
    if (t <= 0) {
      return;
    }

    final segCount = points.length - 1;
    final scaled = t * segCount;
    final completedIndex = scaled.floor().clamp(0, segCount - 1);
    final localT = t >= 1.0 ? 1.0 : scaled - completedIndex;

    final completedPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i <= completedIndex; i++) {
      completedPath.lineTo(points[i].dx, points[i].dy);
    }
    final lastStop = Offset.lerp(
          points[completedIndex],
          points[(completedIndex + 1).clamp(0, points.length - 1)],
          localT,
        ) ??
        points.last;
    completedPath.lineTo(lastStop.dx, lastStop.dy);

    final activePaint = Paint()
      ..color = WaskColors.energyOrange
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(completedPath, activePaint);
  }

  @override
  bool shouldRepaint(covariant _OsmRoutePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.points != points;
  }
}
