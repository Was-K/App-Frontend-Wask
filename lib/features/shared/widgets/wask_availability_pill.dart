import 'package:flutter/material.dart';

import '../../../core/theme/wask_theme.dart';

class WaskAvailabilityPill extends StatelessWidget {
  const WaskAvailabilityPill({
    super.key,
    required this.availableStock,
  });

  final int availableStock;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;

    if (availableStock <= 0) {
      label = 'Agotado';
      color = WaskColors.energyOrange;
    } else if (availableStock <= 5) {
      label = 'Pocas unidades';
      color = WaskColors.amber;
    } else {
      label = 'Disponible';
      color = WaskColors.emerald;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
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
