import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/providers/app_state_provider.dart';
import '../../shared/widgets/wask_bottom_nav.dart';
import '../../shared/widgets/wask_product_image.dart';
import '../../shop/providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _instructionController = TextEditingController();

  @override
  void dispose() {
    _instructionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final appState = context.watch<AppStateProvider>();
    final hasLoyaltyReward =
        appState.loyaltyStatus?.hasFreeDeliveryReward == true;
    final delivery = appState.calculateDeliveryFee(cart.subtotal);
    final total = cart.subtotal + delivery;

    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      bottomNavigationBar: const WaskBottomNav(currentRoute: WaskRoutes.cart),
      body: cart.itemList.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Tu carrito esta vacio. Agrega productos para continuar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: WaskColors.secondaryText),
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...cart.itemList.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: WaskColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: WaskColors.border),
                        ),
                        child: Row(
                          children: [
                            WaskProductImage(
                              imageUrl: item.imageUrl,
                              width: 56,
                              height: 56,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  if ((item.storeName ?? '').isNotEmpty)
                                    Text(
                                      item.storeName!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: WaskColors.secondaryText,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () =>
                                            cart.decrementItem(item.productId),
                                        icon: const Icon(Icons
                                            .remove_circle_outline_rounded),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontFeatures: <FontFeature>[
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () =>
                                            cart.incrementItem(item.productId),
                                        icon: const Icon(
                                            Icons.add_circle_outline_rounded),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'S/ ${item.lineTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: WaskColors.energyOrange,
                                          fontWeight: FontWeight.w700,
                                          fontFeatures: <FontFeature>[
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _instructionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Instruccion de entrega (opcional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: WaskColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: WaskColors.border),
                      ),
                      child: Column(
                        children: [
                          _TotalRow(label: 'Subtotal', value: cart.subtotal),
                          if (hasLoyaltyReward)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Delivery Gratis (Fidelizacion 10 pedidos)',
                                      style: TextStyle(
                                        color: WaskColors.emerald,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'S/ 0.00',
                                    style: TextStyle(
                                      color: WaskColors.emerald,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: <FontFeature>[
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            _TotalRow(label: 'Delivery', value: delivery),
                          const Divider(),
                          _TotalRow(
                              label: 'Total', value: total, isTotal: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        WaskRoutes.home,
                      ),
                      child: const Text('Agregar mas productos'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        WaskRoutes.checkout,
                        arguments: _instructionController.text,
                      ),
                      child: const Text('Continuar al pago'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final double value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'S/ ${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: isTotal ? WaskColors.energyOrange : Colors.white,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
