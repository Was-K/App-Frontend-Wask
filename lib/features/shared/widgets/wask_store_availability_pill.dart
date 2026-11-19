import 'package:flutter/material.dart';

import '../../../core/theme/wask_theme.dart';

class WaskStoreAvailabilityPill extends StatelessWidget {
  const WaskStoreAvailabilityPill({
    super.key,
    required this.isOpenNow,
    required this.inCoverage,
    this.openTime,
    this.maxRadiusKm,
  });

  final bool isOpenNow;
  final bool inCoverage;
  final String? openTime;
  final double? maxRadiusKm;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;

    if (!isOpenNow) {
      label = openTime != null && openTime != '00:00'
          ? 'Cerrado · Abre $openTime'
          : 'Cerrado';
      color = Colors.redAccent;
    } else if (!inCoverage) {
      label =
          'Fuera de zona (${maxRadiusKm?.toStringAsFixed(0) ?? '8'} km máx.)';
      color = WaskColors.energyOrange;
    } else {
      label = 'Abierto ahora';
      color = WaskColors.emerald;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
