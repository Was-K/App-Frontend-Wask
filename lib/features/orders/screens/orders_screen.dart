import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/providers/app_state_provider.dart';
import '../../shared/widgets/wask_bottom_nav.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    if (!AppConfig.enableMocks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AppStateProvider>().loadOrders();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final orders = appState.orders;

    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      bottomNavigationBar: const WaskBottomNav(currentRoute: WaskRoutes.orders),
      body: appState.isLoading && !AppConfig.enableMocks
          ? const Center(child: CircularProgressIndicator())
          : appState.errorMessage != null && !AppConfig.enableMocks
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          appState.errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<AppStateProvider>().loadOrders(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : orders.isEmpty
                  ? const Center(
                      child: Text(
                        'Aun no tienes pedidos.\nTu pedido actual y el historial apareceran aqui.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: AppConfig.enableMocks
                          ? () async {}
                          : () => context.read<AppStateProvider>().loadOrders(),
                      child: ListView.separated(
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
                                  Text(
                                    'Entrega aprox: ${order.deliveryEta ?? 'N/D'}',
                                  ),
                                  Text('Lugar: ${order.address ?? 'N/D'}'),
                                  Text('Tienda: ${order.storeName ?? 'N/D'}'),
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
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                    ),
    );
  }
}
