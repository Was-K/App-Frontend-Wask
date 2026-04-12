import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/providers/app_state_provider.dart';
import '../../shared/widgets/wask_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAgeVerified = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_isAgeVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifica edad (+18) para crear cuenta.')),
      );
      return;
    }

    await context.read<AppStateProvider>().register(
          name: _nameController.text,
          email: _emailController.text,
        );

    if (!mounted) {
      return;
    }

    Navigator.pushReplacementNamed(context, WaskRoutes.addressSelect);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Bienvenido a WAS-K',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Registrate para pedir en Jesus Maria, Lince y Pueblo Libre.',
                style: TextStyle(color: WaskColors.secondaryText),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Correo electronico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Contrasena',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isAgeVerified = !_isAgeVerified;
                  });
                },
                icon: Icon(
                  _isAgeVerified
                      ? Icons.verified_rounded
                      : Icons.badge_outlined,
                ),
                label: Text(_isAgeVerified
                    ? 'Edad verificada (+18)'
                    : 'Verificar edad (+18)'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _isAgeVerified
                        ? WaskColors.energyOrange
                        : Colors.white.withOpacity(0.25),
                  ),
                  foregroundColor: _isAgeVerified
                      ? WaskColors.energyOrange
                      : WaskColors.primaryText,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              WaskButton(
                label: 'CREAR CUENTA',
                expanded: true,
                onPressed: () {
                  _register();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
