import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/wask_theme.dart';
import '../models/app_models.dart';
import '../providers/app_state_provider.dart';

class WaskLoyaltyCard extends StatelessWidget {
  const WaskLoyaltyCard({
    super.key,
    this.onSimulated,
  });

  final VoidCallback? onSimulated;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final loyalty = appState.loyaltyStatus ?? LoyaltyStatus.empty();
    final target = loyalty.targetOrders > 0 ? loyalty.targetOrders : 10;
    final progress = loyalty.currentCycleProgress.clamp(0, target);
    final unlocked = loyalty.hasFreeDeliveryReward;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WaskColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? WaskColors.emerald.withOpacity(0.55)
              : WaskColors.electricBlue.withOpacity(0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (unlocked
                          ? WaskColors.emerald
                          : WaskColors.electricBlue)
                      .withOpacity(0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  unlocked
                      ? Icons.workspace_premium_rounded
                      : Icons.loyalty_rounded,
                  color:
                      unlocked ? WaskColors.emerald : WaskColors.electricBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tarjeta de Fidelización WASK',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: WaskColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loyalty.rewardLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: WaskColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (unlocked
                          ? WaskColors.emerald
                          : WaskColors.electricBlue)
                      .withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: (unlocked
                            ? WaskColors.emerald
                            : WaskColors.electricBlue)
                        .withOpacity(0.45),
                  ),
                ),
                child: Text(
                  unlocked
                      ? '${loyalty.freeDeliveriesAvailable} Delivery Gratis'
                      : '$progress/$target',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color:
                        unlocked ? WaskColors.emerald : WaskColors.iceBlue,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 6.0;
              final perRow = constraints.maxWidth < 310 ? 5 : 10;
              final itemWidth =
                  ((constraints.maxWidth - (spacing * (perRow - 1))) / perRow)
                      .clamp(22.0, 44.0);

              return Wrap(
                spacing: spacing,
                runSpacing: 6,
                children: List.generate(target, (index) {
                  final filled = index < progress;
                  return Container(
                    width: itemWidth,
                    height: 30,
                    decoration: BoxDecoration(
                      color: filled
                          ? (unlocked
                                  ? WaskColors.emerald
                                  : WaskColors.electricBlue)
                              .withOpacity(0.22)
                          : WaskColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: filled
                            ? (unlocked
                                ? WaskColors.emerald
                                : WaskColors.electricBlue)
                            : WaskColors.border,
                      ),
                    ),
                    child: Center(
                      child: filled
                          ? Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: unlocked
                                  ? WaskColors.emerald
                                  : WaskColors.iceBlue,
                            )
                          : Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: WaskColors.secondaryText,
                                fontFeatures: <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  unlocked
                      ? 'Delivery Gratis desbloqueado ($progress/$target pedidos entregados)'
                      : '$progress/$target pedidos entregados · Faltan ${loyalty.nextRewardIn} para tu Delivery Gratis',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: unlocked
                        ? WaskColors.emerald
                        : WaskColors.secondaryText,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: appState.isSimulatingLoyalty
                  ? null
                  : () async {
                      final result = await context
                          .read<AppStateProvider>()
                          .simulateTenDeliveredOrders();
                      if (!context.mounted) {
                        return;
                      }
                      if (result != null) {
                        onSimulated?.call();
                      } else {
                        final msg =
                            context.read<AppStateProvider>().errorMessage ??
                                'No se pudo simular el pedido.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msg)),
                        );
                      }
                    },
              icon: appState.isSimulatingLoyalty
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bolt_rounded, size: 18),
              label: Text(
                appState.isSimulatingLoyalty
                    ? 'Actualizando fidelización...'
                    : 'Simular 10.º pedido entregado (Demo)',
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: unlocked
                    ? WaskColors.emerald
                    : WaskColors.iceBlue,
                side: BorderSide(
                  color: (unlocked ? WaskColors.emerald : WaskColors.iceBlue)
                      .withOpacity(0.45),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
