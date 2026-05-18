import 'package:flutter/material.dart';

import '../../../core/theme/wask_theme.dart';
import '../../shared/models/app_models.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  final OrderRecord order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pedido ${order.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Resumen',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Entrega aprox: ${order.deliveryEta ?? 'N/D'}'),
                Text('Lugar: ${order.address ?? 'N/D'}'),
                Text('Tienda: ${order.storeName ?? 'N/D'}'),
                Text('Estado: ${order.status}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Detalle de pedido',
            child: Column(
              children: order.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text('${item.quantity} x ${item.name}')),
                          Text('S/ ${item.lineTotal.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Detalle de pago',
            child: Column(
              children: [
                _PaymentRow(label: 'Subtotal', value: order.subtotal ?? 0),
                _PaymentRow(label: 'Delivery', value: order.deliveryCost ?? 0),
                _PaymentRow(label: 'Descuento', value: -(order.discount ?? 0)),
                const Divider(),
                _PaymentRow(label: 'Total', value: order.total, isTotal: true),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Metodo: ${order.paymentMethod ?? 'N/D'}'),
                ),
              ],
            ),
          ),
          if ((order.deliveryNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Instruccion de entrega',
              child: Text(order.deliveryNote ?? ''),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WaskColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final double value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final color = isTotal ? WaskColors.energyOrange : Colors.white;
    final weight = isTotal ? FontWeight.w800 : FontWeight.w500;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: weight))),
          Text(
            'S/ ${value.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontWeight: weight),
          ),
        ],
      ),
    );
  }
}
