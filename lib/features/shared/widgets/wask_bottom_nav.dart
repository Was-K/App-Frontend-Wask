import 'package:flutter/material.dart';

import '../../../core/navigation/wask_routes.dart';

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
    return NavigationBar(
      selectedIndex: _indexFromRoute(),
      onDestinationSelected: (index) {
        final targetRoute = _routeFromIndex(index);
        if (targetRoute == currentRoute) {
          return;
        }
        Navigator.pushReplacementNamed(context, targetRoute);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Pedidos',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search_rounded),
          label: 'Buscar',
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart_rounded),
          label: 'Carrito',
        ),
      ],
    );
  }
}
