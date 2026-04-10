import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_router.dart';
import '../Models/mascota_model.dart';
import '../widgets/paw_map_widget.dart';

// --- Pantalla Principal ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Estado de la mascota
  MascotaModel? mascota;
  bool isLoading = true; // true = cargando datos de Firestore, false = listo para mostrar
  String? showFeedback;
  Timer? _feedbackTimer;
  bool menuOpen = false;

  // Estado de la cámara
  bool cameraActive = false;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  // Controladores de animación
  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _cargarMascota();
    
    // Inicializar mascota
    mascota = MascotaModel(
      idMascota: 'mock_id_123',
      nombreMascota: 'Max',
      tipoMascota: 'perro',
      ultimaInteraccion: DateTime.now(),
      nivelSalud: 85,
      nivelEnergia: 60,
      nivelHambre: 45,
      nivelLimpieza: 70,
      nivelAfecto: 90,
    );

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

    _initCameras();
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint("Error al obtener cámaras: $e");
    }
  }

  Future<void> _toggleCamera() async {
    if (cameraActive) {
      await _cameraController?.dispose();
      setState(() {
        _cameraController = null;
        cameraActive = false;
      });
    } else {
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Buscar cámara frontal
        final backCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );
        
        _cameraController = CameraController(backCamera, ResolutionPreset.high);
        try {
          await _cameraController!.initialize();
          setState(() {
            cameraActive = true;
          });
        } catch (e) {
          debugPrint("Error al inicializar cámara: $e");
        }
      }
    }
  }

  // ── Función para descargar la mascota ───────────────────
  Future<void> _cargarMascota() async {
    try {
      // OBTENER EL USUARIO
      final String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        setState(() => isLoading = false); // ← agregar esto
      return;
}

      // HACER LA CONSULTA A FIRESTORE
      // Entramos al documento del usuario y luego a SU colección de mascotas
      final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId) 
        .collection('mascotas')
        .where('activa', isEqualTo: true)
        .limit(1)
        .get();

      if (snapshot.docs.isNotEmpty) {
        // Usamos la magia de tu fromFirestore
        setState(() {
          mascota = MascotaModel.fromFirestore(snapshot.docs.first);
          isLoading = false;
        });
      } else {
        // Si no tiene mascota activa, podríamos redirigir a AdopcionScreen
        debugPrint("El usuario $userId no tiene mascota activa.");
        setState(() {
          mascota = MascotaModel(
            idMascota: 'mock_123',
            nombreMascota: 'Max (Prueba)',
            tipoMascota: 'perro',
            ultimaInteraccion: DateTime.now(),
            nivelSalud: 100,
            nivelEnergia: 100,
            nivelHambre: 100,
            nivelLimpieza: 100,
            nivelAfecto: 100,
          );
          isLoading = false; // Quitamos la pantalla de carga
        });
        // context.go('/adopcion'); 
      }
    } catch (e) {
      debugPrint("Error al cargar la mascota: $e");
      setState(() => isLoading = false);
    }
  }

  void _handleAction(String action) {
    if (mascota == null) return;
    setState(() {
      switch (action) {
        case 'alimentar':
          mascota = mascota!.copyWith(
            nivelHambre: (mascota!.nivelHambre + 25).clamp(0, 100),
            nivelAfecto: (mascota!.nivelAfecto + 5).clamp(0, 100),
            ultimaInteraccion: DateTime.now(),
          );
          showFeedback = '¡Ñam ñam! 😋';
          break;
        case 'jugar':
          mascota = mascota!.copyWith(
            nivelEnergia: (mascota!.nivelEnergia - 15).clamp(0, 100),
            nivelAfecto: (mascota!.nivelAfecto + 20).clamp(0, 100),
            nivelHambre: (mascota!.nivelHambre - 10).clamp(0, 100),
            ultimaInteraccion: DateTime.now(),
          );
          showFeedback = '¡Qué divertido! 🎉';
          break;
        case 'dormir':
          mascota = mascota!.copyWith(
            nivelEnergia: (mascota!.nivelEnergia + 30).clamp(0, 100),
            ultimaInteraccion: DateTime.now(),
          );
          showFeedback = '💤 Zzz...';
          break;
        case 'banar':
          mascota = mascota!.copyWith(
            nivelLimpieza: (mascota!.nivelLimpieza + 30).clamp(0, 100),
            nivelAfecto: (mascota!.nivelAfecto + 10).clamp(0, 100),
            ultimaInteraccion: DateTime.now(),
          );
          showFeedback = '¡Qué limpio! ✨';
          break;
        case 'curar':
          mascota = mascota!.copyWith(
            nivelSalud: (mascota!.nivelSalud + 25).clamp(0, 100),
            ultimaInteraccion: DateTime.now(),
          );
          showFeedback = '¡Me siento mejor! 💊';
          break;
      }
    });

    _bounceController.forward();

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => showFeedback = null);
    });
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _bounceController.dispose();
    _cameraController?.dispose();
    _feedbackTimer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
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
    final petEmoji = mascota!.tipoMascota.toLowerCase() == 'gato' ? '🐱' : '🐶';

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => mostrarMapaHuella(context),
        backgroundColor: AppColors.verdeFondo, // por el momento, luego lo personalizamos
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Text('🐾', style: TextStyle(fontSize: 28)),
      ),
      body: Stack(
        children: [
          // 1. Fondo Degradado o Cámara
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFA3FF88), Color(0xFF8AE670), Color(0xFFA3FF88)],
              ),
            ),
          ),
          if (cameraActive && _cameraController != null && _cameraController!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 1,
                  height: _cameraController!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),

          // 2. Contenido Principal
          Column(
            children: [
              // Header Responsive
              Builder(
                builder: (context) {
                  // Obtenemos las medidas exactas de cualquier pantalla
                  final screenWidth = MediaQuery.of(context).size.width;
                  final topPadding = MediaQuery.of(context).padding.top;
                  
                  // Calculamos un margen del 5% del ancho de la pantalla
                  final paddingLateral = screenWidth * 0.05;

                  return Container(
                    padding: EdgeInsets.only(
                      top: topPadding + 16, // Cubre el Status Bar dinámicamente
                      bottom: 16, 
                      left: paddingLateral, // Margen dinámico
                      right: paddingLateral, // Margen dinámico
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Usamos Expanded + FittedBox para que el texto se encoja si no cabe
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown, // Encoge el texto solo si es necesario
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '🐾 ${mascota!.nombreMascota}',
                              style: const TextStyle(
                                fontSize: 28, // Tamaño máximo, se encogerá en pantallas chicas
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF708BE6),
                              ),
                            ),
                          ),
                        ),
                        // Espacio dinámico (2% del ancho de la pantalla)
                        SizedBox(width: screenWidth * 0.02),
                        
                        // Botones asegurados de usar solo el espacio necesario
                        Row(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            _HeaderButton(
                              icon: cameraActive ? Icons.videocam_off : Icons.camera_alt,
                              color: cameraActive ? AppColors.rosa : AppColors.azulPrincipal,
                              onTap: _toggleCamera,
                            ),
                            // Espacio dinámico (3% del ancho de la pantalla)
                            SizedBox(width: screenWidth * 0.03),
                            _HeaderButton(
                              icon: Icons.menu,
                              color: AppColors.azulPrincipal,
                              onTap: () => setState(() => menuOpen = true),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                }
              ),

              // Zona Central (Mascota animada)
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Sombra de la mascota
                      Positioned(
                        bottom: 40,
                        child: AnimatedBuilder(
                          animation: _floatingController,
                          builder: (context, child) {
                            // El inverso de la flotación para la escala de la sombra
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
                        
                        // Mascota
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
                                        child: _FeedbackBubble(text: showFeedback!),
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

          // 3. Menú Lateral (Drawer personalizado)
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
            right: menuOpen ? 0 : -320, // Slide in/out
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
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        StatBar(icon: Icons.favorite, label: 'Salud', value: mascota!.nivelSalud, color: AppColors.nivelSalud),
                        const SizedBox(height: 24),
                        StatBar(icon: Icons.bolt, label: 'Energía', value: mascota!.nivelEnergia, color: AppColors.nivelEnergia),
                        const SizedBox(height: 24),
                        StatBar(icon: Icons.restaurant, label: 'Hambre', value: mascota!.nivelHambre, color: AppColors.nivelHambre),
                        const SizedBox(height: 24),
                        StatBar(icon: Icons.water_drop, label: 'Limpieza', value: mascota!.nivelLimpieza, color: AppColors.nivelLimpieza),
                        const SizedBox(height: 24),
                        StatBar(icon: Icons.auto_awesome, label: 'Afecto', value: mascota!.nivelAfecto, color: AppColors.nivelAfecto),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
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
// Botón circular con emoji para las acciones principales (alimentar, jugar, etc.)
class ActionButton extends StatefulWidget {
  final String emoji;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;

  const ActionButton({super.key, required this.emoji, required this.label, required this.colors, required this.onTap});

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) {
        setState(() => isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedScale(
        scale: isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: widget.colors),
                boxShadow: [
                  BoxShadow(color: widget.colors.last.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Center(
                child: Text(widget.emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.label, style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
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

class _FeedbackBubble extends StatelessWidget {
  final String text;

  const _FeedbackBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFF4ADE80), width: 3),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}