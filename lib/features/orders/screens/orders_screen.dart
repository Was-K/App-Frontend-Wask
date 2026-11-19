import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/models/app_models.dart';
import '../../shared/providers/app_state_provider.dart';
import '../../shared/widgets/wask_bottom_nav.dart';
import '../../shop/providers/cart_provider.dart';

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

  void _reorder(OrderRecord order) {
    if (order.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este pedido no tiene productos para repetir.'),
        ),
      );
      return;
    }

    final cart = context.read<CartProvider>();
    cart.clear();
    final storeId = order.businessId ?? order.supplierId;
    for (final line in order.items) {
      cart.addItem(
        productId: line.productId,
        name: line.name ?? 'Producto WASK',
        price: line.price ?? 0,
        quantity: line.quantity,
        supplierId: storeId,
        storeName: order.storeName,
      );
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Pedido cargado nuevamente en tu carrito.'),
        ),
      );
    Navigator.pushReplacementNamed(context, WaskRoutes.cart);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final orders = appState.orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              WaskRoutes.tracking,
              arguments: orders.isNotEmpty ? orders.first : null,
            ),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('Mapa en vivo'),
          ),
        ],
      ),
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
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aun no tienes pedidos.\nTu pedido actual y el historial apareceran aqui.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: WaskColors.secondaryText),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: AppConfig.enableMocks
                          ? () async {}
                          : () => context.read<AppStateProvider>().loadOrders(),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
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
                                    border:
                                        Border.all(color: WaskColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Pedido ${order.id}',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'S/ ${order.total.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: WaskColors.energyOrange,
                                              fontWeight: FontWeight.w800,
                                              fontFeatures: <FontFeature>[
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Entrega aprox: ${order.deliveryEta ?? '20-30 min'}',
                                        style: const TextStyle(
                                            color: WaskColors.secondaryText,
                                            fontSize: 13),
                                      ),
                                      Text(
                                        'Lugar: ${order.address ?? 'Lima Metropolitana'}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: WaskColors.secondaryText,
                                            fontSize: 13),
                                      ),
                                      Text(
                                        'Tienda: ${order.storeName ?? 'Licoreria Aliada'}',
                                        style: const TextStyle(
                                            color: WaskColors.secondaryText,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        alignment:
                                            WrapAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: WaskColors.electricBlue
                                                  .withOpacity(0.16),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              order.status,
                                              style: const TextStyle(
                                                color: WaskColors.iceBlue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: () =>
                                                    _reorder(order),
                                                style: OutlinedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 8),
                                                ),
                                                icon: const Icon(
                                                  Icons.replay_rounded,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  'Volver a pedir',
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              TextButton.icon(
                                                onPressed: () =>
                                                    Navigator.pushNamed(
                                                  context,
                                                  WaskRoutes.tracking,
                                                  arguments: order,
                                                ),
                                                icon: const Icon(
                                                  Icons.delivery_dining_rounded,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  'Seguir en mapa',
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemCount: orders.length,
                          ),
                        ),
                      ),
                    ),
    );
  }
}
