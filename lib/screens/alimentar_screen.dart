import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../cubit/pet_cubit.dart';
import '../cubit/pet_state.dart';
import '../widgets/paw_map_widget.dart';
import '../widgets/header_widget.dart';
import 'dart:async';

/// Modelo de alimento
class FoodItem {
  final String id;
  final String emoji;
  final String name;
  final int hunger;
  final Color color;

  FoodItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.hunger,
    required this.color,
  });
}

/// Pantalla de Alimentar
class AlimentarScreen extends StatefulWidget {

  const AlimentarScreen({super.key});

  @override
  State<AlimentarScreen> createState() => _AlimentarScreenState();
}

class _AlimentarScreenState extends State<AlimentarScreen>
with SingleTickerProviderStateMixin {
  // Lista de alimentos disponibles
  final List<FoodItem> foodItems = [
    FoodItem(
      id: '1',
      emoji: '🥩',
      name: 'Carne',
      hunger: 30,
      color: const Color(0xFFf07a94),
    ),
    FoodItem(
      id: '2',
      emoji: '🍖',
      name: 'Hueso',
      hunger: 25,
      color: const Color(0xFFa3ff88),
    ),
    FoodItem(
      id: '3',
      emoji: '🥕',
      name: 'Zanahoria',
      hunger: 15,
      color: const Color(0xFF8ae670),
    ),
    FoodItem(
      id: '4',
      emoji: '🐟',
      name: 'Pescado',
      hunger: 28,
      color: const Color(0xFF708be6),
    ),
    FoodItem(
      id: '5',
      emoji: '🍗',
      name: 'Pollo',
      hunger: 26,
      color: const Color(0xFF8aa2ff),
    ),
    FoodItem(
      id: '6',
      emoji: '🥛',
      name: 'Leche',
      hunger: 10,
      color: const Color(0xFFa3ff88),
    ),
  ];

  // Estado de la pantalla
  FoodItem? activeBag;
  double plateLevel = 0;
  bool eating = false;
  List<String> foodInPlate = [];
  bool cupboardOpen = false;
  Timer? pouringTimer;
  Timer? eatingTimer;
  Timer? _plateDecayTimer;          // Timer que vacía el plato solo
  bool _misionTraviesaActiva = false; // true = comida tirada por la pantalla
  List<Offset> _comidaTirada = [];    // posiciones aleatorias de la comida

  static const Map<String, double> _velocidadPlato = {
    'Glotón':     8.0,  // baja muy rápido — come todo de jalón
    'Juguetón':   3.0,  // baja normal pero tira comida
    'Travieso':   3.0,  // igual que juguetón pero genera misión
    'Dormilón':   0.5,  // baja muy lento — come despacio
    'Curioso':    1.5,  // baja moderado
    'Tierno':     1.0,  // baja lento — come con calma
  };

  // Animación de la mascota
  late AnimationController _petAnimationController;

  @override
  void initState() {
    super.initState();
    _petAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _petAnimationController.dispose();
    pouringTimer?.cancel();
    eatingTimer?.cancel();
    _plateDecayTimer?.cancel();
    super.dispose();
  }

  /// Selecciona un alimento de la alacena
  void handleSelectFood(FoodItem food) {
    if (eating || plateLevel >= 100) return;
    setState(() {
      activeBag = food;
      cupboardOpen = false;
    });
  }

  /// Inicia el vertido de comida
  void startPouring() {
    if (activeBag == null || plateLevel >= 100 || pouringTimer != null) return;

    pouringTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        plateLevel = (plateLevel + 2).clamp(0, 100);

        // Agregar emoji visual cada cierto nivel
        if (plateLevel % 15 == 0 && plateLevel > 0) {
          foodInPlate.add(activeBag!.emoji);
        }

        if (plateLevel >= 100) {
          stopPouring();
        }
      });
    });
  }

  /// Detiene el vertido de comida
  void stopPouring() {
    pouringTimer?.cancel();
    pouringTimer = null;
  }

  /// Elimina la bolsa activa
  void removeBag() {
    setState(() {
      activeBag = null;
    });
  }

  /// Alimenta a la mascota (llamado al finalizar el vaciado del plato)
  void _iniciarVaciadoPlato(String rasgo, int puntos, bool esTravieso) {
    _plateDecayTimer?.cancel();

    // Velocidad según personalidad (puntos por tick de 300ms)
    final velocidad = _velocidadPlato[rasgo] ?? 1.5;

    _plateDecayTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        plateLevel = (plateLevel - velocidad).clamp(0, 100);

        if (plateLevel <= 0) {
          timer.cancel();
          _plateDecayTimer = null;
          foodInPlate.clear();

          // Si NO es travieso → alimentar normal al terminar
          if (!esTravieso) {
            context.read<PetCubit>().alimentar(puntos);
          }

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) setState(() => eating = false);
          });
        }
      });
    });
  }

  // Si la mascota es traviesa/juguetona, tira comida por la pantalla
  void _tirarComida() {
    final random = Random();
    final screenWidth  = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Genera 5-8 posiciones aleatorias en la pantalla
    final cantidad = 5 + random.nextInt(4);
    final nuevasPos = List.generate(cantidad, (_) => Offset(
      random.nextDouble() * (screenWidth  - 60) + 30,
      random.nextDouble() * (screenHeight - 200) + 100,
    ));

    setState(() {
      _comidaTirada = nuevasPos;
      _misionTraviesaActiva = true;
      plateLevel = 0;       // El plato queda vacío
      foodInPlate.clear();
      eating = false;
    });

    // Guardar misión en Firestore
    _crearMisionRecoger();
  }

  // FUNCIÓN PARA CARGAR MASCOTA DESDE FIREBASE (llamada al iniciar la pantalla)
  Future<void> _crearMisionRecoger() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final mascotaId = context.read<PetCubit>().state.mascota?.idMascota;
    if (userId == null || mascotaId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('usuarios').doc(userId)
          .collection('mascotas').doc(mascotaId)
          .collection('misiones_activas').add({
        'tipo': 'recoger_comida',
        'estado': 'pendiente',
        'emoji': activeBag?.emoji ?? '🥩',
        'fecha_asignada': Timestamp.now(),
        'fecha_completada': null,
        'streak': 0,
      });
    } catch (e) {
      debugPrint('Error al crear misión: $e');
    }
  }

  // Función para recoger comida tirada (llamada al pulsar cada comida)
  void _recogerComida(int index) {
    setState(() {
      _comidaTirada.removeAt(index);
      if (_comidaTirada.isEmpty) {
        _misionTraviesaActiva = false;
        // Misión completada — sube limpieza
        context.read<PetCubit>().banar(); // reutiliza banar para subir limpieza
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Recogiste toda la comida! +limpieza 🧹'),
            backgroundColor: Color(0xFF8AE670),
          ),
        );
      }
    });
  }

  /// Alimenta a la mascota
  void handleFeedPet() {
    if (plateLevel == 0 || eating || activeBag == null) return;

    final rasgo = context.read<PetCubit>().state.mascota?.rasgo ?? 'Curioso';
    final esTravieso = rasgo == 'Travieso' || rasgo == 'Juguetón';
    final puntosAlimento = activeBag!.hunger;

    setState(() => eating = true);

    // Si es travieso/juguetón: tira comida, sube hambre muy poco
    if (esTravieso) {
      _tirarComida();
      // Solo sube un 20% de los puntos normales
      context.read<PetCubit>().alimentar((puntosAlimento * 0.2).round());
    }

    // Iniciar vaciado automático del plato
    _iniciarVaciadoPlato(rasgo, puntosAlimento, esTravieso);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => mostrarMapaHuella(context),
        backgroundColor: AppColors.verdeFondo, // O el color que estés usando
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Text('🐾', style: TextStyle(fontSize: 28)),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
            context.go('/home');
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFe8d5c4),
                Color(0xFFf0e6d2),
                Color(0xFFd4c4b0),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Textura de azulejos
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: CustomPaint(
                    painter: TilePainter(),
                  ),
                ),
              ),

              // Contenido principal
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Header
                    _buildHeader(context),

                    // Área principal
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            // Alacena y Mesa
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCupboard(),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTable()),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Mascota
                            Expanded(child: _buildPet()),

                            // Plato
                            _buildPlate(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bolsa arrastrable
              //if (activeBag != null) _buildDraggableBag(),
              _buildComidaTirada(),
            ],
          ),
        ),
      )
    );
  }

  /// Header con título, descripción y barra de hambre
  Widget _buildHeader(BuildContext context) {
    final barraWidth = MediaQuery.of(context).size.width * 0.25;
    
    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state) {
        // 1. Extraemos la mascota del estado actual de tu Cubit
        // (Asumiendo que tu estado tiene una propiedad llamada 'mascota')
        final mascota = state.mascota; 
      
        // 2. Valores por defecto por si la mascota aún está cargando
        final String nombre = mascota?.nombreMascota ?? 'Cargando...';
        final int hambre = mascota?.nivelHambre ?? 0;
        return HeaderWidget(
          // CONTENIDO IZQUIERDO: Título y Subtítulo
          leftContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox( // FittedBox para que no desborde si el nombre es largo
                fit: BoxFit.scaleDown,
                child: Row(
                  children: const [
                    Text('🍽️', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 8),
                    Text(
                      'Comedor',
                      style: TextStyle(
                        fontSize: 24,
                        color: Color(0xFF708be6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Hora de comer $nombre!',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
          
          // CONTENIDO DERECHO: Barra de Hambre
          rightContent: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Hambre:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: barraWidth, // Usamos el ancho dinámico en lugar de 120
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: hambre / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF0AB7A), AppColors.nivelHambre],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$hambre%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  /// Alacena con alimentos (Expansión controlada)
  Widget _buildCupboard() {
    // 1. Ancho FIJO para que no se expanda a los lados
    final double cupboardWidth = 140; 
    
    // 2. Alto controlado (No se estira de más)
    final double closedHeight = 120;
    final double openHeight = 280; // Altura máxima al abrirse

    return GestureDetector(
      onTap: () {
        if (!cupboardOpen) {
          setState(() {
            cupboardOpen = true;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: cupboardWidth,
        height: cupboardOpen ? openHeight : closedHeight,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6d4c3d), Color(0xFF4a3428)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: cupboardOpen
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Header de la alacena abierta
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Alimentos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              cupboardOpen = false;
                            });
                          },
                          child: const Text(
                            '✕',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Grid de alimentos
                    Expanded(
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, 
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: foodItems.length,
                        itemBuilder: (context, index) {
                          final food = foodItems[index];
                          return GestureDetector(
                            onTap: () => handleSelectFood(food),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    food.emoji,
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    food.name,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            // ▼ DISEÑO DE LA ALACENA CERRADA ▼
            : Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF3e291e), width: 2),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                bottomLeft: Radius.circular(6),
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFd4c4b0),
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 2)],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF3e291e), width: 2),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(6),
                                bottomRight: Radius.circular(6),
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFd4c4b0),
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 2)],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3e291e).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF8b6f47), width: 1),
                      ),
                      child: const Text(
                        'Alacena',
                        style: TextStyle(
                          color: Color(0xFFf0e6d2),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Mesa de madera
  Widget _buildTable() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8b6f47), Color(0xFF6d5736)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4a3428), width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Textura de madera
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: CustomPaint(
                painter: WoodGrainPainter(),
              ),
            ),
          ),

          // Botón X si hay bolsa activa
          if (activeBag != null)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: removeBag,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '✕',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (activeBag != null)
            // Centramos la bolsa dentro de la cajita de la mesa
            Center(
              child: _buildDraggableBag(context), 
            ),
          // Mensaje si no hay bolsa
          if (activeBag == null)
            const Center(
              child: Text(
                'Selecciona comida\nde la alacena',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Mascota animada
  Widget _buildPet() {
    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state){
        final petEmoji = (state.mascota?.tipoMascota ?? 'perro') == 'gato' ? '🐱' : '🐶'; // Puedes cambiar esto por diferentes emojis según el tipo de mascota
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _petAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, eating ? 0 : _petAnimationController.value * 8),
                    child: Transform.rotate(
                      angle: eating ? _petAnimationController.value * 0.1 : 0,
                      child: child,
                    ),
                  );
                },
                child: Text(petEmoji, style: const TextStyle(fontSize: 80)),
              ),
              const SizedBox(height: 16),

              // Mensaje de la mascota
              if (!eating && plateLevel == 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '¡Tengo hambre! 🤤',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),

              if (eating)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '¡Ñam ñam! 😋',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Plato de comida
  Widget _buildPlate() {
    return Column(
      children: [
        // Botón "¡Que coma!"
        if (plateLevel > 0 && !eating)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton(
              onPressed: handleFeedPet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFa3ff88),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                '¡Que coma! 🍽️',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        // Plato
        Container(
          width: 180,
          height: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFf5f5f5)],
            ),
            borderRadius: const BorderRadius.all(Radius.elliptical(90, 45)),
            border: Border.all(color: Colors.grey[400]!, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Nivel de llenado
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.elliptical(90, 45)),
                  child: Container(
                    height: 90 * (plateLevel / 100),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFF8ae670).withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Comida en el plato
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: -10,
                      alignment: WrapAlignment.center,
                      children: foodInPlate
                          .map((emoji) => Text(
                                emoji,
                                style: const TextStyle(fontSize: 26),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Indicador de nivel
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${plateLevel.toInt()}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  /// Bolsa arrastrable
  Widget _buildDraggableBag(BuildContext context) {
    return Draggable(
      // Pasamos el context a nuestra función responsiva
      feedback: Material(
        color: Colors.transparent, // Evita un fondo blanco feo al arrastrar
        child: _buildBagWidget(context, activeBag!, isDragging: true),
      ),
      childWhenDragging: Container(),
      onDragUpdate: (details) {
        // Detectar si está sobre el plato
        final screenHeight = MediaQuery.of(context).size.height;
        final plateAreaY = screenHeight * 0.75;

        if (details.globalPosition.dy > plateAreaY - 50) {
          startPouring();
        } else {
          stopPouring();
        }
      },
      onDragEnd: (details) {
        stopPouring();
      },
      // Pasamos el context aquí también
      child: _buildBagWidget(context, activeBag!),
    );
  }

  /// Widget de la bolsa (Responsivo)
  Widget _buildBagWidget(BuildContext context, FoodItem food, {bool isDragging = false}) {
    // Calculamos el tamaño basado en la pantalla. 
    // Usamos clamp para asegurar un tamaño mínimo y máximo razonable.
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final double bagWidth = (screenWidth * 0.28).clamp(80.0, 110.0);
    final double bagHeight = (screenHeight * 0.16).clamp(100.0, 140.0);

    return Container(
      width: bagWidth,
      height: bagHeight,
      padding: const EdgeInsets.all(8.0), // Damos un margen interno
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            food.color,
            food.color.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: food.color, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: isDragging ? 20 : 10,
            offset: Offset(0, isDragging ? 10 : 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Expanded y FittedBox aseguran que el emoji se encoja si la caja es muy pequeña
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                food.emoji,
                style: const TextStyle(fontSize: 48), // Tamaño base
              ),
            ),
          ),
          const SizedBox(height: 4),
          // FittedBox para que el nombre de la comida nunca desborde horizontalmente
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              food.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Si la mascota es traviesa/juguetona, muestra las piezas de comida tiradas por la pantalla
  Widget _buildComidaTirada() {
    if (!_misionTraviesaActiva || _comidaTirada.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        // Overlay semi-transparente con mensaje
        Positioned(
          top: 80, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C42).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '¡Recoge la comida! ${_comidaTirada.length} piezas 🧹',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ),
        // Piezas de comida tiradas
        ..._comidaTirada.asMap().entries.map((entry) {
          final index = entry.key;
          final pos   = entry.value;
          return Positioned(
            left: pos.dx,
            top:  pos.dy,
            child: GestureDetector(
              onTap: () => _recogerComida(index),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                builder: (context, val, child) => Transform.scale(scale: val, child: child),
                child: Text(
                  activeBag?.emoji ?? '🥩',
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// Painter para textura de azulejos
class TilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8b7355)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const tileSize = 50.0;

    // Líneas verticales
    for (double x = 0; x < size.width; x += tileSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Líneas horizontales
    for (double y = 0; y < size.height; y += tileSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter para textura de madera
class WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Líneas verticales simulando vetas de madera
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}