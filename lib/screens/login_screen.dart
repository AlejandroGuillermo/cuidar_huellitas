import 'package:cuidar_huellitas/core/app_colors.dart';
import 'package:cuidar_huellitas/core/app_router.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

//Para rastrear errores específicos del servidor
  String? _errorFirebaseCorreo;
  String? _errorFirebasePassword;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validarEmail(String? value) {
    // Si Firebase nos dio error de correo, mostramos este primero
    if (_errorFirebaseCorreo != null) return 'Correo incorrecto revisa tu email';
    // Validación local normal
    if (value == null || value.trim().isEmpty) {
      return 'El correo es requerido';
    }
    // Expresión regular simple para validar formato de correo
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return 'Ingresa un correo válido (ej. nombre@correo.com)';
    }
    return null;
  }

  String? _validarPassword(String? value) {
    // Si Firebase nos dio error de contraseña, mostramos este primero
    if (_errorFirebasePassword != null) return 'La contraseña es incorrecta';
    // Validación local normal
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    return null;
  }

  Future<void> _iniciarSesion() async {
    // Limpiamos errores específicos antes de validar
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
        //Aquí podrías usar: context.go(AppRoutes.home);
        //context.go('/adopcion');
        context.go(AppRoutes.home);
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al iniciar sesión';
      
      if (e.code == 'invalid-credential') {
        // Error genérico de seguridad moderno (Falla uno de los dos, pero no sabemos cuál)
        mensaje = 'Correo o contraseña incorrectos';
        _errorFirebaseCorreo = mensaje;   // Pintamos el correo
        _errorFirebasePassword = mensaje; // Pintamos la contraseña
        _passwordController.clear();      // Limpiamos la contraseña
        
      } else if (e.code == 'user-not-found') {
        // El correo no existe en la base de datos
        mensaje = 'Este correo no está registrado';
        _errorFirebaseCorreo = mensaje;   // SOLO pintamos el correo de rojo
        
      } else if (e.code == 'wrong-password') {
        // El correo existe, pero la contraseña está mal
        mensaje = 'La contraseña es incorrecta';
        _errorFirebasePassword = mensaje; // SOLO pintamos la contraseña de rojo
        _passwordController.clear();      // Limpiamos la contraseña
        
      } else if (e.code == 'invalid-email') {
        mensaje = 'Formato de correo inválido';
        _errorFirebaseCorreo = mensaje; 
        
      } else if (e.code == 'user-disabled') {
        mensaje = 'Usuario deshabilitado por el administrador';
        _errorFirebaseCorreo = mensaje; 
      }
      
      setState(() => _errorMessage = mensaje);
      _formKey.currentState!.validate(); // Revalidamos para mostrar el rojo en los campos afectados
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
      onChanged: (value) {
        if (_errorFirebaseCorreo != null) {
          setState(() => _errorFirebaseCorreo = null);
          _formKey.currentState!.validate();
        }
      },
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
      onChanged: (value) {
        if (_errorFirebasePassword != null) {
          setState(() => _errorFirebasePassword = null);
          _formKey.currentState!.validate();
        }
      },
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
        context.push(AppRoutes.register);
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