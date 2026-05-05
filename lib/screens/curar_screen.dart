import 'dart:math' as math;

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
import '../widgets/paw_map_widget.dart';
import '../widgets/pet_avatar_rive.dart';

class CurarScreen extends StatefulWidget {
  const CurarScreen({super.key});

  @override
  State<CurarScreen> createState() => _CurarScreenState();
}

class _CurarScreenState extends State<CurarScreen>
    with SingleTickerProviderStateMixin {
  bool _kitOpen = true;
  bool _showDiagnosis = false;
  bool _showFever = false;
  bool _showHearts = false;
  bool _showShock = false;
  String _feedback = 'Arrastra el termÃ³metro para revisar a tu mascota';
  bool _draggingTool = false;

  late final AnimationController _petCtrl;
  late final Animation<double> _petFloat;

  @override
  void initState() {
    super.initState();
    _petCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _petFloat = Tween<double>(
      begin: 0,
      end: -8,
    ).animate(CurvedAnimation(parent: _petCtrl, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWorldEntry());
  }

  Future<void> _syncWorldEntry() async {
    if (!mounted) return;
    final mascota = context.read<PetCubit>().state.mascota;
    if (mascota == null) return;
    await context.read<PetWorldCubit>().syncScreenEntry(
      mascota: mascota,
      location: PetLocation.curar,
      fallbackActivity: PetActivity.idle,
    );
  }

  @override
  void dispose() {
    _petCtrl.dispose();
    super.dispose();
  }

  void _flashFlag(void Function(bool) setter, {int ms = 900}) {
    setter(true);
    Future.delayed(Duration(milliseconds: ms), () {
      if (mounted) setter(false);
    });
  }

  void _diagnose() {
    setState(() {
      _showDiagnosis = true;
      _feedback = 'Fiebre detectada. Ya puedes usar los instrumentos';
    });
    _flashFlag((v) => setState(() => _showFever = v), ms: 1100);
  }

  void _applyMedicine() {
    context.read<PetCubit>().curar();
    setState(() => _feedback = 'Medicina aplicada. La salud sube bastante');
    _flashFlag((v) => setState(() => _showShock = v), ms: 1000);
  }

  void _applyBandage() {
    context.read<PetCubit>().curar();
    setState(() => _feedback = 'Curita colocada. La herida mejora');
  }

  void _applyBrush() {
    context.read<PetCubit>().banar();
    setState(() => _feedback = 'Cepillado exitoso. Mas carino y limpieza');
    _flashFlag((v) => setState(() => _showHearts = v), ms: 900);
  }

  void _applyVaccine() {
    context.read<PetCubit>().curar();
    setState(() => _feedback = 'Vacuna aplicada. Proteccion temporal activa');
  }

  void _handleTool(String tool) {
    if (tool == 'thermometer') _diagnose();
    if (tool == 'medicine') _applyMedicine();
    if (tool == 'bandage') _applyBandage();
    if (tool == 'brush') _applyBrush();
    if (tool == 'vaccine') _applyVaccine();
  }

  void _handleDrop(String tool) {
    setState(() => _draggingTool = false);
    _handleTool(tool);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => mostrarMapaHuella(context),
        backgroundColor: AppColors.verdeFondo,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.pets, color: AppColors.azulPrincipal, size: 28),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 400) {
            context.go(AppRoutes.home);
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF6FBF4), Color(0xFFEAF6E9), Color(0xFFE5F1E7)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _DotBackgroundPainter()),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    BlocBuilder<PetCubit, PetState>(
                      builder: (context, petState) {
                        return Column(
                          children: [
                            _buildTopHeader(size, petState),
                            const SizedBox(height: 12),
                            _buildMonitorRow(petState),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Column(
                        children: [
                          _buildFeedbackBubble(),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildPetZone(),
                                  const SizedBox(height: 10),
                                  _buildTable(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildActionCards(),
                          const SizedBox(height: 10),
                          _buildBottomNav(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_kitOpen) _buildKitPanel(),
              if (_showDiagnosis) _buildDiagnosisOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(Size size, PetState petState) {
    final energia = petState.mascota?.nivelEnergia ?? 65;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.verdeClaro.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.monitor_heart_outlined,
                color: AppColors.verdePrincipal,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hospital',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF16233E),
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'de Mascotas',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF16233E),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: math.min(size.width * 0.42, 290),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F2FA),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFCAE4C1), width: 3),
              ),
              child: Row(
                children: [
                  const Text(
                    'âš¡',
                    style: TextStyle(fontSize: 20, color: Color(0xFF0A6E0C)),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'ENERGÃA',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0A6E0C),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$energia%',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0A6E0C),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'âš¡',
                    style: TextStyle(fontSize: 22, color: Color(0xFF7DDD5B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitorRow(PetState petState) {
    final salud = petState.mascota?.nivelSalud ?? 100;
    final isSick = salud < 70;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 150,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFE1F0DC), width: 2),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  left: 18,
                  right: 18,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9EDD0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 18,
                  child: Container(
                    width: 36,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0D7DC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 18,
                  child: Container(
                    width: 36,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC3D3FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFA0A9A8),
                borderRadius: BorderRadius.circular(26),
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
                  Center(
                    child: Text(
                      isSick
                          ? 'â–â–‚â–â–ƒâ–â–â–'
                          : 'â–â–â–â–â–â–â–',
                      style: const TextStyle(
                        fontSize: 52,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD8FFBF),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 12,
                    child: Text(
                      isSick ? 'Fiebre detectada' : 'Todo bien',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFEFF9E8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          _feedback,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4B5A4C),
          ),
        ),
      ),
    );
  }

  Widget _buildPetZone() {
    final worldState = context.watch<PetWorldCubit>().state;
    final canShowPet =
        !worldState.isLocationLocked ||
        worldState.location == PetLocation.curar;

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) {
        if (!canShowPet) {
          setState(() => _draggingTool = false);
          return false;
        }
        setState(() => _draggingTool = true);
        return true;
      },
      onLeave: (_) => setState(() => _draggingTool = false),
      onAcceptWithDetails: (details) {
        if (!canShowPet) return;
        _handleDrop(details.data);
      },
      builder: (context, accepted, rejected) {
        if (!canShowPet) {
          return Container(
            width: 320,
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white.withValues(alpha: 0.28),
            ),
            child: const Center(
              child: Text(
                'Tu mascota esta ocupada en otra pantalla.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4B5A4C),
                ),
              ),
            ),
          );
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 320,
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _draggingTool
                  ? AppColors.verdePrincipal
                  : Colors.transparent,
              width: 3,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 20,
                left: 20,
                child: Opacity(
                  opacity: 0.18,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.add_box_outlined,
                        size: 34,
                        color: AppColors.verdePrincipal,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 30,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7D7DC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 22,
                right: 18,
                child: Opacity(
                  opacity: 0.18,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.medication_outlined,
                        size: 34,
                        color: AppColors.azulPrincipal,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 30,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC3D3FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _petFloat,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _petFloat.value),
                    child: child,
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    BlocBuilder<PetCubit, PetState>(
                      builder: (context, state) {
                        return PetAvatarRive(
                          tipoMascota: (state.mascota?.tipoMascota ?? 'perro')
                              .toLowerCase(),
                          width: 210,
                          height: 210,
                        );
                      },
                    ),
                    Positioned(
                      bottom: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Arrastra aquÃ­ los instrumentos',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6B786E),
                          ),
                        ),
                      ),
                    ),
                    if (_showFever)
                      const Positioned(
                        top: 20,
                        right: 8,
                        child: Text(
                          'ðŸŒ¡ï¸ðŸ”¥',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    if (_showHearts)
                      const Positioned(
                        top: 18,
                        left: 12,
                        child: Text('ðŸ’šðŸ’š', style: TextStyle(fontSize: 24)),
                      ),
                    if (_showShock)
                      const Positioned(
                        top: 18,
                        child: Text('ðŸ˜µ', style: TextStyle(fontSize: 24)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTable() {
    return SizedBox(
      width: 390,
      height: 160,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Container(
              height: 82,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(44),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 50,
            right: 50,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFD8EBD2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 96,
            top: 90,
            child: Container(
              width: 38,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFD7DDE8),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Positioned(
            right: 96,
            top: 90,
            child: Container(
              width: 38,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFD7DDE8),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              icon: 'ðŸ§°',
              label: 'Curar',
              color: const Color(0xFFF3A7B6),
              helper: 'BotiquÃ­n',
              draggable: true,
              onDragStart: () => 'medicine',
              onTap: _applyMedicine,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _ActionCard(
              icon: 'ðŸ©º',
              label: 'Chequeo',
              color: const Color(0xFF87A2FF),
              helper: 'Revisar',
              draggable: true,
              onDragStart: () => 'thermometer',
              onTap: _diagnose,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _ActionCard(
              icon: 'ðŸ’Š',
              label: 'Vitamina',
              color: const Color(0xFF88E36A),
              helper: 'EnergÃ­a',
              draggable: true,
              onDragStart: () => 'vaccine',
              onTap: _applyVaccine,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Icon(Icons.home, color: Color(0xFF9AA8B8), size: 28),
            Icon(Icons.pets, color: Color(0xFF9AA8B8), size: 28),
            _PillCenter(),
            Icon(Icons.local_dining, color: Color(0xFF9AA8B8), size: 28),
            Icon(Icons.sports_esports, color: Color(0xFF9AA8B8), size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildKitPanel() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 124,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Herramientas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF51605A),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _kitOpen = false),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF51605A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
              children: [
                _toolCard(
                  icon: 'ðŸŒ¡ï¸',
                  label: 'TermÃ³metro',
                  color: const Color(0xFFFFD788),
                  helper: 'Paso previo',
                  tool: 'thermometer',
                  enabled: true,
                ),
                _toolCard(
                  icon: 'ðŸ’Š',
                  label: 'Medicina',
                  color: const Color(0xFF8AE670),
                  helper: 'Sube salud',
                  tool: 'medicine',
                  enabled: true,
                ),
                _toolCard(
                  icon: 'ðŸ©¹',
                  label: 'Curita',
                  color: const Color(0xFFF5B6C1),
                  helper: 'Heridas',
                  tool: 'bandage',
                  enabled: true,
                ),
                _toolCard(
                  icon: 'ðŸª®',
                  label: 'Cepillo',
                  color: const Color(0xFF8AA2FF),
                  helper: 'CariÃ±o',
                  tool: 'brush',
                  enabled: true,
                ),
                _toolCard(
                  icon: 'ðŸ’‰',
                  label: 'Vacuna',
                  color: const Color(0xFFB1F07E),
                  helper: '1 vez/semana',
                  tool: 'vaccine',
                  enabled: !false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolCard({
    required String icon,
    required String label,
    required Color color,
    required String helper,
    required String tool,
    required bool enabled,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? () => _handleTool(tool) : null,
        child: Draggable<String>(
          data: tool,
          feedback: Material(
            color: Colors.transparent,
            child: _MiniToolTile(icon: icon, label: label, color: color),
          ),
          onDragStarted: () => setState(() => _draggingTool = true),
          onDragEnd: (_) => setState(() => _draggingTool = false),
          child: _MiniToolTile(
            icon: icon,
            label: label,
            color: color,
            helper: helper,
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosisOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          color: Colors.black.withValues(alpha: 0.18),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ðŸ©º', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 10),
                  const Text(
                    'DiagnÃ³stico listo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF243448),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Se desbloquean los instrumentos de curaciÃ³n.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6F7F73),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => setState(() => _showDiagnosis = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.verdePrincipal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final String helper;
  final bool draggable;
  final String Function() onDragStart;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.helper,
    required this.draggable,
    required this.onDragStart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Draggable<String>(
        data: onDragStart(),
        feedback: Material(
          color: Colors.transparent,
          child: _ActionTile(
            icon: icon,
            label: label,
            color: color,
            helper: helper,
          ),
        ),
        child: _ActionTile(
          icon: icon,
          label: label,
          color: color,
          helper: helper,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final String helper;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.55),
            blurRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF273148),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            helper,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF7C8A8B),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniToolTile extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final String? helper;

  const _MiniToolTile({
    required this.icon,
    required this.label,
    required this.color,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 82,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.55),
            blurRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Color(0xFF243448),
            ),
          ),
          if (helper != null)
            Text(
              helper!,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7C8A8B),
              ),
            ),
        ],
      ),
    );
  }
}

class _PillCenter extends StatelessWidget {
  const _PillCenter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: const BoxDecoration(
        color: Color(0xFF8AE670),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x558AE670),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.local_hospital, color: Colors.white, size: 34),
    );
  }
}

class _DotBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF87D95B).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    const step = 28.0;
    for (double y = 14; y < size.height; y += step) {
      for (double x = 14; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
