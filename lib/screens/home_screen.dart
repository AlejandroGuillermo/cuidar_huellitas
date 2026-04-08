import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

// --- Modelos de Datos ---
class PetStats {
  int salud;
  int energia;
  int hambre;
  int limpieza;
  int afecto;

  PetStats({
    required this.salud,
    required this.energia,
    required this.hambre,
    required this.limpieza,
    required this.afecto,
  });
}

class Pet {
  String nombre;
  String tipo; // 'dog' o 'cat'
  PetStats stats;

  Pet({
    required this.nombre,
    required this.tipo,
    required this.stats,
  });
}

// --- Pantalla Principal ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Estado de la mascota
  late Pet pet;
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
    
    // Inicializar mascota
    pet = Pet(
      nombre: 'Max',
      tipo: 'dog',
      stats: PetStats(salud: 85, energia: 60, hambre: 45, limpieza: 70, afecto: 90),
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
        final frontCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
        
        _cameraController = CameraController(frontCamera, ResolutionPreset.high);
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

  void _handleAction(String action) {
    setState(() {
      switch (action) {
        case 'alimentar':
          pet.stats.hambre = (pet.stats.hambre + 25).clamp(0, 100);
          pet.stats.afecto = (pet.stats.afecto + 5).clamp(0, 100);
          showFeedback = '¡Ñam ñam! 😋';
          break;
        case 'jugar':
          pet.stats.energia = (pet.stats.energia - 15).clamp(0, 100);
          pet.stats.afecto = (pet.stats.afecto + 20).clamp(0, 100);
          pet.stats.hambre = (pet.stats.hambre - 10).clamp(0, 100);
          showFeedback = '¡Qué divertido! 🎉';
          break;
        case 'dormir':
          pet.stats.energia = (pet.stats.energia + 30).clamp(0, 100);
          showFeedback = '💤 Zzz...';
          break;
        case 'banar':
          pet.stats.limpieza = (pet.stats.limpieza + 30).clamp(0, 100);
          pet.stats.afecto = (pet.stats.afecto + 10).clamp(0, 100);
          showFeedback = '¡Qué limpio! ✨';
          break;
        case 'curar':
          pet.stats.salud = (pet.stats.salud + 25).clamp(0, 100);
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
    final petEmoji = pet.tipo == 'cat' ? '🐱' : '🐶';

    return Scaffold(
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
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🐾 ${pet.nombre}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF708BE6),
                        ),
                      ),
                      Row(
                        children: [
                          _HeaderButton(
                            icon: cameraActive ? Icons.videocam_off : Icons.camera_alt,
                            color: cameraActive ? const Color(0xFFF07A94) : const Color(0xFF708BE6),
                            onTap: _toggleCamera,
                          ),
                          const SizedBox(width: 12),
                          _HeaderButton(
                            icon: Icons.menu,
                            color: const Color(0xFF708BE6),
                            onTap: () => setState(() => menuOpen = true),
                          ),
                        ],
                      )
                    ],
                  ),
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

                // Panel Inferior de Acciones
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '¿Qué quieres hacer?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF708BE6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ActionButton(
                            emoji: '🍖',
                            label: 'Alimentar',
                            colors: const [Color(0xFFA3FF88), Color(0xFF8AE670)],
                            onTap: () => _handleAction('alimentar'),
                          ),
                          ActionButton(
                            emoji: '🎾',
                            label: 'Jugar',
                            colors: const [Color(0xFF8AE670), Color(0xFFA3FF88)],
                            onTap: () => _handleAction('jugar'),
                          ),
                          ActionButton(
                            emoji: '😴',
                            label: 'Dormir',
                            colors: const [Color(0xFF8AA2FF), Color(0xFF708BE6)],
                            onTap: () => _handleAction('dormir'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ActionButton(
                            emoji: '🛁',
                            label: 'Bañar',
                            colors: const [Color(0xFF708BE6), Color(0xFF8AA2FF)],
                            onTap: () => _handleAction('banar'),
                          ),
                          const SizedBox(width: 32),
                          ActionButton(
                            emoji: '💊',
                            label: 'Curar',
                            colors: const [Color(0xFFF07A94), Color(0xFFF07A94)],
                            onTap: () => _handleAction('curar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                      gradient: LinearGradient(colors: [Color(0xFF708BE6), Color(0xFF8AA2FF)]),
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
                        StatBar(icon: Icons.favorite, label: 'Salud', value: pet.stats.salud, color: const Color(0xFFF07A94)),
                        const SizedBox(height: 24),
                        StatBar(icon: Icons.bolt, label: 'Energía', value: pet.stats.energia, color: const Color(0xFF8AE670)),
                        const SizedBox(height: 24),
                        StatBar(icon: Icons.restaurant, label: 'Hambre', value: pet.stats.hambre, color: const Color(0xFFA3FF88)),
                        const SizedBox(height: 24),
                        StatBar(icon: Icons.water_drop, label: 'Limpieza', value: pet.stats.limpieza, color: const Color(0xFF708BE6)),
                        const SizedBox(height: 24),
                        StatBar(icon: Icons.auto_awesome, label: 'Afecto', value: pet.stats.afecto, color: const Color(0xFF8AA2FF)),
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