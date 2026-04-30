import 'dart:async';
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
import '../widgets/paw_map_widget.dart';
import '../widgets/banar/soap_tool_widget.dart';

class BanarScreen extends StatefulWidget {
  const BanarScreen({super.key});

  @override
  State<BanarScreen> createState() => _BanarScreenState();
}

class _BanarScreenState extends State<BanarScreen>
    with SingleTickerProviderStateMixin {
  bool _petInTub = false;
  double _dragOffset = 0;
  bool _applyingBath = false;
  String _bathFeedback = '';
  bool _soapBubblesActive = false;
  bool _draggingBathTool = false;
  DateTime _lastBathToolDropAt = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _soapBubbleTimer;
  late final AnimationController _bubbleController;
  late final Animation<double> _bubbleFloat;

  final List<_BathTool> _tools = const [
    _BathTool(
      label: 'Jabon',
      icon: Icons.soap_outlined,
      color: Color.fromARGB(255, 255, 128, 240),
    ),
    _BathTool(
      label: 'Estropajo',
      icon: Icons.cleaning_services_outlined,
      color: Color(0xFFA67C52),
    ),
    _BathTool(
      label: 'Manguera',
      icon: Icons.water_drop_outlined,
      color: Color(0xFF8AD8FF),
    ),
    _BathTool(
      label: 'Toalla',
      icon: Icons.dry_cleaning_outlined,
      color: Color.fromARGB(255, 231, 245, 163),
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWorldEntry());
  }

  Future<void> _syncWorldEntry() async {
    if (!mounted) return;
    final mascota = context.read<PetCubit>().state.mascota;
    if (mascota == null) return;
    await context.read<PetWorldCubit>().syncScreenEntry(
      mascota: mascota,
      location: PetLocation.banar,
      fallbackActivity: PetActivity.idle,
    );
  }

  @override
  void dispose() {
    _soapBubbleTimer?.cancel();
    _bubbleController.dispose();
    super.dispose();
  }

  void _setDraggingBathTool(bool value) {
    if (!mounted) return;
    setState(() {
      _draggingBathTool = value;
      if (value) _dragOffset = 0;
    });
  }

  bool get _recentBathToolDrop =>
      DateTime.now().difference(_lastBathToolDropAt) <
      const Duration(milliseconds: 350);

  void _acceptBathTool(_BathTool tool) {
    _lastBathToolDropAt = DateTime.now();
    _setDraggingBathTool(false);
    _usarHerramienta(tool);
  }

  Future<void> _usarHerramienta(_BathTool tool) async {
    if (!_petInTub) return;

    if (tool.label == 'Jabon') {
      setState(() {
        _bathFeedback = 'Jabon aplicado sobre las manchas.';
        _soapBubblesActive = true;
      });
      _soapBubbleTimer?.cancel();
      _soapBubbleTimer = Timer(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        setState(() => _soapBubblesActive = false);
      });
      return;
    }
    if (tool.label == 'Manguera') {
      setState(() {
        _bathFeedback = 'Enjuagando para quitar suciedad.';
        _soapBubblesActive = false;
      });
      return;
    }
    if (tool.label == 'Estropajo') {
      setState(() {
        _bathFeedback = 'Frotando zonas sucias.';
        _soapBubblesActive = false;
      });
      return;
    }
    if (tool.label != 'Toalla' || _applyingBath) return;

    setState(() {
      _applyingBath = true;
      _bathFeedback = 'Secando y cerrando el bano...';
      _soapBubblesActive = false;
    });
    await context.read<PetCubit>().banar();
    if (!mounted) return;
    setState(() {
      _applyingBath = false;
      _bathFeedback = 'Bano completado. Limpieza actualizada.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final worldState = context.watch<PetWorldCubit>().state;
    final canShowPet =
        !worldState.isLocationLocked ||
        worldState.location == PetLocation.banar;
    if (!canShowPet && _petInTub) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _petInTub = false);
      });
    }

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (_draggingBathTool) return;
        // Detecta swipe hacia la derecha.
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
        if (_draggingBathTool) return;
        // 2. Evaluamos arrastre largo a la derecha o movimiento rápido a la derecha (velocidad positiva)
        if (_dragOffset > size.width * 0.3 ||
            (details.primaryVelocity ?? 0) > 500) {
          // Si se cumple, navegamos a la pantalla de dormir
          context.go(AppRoutes.dormir);
        } else {
          // Si te arrepientes a medio camino, regresa de golpe a la posición original
          setState(() => _dragOffset = 0);
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
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
                              return _buildBathroom(size, canShowPet);
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
          Positioned(right: 16, bottom: 16, child: _buildPawMapButton()),
        ],
      ),
    );
  }

  Widget _buildPawMapButton() {
    return FloatingActionButton(
      onPressed: () => mostrarMapaHuella(context),
      backgroundColor: AppColors.verdeFondo,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: const Icon(Icons.pets, color: AppColors.azulPrincipal, size: 28),
    );
  }

  Widget _buildBathroom(Size size, bool canShowPet) {
    final floorHeight = size.height * 0.34;
    final petFloorBottom = floorHeight * 0.14;
    final tubBottomCollapsed = floorHeight - 28;
    final tubBottomExpanded = petFloorBottom;
    final transitionDuration = Duration(milliseconds: _petInTub ? 520 : 440);
    final positionCurve = _petInTub
        ? Curves.easeOutBack
        : Curves.easeInOutCubic;

    // --- mismas medidas base de la tina para poder posicionar la barra ---
    final expandedWidth = size.width * 0.78;
    final compactWidth = size.width * 0.56;
    final tubWidth = (_petInTub ? expandedWidth : compactWidth)
        .clamp(220.0, size.width * 0.82)
        .toDouble();
    final tubHeight = tubWidth * 0.62;

    final showToolBar = _petInTub && canShowPet && tubWidth >= 300;
    final availableToolBarWidth = (size.width - 24).clamp(0.0, 420.0);
    final toolBarWidth = (size.width * 0.9)
        .clamp(0.0, availableToolBarWidth)
        .toDouble();
    final maxToolBarLeft = (size.width - toolBarWidth - 12).clamp(
      12.0,
      size.width,
    );
    final toolBarLeft = ((size.width - toolBarWidth) / 2)
        .clamp(12.0, maxToolBarLeft)
        .toDouble();

    final tubBottom = _petInTub ? tubBottomExpanded : tubBottomCollapsed;
    final toolBarAboveTubBottom = (tubBottom + tubHeight + 64)
        .clamp(100.0, size.height * 0.78)
        .toDouble();

    return Stack(
      children: [
        Positioned.fill(child: _buildWall()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: floorHeight,
          child: _buildFloor(),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: floorHeight - 6,
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

        if (showToolBar)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            left: toolBarLeft,
            bottom: toolBarAboveTubBottom,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              scale: _petInTub ? 1 : 0.92,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _petInTub ? 1 : 0,
                child: _buildToolBar(width: toolBarWidth),
              ),
            ),
          ),

        Positioned(
          left: 0,
          right: 0,
          bottom: petFloorBottom,
          child: IgnorePointer(
            ignoring: _petInTub,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              opacity: _petInTub ? 0 : 1,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                offset: _petInTub ? const Offset(0, 0.12) : Offset.zero,
                child: canShowPet
                    ? _buildPetOnFloor(size)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: transitionDuration,
          curve: positionCurve,
          left: 0,
          right: 0,
          bottom: tubBottom,
          child: _buildTub(size, canShowPet),
        ),
        Positioned(
          left: 24,
          right: size.width * 0.38,
          bottom: 28,
          child: _buildHintCard(canShowPet),
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
          width: 60,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF7E98A6),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 7,
            height: 44,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF7E98A6),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Container(
          width: 36,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF95AFBB),
            borderRadius: BorderRadius.circular(18),
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
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildToolBar({required double width}) {
    final compactLayout = width < 340;
    final iconSize = compactLayout ? 20.0 : 22.0;
    final labelSize = compactLayout ? 7.4 : 8.0;
    final verticalPadding = compactLayout ? 8.0 : 10.0;

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: compactLayout ? 10 : 12,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF6C8FA3).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _tools
            .map(
              (tool) => Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compactLayout ? 2 : 4,
                  ),
                  child: _buildToolItem(
                    tool,
                    iconSize: iconSize,
                    labelSize: labelSize,
                    compactLayout: compactLayout,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildToolItem(
    _BathTool tool, {
    required double iconSize,
    required double labelSize,
    required bool compactLayout,
  }) {
    final enabled = _petInTub && !_applyingBath;

    Widget tile({required double opacity, bool tappable = true}) {
      final content = Opacity(
        opacity: opacity,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: compactLayout ? 8 : 10,
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: tool.color.withValues(alpha: 0.78),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tool.label == 'Jabon')
                SoapToolWidget(enabled: enabled, size: iconSize * 2.2)
              else
                Icon(tool.icon, color: const Color(0xFF4A6472), size: iconSize),
              if (tool.label != 'Jabon') ...[
                SizedBox(height: compactLayout ? 2 : 4),
                Text(
                  tool.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4A6472),
                    height: 1.0,
                  ),
                ),
              ],
            ],
          ),
        ),
      );

      if (!tappable) return content;

      return GestureDetector(
        onTap: enabled ? () => _usarHerramienta(tool) : null,
        child: content,
      );
    }

    if (!enabled) {
      return tile(opacity: 0.6);
    }

    return Draggable<_BathTool>(
      data: tool,
      rootOverlay: true,
      onDragStarted: () => _setDraggingBathTool(true),
      onDragEnd: (_) => _setDraggingBathTool(false),
      onDraggableCanceled: (_, _) => _setDraggingBathTool(false),
      onDragCompleted: () => _setDraggingBathTool(false),
      feedback: Material(
        color: Colors.transparent,
        child: IgnorePointer(
          child: _buildToolFeedback(tool, size: compactLayout ? 54 : 60),
        ),
      ),
      childWhenDragging: tile(opacity: 0.35, tappable: false),
      child: tile(opacity: 1.0),
    );
  }

  Widget _buildToolFeedback(_BathTool tool, {required double size}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: tool.color.withValues(alpha: 0.8), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: tool.label == 'Jabon'
              ? Icon(
                  Icons.soap_outlined,
                  color: const Color(0xFF4A6472),
                  size: size * 0.48,
                )
              : Icon(
                  tool.icon,
                  color: const Color(0xFF4A6472),
                  size: size * 0.48,
                ),
        ),
      ),
    );
  }

  Widget _buildTub(Size size, bool canShowPet) {
    final expandedWidth = size.width * 0.78;
    final compactWidth = size.width * 0.56;
    final tubWidth = (_petInTub ? expandedWidth : compactWidth)
        .clamp(220.0, size.width * 0.82)
        .toDouble();
    final tubHeight = tubWidth * 0.62;
    final tubTransitionDuration = Duration(milliseconds: _petInTub ? 520 : 440);
    final tubSizeCurve = _petInTub ? Curves.easeOutBack : Curves.easeInOutCubic;

    return Center(
      child: DragTarget<_BathTool>(
        onWillAcceptWithDetails: (_) =>
            _petInTub && canShowPet && !_applyingBath,
        onAcceptWithDetails: (details) => _acceptBathTool(details.data),
        builder: (context, candidates, rejected) {
          final isHovering = candidates.isNotEmpty;

          return GestureDetector(
            onTap: () {
              if (_draggingBathTool || _recentBathToolDrop) return;
              if (!canShowPet) {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Tu mascota esta en otra pantalla.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                return;
              }
              if (_petInTub) {
                _sacarMascotaDeLaBanera();
                return;
              }
              setState(() => _petInTub = true);
            },
            child: AnimatedContainer(
              duration: tubTransitionDuration,
              curve: tubSizeCurve,
              width: tubWidth,
              height: tubHeight * 1.45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(48),
                boxShadow: isHovering
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.18),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ]
                    : const [],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: tubWidth * 0.85,
                      height: 14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.13),
                            blurRadius: 28,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: tubHeight * 0.02,
                    left: tubWidth * 0.13,
                    child: _buildTubLeg(tubWidth),
                  ),
                  Positioned(
                    bottom: tubHeight * 0.02,
                    right: tubWidth * 0.13,
                    child: _buildTubLeg(tubWidth),
                  ),
                  Positioned(
                    bottom: tubHeight * 0.09,
                    child: Container(
                      width: tubWidth,
                      height: tubHeight * 0.88,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Color(0xFFF5F5F7),
                            Color(0xFFE8E8ED),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                          bottomLeft: Radius.circular(110),
                          bottomRight: Radius.circular(110),
                        ),
                        border: Border.all(color: Colors.white, width: 6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: tubHeight * 0.80,
                    child: Container(
                      width: tubWidth * 1.04,
                      height: tubHeight * 0.22,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFFFFF), Color(0xFFEEEEF3)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: tubHeight * 0.38,
                    child: Container(
                      width: tubWidth * 0.55,
                      height: tubHeight * 0.10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: tubHeight * 0.10,
                    child: Container(
                      width: tubWidth * 0.13,
                      height: tubHeight * 0.10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDDDE4),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFFCCCCD4),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: tubHeight * 0.80,
                    right: tubWidth * 0.11,
                    child: Container(
                      width: tubWidth * 0.022,
                      height: tubHeight * 0.38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFFDDDDE4),
                          width: 0.8,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: tubHeight * 1.18,
                    right: tubWidth * 0.085,
                    child: Container(
                      width: tubWidth * 0.11,
                      height: tubHeight * 0.06,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFFDDDDE4),
                          width: 0.8,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: tubHeight * 1.185,
                    right: tubWidth * 0.074,
                    child: Container(
                      width: tubWidth * 0.06,
                      height: tubWidth * 0.06,
                      decoration: const BoxDecoration(
                        color: Color(0xFF86DE63),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: tubWidth * 0.034,
                          height: tubWidth * 0.034,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6FCC4E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_petInTub && canShowPet)
                    Positioned(
                      top: tubHeight * 0.18,
                      right: tubWidth * 0.05,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: const CircleBorder(),
                        elevation: 3,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _sacarMascotaDeLaBanera,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Color(0xFF58717D),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!_petInTub) ...[
                    Positioned(
                      bottom: tubHeight * 1.10,
                      right: tubWidth * 0.115,
                      child: _buildDrip(tubWidth, delay: 0),
                    ),
                    Positioned(
                      bottom: tubHeight * 0.98,
                      right: tubWidth * 0.115,
                      child: _buildDrip(tubWidth, delay: 800),
                    ),
                  ],
                  if (_petInTub)
                    Positioned(
                      bottom: tubHeight * 0.34,
                      left: 0,
                      right: 0,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) => Transform.scale(
                          scale: value,
                          alignment: Alignment.bottomCenter,
                          child: child,
                        ),
                        child: _buildPetInTubEmoji(tubWidth, tubHeight),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _sacarMascotaDeLaBanera() {
    if (!_petInTub) return;
    _soapBubbleTimer?.cancel();
    setState(() {
      _petInTub = false;
      _bathFeedback = 'La mascota salio de la banera.';
      _soapBubblesActive = false;
    });
  }

  Widget _buildTubLeg(double tubWidth) {
    final w = tubWidth * 0.08;
    final h = w * 1.35;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFE8E8ED)],
        ),
        borderRadius: BorderRadius.circular(w * 0.45),
        border: Border.all(color: const Color(0xFFDDDDE4), width: 0.8),
      ),
    );
  }

  Widget _buildDrip(double tubWidth, {int delay = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeIn,
      builder: (context, v, _) => Opacity(
        opacity: (1 - v).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, v * 22),
          child: Container(
            width: tubWidth * 0.022,
            height: tubWidth * 0.030,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPetInTubEmoji(double tubWidth, double tubHeight) {
    return AnimatedBuilder(
      animation: _bubbleFloat,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bubbleFloat.value),
          child: child,
        );
      },
      // TODO: Reemplazar este emoji por la animacion de Rive cuando este lista.
      child: SizedBox(
        width: tubWidth * 0.52,
        height: tubHeight * 0.42,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (_soapBubblesActive) ..._buildSoapBubbles(tubWidth, tubHeight),
            Text(
              _petEmoji(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: tubWidth * 0.28),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSoapBubbles(double tubWidth, double tubHeight) {
    final bubbleColor = Colors.white.withValues(alpha: 0.95);
    return [
      Positioned(
        top: tubHeight * 0.01,
        left: tubWidth * 0.12,
        child: _soapBubble(tubWidth * 0.055, bubbleColor),
      ),
      Positioned(
        top: tubHeight * 0.06,
        right: tubWidth * 0.10,
        child: _soapBubble(tubWidth * 0.042, bubbleColor),
      ),
      Positioned(
        top: tubHeight * 0.12,
        left: tubWidth * 0.06,
        child: _soapBubble(tubWidth * 0.038, bubbleColor),
      ),
      Positioned(
        top: tubHeight * 0.15,
        right: tubWidth * 0.20,
        child: _soapBubble(tubWidth * 0.030, bubbleColor),
      ),
      Positioned(
        bottom: tubHeight * 0.04,
        left: tubWidth * 0.16,
        child: _soapBubble(tubWidth * 0.034, bubbleColor),
      ),
      Positioned(
        bottom: tubHeight * 0.02,
        right: tubWidth * 0.14,
        child: _soapBubble(tubWidth * 0.028, bubbleColor),
      ),
    ];
  }

  Widget _soapBubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildPetOnFloor(Size size) {
    return AnimatedBuilder(
      animation: _bubbleFloat,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bubbleFloat.value * 0.5),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_petEmoji(), style: TextStyle(fontSize: size.width * 0.18)),
          const SizedBox(height: 4),
          Container(
            width: size.width * 0.12,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }

  String _petEmoji() {
    final isCat = context.read<PetCubit>().state.mascota?.tipoMascota == 'gato';
    return isCat ? '\u{1F431}' : '\u{1F436}';
  }

  Widget _buildHintCard(bool canShowPet) {
    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state) {
        final mascota = state.mascota;
        if (mascota == null) {
          return const SizedBox.shrink();
        }
        if (!canShowPet) {
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
            child: const Text(
              'Tu mascota esta ocupada en otra pantalla.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF58717D),
              ),
            ),
          );
        }
        final mensaje = !_petInTub
            ? 'La banera esta vacia. Toca la banera para meter a la mascota.'
            : (_bathFeedback.isNotEmpty
                  ? _bathFeedback
                  : 'Toca la banera otra vez o la X para sacarla.');

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
            mensaje,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF58717D),
            ),
          ),
        );
      },
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
