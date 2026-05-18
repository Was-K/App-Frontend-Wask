import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/models/app_models.dart';
import '../../shared/providers/app_state_provider.dart';
import '../../shop/providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.deliveryInstruction,
  });

  final String deliveryInstruction;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentType = 'Efectivo';
  String _paymentFlow = 'Contra entrega';
  final _couponController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final appState = context.watch<AppStateProvider>();

    final subtotal = cart.subtotal;
    final delivery = subtotal >= 80 ? 0.0 : 7.0;
    final discount =
        _couponController.text.trim().toUpperCase() == 'WASK10' ? 10.0 : 0.0;
    final total = subtotal + delivery - discount;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar pedido')),
      body: appState.selectedAddress == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No hay direccion seleccionada.',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text('Selecciona una direccion para continuar.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        WaskRoutes.addressSelect,
                      ),
                      child: const Text('Ir a direcciones'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Section(
                  title: 'Entrega',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appState.selectedAddress!.formatted),
                      const SizedBox(height: 4),
                      const Text('Tiempo estimado: 25-30 min'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'Metodo de pago',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _paymentFlow,
                        decoration:
                            const InputDecoration(labelText: 'Tipo de pago'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Contra entrega',
                            child: Text('Pago contra entrega'),
                          ),
                          DropdownMenuItem(
                            value: 'Pago en linea',
                            child: Text('Pago en linea'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _paymentFlow = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          'Tarjeta debito',
                          'Tarjeta credito',
                          'Efectivo',
                          'Yape',
                          'Plin',
                        ]
                            .map(
                              (method) => ChoiceChip(
                                label: Text(method),
                                selected: _paymentType == method,
                                onSelected: (_) {
                                  setState(() {
                                    _paymentType = method;
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'Cupon',
                  child: TextField(
                    controller: _couponController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Ingresa tu cupon (ej: WASK10)',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'Detalle de pago',
                  child: Column(
                    children: [
                      _TotalRow(label: 'Subtotal', value: subtotal),
                      _TotalRow(label: 'Costo de envio', value: delivery),
                      _TotalRow(label: 'Descuento', value: -discount),
                      const Divider(),
                      _TotalRow(label: 'Total', value: total, isTotal: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: cart.itemList.isEmpty || _isSubmitting
                      ? null
                      : () async {
                          final appState = context.read<AppStateProvider>();
                          final currentUser = appState.currentUser;
                          final businessId = currentUser?.companyId;
                          final supplierIds = cart.itemList
                              .map((item) => item.supplierId)
                              .whereType<String>()
                              .toSet();

                          if (businessId == null || businessId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se puede crear el pedido porque falta businessId.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (supplierIds.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se puede crear el pedido porque falta supplierId.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (supplierIds.length > 1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'El carrito tiene productos de varios proveedores.',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            _isSubmitting = true;
                          });

                          final items = cart.itemList
                              .map(
                                (item) => OrderLine(
                                  productId: item.productId,
                                  name: item.name,
                                  price: item.price,
                                  quantity: item.quantity,
                                ),
                              )
                              .toList();

                          final order = await appState.placeOrder(
                            items: items,
                            storeName: 'Proveedor WAS-K',
                            paymentMethod: '$_paymentFlow - $_paymentType',
                            subtotal: subtotal,
                            deliveryCost: delivery,
                            discount: discount,
                            deliveryNote: widget.deliveryInstruction,
                            businessId: businessId,
                            supplierId: supplierIds.first,
                          );

                          if (!mounted) {
                            return;
                          }

                          setState(() {
                            _isSubmitting = false;
                          });

                          if (order == null) {
                            final message = appState.errorMessage ??
                                'No se pudo crear el pedido.';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                            return;
                          }

                          if (!AppConfig.enableMocks) {
                            await appState.loadOrders();
                          }

                          context.read<CartProvider>().clear();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Pedido creado con exito.')),
                          );

                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            WaskRoutes.orders,
                            (route) => false,
                          );
                        },
                  child: Text(_isSubmitting ? 'Procesando...' : 'Pagar'),
                ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WaskColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          child,
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
