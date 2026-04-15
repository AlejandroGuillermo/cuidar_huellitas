import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_router.dart';
import '../widgets/action_screen_header.dart';
import '../widgets/paw_map_widget.dart';
import '../widgets/ventana_habitacion.dart';

class DormirScreen extends StatefulWidget {
  const DormirScreen({super.key});

  @override
  State<DormirScreen> createState() => _DormirScreenState();
}

class _DormirScreenState extends State<DormirScreen> {
  double _dragOffset = 0;
  
  // ── Estados de la habitación ──
  //bool _isWindowOpen = true;
  bool _isPetInBed = false;
  bool _isWalking = false;

  // ── Variables para el Time-Lapse ──
  DateTime _horaDinamica = DateTime(2023, 1, 1, 19, 40); // La hora que irá avanzando
  Timer? _timer;               // El temporizador

  @override
  void initState() {
    super.initState();
    // Empezamos a las 5:00 AM para que veas el amanecer casi de inmediato
    
    // Configuramos el temporizador para que se ejecute cada 1 segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _horaDinamica = _horaDinamica.add(const Duration(minutes: 10));
        });
      }
    });
  }

  @override
  void dispose() {
    // ⚠️ CRÍTICO: Cancelar el timer al salir de la pantalla para evitar fugas de memoria
    _timer?.cancel(); 
    super.dispose();
  }

  void _irADormir() {
    if (_isPetInBed) return; // Si ya está en la cama, no hace nada

    setState(() {
      _isWalking = true;
    });

    // Simulamos el tiempo que tarda en caminar hacia la cama
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isWalking = false;
          _isPetInBed = true;
        });
      }
    });
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
      backgroundColor: const Color(0xFF1A1A2E), // Azul muy oscuro (Noche)
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          // Deslizar hacia la DERECHA (dx positivo) para volver
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
            // Pantalla de Home "asomándose" por la derecha al volver
            Transform.translate(
              offset: Offset(_dragOffset - size.width, 0),
              child: Container(color: const Color.fromARGB(22, 138, 230, 112)),
            ),

            // Contenido de la habitación
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: _buildDormirBody(size),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDormirBody(Size size) {
    return Stack(
      children: [
        // 1. Pared y Ventana
        Positioned(
          top: 140,
          left: 0,
          right: 0,
          child: Center(child: VentanaHabitacion(horaSimulada: _horaDinamica)),
        ),

        // 2. Encabezado
        Column(
          children: [
            ActionScreenHeader(
              icon: Icons.bed,
              title: 'Habitación',
              subtitlePrefix: '¡Shhh! Está descansando',
              statLabel: 'Energía:',
              // Esto asume que tienes PetCubit en el contexto, ajústalo según tu código
              statSelector: (m) => m.nivelEnergia, 
              barColors: [const Color(0xFFF9A857), AppColors.nivelEnergia],
            ),
          ],
        ),

        // 3. La Cama de la Mascota (Fondo derecha)
        Positioned(
          bottom: 100,
          right: 30,
          child: GestureDetector(
            onLongPress: _irADormir,
            child: _buildCama(),
          ),
        ),

        // 4. La Mascota (Con animación de caminar)
        // Usamos AnimatedAlign para mover a la mascota desde la izquierda hacia la cama a la derecha
        AnimatedAlign(
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          alignment: _isPetInBed || _isWalking 
              ? const Alignment(0.6, 0.75)  // Posición en la cama
              : const Alignment(-0.6, 0.75), // Posición inicial (izq)
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Zzz Flotantes cuando duerme
              if (_isPetInBed)
                const Positioned(
                  top: -40,
                  right: -10,
                  child: Text('💤', style: TextStyle(fontSize: 30)),
                ),
              // Mascota
              Text(
                _isPetInBed ? '😴' : '🐶', // Cambia de estado
                style: const TextStyle(fontSize: 90),
              ),
            ],
          ),
        ),

        // 5. Indicador para el niño
        if (!_isPetInBed && !_isWalking)
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Mantén presionada la cama\npara ir a dormir',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }

  // ── Componente: Cama ──
  Widget _buildCama() {
    return Container(
      width: 140,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.indigo[300],
        borderRadius: const BorderRadius.all(Radius.elliptical(140, 70)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.indigo[800]!, width: 4),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cojín central
          Container(
            width: 100,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.indigo[100],
              borderRadius: const BorderRadius.all(Radius.elliptical(100, 40)),
            ),
          ),
          // Indicador sutil para que el niño sepa que puede interactuar
          if (!_isPetInBed)
            const Text('🛏️', style: TextStyle(fontSize: 30, color: Colors.white54)),
        ],
      ),
    );
  }
}