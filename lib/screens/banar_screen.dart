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
  final tubWidth = size.width * 0.62;
  final totalHeight = size.height * 0.32;

  final bodyWidth = tubWidth * 0.96;
  final bodyHeight = totalHeight * 0.46;
  final rimWidth = tubWidth * 0.82;
  final rimHeight = totalHeight * 0.11;
  final waterWidth = tubWidth * 0.72;
  final waterHeight = totalHeight * 0.075;

  return GestureDetector(
    onTap: () => setState(() => _petInTub = !_petInTub),
    child: SizedBox(
      width: tubWidth,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // sombra al piso
          Positioned(
            bottom: 4,
            child: Container(
              width: tubWidth * 0.72,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),

          // grifo / tubo vertical
          Positioned(
            top: totalHeight * 0.10,
            right: tubWidth * 0.16,
            child: Container(
              width: 18,
              height: totalHeight * 0.22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFC7D4DB),
                    Color(0xFF90A2AC),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),

          // cabezal del grifo
          Positioned(
            top: totalHeight * 0.03,
            right: tubWidth * 0.05,
            child: Container(
              width: 62,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFDCE5EA),
                    Color(0xFFA5B5BE),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 10,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7E9098),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.25),
                            blurRadius: 3,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7E9098),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.25),
                            blurRadius: 3,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF90A1AA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // cuerpo principal
          Positioned(
            bottom: 18,
            child: Container(
              width: bodyWidth,
              height: bodyHeight,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFF5FAFD),
                    Color(0xFFDCEAF1),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(56),
                  topRight: Radius.circular(56),
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                border: Border.all(
                  color: const Color(0xFFD4E4EC),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),

          // brillo lateral para volumen
          Positioned(
            bottom: 46,
            left: tubWidth * 0.12,
            child: Container(
              width: tubWidth * 0.09,
              height: bodyHeight * 0.55,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.36),
                    Colors.white.withValues(alpha: 0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),

          // borde superior interior
          Positioned(
            bottom: bodyHeight * 0.62,
            child: Container(
              width: rimWidth,
              height: rimHeight,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF9FDFF),
                    Color(0xFFE6F1F6),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: const Color(0xFFD6E6EE),
                  width: 2,
                ),
              ),
            ),
          ),

          // cavidad interior profunda
          Positioned(
            bottom: bodyHeight * 0.46,
            child: Container(
              width: tubWidth * 0.76,
              height: bodyHeight * 0.15,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5FA),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),

          // agua
          Positioned(
            bottom: bodyHeight * 0.47,
            child: Container(
              width: waterWidth,
              height: waterHeight,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFDFF7FF),
                    Color(0xFFAFDDEB),
                  ],
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9AD3E6).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: waterWidth * 0.78,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // espuma decorativa para que se vea más cute
          Positioned(
            bottom: bodyHeight * 0.56,
            left: tubWidth * 0.14,
            child: Row(
              children: [
                _foamBubble(18),
                const SizedBox(width: 4),
                _foamBubble(13),
                const SizedBox(width: 2),
                _foamBubble(16),
              ],
            ),
          ),

          Positioned(
            bottom: bodyHeight * 0.58,
            right: tubWidth * 0.16,
            child: Row(
              children: [
                _foamBubble(12),
                const SizedBox(width: 3),
                _foamBubble(17),
              ],
            ),
          ),

          // patas
          Positioned(
            bottom: 0,
            left: tubWidth * 0.15,
            child: _buildPremiumTubLeg(),
          ),
          Positioned(
            bottom: 0,
            right: tubWidth * 0.15,
            child: _buildPremiumTubLeg(),
          ),

          if (_petInTub) ...[
            Positioned(
              bottom: bodyHeight * 0.76,
              left: tubWidth * 0.13,
              child: AnimatedBuilder(
                animation: _bubbleFloat,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _bubbleFloat.value),
                  child: child,
                ),
                child: _buildTubBubbles(),
              ),
            ),
            Positioned(
              bottom: bodyHeight * 0.43,
              left: tubWidth * 0.19,
              child: _buildPetInTub(),
            ),
          ] else
            Positioned(
              bottom: bodyHeight * 0.23,
              left: tubWidth * 0.12,
              right: tubWidth * 0.12,
              child: Column(
                children: const [
                  Icon(
                    Icons.touch_app_rounded,
                    color: Color(0xFF6D8B99),
                    size: 28,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Toca la bañera\npara meter a tu mascota',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5A7481),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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
