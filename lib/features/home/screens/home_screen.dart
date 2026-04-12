import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/providers/app_state_provider.dart';
import '../../shared/widgets/wask_bottom_nav.dart';
import '../../shop/providers/cart_provider.dart';
import '../data/mock_marketplace_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().totalItems;
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      bottomNavigationBar: const WaskBottomNav(currentRoute: WaskRoutes.home),
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.pushNamed(context, WaskRoutes.account),
          child: Text('Hola, ${appState.displayName}'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, WaskRoutes.cart),
                  icon: const Icon(Icons.shopping_cart_outlined),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 4,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: WaskColors.energyOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () =>
                  Navigator.pushNamed(context, WaskRoutes.addressSelect),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: WaskColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: WaskColors.electricBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appState.selectedAddress?.formatted ??
                            'Selecciona una direccion de entrega',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              readOnly: true,
              onTap: () => Navigator.pushNamed(context, WaskRoutes.search),
              decoration: const InputDecoration(
                hintText: 'Buscar productos o marcas',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF003F82), WaskColors.electricBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WAS-K',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Delivery en menos de 30 min o es gratis.',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Categorias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 102,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: marketplaceCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = marketplaceCategories[index];
                  return Container(
                    width: 108,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: WaskColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_iconForName(category.iconName),
                            color: WaskColors.electricBlue),
                        const SizedBox(height: 8),
                        Text(
                          category.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mejores promociones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: marketplacePromos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final promo = marketplacePromos[index];
                  return Container(
                    width: 220,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: WaskColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x22007BFF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: WaskColors.energyOrange),
                        const SizedBox(height: 8),
                        Text(
                          promo.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          promo.subtitle,
                          style: const TextStyle(
                              color: WaskColors.secondaryText, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Licorerias Aliadas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...marketplaceStores.map(
              (store) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: WaskColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.pushNamed(
                    context,
                    WaskRoutes.productDetail,
                    arguments: {
                      'id': marketplaceProducts.first.id,
                      'name': marketplaceProducts.first.name,
                      'price': marketplaceProducts.first.price,
                    },
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: Image.asset(
                              'assets/images/logo.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.black26,
                                child: const Icon(Icons.storefront_rounded),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star_rate_rounded,
                                      size: 18, color: WaskColors.energyOrange),
                                  const SizedBox(width: 8),
                                  Text(store.rating),
                                  const SizedBox(width: 8),
                                  Text(
                                    '| ${store.eta}',
                                    style: const TextStyle(
                                        color: WaskColors.secondaryText),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                store.district,
                                style: const TextStyle(
                                    color: WaskColors.secondaryText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Text(
              'Recomendados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...marketplaceProducts.take(4).map(
                  (product) => Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor:
                            WaskColors.electricBlue.withOpacity(0.14),
                        child: const Icon(Icons.local_bar_rounded,
                            color: WaskColors.electricBlue),
                      ),
                      title: Text(product.name),
                      subtitle: Text('S/ ${product.price.toStringAsFixed(2)}'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pushNamed(
                        context,
                        WaskRoutes.productDetail,
                        arguments: {
                          'id': product.id,
                          'name': product.name,
                          'price': product.price,
                        },
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            const Text(
              'Marcas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: marketplaceBrands
                  .map(
                    (brand) => Chip(
                      label: Text(brand),
                      backgroundColor: WaskColors.surface,
                      side: const BorderSide(color: Color(0x22007BFF)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  IconData _iconForName(String iconName) {
    switch (iconName) {
      case 'sports_bar':
        return Icons.sports_bar_rounded;
      case 'local_bar':
        return Icons.local_bar_rounded;
      case 'wine_bar':
        return Icons.wine_bar_rounded;
      case 'fastfood':
      default:
        return Icons.fastfood_rounded;
    }
  }
}
