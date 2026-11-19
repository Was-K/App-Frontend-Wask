import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/models/app_models.dart';
import '../../shared/providers/app_state_provider.dart';
import '../providers/cart_provider.dart';

/// Valida si la tienda esta abierta y dentro de cobertura del cliente.
/// Devuelve `null` si puede recibir pedidos, o un mensaje amigable en español.
String? getStoreUnavailableReason(
  BuildContext context,
  Supplier? supplier,
) {
  if (supplier == null) {
    return null;
  }
  if (!supplier.isOpenNow) {
    final openHint =
        supplier.openTime != null && supplier.openTime != '00:00'
            ? ' (abre a las ${supplier.openTime})'
            : '';
    return '${supplier.name} está cerrada en este momento$openHint.';
  }
  final distKm =
      context.read<AppStateProvider>().distanceToSupplierKm(supplier);
  if (!supplier.canDeliverDistance(distKm)) {
    final maxKm = supplier.deliveryRadiusKm?.toStringAsFixed(0) ?? '8';
    return 'Tu dirección supera la zona de reparto de ${supplier.name} ($maxKm km máx.).';
  }
  return null;
}

Future<bool> addProductWithStoreGuard(
  BuildContext context, {
  required String productId,
  required String name,
  required double price,
  int quantity = 1,
  String? supplierId,
  String? imageUrl,
  String? storeName,
  Supplier? supplier,
  VoidCallback? onViewCart,
}) async {
  final unavailableReason = getStoreUnavailableReason(context, supplier);
  if (unavailableReason != null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(unavailableReason),
        ),
      );
    return false;
  }

  final cart = context.read<CartProvider>();
  final existingItems = cart.itemList;

  if (existingItems.isNotEmpty && supplierId != null && supplierId.isNotEmpty) {
    final existingSupplierIds = existingItems
        .map((item) => item.supplierId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    if (existingSupplierIds.isNotEmpty &&
        !existingSupplierIds.contains(supplierId)) {
      final previousStore = existingItems.first.storeName ?? 'otra licoreria';
      final nextStore = storeName ?? 'esta licoreria';

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: WaskColors.surface,
          title: const Text(
            '¿Cambiar de tienda?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Tu carrito tiene productos de $previousStore. ¿Deseas reemplazarlo para pedir en $nextStore?',
            style: const TextStyle(color: WaskColors.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Cambiar tienda'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return false;
      }
      cart.clear();
    }
  }

  cart.addItem(
    productId: productId,
    name: name,
    price: price,
    quantity: quantity,
    supplierId: supplierId,
    imageUrl: imageUrl,
    storeName: storeName,
  );

  if (context.mounted) {
    final navigator = Navigator.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(
            quantity > 1
                ? 'Agregaste $quantity unidad(es) de $name al carrito.'
                : '$name agregado al carrito.',
          ),
          action: SnackBarAction(
            label: 'Ver carrito',
            textColor: WaskColors.iceBlue,
            onPressed: onViewCart ??
                () {
                  navigator.pushNamed(WaskRoutes.cart);
                },
          ),
        ),
      );
  }
  return true;
}
