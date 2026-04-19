import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/app_colors.dart';
import '../core/app_router.dart';
import '../cubit/pet_cubit.dart';
import '../cubit/pet_state.dart';
import '../widgets/action_screen_header.dart';
import '../widgets/paw_map_widget.dart';

class BanarScreen extends StatefulWidget {
  const BanarScreen({super.key});

  @override
  State<BanarScreen> createState() => _BanarScreenState();
}

class _BanarScreenState extends State<BanarScreen>
    with SingleTickerProviderStateMixin {
  bool _petInTub = false;
  double _dragOffset = 0;
  late final AnimationController _bubbleController;
  late final Animation<double> _bubbleFloat;

  final List<_BathTool> _tools = const [
    _BathTool(
      label: 'Jabon',
      icon: Icons.soap_outlined,
      color: Color(0xFFFFD980),
    ),
    _BathTool(
      label: 'Manguera',
      icon: Icons.water_drop_outlined,
      color: Color(0xFF8AD8FF),
    ),
    _BathTool(
      label: 'Estropajo',
      icon: Icons.cleaning_services_outlined,
      color: Color(0xFFA67C52),
    ),
    _BathTool(
      label: 'Toalla',
      icon: Icons.dry_cleaning_outlined,
      color: Color(0xFFF5A3B7),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _bubbleFloat = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _bubbleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    super.dispose();
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
          // 1. Cambiamos a dx > 0 para detectar deslizamiento hacia la DERECHA
          if (details.delta.dx > 0) {
            setState(
              () => _dragOffset = (_dragOffset + details.delta.dx).clamp(
                0.0, // No deja que se mueva a la izquierda (negativo)
                size.width, // Tope máximo a la derecha (el ancho de la pantalla)
              ),
            );
          }
        },
        onHorizontalDragEnd: (details) {
          // 2. Evaluamos arrastre largo a la derecha o movimiento rápido a la derecha (velocidad positiva)
          if (_dragOffset > size.width * 0.3 || (details.primaryVelocity ?? 0) > 500) {
            // Si se cumple, navegamos a la pantalla de dormir
            context.go(AppRoutes.dormir);
          } else {
            // Si te arrepientes a medio camino, regresa de golpe a la posición original
            setState(() => _dragOffset = 0);
          }
        },
        child: Container(
          color: const Color(0xFFC7E6F7),
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFEAF8FF),
                    Color(0xFFD7F0FF),
                    Color(0xFFC7E6F7),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    ActionScreenHeader(
                      icon: Icons.bathtub,
                      title: 'Hora del bano',
                      subtitlePrefix: 'Vamos a dejar limpio a',
                      statLabel: 'Limpieza:',
                      statSelector: (mascota) => mascota.nivelLimpieza,
                      barColors: const [
                        Color(0xFF8AD8FF),
                        AppColors.nivelLimpieza,
                      ],
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          return _buildBathroom(size);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBathroom(Size size) {
    return Stack(
      children: [
        Positioned.fill(child: _buildWall()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: size.height * 0.34,
          child: _buildFloor(),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: size.height * 0.34 - 6,
          height: 12,
          child: Container(color: const Color(0xFF8FB3C2)),
        ),
        Positioned(
          top: size.height * 0.08,
          left: size.width * 0.08,
          child: _buildMirror(),
        ),
        Positioned(
          top: size.height * 0.11,
          right: size.width * 0.12,
          child: _buildShowerHead(),
        ),
        if (_petInTub)
          Positioned(
            left: 16,
            top: size.height * 0.18,
            bottom: size.height * 0.16,
            child: _buildToolBar(),
          ),
        Positioned(
          right: size.width * 0.04,
          bottom: size.height * 0.12,
          child: _buildTub(size),
        ),
        Positioned(
          left: 24,
          right: size.width * 0.38,
          bottom: 28,
          child: _buildHintCard(),
        ),
      ],
    );
  }

  Widget _buildWall() {
    return CustomPaint(
      painter: _TilePainter(
        tileColor: const Color(0xFFDDF4FF),
        lineColor: const Color(0xFFB3D7E8),
        accentColor: const Color(0xFFCDEBFA),
      ),
    );
  }

  Widget _buildFloor() {
    return CustomPaint(
      painter: _TilePainter(
        tileColor: const Color(0xFFA4D1DB),
        lineColor: const Color(0xFF78A7B3),
        accentColor: const Color(0xFF95C3CF),
        tileSize: 34,
      ),
    );
  }

  Widget _buildMirror() {
    return Column(
      children: [
        Container(
          width: 110,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(56),
            border: Border.all(color: const Color(0xFF82B2C9), width: 8),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF9FEFF), Color(0xFFD0EEFF)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 18,
                left: 20,
                child: Container(
                  width: 34,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Positioned(
                top: 34,
                left: 26,
                child: Container(
                  width: 18,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 90,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF9FC6D8),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildShowerHead() {
    return Column(
      children: [
        Container(
          width: 74,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF7E98A6),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 10,
            height: 58,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF7E98A6),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Container(
          width: 44,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF95AFBB),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        if (_petInTub)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(
                10,
                (_) => Container(
                  width: 5,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8AD8FF).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildToolBar() {
    return Container(
      width: 98,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF6C8FA3).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _tools.map((tool) => _buildToolItem(tool)).toList(),
      ),
    );
  }

  Widget _buildToolItem(_BathTool tool) {
    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tool.color.withValues(alpha: 0.75), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tool.icon, color: const Color(0xFF4A6472), size: 22),
          const SizedBox(height: 4),
          Text(
            tool.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A6472),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTub(Size size) {
  // Ajustamos las proporciones al aspect-[4/3] del diseño de React
  final tubWidth = size.width * 0.75; 
  final tubHeight = tubWidth * 0.75; 

  return Center(
    child: GestureDetector(
      onTap: () => setState(() => _petInTub = !_petInTub),
      child: SizedBox(
        width: tubWidth,
        height: tubHeight * 1.3, // Espacio extra para el grifo y el vapor
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // 1. Vapor de fondo (Blur)
            Positioned(top: 0, left: tubWidth * 0.1, child: _buildSteamVapor(60, 50)),
            Positioned(top: 20, right: tubWidth * 0.2, child: _buildSteamVapor(80, 60)),
            Positioned(top: 40, left: tubWidth * 0.4, child: _buildSteamVapor(50, 40)),

            // 2. Patas frontales (Estilo pastilla del diseño React)
            Positioned(
              bottom: tubHeight * 0.02,
              left: tubWidth * 0.15,
              child: _buildFrontalTubLeg(tubWidth),
            ),
            Positioned(
              bottom: tubHeight * 0.02,
              right: tubWidth * 0.15,
              child: _buildFrontalTubLeg(tubWidth),
            ),

            // 3. Grifo Frontal (Atrás de la bañera)
            Positioned(
              top: tubHeight * 0.05,
              right: tubWidth * 0.15,
              child: _buildFrontalFaucet(tubWidth),
            ),

            // 4. Cuerpo Principal de la Bañera (Vista Frontal)
            Positioned(
              bottom: tubHeight * 0.08,
              child: Container(
                width: tubWidth,
                height: tubHeight * 0.85,
                decoration: BoxDecoration(
                  // gradient-to-b from-white via-gray-50 to-gray-200
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Color(0xFFF9FAFB), Color(0xFFE5E7EB)],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(80),
                    bottomRight: Radius.circular(80),
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 8),
                ),
                child: Stack(
                  children: [
                    // Borde interior superior (Rim)
                    Container(
                      height: tubHeight * 0.18,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFE5E7EB), Color(0xFFF3F4F6)],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFD1D5DB), width: 4),
                        ),
                      ),
                    ),

                    // 5. Agua y Mascota
                    Positioned(
                      top: tubHeight * 0.12,
                      left: tubWidth * 0.06,
                      right: tubWidth * 0.06,
                      bottom: tubHeight * 0.06,
                      child: Container(
                        decoration: BoxDecoration(
                          // from-cyan-300/90 via-blue-400/90 to-blue-500/80
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xE667E8F9), 
                              Color(0xE660A5FA), 
                              Color(0xCC3B82F6), 
                            ],
                          ),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            // Brillo blanco difuminado en la esquina superior izquierda
                            Positioned(
                              top: -20,
                              left: -10,
                              child: Container(
                                width: tubWidth * 0.4,
                                height: tubHeight * 0.4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    )
                                  ],
                                ),
                              ),
                            ),

                            // Línea de superficie del agua
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFFA5F3FC).withValues(alpha: 0.6),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),

                            // Burbujas estáticas emulando el array de React
                            _buildWaterBubble(left: 20, bottom: 30, size: 12),
                            _buildWaterBubble(left: 60, bottom: 70, size: 16),
                            _buildWaterBubble(right: 30, bottom: 40, size: 14),
                            _buildWaterBubble(right: 70, bottom: 20, size: 10),
                            _buildWaterBubble(left: tubWidth * 0.4, bottom: 50, size: 18),

                            // Mascota
                            if (_petInTub)
                              Positioned(
                                bottom: tubHeight * 0.08, // Lo empujamos desde abajo
                                left: 0,                  // Centrado horizontal
                                right: 0,                 // Centrado horizontal
                                // Al usar Positioned sin un "top", la altura es libre (infinita)
                                child: TweenAnimationBuilder(
                                  tween: Tween<double>(begin: 0, end: 10),
                                  duration: const Duration(seconds: 2),
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, -value),
                                      child: child,
                                    );
                                  },
                                  child: _buildPetInTub(), // Tu mascota actual
                                ),
                              ),

                            // Capa de agua frontal (Efecto inmersión sobre la mascota)
                            if (_petInTub)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        const Color(0xFF67E8F9).withValues(alpha: 0.2),
                                        const Color(0xFF3B82F6).withValues(alpha: 0.4),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
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

// ── Helpers para el nuevo diseño ────────────────────────────

// Pata vista de frente (estilo cápsula)
Widget _buildFrontalTubLeg(double tubWidth) {
  return Container(
    width: tubWidth * 0.08,
    height: tubWidth * 0.15,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE5E7EB), Color(0xFF9CA3AF)], // gray-200 to gray-400
      ),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(999)),
      border: Border.all(color: const Color(0xFF6B7280), width: 2), // border-gray-500
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        )
      ],
    ),
  );
}

// Grifo visto de frente
Widget _buildFrontalFaucet(double tubWidth) {
  return SizedBox(
    width: tubWidth * 0.12,
    height: tubWidth * 0.25,
    child: Stack(
      alignment: Alignment.topCenter,
      children: [
        // Cuerpo del grifo
        Container(
          width: tubWidth * 0.12,
          height: tubWidth * 0.18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFD1D5DB), Color(0xFF6B7280)], // gray-300 to gray-500
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF4B5563), width: 3), // gray-600
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
              )
            ],
          ),
        ),
        // Agujero por donde sale el agua
        Positioned(
          top: tubWidth * 0.04,
          child: Container(
            width: tubWidth * 0.04,
            height: tubWidth * 0.04,
            decoration: const BoxDecoration(
              color: Color(0xFF60A5FA), // blue-400
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Chorro de agua
        Positioned(
          top: tubWidth * 0.15,
          child: Container(
            width: tubWidth * 0.025,
            height: tubWidth * 0.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF93C5FD), // blue-300
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    ),
  );
}

// Burbujas
Widget _buildWaterBubble({double? left, double? right, double? bottom, required double size}) {
  return Positioned(
    left: left,
    right: right,
    bottom: bottom,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
    ),
  );
}

// Vapor simulado con sombras muy difuminadas
Widget _buildSteamVapor(double width, double height) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.transparent,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.5),
          blurRadius: 30, // Equivale al blur-2xl de Tailwind
          spreadRadius: 10,
        )
      ],
    ),
  );
}

Widget _buildPremiumTubLeg() {
  return Container(
    width: 24,
    height: 32,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFA8BAC3),
          Color(0xFF72868F),
        ],
      ),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
  );
}

Widget _foamBubble(double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.96),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.35),
          blurRadius: 6,
          spreadRadius: 0.4,
        ),
      ],
    ),
  );
}

Widget _buildTubBubbles() {
  return SizedBox(
    width: 62,
    height: 42,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        _bubble(6, 20, 12),
        _bubble(20, 8, 18),
        _bubble(38, 18, 10),
        _bubble(46, 4, 13),
      ],
    ),
  );
}

Widget _bubble(double left, double top, double size) {
  return Positioned(
    left: left,
    top: top,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.35),
            blurRadius: 6,
            spreadRadius: 0.5,
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPetInTub() {
    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state) {
        final isCat = (state.mascota?.tipoMascota ?? 'perro') == 'gato';
        final petEmoji = isCat ? '🐱' : '🐶';

        return Column(
          children: [
            Text(petEmoji, style: const TextStyle(fontSize: 74)),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Listo para el bano',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF537280),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHintCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        _petInTub
            ? 'Ya aparecio la barra con jabon, manguera, estropajo y toalla.'
            : 'La banera esta vacia. Toca la banera para cambiar al estado con mascota.',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF58717D),
        ),
      ),
    );
  }
}

class _BathTool {
  final String label;
  final IconData icon;
  final Color color;

  const _BathTool({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _TilePainter extends CustomPainter {
  final Color tileColor;
  final Color lineColor;
  final Color accentColor;
  final double tileSize;

  _TilePainter({
    required this.tileColor,
    required this.lineColor,
    required this.accentColor,
    this.tileSize = 44,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tilePaint = Paint()..color = tileColor;
    final accentPaint = Paint()..color = accentColor;
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (double y = 0; y < size.height + tileSize; y += tileSize) {
      for (double x = 0; x < size.width + tileSize; x += tileSize) {
        final rect = Rect.fromLTWH(x, y, tileSize, tileSize);
        canvas.drawRect(rect, tilePaint);
        canvas.drawRect(
          Rect.fromLTWH(x + 4, y + 4, tileSize - 8, tileSize - 8),
          accentPaint,
        );
        canvas.drawRect(rect, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TilePainter oldDelegate) {
    return oldDelegate.tileColor != tileColor ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.tileSize != tileSize;
  }
}
