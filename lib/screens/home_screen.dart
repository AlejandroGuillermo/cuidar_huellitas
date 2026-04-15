import 'dart:async';
import 'package:cuidar_huellitas/cubit/pet_state.dart';
import 'package:flutter/material.dart';
//import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/pet_cubit.dart';
import '../core/app_colors.dart';
import '../core/app_router.dart';
import '../widgets/paw_map_widget.dart';
import '../widgets/header_widget.dart';

// --- Pantalla Principal ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Estado de la mascota y carga
  String? showFeedback;
  Timer? _feedbackTimer;
  bool menuOpen = false;
  double _dragOffset = 0;

  // Estado de la cámara (deshabilitado)
  // bool cameraActive = false;
  // CameraController? _cameraController;
  // List<CameraDescription>? _cameras;

  // Controladores de animación
  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animación de flotación (y: [0, -20, 0])
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _floatingAnimation = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Configurar animación de rebote (scale)
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _bounceController.reverse();
      }
    });
    // _initCameras(); // Eliminado
  }

  // Eliminadas funciones de cámara
  void _showCameraComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidad de cámara próximamente')),
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _bounceController.dispose();
    //_cameraController?.dispose();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Envolvemos todo en un BlocBuilder principal con `buildWhen`
    return BlocBuilder<PetCubit, PetState>(
      // ¡MAGIA!: Esto evita que la pantalla parpadee o se redibuje cuando cambia el hambre o energía.
      // Solo se redibujará si cambia el estado de "Cargando" o si la mascota es nueva.
      buildWhen: (previous, current) {
        return previous.isLoading != current.isLoading || 
               previous.mascota?.nombreMascota != current.mascota?.nombreMascota;
      },
      builder: (context, petState) {
        final mascota = petState.mascota;
        final isLoading = petState.isLoading;

        if (isLoading || mascota == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF708BE6)),
                  SizedBox(height: 16),
                  Text("Despertando mascota...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        final petEmoji = mascota.tipoMascota.toLowerCase() == 'gato' ? '🐱' : '🐶';

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => mostrarMapaHuella(context),
            backgroundColor: AppColors.verdeFondo,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            child: Icon(Icons.pets, color: AppColors.azulPrincipal, size: 28),
          ),
          body: SizedBox.expand( // 2. ESTO EXPANDE EL GESTURE DETECTOR A TODA LA PANTALLA
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < 0) {
                    // Deslizar derecha → DormirScreen (está a la izquierda del home)
                    context.push(AppRoutes.dormir);
                  } else if (details.primaryVelocity! > 0) {
                    // Deslizar izquierda → AlimentarScreen (está a la derecha del home)
                    context.push(AppRoutes.alimentar);
                  }
                }
              },
              child: Stack(
                children: [
                  // 3. ESTO EXPANDE EL FONDO A TODA LA PANTALLA
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFA3FF88), Color(0xFF8AE670), Color(0xFFA3FF88)],
                        ),
                      ),
                    ),
                  ),
                  
                  // Contenido Principal
                  Column(
                    children: [
                      HeaderWidget(
                        leftContent: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.pets,
                                size: 28,
                                color: AppColors.azulPrincipal,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                mascota.nombreMascota,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.azulPrincipal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        rightContent: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _HeaderButton(
                              icon: Icons.camera_alt,
                              color: AppColors.azulPrincipal,
                              onTap: _showCameraComingSoon,
                            ),
                            SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                            _HeaderButton(
                              icon: Icons.menu,
                              color: AppColors.azulPrincipal,
                              onTap: () => setState(() => menuOpen = true),
                            ),
                          ],
                        ),
                      ),
                      Expanded( // 4. Este Expanded empuja la mascota para que tome el espacio sobrante
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                bottom: 40,
                                child: AnimatedBuilder(
                                  animation: _floatingController,
                                  builder: (context, child) {
                                    final scale = 1.0 - (_floatingAnimation.value.abs() / 100);
                                    return Transform.scale(
                                      scale: scale,
                                      child: Container(
                                        width: 120,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              AnimatedBuilder(
                                animation: Listenable.merge([_floatingController, _bounceController]),
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, _floatingAnimation.value),
                                    child: Transform.scale(
                                      scale: _bounceAnimation.value,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.topCenter,
                                        children: [
                                          Text(
                                            petEmoji,
                                            style: const TextStyle(fontSize: 150, height: 1.0),
                                          ),
                                          if (showFeedback != null)
                                            Positioned(
                                              top: -30,
                                              child: Text(
                                                showFeedback!,
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Menú Lateral
                  if (menuOpen)
                    GestureDetector(
                      onTap: () => setState(() => menuOpen = false),
                      child: Container(color: Colors.black.withValues(alpha: 0.5)),
                    ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    top: 0,
                    bottom: 0,
                    right: menuOpen ? 0 : -320,
                    width: 320,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 16, left: 24, right: 24),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [AppColors.azulPrincipal, AppColors.azulClaro]),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Estadísticas',
                                  style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                InkWell(
                                  onTap: () => setState(() => menuOpen = false),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white),
                                  ),
                                )
                              ],
                            ),
                          ),
                          Expanded(
                            // 5. ¡AQUÍ VA OTRO BLOCBUILDER!
                            // Como el Scaffold ya no se entera de los cambios de stats, 
                            // le decimos específicamente a esta lista que escuche las barras.
                            child: BlocBuilder<PetCubit, PetState>(
                              builder: (context, state) {
                                final statsMascota = state.mascota;
                                if(statsMascota == null) return const SizedBox();
                                
                                return ListView(
                                  padding: const EdgeInsets.all(24),
                                  children: [
                                    StatBar(icon: Icons.favorite, label: 'Salud', value: statsMascota.nivelSalud, color: AppColors.nivelSalud),
                                    const SizedBox(height: 24),
                                    StatBar(icon: Icons.bolt, label: 'Energía', value: statsMascota.nivelEnergia, color: AppColors.nivelEnergia),
                                    const SizedBox(height: 24),
                                    StatBar(icon: Icons.restaurant, label: 'Hambre', value: statsMascota.nivelHambre, color: AppColors.nivelHambre),
                                    const SizedBox(height: 24),
                                    StatBar(icon: Icons.water_drop, label: 'Limpieza', value: statsMascota.nivelLimpieza, color: AppColors.nivelLimpieza),
                                    const SizedBox(height: 24),
                                    StatBar(icon: Icons.auto_awesome, label: 'Afecto', value: statsMascota.nivelAfecto, color: AppColors.nivelAfecto),
                                  ],
                                );
                              }
                            ),
                          )
                        ],
                      ),
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
}

// --- Componentes Reutilizables ---
// Barra de estadísticas con icono, etiqueta, valor numérico y barra de progreso
class StatBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const StatBar({super.key, required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey[700], size: 20),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 16)),
              ],
            ),
            Text('$value', style: TextStyle(color: Colors.grey[700], fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 32,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            width: MediaQuery.of(context).size.width * (value / 100) * 0.7, // 0.7 para ajustar al ancho del drawer
            height: 32,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}

// Botón circular del header (cámara y menú)
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}