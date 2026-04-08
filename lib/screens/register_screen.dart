import 'package:cuidar_huellitas/core/app_router.dart';
import 'package:cuidar_huellitas/Models/usuario_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_colors.dart';
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
  final _firebaseAuth = FirebaseAuth.instance;

  bool _verPassword = false;
  bool _cargando = false;
  String _tipoSeleccionado = 'niño'; // Por defecto es niño
  String? _errorMessage;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validarVacio(String? value, String mensaje) {
    if (value == null || value.trim().isEmpty) return mensaje;
    return null;
  }

  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'El correo es requerido';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Ingresa un correo válido';
    return null;
  }

  String? _validarPassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es requerida';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  Future<void> _crearCuenta() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _cargando = true; _errorMessage = null; });

    try {
      // Crea la cuenta con email y contraseña
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: _correoController.text.trim(),
        password: _passwordController.text,
      );
      
      await userCredential.user?.updateDisplayName(_nombreController.text.trim());

      // Si la cuenta se creó correctamente, guardamos el usuario en Firestore
      if (userCredential.user != null) {
        
        // 1. Instancias tu modelo con los datos del formulario
        final nuevoUsuario = UsuarioModel(
          idUsuario: userCredential.user!.uid,
          nombre: _nombreController.text.trim(),
          correo: _correoController.text.trim(),
          tipoUsuario: _tipoSeleccionado, // Siguiendo la convención de tu modelo
        );

        // 2. Lo mandas a Firestore usando tu método toFirestore()
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(nuevoUsuario.idUsuario)
            .set(nuevoUsuario.toFirestore());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Cuenta creada con éxito! 🐶')),
        );
        if (_tipoSeleccionado == 'niño') {
          context.go(AppRoutes.adopcion);
        } else {
          //Cambiar esto por AppRoutes.tutorDashboard cuando lo crees
          //context.go(AppRoutes.home);
          context.go(AppRoutes.adopcion); // Por ahora los tutores también van a adopción 
        }
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al crear la cuenta';
      if (e.code == 'weak-password') {
        mensaje = 'La contraseña es muy débil';
      }
      else if (e.code == 'email-already-in-use') {
        mensaje = 'El correo ya está registrado';
      }
      else if (e.code == 'invalid-email') {
        mensaje = 'Correo inválido';
      }
      setState(() => _errorMessage = mensaje);
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.azulPrincipal,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeaderTexts(),
                const SizedBox(height: 36),
                _buildFormCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── HEADER ANIMADO CON HUELLITA ──────────────────────────────
  Widget _buildHeaderTexts() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack, // Efecto de rebote suave
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, -30 * (1 - value)), // Viene desde arriba
          child: Opacity(
            // Evita que la opacidad pase de 1.0
            opacity: value.clamp(0.0, 1.0), 
            child: Column(
              children: [
                const Icon(Icons.pets, size: 50, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Crear una cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 36, fontStyle: FontStyle.italic, fontFamily: 'Inter', fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '¡Únete para cuidar una mascota!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16, fontStyle: FontStyle.italic, fontFamily: 'Inter', fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── TARJETA DEL FORMULARIO ANIMADA ───────────────────────────
  Widget _buildFormCard(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000), // Ligeramente más lento que el header
      curve: Curves.easeOutCubic,
      builder: (context, double value, Widget? child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)), // Sube desde abajo
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child!,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15), 
              blurRadius: 25, 
              offset: const Offset(0, 10)
            )
          ], // Sombra más suave y moderna
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _errorMessage!, 
                    textAlign: TextAlign.center, 
                    style: TextStyle(color: Colors.red.shade700, fontSize: 14, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              _buildLabel('Escribe tu nombre:'),
              _buildCampoTexto(
                controller: _nombreController,
                hint: 'escribir nombre',
                icono: Icons.person_outline, // Agregamos ícono
                validador: (val) => _validarVacio(val, 'El nombre es requerido'),
                tipoTeclado: TextInputType.name,
                accionTeclado: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              
              _buildLabel('Correo electrónico:'),
              _buildCampoTexto(
                controller: _correoController,
                hint: 'escribir correo',
                icono: Icons.email_outlined, // Agregamos ícono
                validador: _validarEmail,
                tipoTeclado: TextInputType.emailAddress,
                accionTeclado: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              
              _buildLabel('Contraseña:'),
              _buildCampoPassword(),
              const SizedBox(height: 32),

              _buildLabel('¿Quién usará la cuenta?'),
              _buildRoleSelector(),
              const SizedBox(height: 32),
              
              _buildBotonComenzar(),
              const SizedBox(height: 24),
              _buildTextoLogin(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black, fontSize: 24, fontFamily: 'Sue Ellen Francisco', fontWeight: FontWeight.w400),
      ),
    );
  }

  InputDecoration _inputDecorationStyle(String hint, {IconData? icono}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontFamily: 'Inter', fontSize: 16),
      filled: true,
      fillColor: AppColors.azulFondo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18), // Un poco más alto
      prefixIcon: icono != null ? Icon(icono, color: AppColors.azulPrincipal) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: const BorderSide(color: AppColors.azulClaro),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: const BorderSide(color: AppColors.azulClaro),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: const BorderSide(color: AppColors.azulPrincipal, width: 2),
      ),
      errorBorder: OutlineInputBorder( // Agregué bordes rojos para errores
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
      ),
    );
  }

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validador,
    required TextInputType tipoTeclado,
    required TextInputAction accionTeclado,
    IconData? icono, // Recibimos el ícono
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: tipoTeclado,
      validator: validador,
      textInputAction: accionTeclado,
      decoration: _inputDecorationStyle(hint, icono: icono),
    );
  }

  Widget _buildCampoPassword() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_verPassword,
      validator: _validarPassword,
      textInputAction: TextInputAction.done,
      decoration: _inputDecorationStyle('escribir contraseña', icono: Icons.lock_outline).copyWith(
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: Icon(_verPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
            onPressed: () => setState(() => _verPassword = !_verPassword),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        Expanded(child: _roleButton('niño', Icons.child_care, 'Niño(a)')),
        const SizedBox(width: 16),
        Expanded(child: _roleButton('tutor', Icons.supervisor_account, 'Tutor')),
      ],
    );
  }

  Widget _roleButton(String valor, IconData icono, String texto) {
    final seleccionado = _tipoSeleccionado == valor;
    return GestureDetector(
      onTap: () => setState(() => _tipoSeleccionado = valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.azulPrincipal : AppColors.azulFondo,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? AppColors.azulPrincipal : AppColors.azulClaro,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icono, color: seleccionado ? Colors.white : AppColors.azulPrincipal, size: 28),
            const SizedBox(height: 4),
            Text(
              texto,
              style: TextStyle(
                color: seleccionado ? Colors.white : AppColors.azulPrincipal,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBotonComenzar() {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.azulPrincipal, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(vertical: 16), // Un poco más alto
        elevation: 2, // Agrega un ligero efecto 3D
      ),
      onPressed: _cargando ? null : _crearCuenta,
      child: _cargando
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.azulPrincipal))
          : const Text('Comenzar Aventura', style: TextStyle(fontSize: 24, fontFamily: 'Sue Ellen Francisco')),
    );
  }

  Widget _buildTextoLogin() {
    return TextButton(
      onPressed: () {
        context.go(AppRoutes.login);
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text.rich(
        TextSpan(
          text: '¿Ya tienes cuenta? ',
          style: const TextStyle(
            color: AppColors.azulPrincipal, 
            fontSize: 22, // Un poquito más grande
            fontFamily: 'Sue Ellen Francisco',
          ),
          children: [
            TextSpan(
              text: 'Iniciar sesión',
              style: TextStyle(
                color: AppColors.verdePrincipal,
                fontWeight: FontWeight.bold,
                // Le agregamos una sombra y subrayado para que resalte más
                decoration: TextDecoration.underline,
                decorationColor: AppColors.verdePrincipal,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center, // Si baja a dos líneas, se centra bonito
      ),
    );
  }
}