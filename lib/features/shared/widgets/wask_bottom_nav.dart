import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shop/providers/cart_provider.dart';

class WaskBottomNav extends StatelessWidget {
  const WaskBottomNav({
    super.key,
    required this.currentRoute,
  });

  final String currentRoute;

  int _indexFromRoute() {
    switch (currentRoute) {
      case WaskRoutes.orders:
        return 1;
      case WaskRoutes.search:
        return 2;
      case WaskRoutes.cart:
        return 3;
      case WaskRoutes.home:
      default:
        return 0;
    }
  }

  String _routeFromIndex(int index) {
    switch (index) {
      case 1:
        return WaskRoutes.orders;
      case 2:
        return WaskRoutes.search;
      case 3:
        return WaskRoutes.cart;
      case 0:
      default:
        return WaskRoutes.home;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.select<CartProvider, int>((c) => c.totalItems);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1017),
        border: Border(
          top: BorderSide(color: WaskColors.border, width: 1),
        ),
      ),
      child: NavigationBar(
        height: 56,
        elevation: 0,
        backgroundColor: const Color(0xFF0D1017),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _indexFromRoute(),
        onDestinationSelected: (index) {
          final targetRoute = _routeFromIndex(index);
          if (targetRoute == currentRoute) {
            return;
          }
          Navigator.pushReplacementNamed(context, targetRoute);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 20),
            selectedIcon: Icon(Icons.home_rounded, size: 20),
            label: 'Inicio',
            tooltip: '',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, size: 20),
            selectedIcon: Icon(Icons.receipt_long_rounded, size: 20),
            label: 'Pedidos',
            tooltip: '',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined, size: 20),
            selectedIcon: Icon(Icons.search_rounded, size: 20),
            label: 'Buscar',
            tooltip: '',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              backgroundColor: WaskColors.energyOrange,
              label: Text(
                '$cartCount',
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
              child: const Icon(Icons.shopping_cart_outlined, size: 20),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              backgroundColor: WaskColors.energyOrange,
              label: Text(
                '$cartCount',
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
              child: const Icon(Icons.shopping_cart_rounded, size: 20),
            ),
            label: 'Carrito',
            tooltip: '',
          ),
        ],
      ),
    );
  }
}
