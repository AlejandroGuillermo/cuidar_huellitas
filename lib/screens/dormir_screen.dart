import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_router.dart';
import '../cubit/pet_cubit.dart';
import '../cubit/pet_state.dart';
import '../widgets/action_screen_header.dart';
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
  double _dragOffset = 0;

  // ── Estado del cuarto ──────────────────────────────────
  bool _isPetInBed = false; // mascota en la cama
  bool _isWalking = false; // caminando hacia la cama
  bool _isDormida = false; // completamente dormida
  bool _guardando = false;

  // ── Variables para el Tiempo Real ──
  DateTime _horaDinamica = DateTime(2023, 1, 1, 19, 40);
  Timer? _timerHora;

  // ── Mecánica de acariciar ──────────────────────────────
  int _cariciasNecesarias = 0;
  int _cariciasHechas = 0;
  List<_Corazon> _corazones = [];
  final Random _rng = Random();

  // ── Mantener presionado para acostarse ────────────────
  double _progresoAcostar = 0.0;
  Timer? _timerAcostar;

  // ── Animaciones ────────────────────────────────────────
  late AnimationController _petFloatCtrl;
  late AnimationController _corazonCtrl;
  late Animation<double> _petFloat;

  @override
  void initState() {
    super.initState();

    _timerHora = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _horaDinamica = _horaDinamica.add(const Duration(minutes: 10));
        });
      }
    });

    _petFloatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _corazonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _petFloat = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _petFloatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timerHora?.cancel();
    _timerAcostar?.cancel();
    _petFloatCtrl.dispose();
    _corazonCtrl.dispose();
    super.dispose();
  }

  // ── Modo hora actual ───────────────────────────────────
  _ModoHora get _modo {
    final h = _horaDinamica.hour;
    if (h >= 6 && h < 13) return _ModoHora.manana;
    if (h >= 13 && h < 20) return _ModoHora.tarde;
    return _ModoHora.noche;
  }

  // ── Iluminación del cuarto (Degradados simulando la ventana) ──
  List<Color> get _coloresPared {
    switch (_modo) {
      case _ModoHora.manana:
        return [const Color(0xFFFFF8E1), const Color(0xFFD7CCC8)]; // Luz cálida
      case _ModoHora.tarde:
        return [const Color(0xFFFFCC80), const Color(0xFFBCAAA4)]; // Atardecer naranja
      case _ModoHora.noche:
        return [const Color(0xFF455A64), const Color(0xFF1C2331)]; // Luz de luna tenue
    }
  }

  List<Color> get _coloresPiso {
    switch (_modo) {
      case _ModoHora.manana:
        return [const Color(0xFFBCAAA4), const Color(0xFFA1887F)];
      case _ModoHora.tarde:
        return [const Color(0xFF8D6E63), const Color(0xFF6D4C41)];
      case _ModoHora.noche:
        return [const Color(0xFF263238), const Color(0xFF10141C)];
    }
  }

  // ── Mecánicas ──────────────────────────────────────────
  void _onBedLongPressStart(LongPressStartDetails _) {
    if (_isPetInBed || _isWalking) return;
    _timerAcostar = Timer.periodic(const Duration(milliseconds: 60), (t) {
      setState(() {
        _progresoAcostar = (_progresoAcostar + 0.03).clamp(0, 1);
        if (_progresoAcostar >= 1.0) {
          t.cancel();
          _acostarse();
        }
      });
    });
  }

  void _onBedLongPressEnd(LongPressEndDetails _) {
    _timerAcostar?.cancel();
    if (!_isPetInBed) setState(() => _progresoAcostar = 0);
  }

  void _acostarse() {
    setState(() {
      _isWalking = true;
      _progresoAcostar = 0;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _isWalking = false;
        _isPetInBed = true;
      });

      final rasgo = context.read<PetCubit>().state.mascota?.rasgo ?? '';
      final esCarinoso = rasgo.toLowerCase() == 'cariñoso';
      final base = 5 + _rng.nextInt(6);
      setState(() {
        _cariciasNecesarias = esCarinoso ? base * 2 : base;
      });
    });
  }

  void _onPetPanUpdate(DragUpdateDetails details) {
    if (!_isPetInBed || _isDormida || _modo != _ModoHora.noche) return;

    if (details.delta.distance > 3) {
      _cariciasHechas++;
      _agregarCorazon(details.localPosition);

      if (_cariciasHechas >= _cariciasNecesarias) {
        _dormirse();
      }
    }
  }

  void _agregarCorazon(Offset pos) {
    setState(() {
      _corazones.add(_Corazon(
        id: DateTime.now().microsecondsSinceEpoch,
        posicion: pos,
        offset: 0,
      ));
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _corazones.removeWhere((c) => c.posicion == pos);
        });
      }
    });
  }

  Future<void> _dormirse() async {
    if (_isDormida) return;
    setState(() {
      _isDormida = true;
      _guardando = true;
    });
    await context.read<PetCubit>().dormir();
    if (mounted) setState(() => _guardando = false);
  }

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
        child: Container(
          // Fondo base para que no se vea blanco al arrastrar
          color: _coloresPared.last,
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: _buildCuerpoPrincipal(size),
          ),
        ),
      ),
    );
  }

  // ── NUEVO: Estructura integrada ───────────────────────
  Widget _buildCuerpoPrincipal(Size size) {
    return Column(
      children: [
        SafeArea(
          top: false,
          bottom: false,
          child: ActionScreenHeader(
            icon: Icons.bed,
            title: _tituloModo,
            subtitlePrefix: _subtituloModo,
            statLabel: 'Energía:',
            statSelector: (m) => m.nivelEnergia,
            barColors: const [Color(0xFF9B59B6), AppColors.nivelEnergia],
          ),
        ),
        // El cuarto se expande para usar el resto de la pantalla
        Expanded(
          child: _buildCuarto(),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════
  // CUARTO UI (100% Responsive)
  // ══════════════════════════════════════════════════════
  Widget _buildCuarto() { // ⚠️ Ya no recibe (Size size) como parámetro
    return LayoutBuilder(
      builder: (context, constraints) {
        // Obtenemos el ancho y alto EXACTO del espacio que dejó el Header
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        
        // Creamos un Size local para pasárselo a la mascota y otros widgets sin romper nada
        final size = Size(width, height);

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // ── 1. Pared (Fondo) ──────────────────────────────
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
            
            // ── 2. Piso ───────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: height * 0.35, // Usamos 'height' local
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
            
            // ── 3. Rodapié ────────────────────────────────────
            Positioned(
              bottom: height * 0.35 - 6, // Usamos 'height' local
              left: 0,
              right: 0,
              height: 12,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                color: _coloresPiso.last.withValues(alpha: 0.6),
              ),
            ),

            // ── 4. Alfombra ───────────────────────────────────
            Positioned(
              bottom: height * 0.12, 
              left: width * 0.1,
              right: width * 0.1,
              child: _buildAlfombra(size),
            ),

            // ── 5. Ventana ────────────────────────────────────
            Positioned(
              top: height * 0.08, 
              left: width * 0.06,
              child: VentanaHabitacion(horaSimulada: _horaDinamica),
            ),

            // ── 6. Estante Decorativo ─────────────────────────
            Positioned(
              top: height * 0.12, 
              right: width * 0.06,
              child: _buildEstante(),
            ),

            // ── 7. Cama ───────────────────────────────────────
            Positioned(
              bottom: height * 0.18, 
              right: width * 0.06,
              child: _buildCama(),
            ),

            // ── 8. Mascota y Efectos ──────────────────────────
            _buildMascota(size),
            
            ..._corazones.map((c) => _buildCorazon(c)),
            if (_progresoAcostar > 0 && !_isPetInBed) _buildBarraAcostar(size),
            _buildIndicador(size),
            if (_isDormida) _buildOverlayDormido(size),
          ],
        );
      },
    );
  }

  // ── Alfombra ────────────────────────────────────────────
  Widget _buildAlfombra(Size size) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF7B1FA2).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: const Color(0xFF9C27B0).withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: size.width * 0.35,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  // ── Estante decorativo (Sin Emojis) ────────────────────
  Widget _buildEstante() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Objetos sobre el estante construidos con Containers
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Maceta con planta
            Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                      color: Colors.green, shape: BoxShape.circle),
                ),
                Container(
                  width: 14,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.brown,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Libros apilados
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(width: 8, height: 24, color: Colors.blue[300]),
                Container(width: 8, height: 28, color: Colors.red[300]),
                Container(width: 8, height: 20, color: Colors.amber[300]),
              ],
            ),
            const SizedBox(width: 12),
            // Pequeña lámpara
            Column(
              children: [
                Container(
                  width: 16,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                ),
                Container(width: 4, height: 8, color: Colors.grey[600]),
              ],
            ),
            const SizedBox(width: 10),
          ],
        ),
        // Tabla del estante
        Container(
          width: 120,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF5D4037),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 4, offset: Offset(0, 3))
            ],
          ),
        ),
        // Soporte del estante
        Container(
          width: 8,
          height: 35,
          margin: const EdgeInsets.only(right: 30),
          color: const Color(0xFF4E342E),
        ),
      ],
    );
  }

  // ── Cama de Mascota ───────────────────────────────────────────────
  Widget _buildCama() {
    return GestureDetector(
      onLongPressStart: _onBedLongPressStart,
      onLongPressEnd: _onBedLongPressEnd,
      child: SizedBox(
        width: 150,
        height: 80, // Proporción más ancha y baja
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // 1. Borde exterior de la cama (La base completa)
            Container(
              width: 140,
              height: 65,
              decoration: BoxDecoration(
                color: const Color(0xFF5E35B1), // Morado principal
                borderRadius: BorderRadius.circular(35), // Forma ovalada
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 8,
                    offset: Offset(0, 6),
                  )
                ],
              ),
            ),
            
            // 2. Fondo interno (crea el efecto de profundidad)
            Positioned(
              top: 20,
              child: Container(
                width: 120,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF311B92), // Morado muy oscuro para la sombra interna
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),

            // 3. Cojín central suave (Donde se acuesta la mascota)
            Positioned(
              top: 23,
              child: Container(
                width: 110,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFFB39DDB), // Morado claro y acolchonado
                  borderRadius: BorderRadius.circular(20),
                ),
                // Un pequeño detalle decorativo en el centro del cojín
                child: Center(
                  child: Icon(
                    Icons.pets,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 20,
                  ),
                ),
              ),
            ),

            // 4. Borde frontal (Ayuda a dar el efecto 3D de que el cojín está hundido)
            Positioned(
              bottom: 0,
              child: Container(
                width: 140,
                height: 25,
                decoration: const BoxDecoration(
                  color: Color(0xFF512DA8), // Tono intermedio
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

  // ── Mascota ─────────────────────────────────────────────
  Widget _buildMascota(Size size) {
    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state) {
        final emoji = (state.mascota?.tipoMascota ?? 'perro') == 'gato' ? '🐱' : '🐶';

        return AnimatedAlign(
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
          alignment: _isPetInBed || _isWalking
              ? const Alignment(0.55, 0.55)
              : const Alignment(-0.5, 0.55),
          child: GestureDetector(
            onPanUpdate:
                (_isPetInBed && !_isDormida && _modo == _ModoHora.noche)
                    ? _onPetPanUpdate
                    : null,
            child: AnimatedBuilder(
              animation: _petFloat,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _isDormida ? 0 : _petFloat.value),
                child: child,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Rotar ligeramente a la mascota para simular que está acostada si está dormida
                  AnimatedRotation(
                    turns: _isDormida ? -0.15 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Text(emoji, style: const TextStyle(fontSize: 90)),
                  ),
                  
                  // Efecto de Zzz (Texto en lugar de Emoji)
                  if (_isDormida)
                    const Positioned(
                      top: -15,
                      right: -20,
                      child: Text('Zzz',
                          style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic)),
                    ),
                    
                  // Barra de progreso caricias
                  if (_isPetInBed &&
                      !_isDormida &&
                      _modo == _ModoHora.noche &&
                      _cariciasNecesarias > 0)
                    Positioned(
                      bottom: -18,
                      left: -10,
                      right: -10,
                      child: _buildBarraCaricias(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBarraCaricias() {
    final progreso = (_cariciasHechas / _cariciasNecesarias).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: progreso,
        backgroundColor: Colors.white24,
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEC407A)),
        minHeight: 8,
      ),
    );
  }

  // ── Corazón flotante (Usa Icon en lugar de Emoji) ──────
  Widget _buildCorazon(_Corazon c) {
    return Positioned(
      left: c.posicion.dx - 12,
      top: c.posicion.dy - 40,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(c.id),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        builder: (context, v, child) => Opacity(
          opacity: 1 - v,
          child: Transform.translate(
            offset: Offset(0, -v * 40),
            child: const Icon(Icons.favorite, color: Colors.redAccent, size: 28),
          ),
        ),
      ),
    );
  }

  // ── Barra de acostar ───────────────────────────────────
  Widget _buildBarraAcostar(Size size) {
    return Positioned(
      bottom: 40,
      left: 40,
      right: 40,
      child: Column(
        children: [
          const Text('Llevando a la cama...',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progresoAcostar,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF9B59B6)),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ── Indicador contextual ───────────────────────────────
  Widget _buildIndicador(Size size) {
    String texto = '';
    if (_isDormida) return const SizedBox.shrink();

    if (!_isPetInBed && !_isWalking) {
      texto = _modo == _ModoHora.noche
          ? 'Mantén presionada la cama\npara acostar a tu mascota'
          : 'Mantén presionada la cama\npara que descanse un rato';
    } else if (_isPetInBed && _modo == _ModoHora.noche) {
      texto = '¡Desliza sobre tu mascota\npara acariciarla!';
    } else if (_isPetInBed && _modo != _ModoHora.noche) {
      texto = 'Descansando...\n(Solo en la noche puede dormir)';
    }

    if (texto.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
      ),
    );
  }

  // ── Overlay dormido ────────────────────────────────────
  Widget _buildOverlayDormido(Size size) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0A3B).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: const Color(0xFF9B59B6).withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bedtime, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                Text(
                  _modo == _ModoHora.noche
                      ? '¡${_nombreMascota()} está durmiendo!'
                      : '¡${_nombreMascota()} está descansando!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  _modo == _ModoHora.noche
                      ? 'Recuperó toda su energía. ¡Buen trabajo!'
                      : 'Descansó un rato. La energía sube poco a poco.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 20),
                if (_guardando)
                  const CircularProgressIndicator(color: Color(0xFF9B59B6))
                else
                  ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.home),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B59B6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.home, color: Colors.white),
                    label: const Text('Volver al inicio',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────
  String get _tituloModo => switch (_modo) {
        _ModoHora.manana => 'Buenos días',
        _ModoHora.tarde => 'Buenas tardes',
        _ModoHora.noche => 'Hora de dormir',
      };

  String get _subtituloModo => switch (_modo) {
        _ModoHora.manana => '¡Descansa un rato,',
        _ModoHora.tarde => '¡Siesta para',
        _ModoHora.noche => '¡A dormir,',
      };

  String _nombreMascota() =>
      context.read<PetCubit>().state.mascota?.nombreMascota ?? 'Tu mascota';
}

// ── Modelo de corazón flotante ─────────────────────────────
class _Corazon {
  final int id;
  final Offset posicion;
  double offset;
  _Corazon({required this.id, required this.posicion, required this.offset});
}
