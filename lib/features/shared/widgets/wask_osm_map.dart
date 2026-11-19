import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/wask_theme.dart';

class WaskWebMercator {
  static const double tileSize = 256.0;

  static Offset latLngToWorldPixel(double lat, double lng, int zoom) {
    final scale = tileSize * (1 << zoom);
    final x = ((lng + 180.0) / 360.0) * scale;
    final latRad = lat.clamp(-85.05112878, 85.05112878) * math.pi / 180.0;
    final sinLat = math.sin(latRad);
    final y =
        (0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) * scale;
    return Offset(x, y);
  }

  static ({double lat, double lng}) worldPixelToLatLng(Offset px, int zoom) {
    final scale = tileSize * (1 << zoom);
    final lng = (px.dx / scale) * 360.0 - 180.0;
    final n = math.pi - 2.0 * math.pi * (px.dy / scale);
    final latRad = math.atan(0.5 * (math.exp(n) - math.exp(-n)));
    final lat = latRad * 180.0 / math.pi;
    return (lat: lat, lng: lng);
  }

  static Offset latLngToScreen(
    double lat,
    double lng,
    int zoom,
    Offset topLeftWorld,
  ) {
    final world = latLngToWorldPixel(lat, lng, zoom);
    return Offset(world.dx - topLeftWorld.dx, world.dy - topLeftWorld.dy);
  }

  static ({double lat, double lng}) panCoordinates({
    required double centerLat,
    required double centerLng,
    required int zoom,
    required Offset deltaPixels,
  }) {
    final centerPx = latLngToWorldPixel(centerLat, centerLng, zoom);
    final shifted =
        Offset(centerPx.dx - deltaPixels.dx, centerPx.dy - deltaPixels.dy);
    final updated = worldPixelToLatLng(shifted, zoom);
    return (
      lat: updated.lat.clamp(-85.0, 85.0),
      lng: updated.lng,
    );
  }
}

typedef WaskOsmOverlayBuilder = List<Widget> Function(
  BuildContext context,
  Size viewportSize,
  Offset topLeftWorld,
  int zoom,
);

class WaskOsmMap extends StatelessWidget {
  const WaskOsmMap({
    super.key,
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    required this.onPanDelta,
    this.onZoomIn,
    this.onZoomOut,
    this.onRecenter,
    this.overlayBuilder,
    this.topLeftBanner,
    this.bottomLeftBanner,
  });

  final double centerLat;
  final double centerLng;
  final int zoom;
  final void Function(Offset delta) onPanDelta;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onRecenter;
  final WaskOsmOverlayBuilder? overlayBuilder;
  final Widget? topLeftBanner;
  final Widget? bottomLeftBanner;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final centerWorld =
              WaskWebMercator.latLngToWorldPixel(centerLat, centerLng, zoom);
          final topLeftWorld =
              Offset(centerWorld.dx - width / 2, centerWorld.dy - height / 2);

          const tileSize = WaskWebMercator.tileSize;
          final maxTileIndex = 1 << zoom;

          final minTileX = (topLeftWorld.dx / tileSize).floor();
          final maxTileX = ((topLeftWorld.dx + width) / tileSize).floor();
          final minTileY = (topLeftWorld.dy / tileSize).floor();
          final maxTileY = ((topLeftWorld.dy + height) / tileSize).floor();

          final tileWidgets = <Widget>[];
          for (var ty = minTileY; ty <= maxTileY; ty++) {
            if (ty < 0 || ty >= maxTileIndex) {
              continue;
            }
            for (var tx = minTileX; tx <= maxTileX; tx++) {
              final wrappedX =
                  ((tx % maxTileIndex) + maxTileIndex) % maxTileIndex;
              final left = tx * tileSize - topLeftWorld.dx;
              final top = ty * tileSize - topLeftWorld.dy;
              final tileUrl =
                  'https://tile.openstreetmap.org/$zoom/$wrappedX/$ty.png';

              tileWidgets.add(
                Positioned(
                  left: left,
                  top: top,
                  width: tileSize,
                  height: tileSize,
                  child: Image.network(
                    tileUrl,
                    width: tileSize,
                    height: tileSize,
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) => _TileFallbackGrid(
                      tx: wrappedX,
                      ty: ty,
                    ),
                  ),
                ),
              );
            }
          }

          return GestureDetector(
            onPanUpdate: (details) => onPanDelta(details.delta),
            child: Container(
              width: width,
              height: height,
              color: const Color(0xFF0E1420),
              child: Stack(
                children: [
                  ...tileWidgets,
                  IgnorePointer(
                    child: Container(color: const Color(0x28050810)),
                  ),
                  if (overlayBuilder != null)
                    ...overlayBuilder!(
                      context,
                      Size(width, height),
                      topLeftWorld,
                      zoom,
                    ),
                  if (topLeftBanner != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 68,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: topLeftBanner!,
                      ),
                    ),
                  if (bottomLeftBanner != null)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 150,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: bottomLeftBanner!,
                      ),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Column(
                      children: [
                        _MapControlButton(
                          icon: Icons.add_rounded,
                          tooltip: 'Acercar',
                          onPressed: onZoomIn,
                        ),
                        const SizedBox(height: 6),
                        _MapControlButton(
                          icon: Icons.remove_rounded,
                          tooltip: 'Alejar',
                          onPressed: onZoomOut,
                        ),
                        if (onRecenter != null) ...[
                          const SizedBox(height: 6),
                          _MapControlButton(
                            icon: Icons.center_focus_strong_rounded,
                            tooltip: 'Centrar',
                            onPressed: onRecenter,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.78),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: WaskColors.border),
                      ),
                      child: Text(
                        '© OpenStreetMap · z$zoom',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.84),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: WaskColors.border),
          ),
          child: Icon(
            icon,
            size: 20,
            color: onPressed == null ? Colors.white24 : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TileFallbackGrid extends StatelessWidget {
  const _TileFallbackGrid({required this.tx, required this.ty});

  final int tx;
  final int ty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101722),
        border: Border.all(color: const Color(0x14FFFFFF), width: 0.5),
      ),
      child: CustomPaint(
        painter: _StreetGridFallbackPainter(seed: tx + ty),
      ),
    );
  }
}

class _StreetGridFallbackPainter extends CustomPainter {
  const _StreetGridFallbackPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final streetPaint = Paint()
      ..color = const Color(0xFF1B2638)
      ..strokeWidth = 2.0;
    final minorPaint = Paint()
      ..color = const Color(0xFF151E2C)
      ..strokeWidth = 1.0;

    for (var i = 1; i < 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorPaint);
      final x = size.width * (i / 4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorPaint);
    }
    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.85, size.height),
      streetPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StreetGridFallbackPainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}
