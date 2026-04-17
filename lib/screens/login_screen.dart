import 'package:cuidar_huellitas/core/app_colors.dart';
import 'package:cuidar_huellitas/core/app_router.dart';
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
          content: Text('Te enviamos un correo para restablecer tu contrasena'),
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
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE4FFD9), Color(0xFFBFF3B1), Color(0xFF93E37B)],
            ),
          ),
          child: Stack(
            children: [
              const _LoginBackground(),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: size.width > 480 ? 430 : double.infinity,
                      ),
                      child: Column(
                        children: [
                          const _LoginHero(),
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
                            onForgotPassword: _cargando
                                ? null
                                : _recuperarContrasena,
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: const [
          Positioned(
            top: -60,
            left: -40,
            child: _GlowCircle(size: 170, color: Color(0x55FFFFFF)),
          ),
          Positioned(
            top: 120,
            right: -30,
            child: _GlowCircle(size: 120, color: Color(0x30FFFFFF)),
          ),
          Positioned(
            bottom: 140,
            left: -20,
            child: _GlowCircle(size: 110, color: Color(0x28FFFFFF)),
          ),
          Positioned(
            bottom: -40,
            right: 10,
            child: _GlowCircle(size: 180, color: Color(0x25FFFFFF)),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.24),
              ),
            ),
            Container(
              width: 138,
              height: 138,
              decoration: const BoxDecoration(
                color: Color(0xFFD9D9D9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.pets_rounded, size: 58, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'Tu mascota te estaba esperando',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textoPrincipal,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Bienvenido de nuevo',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: AppColors.textoPrincipal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Inicia sesion para seguir cuidando, jugando y acompanando a tu mascota.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.45,
            color: AppColors.textoPrincipal.withValues(alpha: 0.75),
          ),
        ),
      ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F2D14),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _InfoBanner(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: errorMessage == null
                    ? const SizedBox(height: 18)
                    : Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: _ErrorCard(message: errorMessage!),
                      ),
              ),
              const SizedBox(height: 18),
              _SectionLabel(
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
                decoration: _inputDecoration(
                  hint: 'nombre@correo.com',
                  prefixIcon: Icons.alternate_email_rounded,
                ),
              ),
              const SizedBox(height: 18),
              _SectionLabel(
                title: 'Contrasena',
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
                    _inputDecoration(
                      hint: 'Tu contraseña',
                      prefixIcon: Icons.key_rounded,
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
                    'Olvidaste tu contrasena?',
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

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textoSecundario,
        fontSize: 14,
      ),
      filled: true,
      fillColor: AppColors.fondoPrincipal,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 10, right: 8),
        child: Icon(prefixIcon, color: AppColors.azulPrincipal, size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 44),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(
          color: AppColors.verdePrincipal.withValues(alpha: 0.20),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: AppColors.verdePrincipal,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppColors.rosa),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppColors.rosa, width: 1.5),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.azulPrincipal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            color: AppColors.azulPrincipal,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Entra para continuar con el cuidado diario de tu mascota.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: AppColors.textoPrincipal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(message),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.rosa.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.rosa),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.rosa,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionLabel({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textoPrincipal),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textoPrincipal,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}