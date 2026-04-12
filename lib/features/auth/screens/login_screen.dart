import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/providers/app_state_provider.dart';
import '../../shared/widgets/wask_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAgeVerified = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _continueToHome() async {
    if (!_isAgeVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Debes verificar que eres mayor de 18 anos para continuar.'),
        ),
      );
      return;
    }

    await context.read<AppStateProvider>().signIn(
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 88,
                    width: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: WaskColors.electricBlue.withOpacity(0.55)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.wine_bar_rounded,
                          size: 44,
                          color: WaskColors.electricBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'WAS-K',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: WaskColors.primaryText,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Delivery de licores en Lima en menos de 30 min o es gratis.',
                    style: TextStyle(
                      color: WaskColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Correo electronico',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
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
                    label: 'INICIAR SESION',
                    expanded: true,
                    onPressed: () {
                      _continueToHome();
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, WaskRoutes.register),
                    child: const Text('No tienes cuenta? Registrate'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
