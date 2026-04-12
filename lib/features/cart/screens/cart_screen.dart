import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/widgets/wask_bottom_nav.dart';
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
    final delivery = cart.subtotal >= 80 ? 0.0 : 7.0;
    final total = cart.subtotal + delivery;

    return Scaffold(
      appBar: AppBar(title: const Text('Carrito')),
      bottomNavigationBar: const WaskBottomNav(currentRoute: WaskRoutes.cart),
      body: cart.itemList.isEmpty
          ? const Center(
              child: Text(
                  'Tu carrito esta vacio. Agrega productos para continuar.'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...cart.itemList.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: WaskColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () =>
                                  cart.decrementItem(item.productId),
                              icon: const Icon(
                                  Icons.remove_circle_outline_rounded),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              onPressed: () =>
                                  cart.incrementItem(item.productId),
                              icon:
                                  const Icon(Icons.add_circle_outline_rounded),
                            ),
                            const Spacer(),
                            Text(
                              'S/ ${item.lineTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: WaskColors.energyOrange,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WaskColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _TotalRow(label: 'Subtotal', value: cart.subtotal),
                      _TotalRow(label: 'Delivery', value: delivery),
                      const Divider(),
                      _TotalRow(label: 'Total', value: total, isTotal: true),
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
                  child: const Text('Continuar'),
                ),
              ],
            ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(
      {required this.label, required this.value, this.isTotal = false});

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
          Text(
            'S/ ${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: isTotal ? WaskColors.energyOrange : Colors.white,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
