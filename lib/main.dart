import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/navigation/wask_routes.dart';
import 'core/theme/wask_theme.dart';
import 'features/account/screens/account_screen.dart';
import 'features/address/screens/address_selection_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/cart/screens/cart_screen.dart';
import 'features/checkout/screens/checkout_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/orders/screens/order_detail_screen.dart';
import 'features/orders/screens/orders_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/shared/models/app_models.dart';
import 'features/shared/providers/app_state_provider.dart';
import 'features/shop/providers/cart_provider.dart';
import 'features/shop/screens/product_detail_screen.dart';
import 'features/tracking/providers/tracking_provider.dart';
import 'features/tracking/screens/tracking_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appStateProvider = await AppStateProvider.create();
  runApp(WaskApp(appStateProvider: appStateProvider));
}

class WaskApp extends StatelessWidget {
  const WaskApp({
    super.key,
    required this.appStateProvider,
  });

  final AppStateProvider appStateProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStateProvider>.value(
          value: appStateProvider,
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider<TrackingProvider>(
          create: (_) => TrackingProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'WAS-K',
        debugShowCheckedModeBanner: false,
        theme: WaskTheme.darkTheme,
        initialRoute: WaskRoutes.login,
        routes: {
          WaskRoutes.login: (_) => const LoginScreen(),
          WaskRoutes.register: (_) => const RegisterScreen(),
          WaskRoutes.addressSelect: (_) => const AddressSelectionScreen(),
          WaskRoutes.home: (_) => const HomeScreen(),
          WaskRoutes.orders: (_) => const OrdersScreen(),
          WaskRoutes.search: (_) => const SearchScreen(),
          WaskRoutes.cart: (_) => const CartScreen(),
          WaskRoutes.account: (_) => const AccountScreen(),
          WaskRoutes.tracking: (_) => const TrackingScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == WaskRoutes.productDetail) {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute<void>(
              builder: (_) => ProductDetailScreen(
                productId: (args?['id'] ?? 'producto_default') as String,
                productName: (args?['name'] ?? 'Producto WAS-K') as String,
                price: ((args?['price'] ?? 0) as num).toDouble(),
                supplierId: args?['supplierId'] as String?,
              ),
            );
          }

          if (settings.name == WaskRoutes.checkout) {
            final instruction = settings.arguments as String? ?? '';
            return MaterialPageRoute<void>(
              builder: (_) => CheckoutScreen(deliveryInstruction: instruction),
            );
          }

          if (settings.name == WaskRoutes.orderDetail) {
            final order = settings.arguments as OrderRecord;
            return MaterialPageRoute<void>(
              builder: (_) => OrderDetailScreen(order: order),
            );
          }

          return null;
        },
      ),
    );
  }
}
