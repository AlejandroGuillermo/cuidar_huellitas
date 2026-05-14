import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../application/cubits/pet_world_cubit.dart';
import '../core/app_colors.dart';
import '../core/app_router.dart';
import '../core/personality_config.dart';
import '../cubit/pet_cubit.dart';
import '../domain/enums/pet_activity.dart';
import '../domain/enums/pet_location.dart';
import '../widgets/action_screen_header.dart';
import '../widgets/banar/estropajo_tool_widget.dart';
import '../widgets/banar/manguera_tool_widget.dart';
import '../widgets/banar/soap_tool_widget.dart';
import '../widgets/banar/toalla_tool_widget.dart';
import '../widgets/paw_map_widget.dart';
import 'banar/cubit/banar_cubit.dart';
import 'banar/cubit/banar_state.dart';
import 'banar/widgets/bath_pet_in_tub_widget.dart';
import 'banar/widgets/bath_pet_on_floor_widget.dart';
import 'banar/widgets/bath_progress_panel_widget.dart';
import 'banar/widgets/bath_scene_widget.dart';
import 'banar/widgets/bath_status_widget.dart';
import 'banar/widgets/bath_toolbar_widget.dart';
import 'banar/widgets/bath_tub_widget.dart';

class BanarScreen extends StatefulWidget {
  const BanarScreen({super.key});

  @override
  State<BanarScreen> createState() => _BanarScreenState();
}

class _BanarScreenState extends State<BanarScreen> {
  static const int _maxBathEscapes = 3;

  bool _applyingBathReward = false;
  DateTime? _lastEscapeAttemptAt;
  Timer? _bathMovementTimer;
  Timer? _bathCalmTimer;

  late final BanarCubit _banarCubit;
  final Random _random = Random();

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

  List<BathToolbarItemData<_BathTool>> get _toolbarItems => _tools
      .map(
        (tool) => BathToolbarItemData<_BathTool>(
          data: tool,
          label: tool.label,
          color: tool.color,
          enabled:
              _petInTub &&
              _canUseBathTools &&
              (tool.label != 'Toalla' || _canUseTowel),
          resetNonce: _toolResetNonce,
          iconBuilder: (size, enabled) => _buildToolIcon(
            tool,
            size: size,
            enabled: enabled,
          ),
          feedbackBuilder: (size) => _buildToolFeedback(tool, size: size),
          onDragStarted: () {
            _setDraggingBathTool(true);
            _banarCubit.setActiveDraggedToolLabel(tool.label);
          },
          onDragEnded: () => _setDraggingBathTool(false),
        ),
      )
      .toList();

  @override
  void initState() {
    super.initState();
    _banarCubit = BanarCubit();
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

  PersonalityConfig? get _currentPersonalityConfig {
    final mascota = context.read<PetCubit>().state.mascota;
    if (mascota == null) return null;
    return PersonalityRegistry.get(mascota.rasgo);
  }

  BanarState get _bathState => _banarCubit.state;

  bool get _isBathDifficult =>
      _currentPersonalityConfig?.acciones.banarDificil ?? false;
  bool get _canEscapeBath =>
      _currentPersonalityConfig?.acciones.banarEscapa ?? false;
  bool get _petInTub => _bathState.petInTub;
  double get _dragOffset => _bathState.dragOffset;
  bool get _draggingBathTool => _bathState.draggingBathTool;
  String? get _activeDraggedToolLabel => _bathState.activeDraggedToolLabel;
  int get _soapProgress => _bathState.soapProgress;
  double get _soapProgressRaw => _bathState.soapProgressRaw;
  int get _scrubProgress => _bathState.scrubProgress;
  double get _scrubProgressRaw => _bathState.scrubProgressRaw;
  int get _rinseProgress => _bathState.rinseProgress;
  double get _rinseProgressRaw => _bathState.rinseProgressRaw;
  int get _towelProgress => _bathState.towelProgress;
  double get _towelProgressRaw => _bathState.towelProgressRaw;
  String? get _bathStatusMessage => _bathState.bathStatusMessage;
  double get _petTubOffsetX => _bathState.petTubOffsetX;
  double get _petTubOffsetY => _bathState.petTubOffsetY;
  bool get _petIsCalm => _bathState.petIsCalm;
  int get _calmProgress => _bathState.calmProgress;
  double get _calmProgressRaw => _bathState.calmProgressRaw;
  int get _toolResetNonce => _bathState.toolResetNonce;
  int get _bathEscapeCount => _bathState.bathEscapeCount;
  bool get _hasBathProgress => _bathState.hasBathProgress;
  bool get _requiresCalmingBeforeTools => _isBathDifficult;
  bool get _canUseBathTools => !_requiresCalmingBeforeTools || _petIsCalm;
  bool get _canUseTowel => _bathState.canUseTowel;

  void _setDraggingBathTool(bool value) {
    if (!mounted) return;
    _banarCubit.setDraggingBathTool(value);
  }

  @override
  void dispose() {
    _stopBathPersonalityEffects();
    _banarCubit.close();
    super.dispose();
  }

  void _meterMascotaEnLaBanera({bool resetProgress = true}) {
    _banarCubit.enterTub(resetProgress: resetProgress);
    _startBathPersonalityEffects();
  }

  void _sacarMascotaDeLaBanera({bool clearStatus = false}) {
    _stopBathPersonalityEffects();
    _banarCubit.exitTub(clearStatus: clearStatus);
  }

  void _startBathPersonalityEffects() {
    _stopBathPersonalityEffects(resetPosition: false);
    if (!_isBathDifficult) return;
    _bathMovementTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      _movePetInsideTub();
    });
    _movePetInsideTub();
  }

  void _stopBathPersonalityEffects({bool resetPosition = true}) {
    _bathMovementTimer?.cancel();
    _bathMovementTimer = null;
    _bathCalmTimer?.cancel();
    _bathCalmTimer = null;
    _banarCubit.resetPersonalityEffects(resetPosition: resetPosition);
  }

  void _movePetInsideTub() {
    if (!mounted || !_petInTub || !_isBathDifficult) return;
    _banarCubit.movePetInsideTub(
      offsetX: (_random.nextDouble() * 0.34) - 0.17,
      offsetY: (_random.nextDouble() * 0.14) - 0.02,
    );
  }

  void _maybeTriggerBathEscape() {
    if (!_petInTub || !_canEscapeBath || _bathEscapeCount >= _maxBathEscapes) {
      return;
    }

    final now = DateTime.now();
    if (_lastEscapeAttemptAt != null &&
        now.difference(_lastEscapeAttemptAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastEscapeAttemptAt = now;

    final progressFactor = (_soapProgressRaw +
            _scrubProgressRaw +
            _rinseProgressRaw +
            _towelProgressRaw) /
        400;
    final escapeChance = 0.16 + (progressFactor * 0.18);
    if (_random.nextDouble() >= escapeChance) return;

    _sacarMascotaDeLaBanera();
    _banarCubit.registerEscape(
      'Tu mascota se escapo del bano. Vuelve a meterla en la banera.',
    );
  }

  int get _bathAffectionPerCalmStep {
    final rasgo = _currentPersonalityConfig?.rasgo ?? '';
    return rasgo == 'Cariñoso' ? 2 : 1;
  }

  Duration _randomBathCalmDuration() {
    final seconds = 3 + _random.nextInt(3);
    return Duration(seconds: seconds);
  }

  void _extendBathCalmWindow() {
    if (!_petIsCalm || !_petInTub) return;
    _bathCalmTimer?.cancel();
    _bathCalmTimer = Timer(_randomBathCalmDuration(), () {
      if (!mounted || !_petInTub || !_isBathDifficult) return;
      _banarCubit.expireCalm('Tu mascota se inquieto. Acariciala otra vez.');
      _startBathPersonalityEffects();
    });
  }

  Future<void> _soothePet(DragUpdateDetails details) async {
    if (!_petInTub || !_requiresCalmingBeforeTools || _draggingBathTool) {
      return;
    }
    if (details.delta.distance <= 2.5) return;

    final previousStep = _calmProgress;
    final nextRaw = (_calmProgressRaw + (details.delta.distance * 0.9)).clamp(
      0.0,
      100.0,
    );
    final nextStep = ((nextRaw / 25).floor() * 25).clamp(0, 100).toInt();

    if (nextRaw == _calmProgressRaw && nextStep == _calmProgress) return;

    _banarCubit.updateCalmProgress(
      rawProgress: nextRaw,
      steppedProgress: nextStep,
      petIsCalm: nextStep >= 100,
      message: nextStep >= 100
          ? 'Ya esta quieta. Ahora usa una herramienta.'
          : 'Acariciala para calmarla $nextStep%.',
    );

    if (nextStep > previousStep) {
      unawaited(
        context.read<PetCubit>().aumentarAfecto(
          _bathAffectionPerCalmStep,
          accion: 'banar_acariciar',
        ),
      );
    }

    if (nextStep >= 100) {
      _bathMovementTimer?.cancel();
      _bathMovementTimer = null;
      _extendBathCalmWindow();
    }
  }

  bool _canAcceptPetTool(_BathTool? tool) {
    return _banarCubit.canAcceptTool(
      label: tool?.label,
      canUseBathTools: _canUseBathTools,
      applyingBathReward: _applyingBathReward,
    );
  }

  void _applySoapDrop(_BathTool tool) {
    if (tool.label != 'Jabon' || !_canUseBathTools) return;
    _setDraggingBathTool(false);
    _increaseSoapProgress(3);
  }

  void _increaseSoapProgress(double delta) {
    if (!_petInTub || !_canUseBathTools || delta <= 0 || _soapProgress >= 100) {
      return;
    }
    _banarCubit.increaseSoapProgress(delta);
    _movePetInsideTub();
    _maybeTriggerBathEscape();
  }

  void _showBathWarning(String message) {
    if (!_petInTub) return;
    _banarCubit.showBathWarning(message);
  }

  void _scrubPet(double delta) {
    if (!_petInTub || !_canUseBathTools || delta <= 0) return;
    final result = _banarCubit.scrub(delta);
    if (result.hasWarning) {
      _showBathWarning(result.warning!);
      return;
    }
    _movePetInsideTub();
    _maybeTriggerBathEscape();
  }

  void _rinseSoap(double delta) {
    if (!_petInTub || !_canUseBathTools || delta <= 0) return;
    final result = _banarCubit.rinseSoap(delta);
    if (result.hasWarning) {
      _showBathWarning(result.warning!);
      return;
    }
    _movePetInsideTub();
    _maybeTriggerBathEscape();
  }

  Future<void> _dryPet(double delta) async {
    if (!_petInTub || !_canUseBathTools || delta <= 0 || _applyingBathReward) {
      return;
    }
    final result = _banarCubit.dry(
      delta: delta,
      applyingBathReward: _applyingBathReward,
    );
    if (result.hasWarning) {
      _showBathWarning(result.warning!);
      return;
    }

    if (result.completed) {
      _applyingBathReward = true;
    }
    _movePetInsideTub();
    _maybeTriggerBathEscape();

    if (!result.completed) return;

    await context.read<PetCubit>().banar();
    if (!mounted) return;
    _applyingBathReward = false;
    _banarCubit.finishBathReward('Bano completado. Limpieza aplicada.');
    _stopBathPersonalityEffects();
  }

  @override
  Widget build(BuildContext context) {
    final worldState = context.watch<PetWorldCubit>().state;
    final canShowPet =
        !worldState.isLocationLocked ||
        worldState.location == PetLocation.banar;

    if (!canShowPet && _petInTub) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _sacarMascotaDeLaBanera();
      });
    }

    return BlocProvider.value(
      value: _banarCubit,
      child: BlocBuilder<BanarCubit, BanarState>(
        builder: (context, state) {
          final viewportSize = MediaQuery.of(context).size;

          return GestureDetector(
            onHorizontalDragUpdate: (details) {
              if (_draggingBathTool || _petInTub) return;
              if (details.delta.dx > 0) {
                _banarCubit.setDragOffset(
                  (_dragOffset + details.delta.dx).clamp(
                    0.0,
                    viewportSize.width,
                  ),
                );
              }
            },
            onHorizontalDragEnd: (details) {
              if (_draggingBathTool || _petInTub) return;
              if (_dragOffset > viewportSize.width * 0.3 ||
                  (details.primaryVelocity ?? 0) > 500) {
                context.go(AppRoutes.dormir);
              } else {
                _banarCubit.setDragOffset(0);
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
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _buildPawMapButton(),
                ),
              ],
            ),
          );
        },
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
    final tubBottomExpanded = floorHeight * 0.14;
    final transitionDuration = Duration(milliseconds: _petInTub ? 520 : 440);
    final positionCurve = _petInTub
        ? Curves.easeOutBack
        : Curves.easeInOutCubic;

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
    final showBathStatus =
        _petInTub &&
        (_bathStatusMessage != null ||
            _soapProgress > 0 ||
            _scrubProgress > 0 ||
            (_requiresCalmingBeforeTools && !_petIsCalm));
    final bathStatusBottom = (tubBottom - 54).clamp(12.0, size.height * 0.18);
    final showProgressPanel = _petInTub && canShowPet;

    return BathSceneWidget(
      floorHeight: floorHeight,
      petFloorBottom: petFloorBottom,
      showProgressPanel: showProgressPanel,
      progressPanel: BathProgressPanelWidget(
        size: size,
        soapProgress: _soapProgress,
        scrubProgress: _scrubProgress,
        rinseProgress: _rinseProgress,
        towelProgress: _towelProgress,
      ),
      showToolBar: showToolBar,
      toolBarLeft: toolBarLeft,
      toolBarAboveTubBottom: toolBarAboveTubBottom,
      petInTub: _petInTub,
      toolBar: BathToolbarWidget<_BathTool>(
        width: toolBarWidth,
        items: _toolbarItems,
      ),
      canShowPet: canShowPet,
      petOnFloor: _buildPetOnFloor(size),
      transitionDuration: transitionDuration,
      positionCurve: positionCurve,
      tubBottom: tubBottom,
      tub: _buildTub(canShowPet),
      showBathStatus: showBathStatus,
      bathStatusBottom: bathStatusBottom,
      bathStatus: BathStatusWidget(
        text: _bathStatusMessage ??
            _bathState.buildStepStatusText(
              requiresCalmingBeforeTools: _requiresCalmingBeforeTools,
            ),
      ),
      wall: _buildWall(),
      floor: _buildFloor(),
      mirror: _buildMirror(),
      sizeHeight: size.height,
      sizeWidth: size.width,
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

  Widget _buildToolIcon(
    _BathTool tool, {
    required double size,
    required bool enabled,
  }) {
    if (tool.label == 'Jabon') {
      return SoapToolWidget(enabled: enabled, size: size);
    }
    if (tool.label == 'Estropajo') {
      return EstropajoToolWidget(enabled: enabled, size: size);
    }
    if (tool.label == 'Manguera') {
      return MangueraToolWidget(enabled: enabled, size: size);
    }
    if (tool.label == 'Toalla') {
      return ToallaToolWidget(enabled: enabled, size: size);
    }

    return Icon(tool.icon, color: const Color(0xFF4A6472), size: size * 0.45);
  }

  Widget _buildToolFeedback(_BathTool tool, {required double size}) {
    if (tool.label == 'Jabon') {
      return Material(
        color: Colors.transparent,
        child: IgnorePointer(
          child: SoapToolWidget(enabled: true, size: size),
        ),
      );
    }
    if (tool.label == 'Manguera') {
      return Material(
        color: Colors.transparent,
        child: IgnorePointer(
          child: MangueraToolWidget(enabled: true, size: size),
        ),
      );
    }
    if (tool.label == 'Estropajo') {
      return Material(
        color: Colors.transparent,
        child: IgnorePointer(
          child: EstropajoToolWidget(enabled: true, size: size),
        ),
      );
    }
    if (tool.label == 'Toalla') {
      return Material(
        color: Colors.transparent,
        child: IgnorePointer(
          child: ToallaToolWidget(enabled: true, size: size),
        ),
      );
    }

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
          child: Icon(
            tool.icon,
            color: const Color(0xFF4A6472),
            size: size * 0.48,
          ),
        ),
      ),
    );
  }

  Widget _buildTub(bool canShowPet) {
    return BathTubWidget(
      petInTub: _petInTub,
      canShowPet: canShowPet,
      draggingBathTool: _draggingBathTool,
      onTapTub: () {
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
          _sacarMascotaDeLaBanera(clearStatus: true);
          return;
        }
        _meterMascotaEnLaBanera(resetProgress: !_hasBathProgress);
      },
      buildTubLeg: _buildTubLeg,
      buildDrip: _buildDrip,
      buildPetInTub: _buildPetInTub,
    );
  }

  Widget _buildPetInTub(double tubWidth) {
    final petSize = (tubWidth * 0.98).clamp(164.0, 220.0);
    final isHoveringTool = _activeDraggedToolLabel == 'Jabon' ||
        _activeDraggedToolLabel == 'Estropajo';

    return BathPetInTubWidget<_BathTool>(
      petSize: petSize,
      canAcceptTool: _canAcceptPetTool,
      onMoveTool: (details) {
        if (!_canUseBathTools) return;
        final tool = details.data;
        if (tool.label == 'Jabon') {
          _increaseSoapProgress(0.6);
        } else if (tool.label == 'Estropajo') {
          _scrubPet(0.6);
        } else if (tool.label == 'Manguera') {
          _rinseSoap(0.6);
        } else if (tool.label == 'Toalla') {
          _dryPet(0.6);
        }
      },
      onAcceptTool: (details) => _applySoapDrop(details.data),
      isHoveringTool: isHoveringTool,
      onPanUpdate: _soothePet,
      slideDuration: Duration(milliseconds: _isBathDifficult ? 380 : 220),
      slideOffset: Offset(_petTubOffsetX, _petTubOffsetY),
      tipoMascota: _tipoMascotaActual(),
    );
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

  Widget _buildPetOnFloor(Size size) {
    final petSize = (size.width * 0.38).clamp(130.0, 190.0);
    return BathPetOnFloorWidget(
      petSize: petSize,
      tipoMascota: _tipoMascotaActual(),
    );
  }

  String _tipoMascotaActual() {
    return context.read<PetCubit>().state.mascota?.tipoMascota ?? 'perro';
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
