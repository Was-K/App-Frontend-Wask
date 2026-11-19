import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/widgets/wask_availability_pill.dart';
import '../../shared/widgets/wask_button.dart';
import '../../shared/widgets/wask_product_image.dart';
import '../providers/cart_provider.dart';
import '../utils/cart_add_helper.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.price,
    this.supplierId,
    this.imageUrl,
    this.brand,
    this.description,
    this.availableStock,
    this.storeName,
    this.distanceKm,
    this.isStoreOpen = true,
    this.inCoverage = true,
    this.unavailableReason,
  });

  final String productId;
  final String productName;
  final double price;
  final String? supplierId;
  final String? imageUrl;
  final String? brand;
  final String? description;
  final int? availableStock;
  final String? storeName;
  final double? distanceKm;
  final bool isStoreOpen;
  final bool inCoverage;
  final String? unavailableReason;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final hasNetworkImage =
        widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty;
    final stockCount = widget.availableStock ?? 10;
    final storeBlocked = !widget.isStoreOpen || !widget.inCoverage;
    final blockedMessage = widget.unavailableReason ??
        (!widget.isStoreOpen
            ? 'Esta tienda está cerrada por ahora.'
            : 'Tu dirección supera la zona de reparto de esta tienda.');

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de producto')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: hasNetworkImage
                      ? WaskProductImage(
                          imageUrl: widget.imageUrl,
                          fit: BoxFit.contain,
                          fallbackIconSize: 52,
                        )
                      : Image.asset(
                          'assets/images/waskaran.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const WaskProductImage(
                            fallbackIconSize: 52,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: WaskColors.iceBlue.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: WaskColors.iceBlue.withOpacity(0.45),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.ac_unit_rounded,
                          size: 13,
                          color: WaskColors.iceBlue,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Helada ❄️',
                          style: TextStyle(
                            color: WaskColors.iceBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  WaskAvailabilityPill(availableStock: stockCount),
                  if ((widget.storeName ?? '').isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: WaskColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: WaskColors.border),
                      ),
                      child: Text(
                        widget.storeName!,
                        style: const TextStyle(
                          color: WaskColors.secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if ((widget.brand ?? '').isNotEmpty) ...[
                Text(
                  widget.brand!,
                  style: const TextStyle(
                    color: WaskColors.secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                widget.productName,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'S/ ${widget.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: WaskColors.energyOrange,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                (widget.description ?? '').trim().isNotEmpty
                    ? widget.description!
                    : 'Despacho rapido en Lima Metropolitana. Listo y helado para tu previa.',
                style: const TextStyle(color: WaskColors.secondaryText),
              ),
              const SizedBox(height: 10),
              Text(
                widget.distanceKm != null
                    ? 'Cerca de ti · a ${widget.distanceKm!.toStringAsFixed(1)} km · Entrega estimada 20-35 min'
                    : 'Disponible cerca de ti · Entrega estimada 20-35 min',
                style: const TextStyle(
                  color: WaskColors.iceBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: WaskColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WaskColors.border),
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
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
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
              const SizedBox(height: 20),
              if (storeBlocked) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: WaskColors.energyOrange.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: WaskColors.energyOrange.withOpacity(0.45),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: WaskColors.energyOrange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          blockedMessage,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              WaskButton(
                label: stockCount <= 0
                    ? 'Producto agotado'
                    : !widget.isStoreOpen
                        ? 'Tienda cerrada'
                        : !widget.inCoverage
                            ? 'Fuera de zona de reparto'
                            : 'Agregar al carrito',
                expanded: true,
                icon: storeBlocked
                    ? Icons.block_rounded
                    : Icons.add_shopping_cart_rounded,
                onPressed: stockCount <= 0 || storeBlocked
                    ? null
                    : () => addProductWithStoreGuard(
                          context,
                          productId: widget.productId,
                          name: widget.productName,
                          price: widget.price,
                          quantity: _quantity,
                          supplierId: widget.supplierId,
                          imageUrl: widget.imageUrl,
                          storeName: widget.storeName,
                        ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, WaskRoutes.tracking),
                icon: const Icon(Icons.delivery_dining_rounded),
                label: const Text('Ir al tracking de pedido'),
              ),
              const SizedBox(height: 14),
              Text(
                'Carrito actual: ${cartProvider.totalItems} item(s)',
                style: const TextStyle(
                  color: WaskColors.secondaryText,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
