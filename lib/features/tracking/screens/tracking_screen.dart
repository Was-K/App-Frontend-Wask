import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/wask_theme.dart';
import '../../logistics/data/logistics_service.dart';
import '../../shared/providers/app_state_provider.dart';
import '../../shared/widgets/wask_button.dart';
import '../providers/tracking_provider.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  LogisticsService? _logisticsService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TrackingProvider>().resetAndStart();
    });

    if (!AppConfig.enableMocks) {
      final apiClient = context.read<AppStateProvider>().apiClient;
      _logisticsService = LogisticsService(apiClient: apiClient);
      _fetchShipments();
    }
  }

  Future<void> _fetchShipments() async {
    try {
      final shipments = await _logisticsService?.getShipments();
      debugPrint('Shipments loaded: ${shipments?.length ?? 0}');
    } catch (error) {
      debugPrint('Error loading shipments: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackingProvider = context.watch<TrackingProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento en Tiempo Real')),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0B0D10),
                  Color(0xFF111723),
                  Color(0xFF0C111A)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 90,
                  left: -30,
                  right: -30,
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(120),
                      border:
                          Border.all(color: const Color(0x22007BFF), width: 2),
                    ),
                  ),
                ),
                Positioned(
                  top: 250,
                  left: 30,
                  right: 30,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: const Color(0x22FFFFFF), width: 1.2),
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 58, color: WaskColors.energyOrange),
                      SizedBox(height: 8),
                      Text(
                        'Repartidor en camino - Lince',
                        style: TextStyle(
                            color: WaskColors.primaryText,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.84),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WAS-K | Lima Centro',
                      style: TextStyle(
                        color: WaskColors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trackingProvider.isFree
                          ? 'WAS-K es GRATIS! (aplican terminos)'
                          : 'Delivery en menos de 30 min o es gratis',
                      style: TextStyle(
                        color: trackingProvider.isFree
                            ? WaskColors.energyOrange
                            : Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        trackingProvider.formattedTime,
                        style: const TextStyle(
                          color: WaskColors.energyOrange,
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cobertura activa: Jesus Maria, Lince, Pueblo Libre',
                      style: TextStyle(
                          color: WaskColors.secondaryText, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    WaskButton(
                      expanded: true,
                      icon: Icons.call_rounded,
                      label: 'Llamar al repartidor',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Llamando al repartidor...')),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    WaskButton(
                      expanded: true,
                      icon: Icons.refresh_rounded,
                      label: 'Reiniciar contador',
                      onPressed: trackingProvider.resetAndStart,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
