import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../application/cubits/pet_world_cubit.dart';
import '../core/app_colors.dart';
import '../core/app_router.dart';
import '../cubit/pet_cubit.dart';
import '../cubit/pet_state.dart';
import '../domain/enums/pet_activity.dart';
import '../domain/enums/pet_location.dart';
import '../widgets/action_screen_header.dart';
import '../widgets/armario_widget.dart';
import '../widgets/paw_map_widget.dart';
import '../widgets/ventana_habitacion.dart';

enum _ModoHora { manana, tarde, noche }

class DormirScreen extends StatefulWidget {
  const DormirScreen({super.key});
  @override
  State<DormirScreen> createState() => _DormirScreenState();
}

class _DormirScreenState extends State<DormirScreen>
    with TickerProviderStateMixin {
  // ── Navegación ─────────────────────────────────────────
  double _dragOffset = 0;

  // ── Hora dinámica ──────────────────────────────────────
  DateTime _horaDinamica = DateTime.now();
  Timer? _timerHora;
  Timer? _timerDescanso;

  // ── Mecánica ────────────────────────────────────────────
  final List<_Corazon> _corazones = [];
  double _progresoAcostar = 0.0;
  Timer? _timerAcostar;
  Alignment _petAlignment = const Alignment(-0.5, 0.55);
  final Random _rng = Random();

  // ── Overlay al dormirse ────────────────────────────────
  bool _mostrarOverlayDormido = false;
  bool _eraDormidaAntes = false;

  // ── Animación de flotación ─────────────────────────────
  late AnimationController _petFloatCtrl;
  late Animation<double> _petFloat;
  String _ultimoMensajeBloqueo = '';

  // ══════════════════════════════════════════════════════
  // CICLO DE VIDA
  // ══════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();

    // Hora: avanza 10 min/seg (modo demo — quitar en producción)
    _timerHora = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(
          () => _horaDinamica = _horaDinamica.add(const Duration(minutes: 10)),
        );
        context.read<PetCubit>().promoverSiestaANocheSiAplica(
          esNocheActual: _esNoche,
      }
    });

    // Tick de recuperación de energía
    _timerDescanso = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) context.read<PetCubit>().tickDescanso();
    });

    _petFloatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _petFloat = Tween<double>(
      begin: 0,
      end: -8,
    ).animate(CurvedAnimation(parent: _petFloatCtrl, curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncWorldEntry();
      await _ensureLockedSleepState();
    });

  Future<void> _syncWorldEntry() async {
    if (mascota == null) return;
    await context.read<PetWorldCubit>().syncScreenEntry(
      location: PetLocation.dormir,
      fallbackActivity: mascota.estaDescansando
          : PetActivity.idle,
    );
  }

  Future<void> _ensureLockedSleepState() async {
    if (!mounted) return;
    final world = context.read<PetWorldCubit>().state;
    final mascota = petCubit.state.mascota;
    if (mascota == null) return;

    if (world.isLocationLocked &&
        world.location == PetLocation.dormir &&
        world.activity == PetActivity.sleeping &&
        !mascota.estaDescansando) {
      await petCubit.forzarDescansoOffline(siesta: world.isNapTime);
    }
  }

  @override
  void dispose() {
    _timerHora?.cancel();
    _timerDescanso?.cancel();
    _timerAcostar?.cancel();
    _petFloatCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════
  // GETTERS DE HORA Y COLOR
  // ══════════════════════════════════════════════════════

  _ModoHora get _modo {
    final h = _horaDinamica.hour;
    if (h >= 6 && h < 13) return _ModoHora.manana;
    if (h >= 13 && h < 20) return _ModoHora.tarde;
    return _ModoHora.noche;
  }

  bool get _esNoche => _modo == _ModoHora.noche;

  List<Color> get _coloresPared => switch (_modo) {
    _ModoHora.manana => [const Color(0xFFFFF8E1), const Color(0xFFD7CCC8)],
    _ModoHora.tarde => [const Color(0xFFFFCC80), const Color(0xFFBCAAA4)],
    _ModoHora.noche => [const Color(0xFF455A64), const Color(0xFF1C2331)],
  };

  List<Color> get _coloresPiso => switch (_modo) {
    _ModoHora.manana => [const Color(0xFFBCAAA4), const Color(0xFFA1887F)],
    _ModoHora.tarde => [const Color(0xFF8D6E63), const Color(0xFF6D4C41)],
    _ModoHora.noche => [const Color(0xFF263238), const Color(0xFF10141C)],
  };

  String get _tituloModo => switch (_modo) {
    _ModoHora.manana => 'Buenos dias',
    _ModoHora.tarde => 'Buenas tardes',
    _ModoHora.noche => 'Hora de dormir',
  };

  String get _subtituloModo => switch (_modo) {
    _ModoHora.manana => 'Descansa un rato,',
    _ModoHora.tarde => 'Siesta para',
    _ModoHora.noche => 'A dormir,',
  };

  // ══════════════════════════════════════════════════════
  // LÓGICA DE INTERACCIÓN
  // ══════════════════════════════════════════════════════

  void _mostrarMensajeBloqueo(String mensaje) {
    final ahora = DateTime.now();
    final esRepetidoReciente =
        _ultimoMensajeBloqueo == mensaje &&
        ahora.difference(_ultimoMensajeBloqueoAt) <
            const Duration(milliseconds: 1400);
    if (esRepetidoReciente) return;
    _ultimoMensajeBloqueo = mensaje;
    _ultimoMensajeBloqueoAt = ahora;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje, style: const TextStyle(fontSize: 13)),
          backgroundColor: const Color(0xFF37474F),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void _onBedLongPressStart(LongPressStartDetails _) {
    final mascota = context.read<PetCubit>().state.mascota;
    if (mascota == null || mascota.estaDescansando) return;

    _timerAcostar = Timer.periodic(const Duration(milliseconds: 60), (t) {
      setState(() {
        _progresoAcostar = (_progresoAcostar + 0.033).clamp(0, 1);
        if (_progresoAcostar >= 1.0) {
          t.cancel();
          _progresoAcostar = 0;
          _ejecutarAcostar();
        }
      });
    });
  }

  void _onBedLongPressEnd(LongPressEndDetails _) {
    _timerAcostar?.cancel();
    if (context.read<PetCubit>().state.mascota?.estadoDescanso == 'despierto') {
      setState(() => _progresoAcostar = 0);
    }
  }

  Future<void> _ejecutarAcostar() async {
    final resultado = await context.read<PetCubit>().intentarAcostar(
      esNoche: _esNoche,
    );
    if (resultado == 'siesta_requiere_cortina') {
      if (!mounted) return;
      _mostrarMensajeBloqueo('Cierra las cortinas para iniciar la siesta');
      return;
    }
    if (resultado == 'rebelde_cuarto') _moverPetRebelde();
  }

  void _moverPetRebelde() {
    if (!mounted) return;
    setState(() {
      _petAlignment = Alignment(
        -0.8 + _rng.nextDouble() * 1.6,
        0.3 + _rng.nextDouble() * 0.4,
      );
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted &&
          context.read<PetCubit>().state.estadoMision == 'perro_rebelde') {
        _moverPetRebelde();
      }
    });
  }

  Future<void> _onPetPanUpdate(DragUpdateDetails details) async {
    final state = context.read<PetCubit>().state;
    final mascota = state.mascota;
    final puedeAcariciarParaDormir =
        mascota?.estadoDescanso == 'acostado' &&
        (_esNoche || mascota?.tipoDescanso == 'siesta');
    if (!puedeAcariciarParaDormir) return;
    if (details.delta.distance <= 3) return;

    final seDurmio = await context.read<PetCubit>().registrarCaricia();
    if (seDurmio && mounted) setState(() {});

    final id = DateTime.now().microsecondsSinceEpoch;
    setState(
      () => _corazones.add(_Corazon(id: id, posicion: details.globalPosition)),
    );
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _corazones.removeWhere((c) => c.id == id));
    });
  }

  Future<void> _onPetTap() async {
    final state = context.read<PetCubit>().state;
    final mascota = state.mascota;
    if (mascota == null) return;

    final esDormida = mascota.estadoDescanso == 'dormido';
    final esSiesta = mascota.estadoDescanso == 'siesta';

    // Tap sobre mascota despierta → calmar rebelde
    if (!esDormida && !esSiesta) {
      if (state.estadoMision == 'perro_rebelde' ||
          state.estadoMision == 'rebelde_escapado') {
        await context.read<PetCubit>().registrarTapCalmar();
      }
      return;
    }

    // Siesta: despertable solo con cortinas abiertas
    if (esSiesta) {
      if (!mascota.cortinasAbiertas) {
        _mostrarMensajeBloqueo(
          'Abre las cortinas para despertarla de la siesta',
        );
        return;
      }
      await context.read<PetCubit>().registrarTapDespertar();
      return;
    }

    // Noche: solo si es de dÃƒÂ­a Y hay luz
    final esDeDia = _modo != _ModoHora.noche;
    final hayLuz = mascota.cortinasAbiertas;

    if (!esDeDia || !hayLuz) {
      _mostrarMensajeBloqueo(
        !esDeDia
            ? 'Aun es de noche, dejala descansar'
            : 'Abre las cortinas para que entre la luz',
      );
      return;
    }

    await context.read<PetCubit>().registrarTapDespertar(
      despertarInstantaneo: true,
    );
  }

  void _onSeDurmio(String nombre) {
    setState(() => _mostrarOverlayDormido = true);
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _mostrarOverlayDormido = false);
    });
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => mostrarMapaHuella(context),
        backgroundColor: AppColors.verdeFondo,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.pets, color: AppColors.azulPrincipal, size: 28),
      ),
      body: GestureDetector(
        onHorizontalDragUpdate: (d) {
          setState(
            () => _dragOffset = (_dragOffset + d.delta.dx).clamp(
              -size.width,
              size.width,
            ),
          );
        },
        onHorizontalDragEnd: (d) {
          if (_dragOffset > size.width * 0.3 ||
              (d.primaryVelocity ?? 0) > 500) {
            context.go(AppRoutes.home);
          } else if (_dragOffset < -size.width * 0.3 ||
              (d.primaryVelocity ?? 0) < -500) {
            context.go(AppRoutes.banar);
          } else {
            setState(() => _dragOffset = 0);
          }
        },
        child: Container(
          color: _coloresPared.last,
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Column(
              children: [
                SafeArea(
                  top: false,
                  bottom: false,
                  child: ActionScreenHeader(
                    icon: Icons.bed,
                    title: _tituloModo,
                    subtitlePrefix: _subtituloModo,
                    statLabel: 'Energia:',
                    statSelector: (m) => m.nivelEnergia,
                    barColors: const [
                      Color(0xFF9B59B6),
                      AppColors.nivelEnergia,
                    ],
                  ),
                ),
                Expanded(child: _buildCuarto()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // CUARTO
  // ══════════════════════════════════════════════════════

  Widget _buildCuarto() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final size = Size(w, h);
        final worldState = context.watch<PetWorldCubit>().state;
        final canShowPet =
            !worldState.isLocationLocked ||
            worldState.location == PetLocation.dormir;

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Pared
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.6, -0.4),
                    radius: 1.3,
                    colors: _coloresPared,
                  ),
                ),
              ),
            ),
            // Piso
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: h * 0.35,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _coloresPiso,
                  ),
                ),
              ),
            ),
            // Rodapié
            Positioned(
              bottom: h * 0.35 - 6,
              left: 0,
              right: 0,
              height: 12,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                color: _coloresPiso.last.withValues(alpha: 0.6),
              ),
            ),
            // Alfombra
            Positioned(
              bottom: h * 0.12,
              left: w * 0.1,
              right: w * 0.1,
              child: _buildAlfombra(size),
            ),
            // Ventana
            Positioned(
              top: h * 0.08,
              left: w * 0.06,
              child: BlocBuilder<PetCubit, PetState>(
                builder: (context, state) {
                  final cortinasAbiertas =
                      state.mascota?.cortinasAbiertas ?? true;
                  return VentanaHabitacion(
                    horaSimulada: _horaDinamica,
                    isWindowOpen: cortinasAbiertas,
                    onWindowToggle: (abiertas) {
                      context.read<PetCubit>().setCortinasAbiertas(abiertas);
                    },
                  );
                },
              ),
            ),
            Positioned(
              top: h * 0.08 + 186,
              left: w * 0.06,
              width: 180,
              child: Align(
                alignment: Alignment.topCenter,
                child: _buildEstadoCortinasChip(),
              ),
            ),
            // Estante
            Positioned(top: h * 0.12, right: w * 0.06, child: _buildEstante()),
            // Armario de items (debajo del estante, pared derecha)
            Positioned(
              top: h * 0.189 + 78,   // justo debajo del estante
              right: w * 0.02,
              child: ArmarioWidget(
                maxHeight: (h * 0.65 - (h * 0.12 + 78)).clamp(100.0, 260.0),
              ),
            ),
            // Cama
            if (canShowPet)
              Positioned(
                bottom: h * 0.18,
                right: w * 0.06,
                child: _buildCama(),
              ),
            // Mascota
            if (canShowPet) _buildMascota(size),
            // Corazones
            if (canShowPet) ..._corazones.map(_buildCorazon),
            // Barra de acostar
            if (canShowPet && _progresoAcostar > 0) _buildBarraAcostar(),
            // Indicador contextual
            if (canShowPet) _buildIndicador(),
            // Banner persistente de dormido
            if (canShowPet)
              BlocBuilder<PetCubit, PetState>(
                builder: (context, state) {
                  final mascota = state.mascota;
                  final dormido = mascota?.estadoDescanso == 'dormido';

                  if (dormido && !_eraDormidaAntes) {
                    _eraDormidaAntes = true;
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) =>
                          _onSeDurmio(mascota?.nombreMascota ?? 'Tu mascota'),
                    );
                  } else if (!dormido) {
                    _eraDormidaAntes = false;
                  }

                  if (!dormido) return const SizedBox.shrink();
                  return _buildBannerDormido(
                    nombre: mascota?.nombreMascota ?? 'Tu mascota',
                    energia: mascota?.nivelEnergia ?? 0,
                    buffActivo: mascota?.buffActivo ?? false,
                  );
                },
              ),
            // Modal temporal (2.5 seg)
            if (canShowPet && _mostrarOverlayDormido)
              BlocBuilder<PetCubit, PetState>(
                builder: (context, state) => _buildModalDormido(
                  state.mascota?.nombreMascota ?? 'Tu mascota',
                ),
              ),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════
  // WIDGETS DEL CUARTO
  // ══════════════════════════════════════════════════════

  Widget _buildAlfombra(Size size) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF7B1FA2).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: const Color(0xFF9C27B0).withValues(alpha: 0.5),
          width: 3,
        ),
      ),
      child: Center(
        child: Container(
          width: size.width * 0.4,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildEstante() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Maceta
            Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 14,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.brown,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Libros
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(width: 8, height: 24, color: Colors.blue[300]),
                Container(width: 8, height: 28, color: Colors.red[300]),
                Container(width: 8, height: 20, color: Colors.amber[300]),
              ],
            ),
            const SizedBox(width: 12),
            // Lámpara
            Column(
              children: [
                Container(
                  width: 16,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                ),
                Container(width: 4, height: 8, color: Colors.grey[600]),
              ],
            ),
            const SizedBox(width: 10),
          ],
        ),
        // Tabla
        Container(
          width: 120,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF5D4037),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        // Soporte
        Container(
          width: 8,
          height: 35,
          margin: const EdgeInsets.only(right: 30),
          color: const Color(0xFF4E342E),
        ),
      ],
    );
  }

  Widget _buildCama() {
    return GestureDetector(
      onLongPressStart: _onBedLongPressStart,
      onLongPressEnd: _onBedLongPressEnd,
      child: SizedBox(
        width: 150,
        height: 80,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Base
            Container(
              width: 140,
              height: 65,
              decoration: BoxDecoration(
                color: const Color(0xFF5E35B1),
                borderRadius: BorderRadius.circular(35),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 8,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
            ),
            // Sombra interna
            Positioned(
              top: 20,
              child: Container(
                width: 120,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF311B92),
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
            // Cojín
            Positioned(
              top: 23,
              child: Container(
                width: 110,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFFB39DDB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Icon(
                    Icons.pets,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 20,
                  ),
                ),
              ),
            ),
            // Borde frontal 3D
            Positioned(
              bottom: 0,
              child: Container(
                width: 140,
                height: 25,
                decoration: const BoxDecoration(
                  color: Color(0xFF512DA8),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoCortinasChip() {
    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state) {
        final abiertas = state.mascota?.cortinasAbiertas ?? true;
        final texto = abiertas
            ? 'cortinas abiertas\ntoca para cerrarla'
            : 'cortinas cerradas\ntoca para abrirlas';
        final colorBorde = abiertas
            ? const Color(0xFFFFD54F)
            : const Color(0xFF80CBC4);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorBorde.withValues(alpha: 0.8)),
          ),
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        );
      },
    );
  }

  Widget _buildMascota(Size size) {
    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state) {
        final mascota = state.mascota;
        final descanso = mascota?.estadoDescanso ?? 'despierto';
        final mision = state.estadoMision;

        final rawEmoji = (mascota?.tipoMascota ?? 'perro') == 'gato'
            ? '\u{1F431}'
            : '\u{1F436}';
        final petEmoji = descanso == 'dormido' ? '\u{1F634}' : rawEmoji;

        final enCama =
            descanso == 'acostado' ||
            descanso == 'dormido' ||
            descanso == 'siesta';

        final alignment = mision == 'perro_rebelde'
            ? _petAlignment
            : enCama
            ? const Alignment(0.55, 0.55)
            : const Alignment(-0.5, 0.55);

        return AnimatedAlign(
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
          alignment: alignment,
          child: GestureDetector(
            onTap: _onPetTap,
            onPanUpdate: _onPetPanUpdate,
            child: AnimatedBuilder(
              animation: _petFloat,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, descanso == 'dormido' ? 0 : _petFloat.value),
                child: child,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Text(petEmoji, style: const TextStyle(fontSize: 90)),

                  if (descanso == 'dormido')
                    const Positioned(
                      top: -20,
                      right: -10,
                      child: Text('\u{1F4A4}', style: TextStyle(fontSize: 28)),
                    ),

                  if (descanso == 'acostado' && state.cariciasTotal > 0)
                    Positioned(
                      bottom: -18,
                      left: -10,
                      right: -10,
                      child: _buildBarraCaricias(
                        state.cariciasHechas,
                        state.cariciasTotal,
                      ),
                    ),

                  if ((descanso == 'dormido' || descanso == 'siesta') &&
                      state.tapsDespertar > 0)
                    Positioned(
                      bottom: -18,
                      left: -10,
                      right: -10,
                      child: _buildBarraTaps(
                        state.tapsDespertar,
                        mascota?.tapsParaDespetarBase ?? 4,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCorazon(_Corazon c) {
    return Positioned(
      left: c.posicion.dx - 12,
      top: c.posicion.dy - 50,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(c.id),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        builder: (_, v, _) => Opacity(
          opacity: 1 - v,
          child: Transform.translate(
            offset: Offset(0, -v * 40),
            child: const Icon(
              Icons.favorite,
              color: Colors.redAccent,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarraCaricias(int hechas, int total) {
    return Column(
      children: [
        Text(
          'Caricias $hechas/$total',
          style: const TextStyle(color: Colors.white70, fontSize: 9),
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total > 0 ? hechas / total : 0,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEC407A)),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildBarraTaps(int taps, int base) {
    return Column(
      children: [
        const Text(
          'Despertando...',
          style: TextStyle(color: Colors.white70, fontSize: 9),
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: base > 0 ? taps / base : 0,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD54F)),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildBarraAcostar() {
    return Positioned(
      bottom: 40,
      left: 40,
      right: 40,
      child: Column(
        children: [
          const Text(
            'Llevando a la cama...',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progresoAcostar,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF9B59B6),
              ),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicador() {
    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state) {
        final mascota = state.mascota;
        final descanso = state.mascota?.estadoDescanso ?? 'despierto';
        final mision = state.estadoMision;

        if (descanso == 'dormido') return const SizedBox.shrink();

        final texto = switch (mision) {
          'perro_rebelde' =>
            'No quiere acostarse.\nTocala varias veces para calmarla.',
          'rebelde_escapado' =>
            'Se escapo.\nBuscala en otras pantallas y calmala.',
          _ => switch (descanso) {
            'despierto' =>
              _esNoche
                  ? 'Manten presionada la cama para acostarla.'
                  : (mascota?.cortinasAbiertas ?? true)
                  ? 'Toca la ventana para cerrar cortinas,\ny luego manten presionada la cama.'
                  : 'Manten presionada la cama\npara iniciar la siesta.',
            'acostado' =>
              state.cariciasTotal > 0
                  ? ((mascota?.tipoDescanso ?? '') == 'siesta'
                        ? 'Desliza sobre tu mascota para que se duerma la siesta.'
                        : 'Desliza sobre tu mascota\npara dormirla por la noche.')
                  : 'Descansando...\nCuando quieras, toca para despertarla.',
            'siesta' =>
              (mascota?.cortinasAbiertas ?? true)
                  ? 'Siesta activa.\nToca varias veces para despertarla.'
                  : 'Siesta activa.\nAbre cortinas para poder despertarla.',
            _ => '',
          },
        };

        if (texto.isEmpty) return const SizedBox.shrink();

        return Positioned(
          bottom: 28,
          left: 16,
          right: 16,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                texto,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════
  // OVERLAYS DE DORMIDO
  // ══════════════════════════════════════════════════════

  Widget _buildModalDormido(String nombre) {
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _mostrarOverlayDormido ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 400),
        child: Container(
          color: Colors.black.withValues(alpha: 0.55),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0A3B).withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF9B59B6).withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('\u{1F4A4}', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 12),
                  Text(
                    '$nombre esta dormido',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'No interrumpas su sueno profundo',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerDormido({
    required String nombre,
    required int energia,
    required bool buffActivo,
  }) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0A3B).withValues(alpha: 0.88),
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF9B59B6).withValues(alpha: 0.4),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            const Text('\u{1F4A4}', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$nombre esta dormido',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'No interrumpas su sueno profundo',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$energia%',
                  style: const TextStyle(
                    color: Color(0xFF9B59B6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 70,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: energia / 100,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF9B59B6),
                      ),
                      minHeight: 5,
                    ),
                  ),
                ),
                if (buffActivo)
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Text(
                      'Buff activo',
                      style: TextStyle(color: Color(0xFFFFD54F), fontSize: 9),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Corazon {
  final int id;
  final Offset posicion;
  const _Corazon({required this.id, required this.posicion});
}
