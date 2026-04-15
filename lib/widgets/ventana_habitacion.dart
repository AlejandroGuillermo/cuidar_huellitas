import 'package:flutter/material.dart';
import 'dart:math' as math;

enum CieloModo { manana, tarde, noche }

class VentanaHabitacion extends StatefulWidget {
  final DateTime? horaSimulada; // Opcional, por si quieres forzar una hora de prueba

  const VentanaHabitacion({super.key, this.horaSimulada});

  @override
  State<VentanaHabitacion> createState() => _VentanaHabitacionState();
}

class _VentanaHabitacionState extends State<VentanaHabitacion> {
  bool _isWindowOpen = true;

  CieloModo _obtenerModo() {
    final hora = (widget.horaSimulada ?? DateTime.now()).hour;

    // Puedes ajustar estos horarios como prefieras
    if (hora >= 6 && hora < 13) return CieloModo.manana;
    if (hora >= 13 && hora < 20) return CieloModo.tarde;
    return CieloModo.noche;
  }

  // Llamamos al widget correcto según el modo
  Widget _obtenerCieloWidget(CieloModo modo, DateTime horaActual) {
    switch (modo) {
      case CieloModo.manana:
        return _CieloManana(horaActual: horaActual); // Podríamos hacer que el sol suba aquí después!
      case CieloModo.tarde:
        return _CieloTarde(horaActual: horaActual); // ¡Pasamos la hora aquí!
      case CieloModo.noche:
        return _CieloNoche(horaActual: horaActual); // La noche no necesita la hora para su animación
    }
  }

  @override
  Widget build(BuildContext context) {
    final horaActual = widget.horaSimulada ?? DateTime.now();
    final modo = _obtenerModo();

    return GestureDetector(
      onTap: () => setState(() => _isWindowOpen = !_isWindowOpen),
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          // El marco de madera
          border: Border.all(color: Colors.brown[300]!, width: 8),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(
            children: [
              // 1. Fondo del Cielo Dinámico (Se llena todo el cuadro de la ventana)
              Positioned.fill(
                child: _obtenerCieloWidget(modo, horaActual), // Pasamos la hora actual para que el atardecer se anime
              ),

              // 2. Rejillas de la ventana
              Center(child: Container(width: 4, color: Colors.brown[300])),
              Center(child: Container(height: 4, color: Colors.brown[300])),

              // 3. Cortina Izquierda
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                top: 0,
                bottom: 0,
                left: 0,
                width: _isWindowOpen ? 25 : 90,
                child: _buildCortina(isLeft: true),
              ),

              // 4. Cortina Derecha
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                top: 0,
                bottom: 0,
                right: 0,
                width: _isWindowOpen ? 25 : 90,
                child: _buildCortina(isLeft: false),
              ),

              // 5. Cortinero superior
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.brown[800],
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 2))
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCortina({required bool isLeft}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLeft
              ? [Colors.red[300]!, Colors.red[600]!, Colors.red[400]!, Colors.red[700]!]
              : [Colors.red[700]!, Colors.red[400]!, Colors.red[600]!, Colors.red[300]!],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
        border: Border(
          right: isLeft ? BorderSide(color: Colors.red[900]!, width: 2) : BorderSide.none,
          left: !isLeft ? BorderSide(color: Colors.red[900]!, width: 2) : BorderSide.none,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(isLeft ? 3 : -3, 0),
          )
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── WIDGETS DE LOS CIELOS (MAÑANA, TARDE, NOCHE)
// ─────────────────────────────────────────────────────────────────────────────

class _CieloManana extends StatefulWidget {
  final DateTime horaActual;
  const _CieloManana({required this.horaActual});

  @override
  State<_CieloManana> createState() => _CieloMananaState();
}

class _CieloMananaState extends State<_CieloManana> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _calcularPosicionSol() {
    const double minutosTotalesManana = 7 * 60;
    int minutosActuales = ((widget.horaActual.hour - 6) * 60) + widget.horaActual.minute;
    minutosActuales = minutosActuales.clamp(0, minutosTotalesManana.toInt());

    double progreso = minutosActuales / minutosTotalesManana;
    const double posicionBaja = 170.0; 
    const double posicionAlta = 10.0;

    return posicionBaja - ((posicionBaja - posicionAlta) * progreso);
  }

  // ── NUEVA Lógica de Fases para la Mañana ──
  List<Color> _calcularColoresCielo() {
    int minutosDesdeLas6 = ((widget.horaActual.hour - 6) * 60) + widget.horaActual.minute;

    // Paletas de color
    const nocheTop = Color(0xFF0F2027);
    const nocheBottom = Color(0xFF203A43);
    
    const naranjaTop = Color(0xFFFFA07A); 
    const naranjaBottom = Color(0xFFFFDAB9);
    
    const diaTop = Color(0xFF6DD5FA);
    const diaBottom = Color(0xFFFFFFFF);

    if (minutosDesdeLas6 < 120) {
      // Fase 1: 6:00 a 8:00 (Noche a Naranja)
      double progreso = minutosDesdeLas6 / 120.0;
      return [
        Color.lerp(nocheTop, naranjaTop, progreso)!,
        Color.lerp(nocheBottom, naranjaBottom, progreso)!,
      ];
    } else if (minutosDesdeLas6 < 240) {
      // Fase 2: 8:00 a 10:00 (Naranja a Celeste Día)
      double progreso = (minutosDesdeLas6 - 120) / 120.0;
      return [
        Color.lerp(naranjaTop, diaTop, progreso)!,
        Color.lerp(naranjaBottom, diaBottom, progreso)!,
      ];
    } else {
      // Fase 3: 10:00 en adelante (Celeste Día constante)
      return const [diaTop, diaBottom];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _calcularColoresCielo(),
        ),
      ),
      child: Stack(
        children: [
          _buildSol(topPosition: _calcularPosicionSol()),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => _buildNubesAnimadas(),
          ),
        ],
      ),
    );
  }

  Widget _buildSol({required double topPosition}) {
    return Positioned(
      top: topPosition,
      right: 30,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFFFFDE4), Color(0xFFFFD700)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 8,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNubesAnimadas() {
    final double nube1X = 200 - (_controller.value * 300);
    final double avanceNube2 = (_controller.value + 0.5) % 1.0;
    final double nube2X = 200 - (avanceNube2 * 250);

    return Stack(
      children: [
        Positioned(
          top: 70,
          left: nube2X,
          child: const Opacity(
            opacity: 0.6,
            child: Text('☁️', style: TextStyle(fontSize: 24)),
          ),
        ),
        Positioned(
          top: 35,
          left: nube1X,
          child: const Opacity(
            opacity: 0.9,
            child: Text('☁️', style: TextStyle(fontSize: 36)),
          ),
        ),
      ],
    );
  }
}

// ---Cielo de la tarde con sol que baja y nubes que se mueven constantemente---
class _CieloTarde extends StatefulWidget {
  final DateTime horaActual;
  const _CieloTarde({required this.horaActual});

  @override
  State<_CieloTarde> createState() => _CieloTardeState();
}

class _CieloTardeState extends State<_CieloTarde> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat(); 
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _calcularColoresTarde() {
    int minDesde13 = ((widget.horaActual.hour - 13) * 60) + widget.horaActual.minute;
    const azulDia = [Color(0xFF6DD5FA), Color(0xFFFFFFFF)];
    const sunset = [Color(0xFF2E1C2B), Color(0xFFE94E65), Color(0xFFF9A06F)];
    const noche = [Color(0xFF0F2027), Color(0xFF203A43)];

    if (minDesde13 < 180) return azulDia; // 1pm - 4pm
    if (minDesde13 < 300) { // 4pm - 6pm (Cielo tornando a naranja)
      double p = (minDesde13 - 180) / 120.0;
      return [Color.lerp(azulDia[0], sunset[0], p)!, Color.lerp(azulDia[1], sunset[2], p)!];
    }
    if (minDesde13 < 330) return sunset; // 6pm - 6:30pm
    if (minDesde13 < 420) { // 6:30pm - 8pm (Transición a noche)
      double p = (minDesde13 - 330) / 90.0;
      return [Color.lerp(sunset[0], noche[0], p)!, Color.lerp(sunset[2], noche[1], p)!];
    }
    return noche;
  }

  List<Color> _calcularColoresSol() {
    int minDesde13 = ((widget.horaActual.hour - 13) * 60) + widget.horaActual.minute;
    const solDia = [Color(0xFFFFFDE4), Color(0xFFFFD700)];
    const solAtardecer = [Color(0xFFFFD26F), Color(0xFFE64A19)];

    if (minDesde13 < 270) return solDia; // 🌟 Empieza a cambiar a las 17:30
    if (minDesde13 < 360) { // Transición de 17:30 a 19:00
      double p = (minDesde13 - 270) / 90.0;
      return [Color.lerp(solDia[0], solAtardecer[0], p)!, Color.lerp(solDia[1], solAtardecer[1], p)!];
    }
    return solAtardecer;
  }

  double _calcularPosicionSol() {
    int minDesde16 = ((widget.horaActual.hour - 16) * 60) + widget.horaActual.minute;
    double progreso = (minDesde16 / 240.0).clamp(0.0, 1.0); 
    return 10.0 + (175.0 * progreso); 
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _calcularColoresTarde(),
        ),
      ),
      child: Stack(
        children: [
          _buildSol(topPosition: _calcularPosicionSol()),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => _buildNubesAnimadas(),
          ),
        ],
      ),
    );
  }

  Widget _buildSol({required double topPosition}) {
    final coloresSol = _calcularColoresSol();
    return Positioned(
      top: topPosition,
      right: 30,
      child: Container(
        width: 45, height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: coloresSol),
          boxShadow: [
            BoxShadow(color: coloresSol[1].withValues(alpha: .6), blurRadius: 20, spreadRadius: 8)
          ],
        ),
      ),
    );
  }

  Widget _buildNubesAnimadas() {
    final double nube1X = 200 - (_controller.value * 300);
    final double avanceNube2 = (_controller.value + 0.5) % 1.0;
    final double nube2X = 200 - (avanceNube2 * 250);
    return Stack(children: [
      Positioned(top: 70, left: nube2X, child: const Opacity(opacity: 0.6, child: Text('☁️', style: TextStyle(fontSize: 24)))),
      Positioned(top: 35, left: nube1X, child: const Opacity(opacity: 0.9, child: Text('☁️', style: TextStyle(fontSize: 36)))),
    ]);
  }
}

//---Cielo de la noche con luna que baja y estrellas que parpadean constantemente---
class _CieloNoche extends StatefulWidget {
  final DateTime horaActual;
  const _CieloNoche({required this.horaActual});

  @override
  State<_CieloNoche> createState() => _CieloNocheState();
}

// ⚠️ CAMBIO: Usamos TickerProviderStateMixin para manejar 2 controladores
class _CieloNocheState extends State<_CieloNoche> with TickerProviderStateMixin {
  
  // Controlador 1: Parpadeo RÁPIDO de estrellas
  late AnimationController _controllerStars;
  // Controlador 2: Movimiento LENTO de nubes
  late AnimationController _controllerClouds;

  @override
  void initState() {
    super.initState();

    // Configuración Estrellas (4 segundos)
    _controllerStars = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Configuración Nubes (30 segundos) - 🌟 NUEVO
    _controllerClouds = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    // ⚠️ CRÍTICO: Limpiar ambos controladores
    _controllerStars.dispose();
    _controllerClouds.dispose(); 
    super.dispose();
  }

  // (Lógica de Tiempo, Posición Luna y Opacidad Luna se mantienen IGUALES)
  // ─────────────────────────────────────────────────────────────────────────────
  int _obtenerMinutosDesde20() {
    if (widget.horaActual.hour >= 20) {
      return ((widget.horaActual.hour - 20) * 60) + widget.horaActual.minute;
    } else {
      return 240 + (widget.horaActual.hour * 60) + widget.horaActual.minute;
    }
  }

  double _calcularPosicionLuna() {
    int minDesde20 = _obtenerMinutosDesde20();
    if (minDesde20 < 240) {
      double progreso = minDesde20 / 240.0;
      return 160.0 - (115.0 * progreso); // Sale desde abajo (130) hacia arriba (15)
    }
    return 15.0; // Se queda arriba después de medianoche
  }

  double _calcularOpacidadLuna() {
    int minDesde20 = _obtenerMinutosDesde20();
    // Empieza a desvanecerse a las 4:30 AM (510 min) hasta las 6:00 AM (600 min)
    if (minDesde20 >= 510) {
      double progresoFade = (minDesde20 - 510) / 90.0;
      return (1.0 - progresoFade).clamp(0.0, 1.0);
    }
    return 1.0; 
  }

  // ── Lógica de Opacidad para Estrellas y Nubes ──
  double _calcularOpacidadEstrellasYNubes() {
    int minDesde20 = _obtenerMinutosDesde20();

    // 1. De 8:00 PM a 12:00 AM (0 a 240 min) -> Aparecen gradualmente
    if (minDesde20 < 240) {
      return (minDesde20 / 240.0).clamp(0.0, 1.0); // Va de 0.0 a 1.0
    }

    // 2. De 4:30 AM a 6:00 AM (510 a 600 min) -> Se desvanecen al amanecer
    if (minDesde20 >= 510) {
      double progresoFade = (minDesde20 - 510) / 90.0;
      return (1.0 - progresoFade).clamp(0.0, 1.0);
    }

    // 3. De 12:00 AM a 4:30 AM -> Totalmente visibles
    return 1.0; 
  }
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // La luna siempre es visible al inicio, solo se apaga al amanecer
    final opacidadLuna = _calcularOpacidadLuna(); 
    
    // Las estrellas/nubes empiezan invisibles, se encienden al inicio, y se apagan al amanecer
    final opacidadCielo = _calcularOpacidadEstrellasYNubes();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F2027), Color(0xFF203A43)],
        ),
      ),
      child: Stack(
        children: [
          // 1. La Luna (Le pasamos su propia opacidad)
          _buildLuna(opacidadLuna),

          // 2. Las Estrellas Parpadeantes
          AnimatedBuilder(
            animation: _controllerStars,
            builder: (context, child) {
              return Stack(
                children: [
                  // ⚠️ Le pasamos opacidadCielo a baseOpacity
                  _buildEstrella(top: 25, left: 20, size: 16, delay: 0.0, baseOpacity: opacidadCielo),
                  _buildEstrella(top: 70, left: 40, size: 12, delay: 0.3, baseOpacity: opacidadCielo),
                  _buildEstrella(top: 100, right: 60, size: 14, delay: 0.6, baseOpacity: opacidadCielo),
                  _buildEstrella(top: 40, right: 70, size: 10, delay: 0.8, isSparkle: true, baseOpacity: opacidadCielo),
                ],
              );
            },
          ),

          // 3. Las Nubes Animadas
          AnimatedBuilder(
            animation: _controllerClouds,
            builder: (context, child) => _buildNubesAnimadas(opacidadCielo),
          ),
        ],
      ),
    );
  }

  // (Métodos _buildLuna y _buildEstrella con ligeros ajustes de opacidad)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildLuna(double opacidad) {
    return Positioned(
      top: _calcularPosicionLuna(),
      right: 15,
      child: Opacity(
        opacity: opacidad,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.26 * opacidad), 
                blurRadius: 35,
                spreadRadius: 8,
              )
            ],
          ),
          child: const Text('🌙', style: TextStyle(fontSize: 50)),
        ),
      ),
    );
  }

  Widget _buildEstrella({
    required double top,
    double? left,
    double? right,
    required double size,
    required double delay,
    required double baseOpacity, // Pasamos la opacidad general de la noche
    bool isSparkle = false,
  }) {
    final double curva = math.sin((_controllerStars.value * 2 * math.pi) + (delay * 2 * math.pi));
    // Brillo parpadeante
    final double opacidadParpadeo = 0.2 + (((curva + 1) / 2) * 0.8);

    // Multiplicamos parpadeo * opacidad base de la noche para que se apaguen al amanecer
    final double opacidadFinal = opacidadParpadeo * baseOpacity;

    return Positioned(
      top: top, left: left, right: right,
      child: Opacity(
        opacity: opacidadFinal,
        child: Text(isSparkle ? '✨' : '⭐', style: TextStyle(fontSize: size)),
      ),
    );
  }
  // ─────────────────────────────────────────────────────────────────────────────

  // ── Generador de Nubes Nocturnas
  Widget _buildNubesAnimadas(double baseOpacity) {
    // Lógica de movimiento igual a los otros cielos
    final double nube1X = 200 - (_controllerClouds.value * 300);
    final double avanceNube2 = (_controllerClouds.value + 0.5) % 1.0;
    final double nube2X = 200 - (avanceNube2 * 250);

    return Opacity(
      // Se apagan al amanecer junto con la noche
      opacity: baseOpacity,
      child: Stack(
        children: [
          // Nube al fondo (Más pequeña y transparente)
          Positioned(
            top: 70,
            left: nube2X,
            child: Opacity(
              opacity: 0.3, // Muy sutil de noche
              child: Text(
                '☁️', 
                // Aplicamos un tinte gris azulado para que no brillen mucho
                style: TextStyle(fontSize: 24, color: Colors.blueGrey[200]), 
              ),
            ),
          ),
          // Nube al frente (Más grande)
          Positioned(
            top: 35,
            left: nube1X,
            child: Opacity(
              opacity: 0.5,
              child: Text(
                '☁️', 
                style: TextStyle(fontSize: 36, color: Colors.blueGrey[100]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}