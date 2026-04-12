import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/widgets/wask_button.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.price,
  });

  final String productId;
  final String productName;
  final double price;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de producto')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.asset(
                'assets/images/waskaran.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: WaskColors.surface,
                  child: const Center(
                    child: Icon(Icons.local_bar_rounded,
                        size: 48, color: WaskColors.electricBlue),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.productName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'S/ ${widget.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: WaskColors.energyOrange,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Despacho rapido para Jesus Maria, Lince y Pueblo Libre. Producto recomendado para previa premium.',
            style: TextStyle(color: WaskColors.secondaryText),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WaskColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _quantity > 1
                      ? () => setState(() {
                            _quantity--;
                          })
                      : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Expanded(
                  child: Text(
                    '$_quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _quantity++;
                  }),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          WaskButton(
            label: 'Agregar al carrito',
            expanded: true,
            icon: Icons.add_shopping_cart_rounded,
            onPressed: () {
              cartProvider.addItem(
                productId: widget.productId,
                name: widget.productName,
                price: widget.price,
                quantity: _quantity,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Agregaste $_quantity unidad(es) al carrito.'),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, WaskRoutes.tracking),
            icon: const Icon(Icons.delivery_dining_rounded),
            label: const Text('Ir al tracking de pedido'),
          ),
          const SizedBox(height: 16),
          Text(
            'Carrito actual: ${cartProvider.totalItems} item(s)',
            style: const TextStyle(color: WaskColors.secondaryText),
          ),
        ],
      ),
    );
  }
}
