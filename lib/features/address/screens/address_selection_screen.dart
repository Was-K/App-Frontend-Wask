import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/providers/app_state_provider.dart';

class AddressSelectionScreen extends StatefulWidget {
  const AddressSelectionScreen({super.key});

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  final _streetController = TextEditingController();
  final _referenceController = TextEditingController();
  String _label = 'Casa';
  String _district = 'Lince';

  static const List<String> _districts = <String>[
    'Jesus Maria',
    'Lince',
    'Pueblo Libre',
  ];

  @override
  void dispose() {
    _streetController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_streetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una direccion valida.')),
      );
      return;
    }

    await context.read<AppStateProvider>().addAddress(
          label: _label,
          street: _streetController.text,
          district: _district,
          reference: _referenceController.text,
        );

    if (!mounted) {
      return;
    }

    _streetController.clear();
    _referenceController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Direccion guardada.')),
    );
  }

  Future<void> _continue() async {
    final appState = context.read<AppStateProvider>();
    if (appState.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona o agrega una direccion.')),
      );
      return;
    }
    Navigator.pushReplacementNamed(context, WaskRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona tu direccion')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Direccion de entrega',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Guarda tus direcciones para volver a usarlas al iniciar sesion.',
            style: TextStyle(color: WaskColors.secondaryText),
          ),
          const SizedBox(height: 16),
          if (appState.addresses.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: WaskColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Todavia no tienes direcciones guardadas.'),
            )
          else
            ...appState.addresses.map(
              (address) => RadioListTile<String>(
                value: address.id,
                groupValue: appState.selectedAddress?.id,
                activeColor: WaskColors.electricBlue,
                tileColor: WaskColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text('${address.label} · ${address.district}'),
                subtitle: Text(address.formatted),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  appState.selectAddress(value);
                },
              ),
            ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Agregar direccion',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _label,
            items: const [
              DropdownMenuItem(value: 'Casa', child: Text('Casa')),
              DropdownMenuItem(value: 'Trabajo', child: Text('Trabajo')),
              DropdownMenuItem(value: 'Otro', child: Text('Otro')),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _label = value;
              });
            },
            decoration: const InputDecoration(labelText: 'Etiqueta'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _streetController,
            decoration: const InputDecoration(
              labelText: 'Direccion',
              hintText: 'Av. Brasil 123, Dpto 402',
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _district,
            items: _districts
                .map((district) => DropdownMenuItem(
                      value: district,
                      child: Text(district),
                    ))
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _district = value;
              });
            },
            decoration: const InputDecoration(labelText: 'Distrito'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _referenceController,
            decoration: const InputDecoration(
              labelText: 'Referencia (opcional)',
              hintText: 'Frente al parque',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveAddress,
            child: const Text('Guardar direccion'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _continue,
            child: const Text('Continuar al inicio'),
          ),
        ],
      ),
    );
  }
}
