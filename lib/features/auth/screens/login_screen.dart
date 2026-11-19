import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../data/auth_service.dart';
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

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa correo y contrasena.')),
      );
      return;
    }

    final success = await context.read<AppStateProvider>().signIn(
          email: email,
          password: password,
        );

    if (!mounted) {
      return;
    }

    if (!success) {
      final message = context.read<AppStateProvider>().errorMessage ??
          'No se pudo iniciar sesion.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    final appState = context.read<AppStateProvider>();
    final nextRoute = appState.selectedAddress != null
        ? WaskRoutes.home
        : WaskRoutes.addressSelect;
    Navigator.pushReplacementNamed(context, nextRoute);
  }

  Future<void> _openForgotPasswordSheet() async {
    final appState = context.read<AppStateProvider>();
    final authService = AuthService(
      apiClient: appState.apiClient,
      tokenStorage: appState.tokenStorage,
    );

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WaskColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ForgotPasswordSheet(
        initialEmail: _emailController.text.trim(),
        authService: authService,
      ),
    );
    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contrasena actualizada. Ya puedes ingresar.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

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
                    label:
                        appState.isLoading ? 'INICIANDO...' : 'INICIAR SESION',
                    expanded: true,
                    onPressed: appState.isLoading ? null : _continueToHome,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton(
                        onPressed: _openForgotPasswordSheet,
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, WaskRoutes.register),
                        child: const Text('Crear cuenta'),
                      ),
                    ],
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

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet({
    required this.initialEmail,
    required this.authService,
  });

  final String initialEmail;
  final AuthService authService;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _emailCtrl;
  final TextEditingController _tokenCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  int _step = 0;
  bool _submitting = false;
  String? _feedback;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recuperar contrasena',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _step == 0
                  ? 'Ingresa tu correo para solicitar un codigo de recuperacion.'
                  : 'Ingresa el codigo asignado y tu nueva contrasena (min. 10 caracteres).',
              style: const TextStyle(
                color: WaskColors.secondaryText,
                fontSize: 13,
              ),
            ),
            if (_feedback != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_isError ? Colors.redAccent : WaskColors.emerald)
                      .withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _feedback!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isError ? Colors.redAccent : WaskColors.emerald,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (_step == 0) ...[
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Tu correo electronico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        if (_emailCtrl.text.trim().isEmpty) return;
                        setState(() {
                          _submitting = true;
                          _feedback = null;
                        });
                        try {
                          await widget.authService
                              .forgotPassword(_emailCtrl.text);
                          if (!mounted) return;
                          setState(() {
                            _isError = false;
                            _feedback =
                                'Solicitud enviada. Si tu correo esta registrado, solicita el codigo al equipo WASK o ingrésalo abajo.';
                            _step = 1;
                          });
                        } catch (err) {
                          if (!mounted) return;
                          setState(() {
                            _isError = true;
                            _feedback = err.toString();
                          });
                        } finally {
                          if (mounted) {
                            setState(() => _submitting = false);
                          }
                        }
                      },
                child: Text(_submitting ? 'Enviando...' : 'Solicitar codigo'),
              ),
              TextButton(
                onPressed: () => setState(() => _step = 1),
                child: const Text('Ya tengo mi codigo'),
              ),
            ] else ...[
              TextField(
                controller: _tokenCtrl,
                decoration: const InputDecoration(
                  hintText: 'Codigo de recuperacion',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Nueva contrasena (min. 10 caracteres)',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        if (_passCtrl.text.length < 10) {
                          setState(() {
                            _isError = true;
                            _feedback =
                                'La nueva contrasena debe tener al menos 10 caracteres.';
                          });
                          return;
                        }
                        setState(() {
                          _submitting = true;
                          _feedback = null;
                        });
                        try {
                          await widget.authService.resetPassword(
                            token: _tokenCtrl.text,
                            newPassword: _passCtrl.text,
                          );
                          if (!mounted) return;
                          Navigator.pop(context, true);
                        } catch (err) {
                          if (!mounted) return;
                          setState(() {
                            _isError = true;
                            _feedback = err.toString();
                          });
                        } finally {
                          if (mounted) {
                            setState(() => _submitting = false);
                          }
                        }
                      },
                child: Text(
                  _submitting ? 'Guardando...' : 'Guardar nueva contrasena',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
