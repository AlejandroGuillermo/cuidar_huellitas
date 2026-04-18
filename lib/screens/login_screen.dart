import 'package:cuidar_huellitas/core/app_colors.dart';
import 'package:cuidar_huellitas/core/app_router.dart';
import 'package:cuidar_huellitas/widgets/auth/auth_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firebaseAuth = FirebaseAuth.instance;

  bool _verPassword = false;
  bool _cargando = false;
  String? _errorMessage;
  String? _errorFirebaseCorreo;
  String? _errorFirebasePassword;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validarEmail(String? value) {
    if (_errorFirebaseCorreo != null) return _errorFirebaseCorreo;
    if (value == null || value.trim().isEmpty) {
      return 'El correo es requerido';
    }
    if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value.trim())) {
      return 'Ingresa un correo valido';
    }
    return null;
  }

  String? _validarPassword(String? value) {
    if (_errorFirebasePassword != null) return _errorFirebasePassword;
    if (value == null || value.isEmpty) {
      return 'La contrasena es requerida';
    }
    if (value.length < 6) {
      return 'Minimo 6 caracteres';
    }
    return null;
  }

  Future<void> _iniciarSesion() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorFirebaseCorreo = null;
      _errorFirebasePassword = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _errorMessage = null;
    });

    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: _correoController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sesion iniciada')));
      context.go(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      String mensaje = 'No pudimos iniciar sesion';

      if (e.code == 'invalid-credential') {
        mensaje = 'Correo o contrasena incorrectos';
        _errorFirebaseCorreo = mensaje;
        _errorFirebasePassword = mensaje;
        _passwordController.clear();
      } else if (e.code == 'user-not-found') {
        mensaje = 'Este correo no esta registrado';
        _errorFirebaseCorreo = mensaje;
      } else if (e.code == 'wrong-password') {
        mensaje = 'La contrasena es incorrecta';
        _errorFirebasePassword = mensaje;
        _passwordController.clear();
      } else if (e.code == 'invalid-email') {
        mensaje = 'Formato de correo invalido';
        _errorFirebaseCorreo = mensaje;
      } else if (e.code == 'user-disabled') {
        mensaje = 'Tu cuenta fue deshabilitada';
        _errorFirebaseCorreo = mensaje;
      } else if (e.code == 'too-many-requests') {
        mensaje = 'Demasiados intentos. Espera un momento y vuelve a intentar';
      }

      setState(() => _errorMessage = mensaje);
      _formKey.currentState!.validate();
    } catch (_) {
      setState(() => _errorMessage = 'Ocurrio un error inesperado');
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _recuperarContrasena() async {
    final correo = _correoController.text.trim();
    final esValido =
        correo.isNotEmpty &&
        RegExp(
          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        ).hasMatch(correo);

    if (!esValido) {
      setState(() {
        _errorFirebaseCorreo = 'Escribe un correo valido para recuperar acceso';
      });
      _formKey.currentState!.validate();
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: correo);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Te enviamos un correo para restablecer tu contraseña'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      final mensaje = switch (e.code) {
        'user-not-found' => 'No encontramos una cuenta con ese correo',
        'invalid-email' => 'El correo no es valido',
        _ => 'No pudimos enviar el correo de recuperacion',
      };

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthScaffold(
      gradientColors: const [
        Color(0xFFE4FFD9),
        Color(0xFFBFF3B1),
        Color(0xFF93E37B),
      ],
      background: const AuthBackground(
        circles: [
          AuthCircleData(
            top: -60,
            left: -40,
            size: 170,
            color: Color(0x55FFFFFF),
          ),
          AuthCircleData(
            top: 120,
            right: -30,
            size: 120,
            color: Color(0x30FFFFFF),
          ),
          AuthCircleData(
            bottom: 140,
            left: -20,
            size: 110,
            color: Color(0x28FFFFFF),
          ),
          AuthCircleData(
            bottom: -40,
            right: 10,
            size: 180,
            color: Color(0x25FFFFFF),
          ),
        ],
      ),
      child: Column(
        children: [
          const AuthHero(
            chipText: 'Tu mascota te estaba esperando',
            title: 'Bienvenido de nuevo',
            subtitle:
                'Inicia sesion para seguir cuidando, jugando y acompanando a tu mascota.',
          ),
          const SizedBox(height: 24),
          _LoginCard(
            errorMessage: _errorMessage,
            formKey: _formKey,
            correoController: _correoController,
            passwordController: _passwordController,
            verPassword: _verPassword,
            cargando: _cargando,
            onTogglePassword: () {
              setState(() => _verPassword = !_verPassword);
            },
            onForgotPassword: _cargando ? null : _recuperarContrasena,
            onLogin: _cargando ? null : _iniciarSesion,
            onRegister: () => context.push(AppRoutes.register),
            onEmailChanged: () {
              if (_errorFirebaseCorreo != null) {
                setState(() => _errorFirebaseCorreo = null);
                _formKey.currentState!.validate();
              }
            },
            onPasswordChanged: () {
              if (_errorFirebasePassword != null) {
                setState(() => _errorFirebasePassword = null);
                _formKey.currentState!.validate();
              }
            },
            validarEmail: _validarEmail,
            validarPassword: _validarPassword,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final String? errorMessage;
  final GlobalKey<FormState> formKey;
  final TextEditingController correoController;
  final TextEditingController passwordController;
  final bool verPassword;
  final bool cargando;
  final VoidCallback onTogglePassword;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onLogin;
  final VoidCallback onRegister;
  final VoidCallback onEmailChanged;
  final VoidCallback onPasswordChanged;
  final String? Function(String?) validarEmail;
  final String? Function(String?) validarPassword;
  final ThemeData theme;

  const _LoginCard({
    required this.errorMessage,
    required this.formKey,
    required this.correoController,
    required this.passwordController,
    required this.verPassword,
    required this.cargando,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onLogin,
    required this.onRegister,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.validarEmail,
    required this.validarPassword,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: Form(
        key: formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthInfoBanner(
                icon: Icons.favorite_border_rounded,
                message:
                    'Entra para continuar con el cuidado diario de tu mascota.',
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: errorMessage == null
                    ? const SizedBox(height: 18)
                    : Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: AuthErrorCard(message: errorMessage!),
                      ),
              ),
              const SizedBox(height: 18),
              const AuthFieldLabel(
                title: 'Correo electronico',
                icon: Icons.mail_outline_rounded,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: correoController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: validarEmail,
                autofillHints: const [AutofillHints.email],
                onChanged: (_) => onEmailChanged(),
                decoration: buildAuthInputDecoration(
                  hint: 'nombre@correo.com',
                  prefixIcon: Icons.alternate_email_rounded,
                  accentColor: AppColors.azulPrincipal,
                  fillColor: AppColors.fondoPrincipal,
                ),
              ),
              const SizedBox(height: 18),
              const AuthFieldLabel(
                title: 'Contraseña',
                icon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,
                obscureText: !verPassword,
                textInputAction: TextInputAction.done,
                validator: validarPassword,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => onLogin?.call(),
                onChanged: (_) => onPasswordChanged(),
                decoration:
                    buildAuthInputDecoration(
                      hint: 'Tu contraseña',
                      prefixIcon: Icons.key_rounded,
                      accentColor: AppColors.azulPrincipal,
                      fillColor: AppColors.fondoPrincipal,
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: onTogglePassword,
                        icon: Icon(
                          verPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onForgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.azulPrincipal,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: const Text(
                    'Olvidaste tu contraseña?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: onLogin,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.verdePrincipal,
                    foregroundColor: AppColors.textoPrincipal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: cargando
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.textoPrincipal,
                            ),
                          )
                        : const Text(
                            'Entrar',
                            key: ValueKey('text'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'o',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textoSecundario,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: onRegister,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textoPrincipal,
                    side: BorderSide(
                      color: AppColors.azulPrincipal.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Crear una cuenta',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Tu progreso se sincroniza con tu cuenta para que nunca pierdas el avance de tu mascota.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textoSecundario,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}