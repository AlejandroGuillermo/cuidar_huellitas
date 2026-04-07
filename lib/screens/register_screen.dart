import 'package:cuidar_huellitas/core/app_router.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      // Crea el usuario en Firebase Auth
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: _correoController.text.trim(),
        password: _passwordController.text,
      );
      
      // Opcional: Actualizar el perfil con el nombre
      await userCredential.user?.updateDisplayName(_nombreController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Cuenta creada con éxito! 🐶')),
        );
        context.go(AppRoutes.adopcion);
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

  Widget _buildHeaderTexts() {
    return const Column(
      children: [
        Text(
          'Crear una cuenta',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 36, fontStyle: FontStyle.italic, fontFamily: 'Inter', fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text(
          '¡Unete para cuidar una mascota!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic, fontFamily: 'Inter', fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 5))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700, fontSize: 14)),
              const SizedBox(height: 16),
            ],
            _buildLabel('Escribe tu nombre:'),
            _buildCampoTexto(
              controller: _nombreController,
              hint: 'escribir nombre',
              validador: (val) => _validarVacio(val, 'El nombre es requerido'),
              tipoTeclado: TextInputType.name,
              accionTeclado: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            
            _buildLabel('Correo electronico:'),
            _buildCampoTexto(
              controller: _correoController,
              hint: 'escribir correo',
              validador: _validarEmail,
              tipoTeclado: TextInputType.emailAddress,
              accionTeclado: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            
            _buildLabel('Contraseña:'),
            _buildCampoPassword(),
            const SizedBox(height: 32),
            
            _buildBotonComenzar(),
            const SizedBox(height: 24),
            _buildTextoLogin(),
          ],
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

  InputDecoration _inputDecorationStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontFamily: 'Inter', fontSize: 16),
      filled: true,
      fillColor: AppColors.azulFondo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
    );
  }

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validador,
    required TextInputType tipoTeclado,
    required TextInputAction accionTeclado,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: tipoTeclado,
      validator: validador,
      textInputAction: accionTeclado,
      decoration: _inputDecorationStyle(hint),
    );
  }

  Widget _buildCampoPassword() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_verPassword,
      validator: _validarPassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _crearCuenta(),
      decoration: _inputDecorationStyle('escribir contraseña').copyWith(
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

  Widget _buildBotonComenzar() {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.azulPrincipal, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: _cargando ? null : _crearCuenta,
      child: _cargando
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.azulPrincipal))
          : const Text('Comenzar Aventura', style: TextStyle(fontSize: 24, fontFamily: 'Sue Ellen Francisco')),
    );
  }

  Widget _buildTextoLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿Ya tienes cuenta? ',
          style: TextStyle(color: AppColors.azulPrincipal, fontSize: 20, fontFamily: 'Sue Ellen Francisco'),
        ),
        GestureDetector(
          onTap: () {
          // Navega a la pantalla de login
            context.go(AppRoutes.login);
          },
          child: const Text(
            'Iniciar sesión',
            style: TextStyle(color: AppColors.verdePrincipal, fontSize: 20, fontFamily: 'Sue Ellen Francisco', fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}