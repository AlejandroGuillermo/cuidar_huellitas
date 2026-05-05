import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../application/cubits/pet_world_cubit.dart';
import '../core/app_colors.dart';
import '../cubit/pet_cubit.dart';
import '../cubit/pet_state.dart';
import '../domain/enums/pet_activity.dart';
import '../domain/enums/pet_location.dart';
import '../widgets/paw_map_widget.dart';
import '../widgets/action_screen_header.dart';
import '../widgets/pet_avatar_rive.dart';

// ── Modelo de juguete ──────────────────────────────────────
class Toy {
  final String id;
  final String emoji;
  final String name;
  final Color color;
  final int afectoBonus; // cuánto sube el afecto al jugar
  final int energiaCosto; // cuánta energía consume

  const Toy({
    required this.id,
    required this.emoji,
    required this.name,
    required this.color,
    this.afectoBonus = 15,
    this.energiaCosto = 10,
  });
}

class _ToyInPlay {
  final String playId;
  final Toy toy;
  final Offset pos;

  const _ToyInPlay({
    required this.playId,
    required this.toy,
    required this.pos,
  });

  _ToyInPlay copyWith({Offset? pos}) {
    return _ToyInPlay(playId: playId, toy: toy, pos: pos ?? this.pos);
  }
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
    Toy(
      id: '1',
      emoji: '🎾',
      name: 'Pelota',
      color: Color(0xFFa3ff88),
      afectoBonus: 20,
      energiaCosto: 12,
    ),
    Toy(
      id: '2',
      emoji: '🦴',
      name: 'Hueso',
      color: Color(0xFF8ae670),
      afectoBonus: 15,
      energiaCosto: 8,
    ),
    Toy(
      id: '3',
      emoji: '🪃',
      name: 'Frisbee',
      color: Color(0xFF708be6),
      afectoBonus: 25,
      energiaCosto: 15,
    ),
    Toy(
      id: '4',
      emoji: '🧸',
      name: 'Peluche',
      color: Color(0xFFf07a94),
      afectoBonus: 10,
      energiaCosto: 5,
    ),
    Toy(
      id: '5',
      emoji: '🪢',
      name: 'Cuerda',
      color: Color(0xFF8aa2ff),
      afectoBonus: 18,
      energiaCosto: 10,
    ),
    Toy(
      id: '6',
      emoji: '⚽',
      name: 'Balón',
      color: Color(0xFFa3ff88),
      afectoBonus: 22,
      energiaCosto: 13,
    ),
  ];

  // ── Estado del juego ───────────────────────────────────
  final Random _random = Random();
  final List<_ToyInPlay> _toysEnCampo = [];
  String? _toyObjetivoId;
  String? _toyEnBocaId;
  Offset _petPos = const Offset(100, 300); // posición de la mascota
  int _jugadas = 0;
  double _progresoQuitar = 0; // barra para quitarle el juguete al perro
  bool _mostrando = false; // caja de juguetes abierta
  bool _enCooldown = false;
  bool _segundoJugueteYaGenerado = false;

  // ── Animaciones ────────────────────────────────────────
  late AnimationController _petController;
  late AnimationController _toyController;
  late AnimationController _quitarController;
  late Animation<double> _petBounce;
  late Animation<double> _toyFloat;

  // ── Timer de persecución ───────────────────────────────
  Timer? _chaseTimer;
  Timer? _quitarTimer;
  Timer? _segundoJugueteTimer;

  // ── Posición de la caja ────────────────────────────────
  final Rect _cajaRect = const Rect.fromLTWH(12, 60, 105, 85);

  // Partículas
  List<Offset> particles = [];

  // ── Drag offset para transición home ──────────────────
  @override
  void initState() {
    super.initState();

    _petController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _toyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _quitarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _petBounce = Tween<double>(
      begin: 0,
      end: -8,
    ).animate(CurvedAnimation(parent: _petController, curve: Curves.easeInOut));

    _toyFloat = Tween<double>(
      begin: 0,
      end: -6,
    ).animate(CurvedAnimation(parent: _toyController, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncWorldEntry();
      _hydrateOfflinePlayFromWorld();
    });
  }

  Future<void> _syncWorldEntry() async {
    if (!mounted) return;
    final mascota = context.read<PetCubit>().state.mascota;
    if (mascota == null) return;
    await context.read<PetWorldCubit>().syncScreenEntry(
      mascota: mascota,
      location: PetLocation.jugar,
      fallbackActivity: PetActivity.idle,
    );
  }

  Toy _toyByWorldId(String? rawId) {
    if (rawId == null || rawId.isEmpty) {
      return toys[_random.nextInt(toys.length)];
    }

    final normalized = rawId.toLowerCase();
    for (final toy in toys) {
      if (toy.id == rawId || toy.name.toLowerCase() == normalized) {
        return toy;
      }
      if ((normalized == 'pelota' && toy.id == '1') ||
          (normalized == 'hueso' && toy.id == '2') ||
          (normalized == 'frisbee' && toy.id == '3') ||
          (normalized == 'peluche' && toy.id == '4') ||
          (normalized == 'cuerda' && toy.id == '5') ||
          (normalized == 'balon' && toy.id == '6')) {
        return toy;
      }
    }
    return toys[_random.nextInt(toys.length)];
  }

  void _hydrateOfflinePlayFromWorld() {
    if (!mounted) return;
    if (_toyEnBocaId != null) return;

    final world = context.read<PetWorldCubit>().state;
    if (!world.isLocationLocked ||
        world.location != PetLocation.jugar ||
        world.activity != PetActivity.playing) {
      return;
    }

    final toy = _toyByWorldId(world.currentToyId);
    final playId = _nuevoToyPlayId(toy);
    setState(() {
      _toysEnCampo
        ..clear()
        ..add(_ToyInPlay(playId: playId, toy: toy, pos: _petPos));
      _toyEnBocaId = playId;
      _toyObjetivoId = null;
      _mostrando = false;
      _progresoQuitar = 0;
      _segundoJugueteYaGenerado = true;
    });
  }

  Future<void> _anchorPlayState(String toyId) async {
    final mascota = context.read<PetCubit>().state.mascota;
    if (mascota == null) return;
    final worldCubit = context.read<PetWorldCubit>();
    await worldCubit.updateWorld(
      mascota: mascota,
      next: worldCubit.state.copyWith(
        location: PetLocation.jugar,
        activity: PetActivity.playing,
        currentToyId: toyId,
        clearFood: true,
        isLocationLocked: true,
        isNapTime: false,
        simulatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _releasePlayLock() async {
    final mascota = context.read<PetCubit>().state.mascota;
    if (mascota == null) return;
    final worldCubit = context.read<PetWorldCubit>();
    if (!(worldCubit.state.isLocationLocked &&
        worldCubit.state.location == PetLocation.jugar)) {
      return;
    }
    await worldCubit.updateWorld(
      mascota: mascota,
      next: worldCubit.state.copyWith(
        activity: PetActivity.idle,
        clearToy: true,
        isLocationLocked: false,
        isNapTime: false,
        simulatedAt: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _petController.dispose();
    _toyController.dispose();
    _quitarController.dispose();
    _chaseTimer?.cancel();
    _quitarTimer?.cancel();
    _segundoJugueteTimer?.cancel();
    super.dispose();
  }

  // --- MÉTODOS DE LA MASCOTA ---

  String _nuevoToyPlayId(Toy toy) {
    return '${toy.id}_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(99999)}';
  }

  int _indexToy(String playId) {
    return _toysEnCampo.indexWhere((t) => t.playId == playId);
  }

  _ToyInPlay? _toyEnCampoPorId(String? playId) {
    if (playId == null) return null;
    final index = _indexToy(playId);
    if (index == -1) return null;
    return _toysEnCampo[index];
  }

  void _actualizarToyPosicion(String playId, Offset nuevaPos) {
    final index = _indexToy(playId);
    if (index == -1) return;
    _toysEnCampo[index] = _toysEnCampo[index].copyWith(pos: nuevaPos);
  }

  bool _esRasgoConSegundoJuguete(String rasgo) {
    final normalizado = rasgo.toLowerCase();
    return normalizado.contains('juguet') || normalizado.contains('travieso');
  }

  void _programarSegundoJugueteSiAplica() {
    _segundoJugueteTimer?.cancel();
    if (_segundoJugueteYaGenerado || _toysEnCampo.length != 1) return;

    final rasgo = context.read<PetCubit>().state.mascota?.rasgo ?? '';
    if (!_esRasgoConSegundoJuguete(rasgo)) return;

    final retraso = Duration(seconds: 6 + _random.nextInt(8));
    _segundoJugueteTimer = Timer(retraso, _generarSegundoJuguete);
  }

  void _generarSegundoJuguete() {
    if (!mounted || _segundoJugueteYaGenerado || _toysEnCampo.length != 1) {
      return;
    }

    final idsActivos = _toysEnCampo.map((t) => t.toy.id).toSet();
    final candidatos = toys
        .where((toy) => !idsActivos.contains(toy.id))
        .toList();
    if (candidatos.isEmpty) return;

    final toy = candidatos[_random.nextInt(candidatos.length)];
    final size = MediaQuery.of(context).size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateOfflinePlayFromWorld();
    });
    final x = (_cajaRect.right + 35 + (_random.nextDouble() * 60)).clamp(
      20.0,
      size.width - 60.0,
    );
    final y = (_cajaRect.bottom + 40 + (_random.nextDouble() * 60)).clamp(
      100.0,
      size.height - 200.0,
    );

    setState(() {
      _toysEnCampo.add(
        _ToyInPlay(playId: _nuevoToyPlayId(toy), toy: toy, pos: Offset(x, y)),
      );
      _segundoJugueteYaGenerado = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tu mascota sacó otro juguete. Puedes guardar cualquiera en la caja.',
        ),
        duration: Duration(milliseconds: 1600),
      ),
    );

    if (_toyEnBocaId == null) {
      _iniciarPersecucion();
    }
  }

  _ToyInPlay? _objetivoActual() {
    final libres = _toysEnCampo.where((t) => t.playId != _toyEnBocaId).toList();
    if (libres.isEmpty) return null;

    final objetivoPrevio = _toyEnCampoPorId(_toyObjetivoId);
    if (objetivoPrevio != null && objetivoPrevio.playId != _toyEnBocaId) {
      return objetivoPrevio;
    }

    libres.sort((a, b) {
      final da = (a.pos - _petPos).distanceSquared;
      final db = (b.pos - _petPos).distanceSquared;
      return da.compareTo(db);
    });
    return libres.first;
  }

  // ── Seleccionar juguete de la caja ─────────────────────
  void _seleccionarJuguete(Toy toy) {
    _segundoJugueteTimer?.cancel();
    setState(() {
      _toysEnCampo
        ..clear()
        ..add(
          _ToyInPlay(
            playId: _nuevoToyPlayId(toy),
            toy: toy,
            pos: const Offset(180, 220),
          ),
        );
      _toyObjetivoId = _toysEnCampo.first.playId;
      _toyEnBocaId = null;
      _segundoJugueteYaGenerado = false;
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
      if (!mounted || _toyEnBocaId != null) {
        timer.cancel();
        return;
      }

      final objetivo = _objetivoActual();
      if (objetivo == null) {
        timer.cancel();
        setState(() => _toyObjetivoId = null);
        return;
      }

      if (_toyObjetivoId != objetivo.playId) {
        setState(() => _toyObjetivoId = objetivo.playId);
      }

      final dx = objetivo.pos.dx - _petPos.dx;
      final dy = objetivo.pos.dy - _petPos.dy;
      final dist = sqrt(dx * dx + dy * dy);

      // Velocidad de persecución
      const speed = 3.0;

      if (dist < 50) {
        // ¡Alcanzó el juguete!
        timer.cancel();
        setState(() {
          _toyEnBocaId = objetivo.playId;
          _toyObjetivoId = null;
          _jugadas++;
          _actualizarToyPosicion(objetivo.playId, _petPos);
        });
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
    _programarSegundoJugueteSiAplica();
    final toyEnBoca = _toyEnCampoPorId(_toyEnBocaId);
    if (toyEnBoca != null) {
      _anchorPlayState(toyEnBoca.toy.id);
    }
    // Vibración haptica leve (opcional)
  }

  // ── Mover el juguete al arrastrar ──────────────────────
  void _onToyDragUpdate(String playId, DragUpdateDetails details) {
    if (_toyEnBocaId == playId) {
      return; // no se puede mover si el perro lo tiene
    }
    final toy = _toyEnCampoPorId(playId);
    if (toy == null) return;

    setState(() {
      _actualizarToyPosicion(
        playId,
        Offset(
          (toy.pos.dx + details.delta.dx).clamp(
            20,
            MediaQuery.of(context).size.width - 60,
          ),
          (toy.pos.dy + details.delta.dy).clamp(
            100,
            MediaQuery.of(context).size.height - 200,
          ),
        ),
      );
    });
  }

  void _onToyDragEnd(String playId, DragEndDetails details) {
    final toy = _toyEnCampoPorId(playId);
    if (toy == null) return;

    // Verificar si se soltó en la caja
    if (_cajaRect.contains(toy.pos)) {
      _guardarJugueteEnCaja(playId);
      return;
    }

    if (_toyEnBocaId == null) {
      _iniciarPersecucion();
    }
  }

  // ── Guardar juguete en la caja ─────────────────────────
  void _guardarJugueteEnCaja(String playId) {
    final toyInPlay = _toyEnCampoPorId(playId);
    if (toyInPlay == null) return;
    final removingFromMouth = _toyEnBocaId == playId;

    setState(() {
      _toysEnCampo.removeWhere((t) => t.playId == playId);
      if (_toyEnBocaId == playId) {
        _toyEnBocaId = null;
      }
      if (_toyObjetivoId == playId) {
        _toyObjetivoId = null;
      }
      _progresoQuitar = 0;
      if (_toysEnCampo.isEmpty) {
        _segundoJugueteYaGenerado = false;
        _segundoJugueteTimer?.cancel();
      }
    });
    _chaseTimer?.cancel();
    if (removingFromMouth) {
      _releasePlayLock();
    }

    // Guardar jugada en Firestore
    _guardarJugadaEnFirestore(toyInPlay.toy, completada: true);

    if (_toysEnCampo.isNotEmpty && _toyEnBocaId == null) {
      _iniciarPersecucion();
    }
  }

  // ── Mantener presionado para quitar ───────────────────
  void _onPetLongPressStart(LongPressStartDetails _) {
    if (_toyEnBocaId == null) return;
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
    final toyEnBoca = _toyEnCampoPorId(_toyEnBocaId);
    if (toyEnBoca == null) return;

    // El niño le quitó el juguete → registrar jugada
    context.read<PetCubit>().jugar(
      afectoBonus: toyEnBoca.toy.afectoBonus,
      energiaCosto: toyEnBoca.toy.energiaCosto,
    );

    setState(() {
      _toyEnBocaId = null;
      _progresoQuitar = 0;
      _enCooldown = true;
      _actualizarToyPosicion(
        toyEnBoca.playId,
        Offset(_petPos.dx + 60, _petPos.dy - 30),
      );
      _toyObjetivoId = toyEnBoca.playId;
    });
    _releasePlayLock();

    _guardarJugadaEnFirestore(toyEnBoca.toy, completada: true);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;

      setState(() {
        _enCooldown = false;
      });

      _iniciarPersecucion();
    });
  }

  // ── Guardar en Firestore ───────────────────────────────
  Future<void> _guardarJugadaEnFirestore(
    Toy toy, {
    required bool completada,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final mascotaId = context.read<PetCubit>().state.mascota?.idMascota;
      if (userId == null || mascotaId == null) return;

      final mascotaRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId);

      final ahora = DateTime.now();
      final antes = context.read<PetCubit>().state.mascota!.nivelesMap;

      // Registro para el Motor de IA
      await mascotaRef.collection('progreso').add({
        'id_mision': 'jugar',
        'accion_realizada': 'jugar',
        'juguete': toy.emoji,
        'hora_dia': ahora.hour + (ahora.minute / 60.0),
        'fecha_actualizacion': Timestamp.now(),
        'estado_antes': antes,
        'estado_despues': {
          ...antes,
          'afecto': (antes['afecto'] ?? 0) + toy.afectoBonus,
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

    // 1. Envolvemos en PopScope para bloquear el botón físico de 'Atrás' en Android o el swipe nativo de iOS
    return PopScope(
      canPop: false,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => mostrarMapaHuella(context),
          backgroundColor: AppColors.verdeFondo, // Usa tu AppColors.verdeFondo
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(
            Icons.pets,
            color: AppColors.azulPrincipal,
            size: 28,
          ),
        ),

        // 2. Quitamos el GestureDetector, el Stack y el Transform.
        // Solo llamamos directamente a tu pantalla de juego.
        body: _buildGameScreen(size),
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
            top: false,
            child: Column(
              children: [
                ActionScreenHeader(
                  icon: Icons.toys,
                  title: 'Área de Juegos',
                  subtitlePrefix: 'Hora de jugar con',
                  statLabel: 'Energía:',
                  statSelector: (mascota) => mascota.nivelEnergia,
                  barColors: const [Color(0xFFF0A77A), Color(0xFFFF8C42)],
                ),
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
    final worldState = context.watch<PetWorldCubit>().state;
    final canShowPet =
        !worldState.isLocationLocked ||
        worldState.location == PetLocation.jugar;

    if (!canShowPet) {
      return const Center(
        child: Text(
          'Tu mascota esta ocupada en otra pantalla.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3D4D75),
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Caja de juguetes
        _buildToyBox(),

        // Contador de jugadas
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Jugadas: $_jugadas',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF708be6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Juguetes arrastrables (puede haber más de uno afuera)
        ..._toysEnCampo
            .where((toy) => toy.playId != _toyEnBocaId)
            .map(
              (toy) => Positioned(
                left: toy.pos.dx - 24,
                top: toy.pos.dy - 24,
                child: GestureDetector(
                  onPanUpdate: (details) =>
                      _onToyDragUpdate(toy.playId, details),
                  onPanEnd: (details) => _onToyDragEnd(toy.playId, details),
                  child: AnimatedBuilder(
                    animation: _toyFloat,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _toyFloat.value),
                      child: child,
                    ),
                    child: Text(
                      toy.toy.emoji,
                      style: const TextStyle(
                        fontSize: 44,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

        // Mascota con GestureDetector para quitar juguete
        Positioned(
          left: _petPos.dx - 36,
          top: _petPos.dy - 36,
          child: GestureDetector(
            onLongPressStart: _onPetLongPressStart,
            onLongPressEnd: _onPetLongPressEnd,
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
                      final tipoMascota =
                          (state.mascota?.tipoMascota ?? 'perro').toLowerCase();
                      return PetAvatarRive(
                        tipoMascota: tipoMascota,
                        width: 132,
                        height: 132,
                      );
                    },
                  ),
                  // Juguete encima si la mascota lo tiene
                  if (_toyEnBocaId != null &&
                      _toyEnCampoPorId(_toyEnBocaId) != null)
                    Positioned(
                      top: -10,
                      right: -10,
                      child: Text(
                        _toyEnCampoPorId(_toyEnBocaId)!.toy.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Letrero y barra "quitar" cuando el perro tiene el juguete
        if (_toyEnBocaId != null && _progresoQuitar > 0)
          Positioned(
            left: _petPos.dx - 80,
            top: _petPos.dy - 80,
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
                  const Text(
                    '¡Mantén presionado!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'para quitarle el juguete',
                    style: TextStyle(color: Color(0xFFFBEAF0), fontSize: 10),
                  ),
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
        if (_toysEnCampo.isEmpty)
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
                  const Text(
                    '¡Elige un juguete\nde la caja!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF708be6),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Barra de progreso de juego
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diversión — ${(_jugadas * 10).clamp(0, 100)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textoSecundario,
                  ),
                ),
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
      left: 12,
      top: 155,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF5a70b8),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Elige un juguete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: toys.map((toy) {
                return GestureDetector(
                  onTap: () => _seleccionarJuguete(toy),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: toy.color, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(toy.emoji, style: const TextStyle(fontSize: 24)),
                        Text(
                          toy.name,
                          style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
        Positioned(
          top: size.height * 0.25,
          left: 10,
          child: _circle(160, const Color(0xFF6db854), 0.2),
        ),
        Positioned(
          top: size.height * 0.33,
          right: 20,
          child: _circle(220, const Color(0xFF5fa045), 0.15),
        ),
        Positioned(
          bottom: size.height * 0.25,
          left: size.width * 0.33,
          child: _circle(190, const Color(0xFF7bc95f), 0.2),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
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

  // ── Caja de juguetes ───────────────────────────────────
  Widget _buildToyBox() {
    return Positioned(
      left: 12,
      top: 60,
      child: GestureDetector(
        onTap: () => setState(() => _mostrando = !_mostrando),
        child: Container(
          width: 105,
          height: 85,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF708be6), Color(0xFF5a70b8)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 34)),
              const SizedBox(height: 4),
              Text(
                _mostrando ? 'Cerrar' : 'Juguetes',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
