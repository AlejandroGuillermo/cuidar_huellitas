import 'package:cuidar_huellitas/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';

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


  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es requerido';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _validarPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    return null;
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _errorMessage = null;
    });

    try {
      final correo = _correoController.text.trim();
      final password = _passwordController.text;

      await _firebaseAuth.signInWithEmailAndPassword(
        email: correo,
        password: password,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Sesion iniciada!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al iniciar sesión';
      if (e.code == 'user-not-found') {
        mensaje = 'Usuario no encontrado';
      } else if (e.code == 'wrong-password') {
        mensaje = 'Contraseña incorrecta';
      } else if (e.code == 'invalid-email') {
        mensaje = 'Correo inválido';
      } else if (e.code == 'user-disabled') {
        mensaje = 'Usuario deshabilitado';
      }
      setState(() => _errorMessage = mensaje);
    } catch (e) {
      setState(() => _errorMessage = 'Error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.verdePrincipal,
      // SafeArea y SingleChildScrollView hacen que el diseño sea responsive
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAvatar(),
                const SizedBox(height: 36),
                _buildFormCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── AVATAR CIRCULAR (Diseño Gris) ─────────────────────────────
  Widget _buildAvatar() {
    return Container(
      width: 150,
      height: 150,
      decoration: const BoxDecoration(
        color: Color(0xFFD9D9D9),
        shape: BoxShape.circle,
      ),
      // Aquí puedes poner un Image.asset o un icono en el futuro
      child: const Center(
        child: Icon(Icons.pets, size: 60, color: Colors.white),
      ),
    );
  }

  // ── TARJETA DEL FORMULARIO ─────────────────────────
  Widget _buildFormCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50), // Borde muy redondeado según el diseño
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Inicio de sesion',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 32,
                fontFamily: 'Sue Ellen Francisco',
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
              ),
              const SizedBox(height: 16),
            ],

            _buildLabel('Correo electronico:'),
            _buildCampoEmail(),
            const SizedBox(height: 16),

            _buildLabel('Contraseña:'),
            _buildCampoPassword(),
            const SizedBox(height: 8),

            TextButton(
              onPressed: () {},
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: AppColors.azulPrincipal,
                  fontSize: 20,
                  fontFamily: 'Sue Ellen Francisco',
                ),
              ),
            ),

            const SizedBox(height: 16),
            _buildBotonEntrar(),
            const SizedBox(height: 16),

            const Text(
              'o',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontFamily: 'Inter'),
            ),

            const SizedBox(height: 16),
            _buildBotonCrearCuenta(),
          ],
        ),
      ),
    );
  }

  // ── WIDGETS AUXILIARES PARA INPUTS ────────────────────────
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontFamily: 'Sue Ellen Francisco',
        ),
      ),
    );
  }

  InputDecoration _inputDecorationStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.verdeFondo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(color: AppColors.verdeClaro),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(color: AppColors.verdeClaro),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(color: AppColors.verdePrincipal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  Widget _buildCampoEmail() {
    return TextFormField(
      controller: _correoController,
      keyboardType: TextInputType.emailAddress,
      validator: _validarEmail,
      textInputAction: TextInputAction.next,
      decoration: _inputDecorationStyle('Correo electrónico'),
    );
  }

  Widget _buildCampoPassword() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_verPassword,
      validator: _validarPassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _iniciarSesion(),
      decoration: _inputDecorationStyle('Contraseña').copyWith(
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: Icon(
              _verPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () => setState(() => _verPassword = !_verPassword),
          ),
        ),
      ),
    );
  }

  // ── BOTONES ───────────────────────────────────────────────
  Widget _buildBotonEntrar() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.verdePrincipal,
        foregroundColor: Colors.black, // Color del texto
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: _cargando ? null : _iniciarSesion,
      child: _cargando
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
            )
          : const Text(
              'Entrar',
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'Sue Ellen Francisco',
              ),
            ),
    );
  }

  Widget _buildBotonCrearCuenta() {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black, // Color del texto
        side: BorderSide(color: AppColors.azulPrincipal, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: () {
        // Navegamos a la pantalla de registro
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RegisterScreen(), // <-- OJO: Cambia "RegistroScreen" por el nombre real de tu clase de registro
          ),
        );
      },
      child: const Text(
        'Crear una cuenta',
        style: TextStyle(
          fontSize: 24,
          fontFamily: 'Sue Ellen Francisco',
        ),
      ),
    );
  }
}