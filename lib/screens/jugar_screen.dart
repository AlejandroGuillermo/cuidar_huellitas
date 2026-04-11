import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_router.dart';
import '../cubit/pet_cubit.dart';
import '../cubit/pet_state.dart';
import '../widgets/paw_map_widget.dart';
import '../widgets/header_widget.dart';

// ── Modelo de juguete ──────────────────────────────────────
class Toy {
  final String id;
  final String emoji;
  final String name;
  final Color color;
  final int afectoBonus;   // cuánto sube el afecto al jugar
  final int energiaCosto;  // cuánta energía consume

  const Toy({
    required this.id,
    required this.emoji,
    required this.name,
    required this.color,
    this.afectoBonus  = 15,
    this.energiaCosto = 10,
  });
}

// ── Pantalla de Jugar ──────────────────────────────────────
class JugarScreen extends StatefulWidget {
  const JugarScreen({super.key});

  @override
  State<JugarScreen> createState() => _JugarScreenState();
}

class _JugarScreenState extends State<JugarScreen>
    with TickerProviderStateMixin {
  // Lista de juguetes disponibles
  final List<Toy> toys = [
    Toy(id: '1', emoji: '🎾', name: 'Pelota',  color: Color(0xFFa3ff88), afectoBonus: 20, energiaCosto: 12),
    Toy(id: '2', emoji: '🦴', name: 'Hueso',   color: Color(0xFF8ae670), afectoBonus: 15, energiaCosto: 8),
    Toy(id: '3', emoji: '🪃', name: 'Frisbee', color: Color(0xFF708be6), afectoBonus: 25, energiaCosto: 15),
    Toy(id: '4', emoji: '🧸', name: 'Peluche', color: Color(0xFFf07a94), afectoBonus: 10, energiaCosto: 5),
    Toy(id: '5', emoji: '🪢', name: 'Cuerda',  color: Color(0xFF8aa2ff), afectoBonus: 18, energiaCosto: 10),
    Toy(id: '6', emoji: '⚽', name: 'Balón',   color: Color(0xFFa3ff88), afectoBonus: 22, energiaCosto: 13),
  ];

  // ── Estado del juego ───────────────────────────────────
  Toy? _toyActivo;            // juguete en el campo
  Offset _toyPos = const Offset(180, 200);  // posición del juguete
  Offset _petPos = const Offset(100, 300);  // posición de la mascota
  bool _petTieneToy = false;  // el perro alcanzó el juguete
  bool _toyEnCaja = false;    // se arrastró a la caja
  int _jugadas = 0;
  double _progresoQuitar = 0; // barra para quitarle el juguete al perro
  bool _mostrando = false;    // caja de juguetes abierta
  bool _enCooldown = false;

  // ── Animaciones ────────────────────────────────────────
  late AnimationController _petController;
  late AnimationController _toyController;
  late AnimationController _quitarController;
  late Animation<double> _petBounce;
  late Animation<double> _toyFloat;

  // ── Timer de persecución ───────────────────────────────
  Timer? _chaseTimer;
  Timer? _quitarTimer;

  // ── Posición de la caja ────────────────────────────────
  final Rect _cajaRect = const Rect.fromLTWH(12, 60, 105, 85);

  // Partículas
  List<Offset> particles = [];

  // ── Drag offset para transición home ──────────────────
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();

    _petController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _toyController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _quitarController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200),
    );

    _petBounce = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _petController, curve: Curves.easeInOut),
    );

    _toyFloat = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _toyController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _petController.dispose();
    _toyController.dispose();
    _quitarController.dispose();
    _chaseTimer?.cancel();
    _quitarTimer?.cancel();
    super.dispose();
  }

  // --- MÉTODOS DE LA MASCOTA ---

  // ── Seleccionar juguete de la caja ─────────────────────
  void _seleccionarJuguete(Toy toy) {
    setState(() {
      _toyActivo = toy;
      _toyPos = const Offset(180, 220);
      _petTieneToy = false;
      _progresoQuitar = 0;
      _mostrando = false;
    });
    _iniciarPersecucion();
  }

  // ── La mascota persigue el juguete ─────────────────────
  void _iniciarPersecucion() {
    if (_enCooldown) return;
    _chaseTimer?.cancel();
    _chaseTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || _toyActivo == null || _petTieneToy) {
        timer.cancel();
        return;
      }

      final dx = _toyPos.dx - _petPos.dx;
      final dy = _toyPos.dy - _petPos.dy;
      final dist = sqrt(dx * dx + dy * dy);

      // Velocidad de persecución
      const speed = 3.0;

      if (dist < 50) {
        // ¡Alcanzó el juguete!
        timer.cancel();
        setState(() => _petTieneToy = true);
        _onPetAlcanzaJuguete();
        return;
      }

      setState(() {
        _petPos = Offset(
          _petPos.dx + (dx / dist) * speed,
          _petPos.dy + (dy / dist) * speed,
        );
      });
    });
  }

  // ── El perro alcanzó el juguete ────────────────────────
  void _onPetAlcanzaJuguete() {
    setState(() {
      _jugadas++;
      _toyPos = _petPos; // el juguete va donde está el perro
    });
    // Vibración haptica leve (opcional)
  }

  // ── Mover el juguete al arrastrar ──────────────────────
  void _onToyDragUpdate(DragUpdateDetails details) {
    if (_petTieneToy) return; // no se puede mover si el perro lo tiene
    setState(() {
      _toyPos = Offset(
        (_toyPos.dx + details.delta.dx).clamp(20, MediaQuery.of(context).size.width  - 60),
        (_toyPos.dy + details.delta.dy).clamp(100, MediaQuery.of(context).size.height - 200),
      );
    });
  }

  void _onToyDragEnd(DragEndDetails details) {
    // Verificar si se soltó en la caja
    if (_cajaRect.contains(_toyPos)) {
      _guardarJugueteEnCaja();
    }
  }

  // ── Guardar juguete en la caja ─────────────────────────
  void _guardarJugueteEnCaja() {
    final toy = _toyActivo;
    if (toy == null) return;

    setState(() {
      _toyActivo = null;
      _petTieneToy = false;
      _progresoQuitar = 0;
    });
    _chaseTimer?.cancel();

    // Guardar jugada en Firestore
    _guardarJugadaEnFirestore(toy, completada: true);
  }

  // ── Mantener presionado para quitar ───────────────────
  void _onPetLongPressStart(LongPressStartDetails _) {
    if (!_petTieneToy) return;
    _quitarTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      setState(() {
        _progresoQuitar = (_progresoQuitar + 0.04).clamp(0, 1);
        if (_progresoQuitar >= 1) {
          timer.cancel();
          _quitarJuguete();
        }
      });
    });
  }

  void _onPetLongPressEnd(LongPressEndDetails _) {
    _quitarTimer?.cancel();
    setState(() => _progresoQuitar = 0);
  }

  void _quitarJuguete() {
    final toy = _toyActivo;
    if (toy == null) return;

    // El niño le quitó el juguete → registrar jugada
    context.read<PetCubit>().jugar(
      afectoBonus:  toy.afectoBonus,
      energiaCosto: toy.energiaCosto,
    );

    setState(() {
      _petTieneToy = false;
      _progresoQuitar = 0;
      _enCooldown = true;
      _toyPos = Offset(
        _petPos.dx + 60,
        _petPos.dy - 30,
      );
    });

    _guardarJugadaEnFirestore(toy, completada: true);
    Future.delayed(const Duration(milliseconds: 1000), () {
    if (!mounted) return;

      setState(() {
        _enCooldown = false;
      });

      _iniciarPersecucion();
    });
  }

  // ── Guardar en Firestore ───────────────────────────────
  Future<void> _guardarJugadaEnFirestore(Toy toy, {required bool completada}) async {
    try {
      final userId    = FirebaseAuth.instance.currentUser?.uid;
      final mascotaId = context.read<PetCubit>().state.mascota?.idMascota;
      if (userId == null || mascotaId == null) return;

      final mascotaRef = FirebaseFirestore.instance
          .collection('usuarios').doc(userId)
          .collection('mascotas').doc(mascotaId);

      final ahora = DateTime.now();
      final antes  = context.read<PetCubit>().state.mascota!.nivelesMap;

      // Registro para el Motor de IA
      await mascotaRef.collection('progreso').add({
        'id_mision':           'jugar',
        'accion_realizada':    'jugar',
        'juguete':             toy.emoji,
        'hora_dia':            ahora.hour + (ahora.minute / 60.0),
        'fecha_actualizacion': Timestamp.now(),
        'estado_antes':        antes,
        'estado_despues': {
          ...antes,
          'afecto':  (antes['afecto']  ?? 0) + toy.afectoBonus,
          'energia': (antes['energia'] ?? 0) - toy.energiaCosto,
        },
        'jugadas_sesion': _jugadas,
        'completada': completada,
      });

      // Actualizar misión activa si existe
      await mascotaRef.update({'ultima_interaccion': Timestamp.now()});

    } catch (e) {
      debugPrint('Error guardando jugada: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      // 
      floatingActionButton: FloatingActionButton(
        onPressed: () => mostrarMapaHuella(context),
        backgroundColor: AppColors.verdeFondo,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Text('🐾', style: TextStyle(fontSize: 28)),
      ),
      // 2. Envolvemos el Body en un GestureDetector para el Swipe
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Deslizar derecha → Home
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx > 0) {
            setState(() => _dragOffset =
                (_dragOffset + details.delta.dx).clamp(0, size.width));
          }
        },
        onHorizontalDragEnd: (details) {
          if (_dragOffset > size.width * 0.3 ||
              (details.primaryVelocity ?? 0) > 500) {
            context.go(AppRoutes.home);
          } else {
            setState(() => _dragOffset = 0);
          }
        },
        child: Stack(
          children: [
            // ── Home visible al deslizar ─────────────────
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(_dragOffset - size.width, 0),
                child: Container(
                  color: AppColors.verdeFondo,
                  child: const Center(child: Text('🏠', style: TextStyle(fontSize: 80))),
                ),
              ),
            ),

            // ── Pantalla de juego ─────────────────────────
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: _buildGameScreen(size),
            ),

            // ── Indicador deslizar ────────────────────────
            if (_dragOffset > 20)
              Positioned(
                right: 16, top: 0, bottom: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Home →',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ▼ TODOS LOS MÉTODOS VISUALES SE MANTIENEN IGUAL ▼
  Widget _buildGameScreen(Size size) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF87ceeb), Color(0xFFa3ff88), Color(0xFF8ae670)],
        ),
      ),
      child: Stack(
        children: [
          _buildGrass(size),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildPlayArea(size)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Área de juego ──────────────────────────────────────
  Widget _buildPlayArea(Size size) {
    return Stack(
      children: [
        // Caja de juguetes
        _buildToyBox(),

        // Contador de jugadas
        Positioned(
          top: 12, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('Jugadas: $_jugadas',
                style: const TextStyle(fontSize: 12, color: Color(0xFF708be6), fontWeight: FontWeight.bold)),
          ),
        ),

        // Juguete arrastrable
        if (_toyActivo != null && !_petTieneToy)
          Positioned(
            left: _toyPos.dx - 24,
            top:  _toyPos.dy - 24,
            child: GestureDetector(
              onPanUpdate: _onToyDragUpdate,
              onPanEnd:    _onToyDragEnd,
              child: AnimatedBuilder(
                animation: _toyFloat,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _toyFloat.value),
                  child: child,
                ),
                child: Text(_toyActivo!.emoji,
                    style: const TextStyle(fontSize: 44,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))])),
              ),
            ),
          ),

        // Mascota con GestureDetector para quitar juguete
        Positioned(
          left: _petPos.dx - 36,
          top:  _petPos.dy - 36,
          child: GestureDetector(
            onLongPressStart: _onPetLongPressStart,
            onLongPressEnd:   _onPetLongPressEnd,
            child: AnimatedBuilder(
              animation: _petBounce,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _petBounce.value),
                child: child,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  BlocBuilder<PetCubit, PetState>(
                    builder: (context, state) {
                      final emoji = (state.mascota?.tipoMascota ?? 'perro') == 'gato' ? '🐱' : '🐶';
                      return Text(emoji, style: const TextStyle(fontSize: 72));
                    },
                  ),
                  // Juguete encima si el perro lo tiene
                  if (_petTieneToy && _toyActivo != null)
                    Positioned(
                      top: -10, right: -10,
                      child: Text(_toyActivo!.emoji, style: const TextStyle(fontSize: 28)),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Letrero y barra "quitar" cuando el perro tiene el juguete
        if (_petTieneToy && _progresoQuitar > 0)
          Positioned(
            left: _petPos.dx - 80,
            top:  _petPos.dy - 80,
            child: Container(
              width: 160,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.rosa.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF993556), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('¡Mantén presionado!',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  const Text('para quitarle el juguete',
                      style: TextStyle(color: Color(0xFFFBEAF0), fontSize: 10)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progresoQuitar,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      color: Colors.white,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Mensaje si no hay juguete activo
        if (_toyActivo == null)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 10),
                  const Text('¡Elige un juguete\nde la caja!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF708be6))),
                ],
              ),
            ),
          ),

        // Barra de progreso de juego
        Positioned(
          bottom: 12, left: 12, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Diversión — ${(_jugadas * 10).clamp(0, 100)}%',
                    style: const TextStyle(fontSize: 10, color: AppColors.textoSecundario)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_jugadas * 0.1).clamp(0, 1),
                    backgroundColor: Colors.grey[200],
                    color: AppColors.verdePrincipal,
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Caja de juguetes abierta (overlay)
        if (_mostrando) _buildToySelector(),
      ],
    );
  }

  // ── Selector de juguetes ───────────────────────────────
  Widget _buildToySelector() {
    return Positioned(
      left: 12, top: 155,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF5a70b8),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Elige un juguete',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: toys.map((toy) {
                return GestureDetector(
                  onTap: () => _seleccionarJuguete(toy),
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: toy.color, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(toy.emoji, style: const TextStyle(fontSize: 24)),
                        Text(toy.name, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pasto decorativo ───────────────────────────────────
  Widget _buildGrass(Size size) {
    return Stack(
      children: [
        Positioned(top: size.height * 0.25, left: 10,
            child: _circle(160, const Color(0xFF6db854), 0.2)),
        Positioned(top: size.height * 0.33, right: 20,
            child: _circle(220, const Color(0xFF5fa045), 0.15)),
        Positioned(bottom: size.height * 0.25, left: size.width * 0.33,
            child: _circle(190, const Color(0xFF7bc95f), 0.2)),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [
                  const Color(0xFF5fa045).withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────
  Widget _buildHeader() {
    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state) {
        final nombre  = state.mascota?.nombreMascota ?? 'Tu mascota';
        final energia = state.mascota?.nivelEnergia  ?? 0;
        return HeaderWidget(
          leftContent: Row(
            children: [
              const Text('🎾', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Área de Juegos',
                      style: TextStyle(fontSize: 18, color: Color(0xFF708be6), fontWeight: FontWeight.bold)),
                  Text('Hora de jugar con $nombre',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          rightContent: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Energía:', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70, height: 12,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(6)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: energia / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: energia < 30
                                ? [const Color(0xFFE24B4A), const Color(0xFFFF8C42)]
                                : [const Color(0xFFf07a94), AppColors.verdePrincipal],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('$energia%',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: energia < 30 ? const Color(0xFFE24B4A) : AppColors.textoPrincipal,
                      )),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Caja de juguetes ───────────────────────────────────
  Widget _buildToyBox() {
    return Positioned(
      left: 12, top: 60,
      child: GestureDetector(
        onTap: () => setState(() => _mostrando = !_mostrando),
        child: Container(
          width: 105, height: 85,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF708be6), Color(0xFF5a70b8)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 34)),
              const SizedBox(height: 4),
              Text(_mostrando ? 'Cerrar' : 'Juguetes',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle(double size, Color color, double opacity) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}