import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/providers/app_state_provider.dart';
import '../../shared/widgets/wask_bottom_nav.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<AppStateProvider>().orders;

    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      bottomNavigationBar: const WaskBottomNav(currentRoute: WaskRoutes.orders),
      body: orders.isEmpty
          ? const Center(
              child: Text(
                'Aun no tienes pedidos.\nTu pedido actual y el historial apareceran aqui.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final order = orders[index];
                return InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    WaskRoutes.orderDetail,
                    arguments: order,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: WaskColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido ${order.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Entrega aprox: ${order.deliveryEta}'),
                        Text('Lugar: ${order.address}'),
                        Text('Tienda: ${order.storeName}'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(order.status),
                            ),
                            const Spacer(),
                            Text(
                              'S/ ${order.total.toStringAsFixed(2)}',
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
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: orders.length,
            ),
    );
  }
}
