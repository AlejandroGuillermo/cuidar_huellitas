import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuidar_huellitas/Models/usuario_model.dart';
import 'package:cuidar_huellitas/application/services/notification_service.dart';
import 'package:cuidar_huellitas/core/app_colors.dart';
import 'package:cuidar_huellitas/core/app_router.dart';
import 'package:cuidar_huellitas/cubit/pet_cubit.dart';
import 'package:cuidar_huellitas/data/repositories/inventory_repository.dart';
import 'package:cuidar_huellitas/widgets/auth/auth_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firebaseAuth = FirebaseAuth.instance;

  bool _verPassword = false;
  bool _verConfirmPassword = false;
  bool _cargando = false;
  String _tipoSeleccionado = 'nino';
  String? _errorMessage;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validarVacio(String? value, String mensaje) {
    if (value == null || value.trim().isEmpty) return mensaje;
    return null;
  }

  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es requerido';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
      return 'Ingresa un correo valido';
    }
    return null;
  }

  String? _validarPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contrasena es requerida';
    }
    if (value.length < 6) {
      return 'Minimo 6 caracteres';
    }
    return null;
  }

  String? _validarConfirmacion(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contrasena';
    }
    if (value != _passwordController.text) {
      return 'Las contrasenas no coinciden';
    }
    return null;
  }

  Future<void> _crearCuenta() async {
    FocusScope.of(context).unfocus();
    final petCubit = context.read<PetCubit>();

    if (!_formKey.currentState!.validate()) return;

    final pedirNotificaciones = await _mostrarAvisoNotificacionesTutor();
    if (!mounted) return;

    setState(() {
      _cargando = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: _correoController.text.trim(),
        password: _passwordController.text,
      );

      await userCredential.user?.updateDisplayName(
        _nombreController.text.trim(),
      );

      if (userCredential.user != null) {
        final nuevoUsuario = UsuarioModel(
          idUsuario: userCredential.user!.uid,
          nombre: _nombreController.text.trim(),
          correo: _correoController.text.trim(),
          tipoUsuario: _tipoSeleccionado,
        );

        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(nuevoUsuario.idUsuario)
            .set(nuevoUsuario.toFirestore());
        await InventoryRepository().ensureDefaultInventory(
          nuevoUsuario.idUsuario,
        );
      }

      if (pedirNotificaciones) {
        await NotificationService.instance.requestPermissions();
      }

      await petCubit.cargarMascota();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cuenta creada con exito')));
      context.go(AppRoutes.adopcion);
    } on FirebaseAuthException catch (e) {
      String mensaje = 'No pudimos crear la cuenta';

      if (e.code == 'weak-password') {
        mensaje = 'La contrasena es muy debil';
      } else if (e.code == 'email-already-in-use') {
        mensaje = 'El correo ya esta registrado';
      } else if (e.code == 'invalid-email') {
        mensaje = 'Correo invalido';
      } else if (e.code == 'too-many-requests') {
        mensaje = 'Demasiados intentos. Espera un momento e intentalo de nuevo';
      }

      setState(() => _errorMessage = mensaje);
    } catch (_) {
      setState(() => _errorMessage = 'Ocurrio un error inesperado');
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<bool> _mostrarAvisoNotificacionesTutor() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Aviso para madre, padre o tutor'),
          content: const Text(
            'CuidARHuellitas puede enviar recordatorios locales para volver a cuidar la mascota. No incluiremos datos de salud, rutina ni informacion sensible en el mensaje.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Permitir recordatorios'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthScaffold(
      gradientColors: const [
        Color(0xFFE8F0FF),
        Color(0xFFCFE0FF),
        Color(0xFFA9C4FF),
      ],
      background: const AuthBackground(
        circles: [
          AuthCircleData(
            top: -50,
            left: -20,
            size: 180,
            color: Color(0x55FFFFFF),
          ),
          AuthCircleData(
            top: 90,
            right: -10,
            size: 120,
            color: Color(0x3AFFFFFF),
          ),
          AuthCircleData(
            bottom: 130,
            left: -25,
            size: 110,
            color: Color(0x2EFFFFFF),
          ),
          AuthCircleData(
            bottom: -50,
            right: 12,
            size: 170,
            color: Color(0x26FFFFFF),
          ),
        ],
      ),
      child: Column(
        children: [
          const AuthHero(
            chipText: 'Tu nueva aventura empieza aqui',
            title: 'Crear una cuenta',
            subtitle:
                'Registrate para adoptar, jugar y cuidar a tu mascota desde el primer dia.',
          ),
          const SizedBox(height: 24),
          _RegisterCard(
            formKey: _formKey,
            nombreController: _nombreController,
            correoController: _correoController,
            passwordController: _passwordController,
            confirmPasswordController: _confirmPasswordController,
            verPassword: _verPassword,
            verConfirmPassword: _verConfirmPassword,
            cargando: _cargando,
            tipoSeleccionado: _tipoSeleccionado,
            errorMessage: _errorMessage,
            theme: theme,
            validarNombre: (value) =>
                _validarVacio(value, 'El nombre es requerido'),
            validarEmail: _validarEmail,
            validarPassword: _validarPassword,
            validarConfirmacion: _validarConfirmacion,
            onTogglePassword: () {
              setState(() => _verPassword = !_verPassword);
            },
            onToggleConfirmPassword: () {
              setState(() => _verConfirmPassword = !_verConfirmPassword);
            },
            onTipoSeleccionado: (tipo) {
              setState(() => _tipoSeleccionado = tipo);
            },
            onCrearCuenta: _cargando ? null : _crearCuenta,
            onGoLogin: () => context.go(AppRoutes.login),
          ),
        ],
      ),
    );
  }
}

class _RegisterCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreController;
  final TextEditingController correoController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool verPassword;
  final bool verConfirmPassword;
  final bool cargando;
  final String tipoSeleccionado;
  final String? errorMessage;
  final ThemeData theme;
  final String? Function(String?) validarNombre;
  final String? Function(String?) validarEmail;
  final String? Function(String?) validarPassword;
  final String? Function(String?) validarConfirmacion;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final ValueChanged<String> onTipoSeleccionado;
  final VoidCallback? onCrearCuenta;
  final VoidCallback onGoLogin;

  const _RegisterCard({
    required this.formKey,
    required this.nombreController,
    required this.correoController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.verPassword,
    required this.verConfirmPassword,
    required this.cargando,
    required this.tipoSeleccionado,
    required this.errorMessage,
    required this.theme,
    required this.validarNombre,
    required this.validarEmail,
    required this.validarPassword,
    required this.validarConfirmacion,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onTipoSeleccionado,
    required this.onCrearCuenta,
    required this.onGoLogin,
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
                icon: Icons.auto_awesome_outlined,
                message:
                    'Tu cuenta servira para guardar avances, mascota y rutina diaria.',
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
                title: 'Tu nombre',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: nombreController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: validarNombre,
                decoration: buildAuthInputDecoration(
                  hint: 'Como quieres que te llamemos?',
                  prefixIcon: Icons.badge_outlined,
                  accentColor: AppColors.azulPrincipal,
                  fillColor: const Color(0xFFF7FAFF),
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
                autofillHints: const [AutofillHints.email],
                validator: validarEmail,
                decoration: buildAuthInputDecoration(
                  hint: 'nombre@correo.com',
                  prefixIcon: Icons.alternate_email_rounded,
                  accentColor: AppColors.azulPrincipal,
                  fillColor: const Color(0xFFF7FAFF),
                ),
              ),
              const SizedBox(height: 18),
              const AuthFieldLabel(
                title: 'Contrasena',
                icon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,
                obscureText: !verPassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: validarPassword,
                decoration:
                    buildAuthInputDecoration(
                      hint: 'Minimo 6 caracteres',
                      prefixIcon: Icons.key_rounded,
                      accentColor: AppColors.azulPrincipal,
                      fillColor: const Color(0xFFF7FAFF),
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
              const SizedBox(height: 18),
              const AuthFieldLabel(
                title: 'Confirmar contrasena',
                icon: Icons.verified_user_outlined,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: !verConfirmPassword,
                textInputAction: TextInputAction.done,
                validator: validarConfirmacion,
                onFieldSubmitted: (_) => onCrearCuenta?.call(),
                decoration:
                    buildAuthInputDecoration(
                      hint: 'Escribe de nuevo tu contrasena',
                      prefixIcon: Icons.shield_outlined,
                      accentColor: AppColors.azulPrincipal,
                      fillColor: const Color(0xFFF7FAFF),
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: onToggleConfirmPassword,
                        icon: Icon(
                          verConfirmPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ),
              ),
              const SizedBox(height: 24),
              const AuthFieldLabel(
                title: 'Quien usara la cuenta?',
                icon: Icons.groups_2_outlined,
              ),
              const SizedBox(height: 12),
              _RoleSelector(
                tipoSeleccionado: tipoSeleccionado,
                onSeleccionado: onTipoSeleccionado,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: onCrearCuenta,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.azulPrincipal,
                    foregroundColor: Colors.white,
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
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Comenzar aventura',
                            key: ValueKey('text'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Crearemos tu perfil y guardaremos el progreso de tu mascota para que puedas seguir donde te quedaste.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textoSecundario,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onGoLogin,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.azulPrincipal,
                ),
                child: const Text.rich(
                  TextSpan(
                    text: 'Ya tienes cuenta? ',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    children: [
                      TextSpan(
                        text: 'Iniciar sesion',
                        style: TextStyle(
                          color: AppColors.verdePrincipal,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final String tipoSeleccionado;
  final ValueChanged<String> onSeleccionado;

  const _RoleSelector({
    required this.tipoSeleccionado,
    required this.onSeleccionado,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleButton(
            icono: Icons.child_care_outlined,
            titulo: 'Niño(a)',
            subtitulo: 'Cuenta para jugar',
            seleccionado: tipoSeleccionado == 'niño',
            onTap: () => onSeleccionado('niño'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _RoleButton(
            icono: Icons.supervisor_account_outlined,
            titulo: 'Tutor',
            subtitulo: 'Acompaña el cuidado',
            seleccionado: tipoSeleccionado == 'tutor',
            onTap: () => onSeleccionado('tutor'),
          ),
        ),
      ],
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final bool seleccionado;
  final VoidCallback onTap;

  const _RoleButton({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.azulPrincipal : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: seleccionado
                ? AppColors.azulPrincipal
                : AppColors.azulPrincipal.withValues(alpha: 0.18),
            width: 1.6,
          ),
          boxShadow: seleccionado
              ? const [
                  BoxShadow(
                    color: Color(0x224D7EFF),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icono,
              size: 28,
              color: seleccionado ? Colors.white : AppColors.azulPrincipal,
            ),
            const SizedBox(height: 10),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: seleccionado ? Colors.white : AppColors.textoPrincipal,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: seleccionado
                    ? Colors.white.withValues(alpha: 0.86)
                    : AppColors.textoSecundario,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
