import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_router.dart';
import '../Models/mascota_model.dart';

class AdopcionScreen extends StatefulWidget {
  const AdopcionScreen({super.key});

  @override
  State<AdopcionScreen> createState() => _AdopcionScreenState();
}

class _AdopcionScreenState extends State<AdopcionScreen>
    with TickerProviderStateMixin {
  String _tipoSeleccionado = 'perro';
  bool _guardando = false;
  

  // ── Animaciones ────────────────────────────────────────
  late AnimationController _mascotaController;
  late AnimationController _cardController;
  late Animation<double> _mascotaAnim;
  late Animation<double> _cardAnim;

  final List<String> _nombresPerro = [
    'Firuláis', 'Rocky', 'Max', 'Bruno', 'Toby',
    'Charlie', 'Zeus', 'Coco', 'Beto', 'Canelo',
  ];
  final List<String> _nombresGato = [
    'Luna', 'Michi', 'Nala', 'Sombra', 'Pelusa',
    'Milo', 'Simba', 'Oreo', 'Canela', 'Gatito',
  ];

  // Personalidades con emoji, descripción e impacto en la IA
  final List<Map<String, String>> _personalidades = [
    {
      'nombre': 'Juguetón',
      'emoji': '🎾',
      'descripcion': 'Le encanta jugar, correr y estar en constante movimiento. Siempre busca divertirse.',
      'ia': '• Energía ↓ más rápido\n• Hambre ↓ ligeramente más rápido\n• Limpieza ↓ moderado\n• Afecto ↑ rápido al jugar\n• Salud ↓ leve si energía es baja',
    },
    {
      'nombre': 'Dormilón',
      'emoji': '😴',
      'descripcion': 'Prefiere descansar y dormir. Es tranquilo y poco activo.',
      'ia': '• Energía ↓ lento\n• Hambre ↓ un poco más lento\n• Limpieza ↓ lento\n• Afecto ↑ lento\n• Salud ↑ estable',
    },
    {
      'nombre': 'Cariñoso',
      'emoji': '🥰',
      'descripcion': 'Busca atención, cariño y compañía constante.',
      'ia': '• Afecto ↑ muy rápido al interactuar\n• Afecto ↓ más rápido si se ignora\n• Energía ↓ ligeramente\n• Hambre ↓ normal\n• Salud ↓ si afecto es bajo',
    },
    {
      'nombre': 'Travieso',
      'emoji': '😈',
      'descripcion': 'Hace travesuras constantemente y requiere atención.',
      'ia': '• Limpieza ↓ muy rápido\n• Energía ↓ moderado\n• Hambre ↓ normal\n• Afecto ↑ variable (aleatorio)\n• Salud ↓ leve por riesgo',
    },
    {
      'nombre': 'Glotón',
      'emoji': '🍖',
      'descripcion': 'Siempre quiere comer, le encanta la comida.',
      'ia': '• Hambre ↓ muy rápido\n• Energía ↑ más al comer\n• Limpieza ↓ leve\n• Afecto ↑ al alimentar\n• Salud ↓ si hambre es muy baja',
    },
  ];

  late String _nombreActual;
  late String _personalidadActual;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();

    // Rebote continuo de la mascota en el header
    _mascotaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _mascotaAnim = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _mascotaController, curve: Curves.easeInOut),
    );

    // Entrada de tarjetas al cambiar de tipo
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _cardAnim = CurvedAnimation(parent: _cardController, curve: Curves.easeOut);

    _asignarAleatorios();
    _nameController = TextEditingController(text: _nombreActual);
    _cardController.forward();
  }

  @override
  void dispose() {
    _mascotaController.dispose();
    _cardController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _asignarAleatorios() {
    final random = Random();
    final nombres = _tipoSeleccionado == 'perro' ? _nombresPerro : _nombresGato;
    _nombreActual = nombres[random.nextInt(nombres.length)];
    _personalidadActual =
        _personalidades[random.nextInt(_personalidades.length)]['nombre']!;
  }

  void _otroNombre() {
    final random = Random();
    final nombres = _tipoSeleccionado == 'perro' ? _nombresPerro : _nombresGato;
    String nuevo;
    do {
      nuevo = nombres[random.nextInt(nombres.length)];
    } while (nuevo == _nombreActual && nombres.length > 1);
    setState(() {
      _nombreActual = nuevo;
      _nameController.text = nuevo;
    });
  }

  void _seleccionarTipo(String tipo) {
    _cardController.reset();
    setState(() {
      _tipoSeleccionado = tipo;
      _asignarAleatorios();
      _nameController.text = _nombreActual;
    });
    _cardController.forward();
  }

  Map<String, String> get _personalidadInfo =>
      _personalidades.firstWhere((p) => p['nombre'] == _personalidadActual);

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    return Scaffold(
      backgroundColor: AppColors.fondoPrincipal,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(isSmall),
            _buildContenido(isSmall),
          ],
        ),
      ),
    );
  }

  // ── Header azul con mascota animada ───────────────────
  Widget _buildHeader(bool isSmall) {
    final emoji = _tipoSeleccionado == 'perro' ? '🐶' : '🐱';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 56, bottom: 28,
        left: isSmall ? 12 : 20,
        right: isSmall ? 12 : 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.azulPrincipal,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        children: [
          const Text('Primera vez',
              style: TextStyle(fontSize: 12, color: Color(0xFFCECBF6))),
          const SizedBox(height: 4),
          const Text('Adopta tu mascota',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Elige a tu nuevo amigo',
              style: TextStyle(fontSize: 13, color: Color(0xFF8AA2FF))),
          const SizedBox(height: 20),
          // Mascota con rebote continuo
          AnimatedBuilder(
            animation: _mascotaAnim,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _mascotaAnim.value),
              child: child,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Text(emoji,
                  key: ValueKey(_tipoSeleccionado),
                  style: TextStyle(fontSize: isSmall ? 64 : 80)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Contenido ─────────────────────────────────────────
  Widget _buildContenido(bool isSmall) {
    return Padding(
      padding: EdgeInsets.all(isSmall ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Text('¿Quién te acompañará?',
                style: TextStyle(
                  fontSize: isSmall ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textoPrincipal,
                )),
          ),
          const SizedBox(height: 14),

          // Tarjetas con animación de entrada
          FadeTransition(
            opacity: _cardAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(_cardAnim),
              child: Row(
                children: [
                  Expanded(child: _buildTarjetaMascota('perro', '🐶', 'Fiel y juguetón')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTarjetaMascota('gato', '🐱', 'Curioso e independiente')),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          _buildNombre(isSmall),
          const SizedBox(height: 16),
          _buildPersonalidad(),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _guardando ? null : _adoptar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulPrincipal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: _guardando 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : Text(
                'Adoptar a $_nombreActual ✨',
                style: TextStyle(
                    fontSize: isSmall ? 14 : 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Tarjeta perro / gato ──────────────────────────────
  Widget _buildTarjetaMascota(String tipo, String emoji, String descripcion) {
    final sel = _tipoSeleccionado == tipo;
    return GestureDetector(
      onTap: () => _seleccionarTipo(tipo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: sel ? AppColors.azulPrincipal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? const Color.fromARGB(255, 61, 150, 39) : AppColors.borde,
            width: sel ? 3 : 1.5,
          ),
          boxShadow: sel
              ? [BoxShadow(
                  color: AppColors.azulPrincipal.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            Text(
              tipo == 'perro' ? 'Perro' : 'Gato',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: sel ? Colors.white : AppColors.textoPrincipal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              descripcion,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: sel ? const Color(0xFFCECBF6) : AppColors.textoSecundario,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: sel ? AppColors.verdePrincipal : const Color(0xFFF1EFE8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                sel ? 'Seleccionado ✓' : 'Seleccionar',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: sel ? AppColors.textoPrincipal : AppColors.textoSecundario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Nombre ─────────────────────────────────────────────
  Widget _buildNombre(bool isSmall) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nombre asignado',
              style: TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(
                    fontSize: isSmall ? 16 : 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textoPrincipal,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) => _nombreActual = v,
                ),
              ),
              GestureDetector(
                onTap: _otroNombre,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.verdeFondo,
                    border: Border.all(color: AppColors.verdePrincipal),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Otro nombre',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2A5C14),
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Personalidad ───────────────────────────────────────
  Widget _buildPersonalidad() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Personalidad',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textoPrincipal)),
              SizedBox(height: 4),
              Text('Toca una para conocerla',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textoSecundario)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _personalidades.map((p) {
            final sel = p['nombre'] == _personalidadActual;
            return GestureDetector(
              onTap: () => setState(() => _personalidadActual = p['nombre']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppColors.azulPrincipal : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? AppColors.azulPrincipal : AppColors.borde),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p['emoji']!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      p['nombre']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : AppColors.textoPrincipal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 14),

        // Descripción + impacto IA con AnimatedSwitcher
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(_personalidadActual),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.azulFondo,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.azulClaro.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_personalidadInfo['emoji']!,
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      _personalidadInfo['nombre']!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.azulPrincipal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_personalidadInfo['descripcion']!,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textoPrincipal)),
                const SizedBox(height: 10),
                // Caja impacto IA
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🤖', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Impacto en el comportamiento',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.azulPrincipal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _personalidadInfo['ia']!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textoSecundario),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Adoptar ────────────────────────────────────────────
  Future<void> _adoptar() async {
    setState(() => _guardando = true); // Mostramos el loader

    try {
      // 1. Obtenemos el ID del usuario que está usando la app
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('No hay un usuario con sesión iniciada');
      }

      // 2. Preparamos la ruta en Firestore: usuarios -> [ID] -> mascotas
      final nuevaMascotaRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('mascotas')
          .doc(); // Al dejar doc() vacío, Firebase crea un ID único y aleatorio para la mascota

      // 3. Empaquetamos los datos en tu MascotaModel
      final nuevaMascota = MascotaModel(
        idMascota: nuevaMascotaRef.id,
        nombreMascota: _nombreActual,
        tipoMascota: _tipoSeleccionado,
        rasgo: _personalidadActual,
        ultimaInteraccion: DateTime.now(), // Inicializamos el reloj para la IA
      );

      // 4. Lo mandamos a la nube usando toFirestore()
      await nuevaMascotaRef.set(nuevaMascota.toFirestore());

      if (!mounted) return;

      // 5. ¡Éxito! Mostramos el diálogo de celebración
      showDialog(
        context: context,
        barrierDismissible: false, // Obliga al usuario a tocar el botón "¡Vamos!"
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('¡Felicidades! 🎉'),
          content: Text(
            'Adoptaste a $_nombreActual.\n'
            'Es un $_tipoSeleccionado $_personalidadActual.\n\n'
            '${_personalidadInfo['descripcion']}',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulPrincipal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                context.go(AppRoutes.home); // Descomenta esto cuando tengas tu HomeScreen listo
              },
              child: const Text('¡Vamos! 🐾',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      // Si algo falla (ej. se va el internet), le avisamos al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hubo un error al adoptar: $e')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false); // Ocultamos el loader
    }
  }
}