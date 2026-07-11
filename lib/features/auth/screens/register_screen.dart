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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isAgeVerified = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_isAgeVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifica edad (+18) para crear cuenta.')),
      );
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos.')),
      );
      return;
    }

    if (password.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La contrasena debe tener al menos 10 caracteres.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contrasenas no coinciden.')),
      );
      return;
    }

    final user = await context.read<AppStateProvider>().register(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
        );

    if (!mounted) {
      return;
    }

    if (user == null) {
      final message = context.read<AppStateProvider>().errorMessage ??
          'No se pudo completar el registro.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    if ((user.status ?? '').toUpperCase() == 'PENDING' ||
        user.isVerified == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Cuenta creada. Revisa tu correo para verificar la cuenta.'),
        ),
      );
    }

    Navigator.pushReplacementNamed(context, WaskRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

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
                controller: _firstNameController,
                decoration: const InputDecoration(
                  hintText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  hintText: 'Apellido',
                  prefixIcon: Icon(Icons.badge_outlined),
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
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Confirmar contrasena',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
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
                label: appState.isLoading ? 'CREANDO...' : 'CREAR CUENTA',
                expanded: true,
                onPressed: appState.isLoading ? null : _register,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
