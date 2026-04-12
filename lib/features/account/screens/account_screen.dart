import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/providers/app_state_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: WaskColors.surface,
              borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 12),
          _AccountOption(
            icon: Icons.local_offer_outlined,
            title: 'Mis cupones',
            subtitle: 'Cupon activo: WASK10',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cupon disponible: WASK10')),
            ),
          ),
          _AccountOption(
            icon: Icons.person_outline_rounded,
            title: 'Informacion personal',
            subtitle: 'Nombre y correo',
            onTap: () {},
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
            subtitle: 'Casa, trabajo y otros',
            onTap: () => Navigator.pushNamed(context, WaskRoutes.addressSelect),
          ),
          _AccountOption(
            icon: Icons.credit_card_outlined,
            title: 'Metodos de pago',
            subtitle: 'Debito, credito, Yape, Plin y efectivo',
            onTap: () => Navigator.pushNamed(context, WaskRoutes.checkout),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: WaskColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
