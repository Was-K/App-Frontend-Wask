import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/providers/app_state_provider.dart';
import '../../shared/widgets/wask_loyalty_card.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppStateProvider>().loadLoyaltyStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: WaskColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: WaskColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appState.displayName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appState.currentUser?.email ?? '',
                      style: const TextStyle(color: WaskColors.secondaryText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              WaskLoyaltyCard(
                onSimulated: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        backgroundColor: WaskColors.emerald,
                        content: Text(
                          '¡Felicidades! 10 pedidos entregados = 1 Delivery Gratis desbloqueado',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                },
              ),
              const SizedBox(height: 14),
              _AccountOption(
                icon: Icons.local_offer_outlined,
                title: 'Mis cupones',
                subtitle: 'Cupon activo: WASK10',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cupon disponible: WASK10')),
                ),
              ),
              _AccountOption(
                icon: Icons.receipt_long_outlined,
                title: 'Pedidos',
                subtitle: 'Historial y pedido actual',
                onTap: () =>
                    Navigator.pushReplacementNamed(context, WaskRoutes.orders),
              ),
              _AccountOption(
                icon: Icons.location_on_outlined,
                title: 'Direcciones de entrega',
                subtitle: appState.selectedAddress?.formattedFullAddress ??
                    'Casa, trabajo, previa y otros',
                onTap: () =>
                    Navigator.pushNamed(context, WaskRoutes.addressSelect),
              ),
              _AccountOption(
                icon: Icons.credit_card_outlined,
                title: 'Metodos de pago',
                subtitle: 'Yape, Plin, Efectivo contra entrega y POS',
                onTap: () => Navigator.pushNamed(context, WaskRoutes.checkout),
              ),
              _AccountOption(
                icon: Icons.delivery_dining_rounded,
                title: 'Tracking en vivo',
                subtitle: 'Ver ruta del motorizado en Lima',
                onTap: () => Navigator.pushNamed(context, WaskRoutes.tracking),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  await context.read<AppStateProvider>().logout();
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    WaskRoutes.login,
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Salir de la cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountOption extends StatelessWidget {
  const _AccountOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: WaskColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: WaskColors.border),
        ),
        child: ListTile(
          leading: Icon(icon, color: WaskColors.electricBlue),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: WaskColors.secondaryText),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}
