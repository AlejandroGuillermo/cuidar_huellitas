import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../Models/mascota_model.dart';
import '../application/cubits/pet_world_cubit.dart';
import '../core/app_colors.dart';
import '../core/app_router.dart';
import '../core/personality_config.dart';
import '../cubit/pet_cubit.dart';
import '../cubit/pet_state.dart';
import '../domain/enums/pet_activity.dart';
import '../domain/enums/pet_location.dart';
import '../widgets/botiquin_widget.dart';
import '../widgets/header_widget.dart';
import '../widgets/pet_avatar_rive.dart';
import '../widgets/paw_map_widget.dart';

class CurarScreen extends StatefulWidget {
  final String petName;
  final double healthPercent;

  const CurarScreen({
    super.key,
    this.petName = 'Copito',
    this.healthPercent = 0.75,
  });

  @override
  State<CurarScreen> createState() => _CurarScreenState();
}

class _CurarScreenState extends State<CurarScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartController;
  late final Animation<double> _heartAnim;
  bool _escaneando = false;
  bool _mostrandoResultado = false;
  String? _diagnosticoActual;
  String? _itemSeleccionado;
  String _textoEscaneo = 'Arrastra el escaner hacia tu mascota para revisarla.';
  String? _tipoEfectoActivo;
  String? _resumenStats;
  String? _ultimoErrorBotiquin;
  bool _botiquinAbierto = false;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _heartAnim = CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWorldEntry());
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  bool _stockAgotado(MascotaModel mascota, String tipoItem) {
    return (mascota.runtime.inventarioBotiquin[tipoItem] ?? 0) <= 0;
  }

  bool _cumpleCondicion(MascotaModel mascota, String tipoItem) {
    return switch (tipoItem) {
      'venda' => true,
      'suero' =>
        mascota.nivelEnergia < 40 ||
            mascota.nivelHambre < 40 ||
            mascota.ticksEnergiaBaja >= 1,
      'aroma' =>
        mascota.nivelAfecto < 40 ||
            mascota.nivelLimpieza < 40 ||
            mascota.anomaliaActiva,
      _ => false,
    };
  }

  Duration? _cooldownRestante(MascotaModel mascota) {
    final ultimaCuracion = mascota.ultimaCuracion;
    if (ultimaCuracion == null) return null;
    final restante =
        const Duration(hours: 2) - DateTime.now().difference(ultimaCuracion);
    return restante.isNegative ? null : restante;
  }

  String _textoNarrativo(MascotaModel mascota, String tipoItem) {
    return switch (tipoItem) {
      'venda' => 'Detectado: dano fisico. Aplicando tratamiento...',
      'suero' => 'Detectado: agotamiento. Administrando suero...',
      'aroma' => 'Detectado: estres emocional. Iniciando terapia...',
      _ => 'Escaneo en curso...',
    };
  }

  String _textoDiagnostico(String? tipoItem) {
    return switch (tipoItem) {
      'venda' => 'Detectado: dano fisico. Se recomienda usar venda.',
      'suero' => 'Detectado: agotamiento. Se recomienda aplicar suero.',
      'aroma' => 'Detectado: estres emocional. Se recomienda aromaterapia.',
      _ => 'No se detectaron sintomas. No necesita tratamiento.',
    };
  }

  String _resumenTratamiento(MascotaModel mascota, String tipoItem) {
    final modsAccion = PersonalityRegistry.get(mascota.rasgo)?.acciones;

    String formatValue(double value) => value.round().toString();

    return switch (tipoItem) {
      'venda' =>
        '+${formatValue(30 * (1 + ((modsAccion?.vendaSalud ?? 0).toDouble())))} Salud  +${formatValue(5 * (1 + ((modsAccion?.vendaAfecto ?? 0).toDouble())))} Afecto',
      'suero' =>
        '+${formatValue(25 * (1 + ((modsAccion?.sueroEnergia ?? 0).toDouble())))} Energia  +${formatValue(20 * (1 + ((modsAccion?.sueroHambre ?? 0).toDouble())))} Hambre  +${formatValue(5 * (1 + ((modsAccion?.sueroSalud ?? 0).toDouble())))} Salud',
      'aroma' =>
        '+${formatValue(25 * (1 + ((modsAccion?.aromaAfecto ?? 0).toDouble())))} Afecto  +${formatValue(15 * (1 + ((modsAccion?.aromaLimpieza ?? 0).toDouble())))} Limpieza  +${formatValue(5 * (1 + ((modsAccion?.aromaSalud ?? 0).toDouble())))} Salud',
      _ => '',
    };
  }

  void _toggleBotiquin() {
    if (_diagnosticoActual == null) {
      _mostrarSnackError('escanear_primero');
      return;
    }
    setState(() {
      _botiquinAbierto = !_botiquinAbierto;
    });
  }

  String? _resolverDiagnostico(MascotaModel mascota) {
    if (mascota.nivelSalud < 60) return 'venda';
    if (mascota.nivelEnergia < 40 ||
        mascota.nivelHambre < 40 ||
        mascota.ticksEnergiaBaja >= 1) {
      return 'suero';
    }
    if (mascota.nivelAfecto < 40 ||
        mascota.nivelLimpieza < 40 ||
        mascota.anomaliaActiva) {
      return 'aroma';
    }
    return null;
  }

  Future<void> _aplicarTratamiento(MascotaModel mascota, String tipoItem) async {
    if (_stockAgotado(mascota, tipoItem)) {
      _mostrarSnackError('sin_stock');
      return;
    }
    if (tipoItem == 'venda' && _cooldownRestante(mascota) != null) {
      _mostrarSnackError('cooldown_activo');
      return;
    }
    if (tipoItem != 'venda' && !_cumpleCondicion(mascota, tipoItem)) {
      _mostrarSnackError('condicion_no_cumplida');
      return;
    }
    setState(() {
      _botiquinAbierto = false;
      _itemSeleccionado = tipoItem;
      _mostrandoResultado = false;
      _tipoEfectoActivo = null;
      _resumenStats = null;
    });

    await context.read<PetCubit>().usarItemBotiquin(tipoItem);
    if (!mounted) return;

    final error = context.read<PetCubit>().botiquinError;
    if (error != null) {
      setState(() {
        _textoEscaneo = _diagnosticoActual == null
            ? 'Arrastra el escaner hacia tu mascota para revisarla.'
            : _textoDiagnostico(_diagnosticoActual!);
        _tipoEfectoActivo = null;
        _resumenStats = null;
        _mostrandoResultado = false;
      });
      return;
    }

    setState(() {
      _tipoEfectoActivo = tipoItem;
      _resumenStats = _resumenTratamiento(mascota, tipoItem);
      _textoEscaneo = _textoNarrativo(mascota, tipoItem);
      _mostrandoResultado = true;
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _diagnosticoActual = null;
      _itemSeleccionado = null;
      _textoEscaneo = 'Curado';
      _tipoEfectoActivo = null;
      _resumenStats = null;
      _mostrandoResultado = false;
      _botiquinAbierto = false;
    });
  }

  Future<void> _iniciarEscaneo(MascotaModel mascota) async {
    if (_escaneando) return;

    setState(() {
      _botiquinAbierto = false;
      _escaneando = true;
      _mostrandoResultado = true;
      _textoEscaneo = '';
      _tipoEfectoActivo = null;
      _resumenStats = null;
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final diagnostico = _resolverDiagnostico(mascota);

    setState(() {
      _escaneando = false;
      _diagnosticoActual = diagnostico;
      _itemSeleccionado = diagnostico;
      _mostrandoResultado = true;
      _textoEscaneo = _textoDiagnostico(diagnostico);
    });

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    setState(() {
      _mostrandoResultado = false;
    });
  }

  void _mostrarSnackError(String error) {
    final mensaje = switch (error) {
      'cooldown_activo' => 'La venda necesita mas tiempo para hacer efecto',
      'condicion_no_cumplida' => 'Tu mascota no necesita esto ahora',
      'sin_stock' => 'Sin stock. Visita la tienda',
      'escanear_primero' => 'Primero escanea a tu mascota',
      _ => 'No se pudo aplicar el tratamiento',
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _mostrarBloqueoNavegacion() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Termina la revision o el tratamiento antes de salir'),
        ),
      );
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
  Widget build(BuildContext context) {
    return BlocConsumer<PetCubit, PetState>(
      listener: (context, state) {
        final error = context.read<PetCubit>().botiquinError;
        if (error != null && error != _ultimoErrorBotiquin) {
          _ultimoErrorBotiquin = error;
          _mostrarSnackError(error);
        }
        if (error == null) {
          _ultimoErrorBotiquin = null;
        }
      },
      builder: (context, state) {
        final mascota = state.mascota;
        final petName = mascota?.nombreMascota ?? widget.petName;
        final petType = (mascota?.tipoMascota ?? 'perro').toLowerCase();
        final healthPercent = mascota == null
            ? widget.healthPercent
            : ((mascota.nivelSalud.clamp(0, 100)) / 100);

        return Scaffold(
          backgroundColor: AppColors.verdeVeterinario,
          floatingActionButton: FloatingActionButton(
            heroTag: 'mapa_fab',
            onPressed: () => mostrarMapaHuella(context),
            backgroundColor: AppColors.verdeFondo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.pets,
              color: AppColors.azulPrincipal,
              size: 28,
            ),
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              if (_itemSeleccionado != null ||
                  _escaneando ||
                  _diagnosticoActual != null ||
                  _botiquinAbierto ||
                  _tipoEfectoActivo != null) {
                _mostrarBloqueoNavegacion();
                return;
              }
              final velocity = details.primaryVelocity;
              if (velocity == null) return;
              if (velocity < -400) {
                context.go(AppRoutes.alimentar);
              } else if (velocity > 400) {
                context.go(AppRoutes.retos);
              }
            },
            child: Column(
              children: [
                _TopBar(
                  petName: petName,
                  healthPercent: healthPercent,
                ),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: _VetScene(
                      heartAnim: _heartAnim,
                      petType: petType,
                      mascota: mascota,
                      botiquinAbierto: _botiquinAbierto,
                      diagnosticoActual: _diagnosticoActual,
                      isScanning: _escaneando,
                      itemSeleccionado: _itemSeleccionado,
                      textoEscaneo: _textoEscaneo,
                      mostrandoResultado: _mostrandoResultado,
                      tipoEfectoActivo: _tipoEfectoActivo,
                      resumenStats: _resumenStats,
                      onSelectItem: mascota == null
                          ? null
                          : (tipoItem) {
                              _aplicarTratamiento(mascota, tipoItem);
                            },
                      onToggleBotiquin: mascota == null ? null : _toggleBotiquin,
                      onCloseBotiquin: () {
                        if (_botiquinAbierto) {
                          setState(() {
                            _botiquinAbierto = false;
                          });
                        }
                      },
                      onPetScanGesture: mascota == null
                          ? null
                          : (data) {
                              if (data == 'scanner') {
                                _iniciarEscaneo(mascota);
                              } else {
                                _aplicarTratamiento(mascota, data);
                              }
                            },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final String petName;
  final double healthPercent;

  const _TopBar({required this.petName, required this.healthPercent});

  @override
  Widget build(BuildContext context) {
    final barraWidth = MediaQuery.of(context).size.width * 0.25;

    return HeaderWidget(
      leftContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                const Icon(
                  Icons.local_hospital_outlined,
                  size: 32,
                  color: AppColors.azulPrincipal,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Veterinaria',
                  style: TextStyle(
                    fontSize: 24,
                    color: AppColors.azulPrincipal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Hora de Curar a $petName',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
      rightContent: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'Salud:',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: barraWidth,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: healthPercent.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.rosa, AppColors.nivelSalud],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(healthPercent * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: healthPercent < 0.30
                      ? AppColors.estadoEnfermo
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VetScene extends StatelessWidget {
  final Animation<double> heartAnim;
  final String petType;
  final MascotaModel? mascota;
  final bool botiquinAbierto;
  final String? diagnosticoActual;
  final bool isScanning;
  final String? itemSeleccionado;
  final String? textoEscaneo;
  final bool mostrandoResultado;
  final String? tipoEfectoActivo;
  final String? resumenStats;
  final ValueChanged<String>? onSelectItem;
  final VoidCallback? onToggleBotiquin;
  final VoidCallback? onCloseBotiquin;
  final ValueChanged<String>? onPetScanGesture;

  const _VetScene({
    required this.heartAnim,
    required this.petType,
    required this.mascota,
    required this.botiquinAbierto,
    required this.diagnosticoActual,
    required this.isScanning,
    required this.itemSeleccionado,
    required this.textoEscaneo,
    required this.mostrandoResultado,
    required this.tipoEfectoActivo,
    required this.resumenStats,
    required this.onSelectItem,
    required this.onToggleBotiquin,
    required this.onCloseBotiquin,
    required this.onPetScanGesture,
  });

  @override
  Widget build(BuildContext context) {
    final worldState = context.watch<PetWorldCubit>().state;
    final canShowPet =
        !worldState.isLocationLocked ||
        worldState.location == PetLocation.curar;
    final textoEscaneoMostrado = canShowPet
        ? textoEscaneo
        : 'Tu mascota esta en ${_locationLabel(worldState.location)}.';

    return LayoutBuilder(
      builder: (context, constraints) {
        final sceneWidth = constraints.maxWidth;
        final sceneHeight = constraints.maxHeight;
        final isCompactWidth = sceneWidth < 380;
        final isCompactHeight = sceneHeight < 640;
        final horizontalPadding = isCompactWidth ? 18.0 : 32.0;
        final topWidgetsHeight = isCompactHeight ? 88.0 : 100.0;
        final topWidgetsTop = (sceneHeight * 0.03).clamp(12.0, 24.0);
        final tableWidth = sceneWidth.clamp(260.0, 420.0) * 0.62;
        final petSize = isCompactWidth ? 140.0 : 170.0;
        final sceneBlockBottom = (sceneHeight * 0.18).clamp(52.0, 110.0);
        final petTableSpacing = (sceneHeight * 0.03).clamp(8.0, 18.0);
        final scannerBottom = (sceneHeight * 0.012).clamp(4.0, 16.0);
        final botiquinTop = topWidgetsTop + topWidgetsHeight + 8;
        final botiquinClosedWidth = sceneWidth.clamp(320.0, 480.0) * 0.28;
        final botiquinClosedHeight = isCompactHeight ? 114.0 : 124.0;
        final botiquinOpenWidth = (sceneWidth * 0.72).clamp(300.0, 390.0);
        final botiquinOpenHeight = isCompactHeight ? 126.0 : 138.0;
        final botiquinIconSize = isCompactWidth ? 52.0 : 62.0;
        final scannerSize = isCompactWidth ? 66.0 : 74.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            if (botiquinAbierto)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onCloseBotiquin,
                  child: const SizedBox.expand(),
                ),
              ),
            Positioned(
              top: topWidgetsTop,
              left: horizontalPadding,
              right: horizontalPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MedicalPanel(
                    width: isCompactWidth ? 78 : 90,
                    height: topWidgetsHeight,
                  ),
                  SizedBox(width: isCompactWidth ? 8 : 12),
                  _EcgMonitor(
                    animation: heartAnim,
                    height: topWidgetsHeight,
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: scannerBottom,
              left: horizontalPadding,
              child: _ScannerToolDock(
                tipoItem: diagnosticoActual,
                bloqueado: isScanning,
                size: scannerSize,
                labelFontSize: isCompactWidth ? 11 : 12,
              ),
            ),
            if (mascota != null)
              Positioned(
                top: botiquinTop,
                right: horizontalPadding - (isCompactWidth ? 6 : 14),
                child: _BotiquinTopDock(
                  abierto: botiquinAbierto,
                  mascota: mascota!,
                  onToggleBotiquin: onToggleBotiquin,
                  onSelectItem: onSelectItem,
                  closedWidth: botiquinClosedWidth,
                  closedHeight: botiquinClosedHeight,
                  openWidth: botiquinOpenWidth,
                  openHeight: botiquinOpenHeight,
                  iconSize: botiquinIconSize,
                  compact: isCompactWidth || isCompactHeight,
                  itemDisponible: (tipoItem) =>
                      _BotiquinAvailability.fromMascota(mascota!, tipoItem),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: sceneBlockBottom,
              child: _CenteredVetStage(
                heartAnim: heartAnim,
                petType: petType,
                petSize: petSize,
                tableWidth: tableWidth,
                petTableSpacing: petTableSpacing,
                glowHeight: sceneHeight * 0.06,
                canShowPet: canShowPet,
                isScanning: isScanning,
                itemSeleccionado: itemSeleccionado,
                textoEscaneo: textoEscaneoMostrado,
                mostrandoResultado: mostrandoResultado,
                tipoEfectoActivo: tipoEfectoActivo,
                resumenStats: resumenStats,
                onPetScanGesture: onPetScanGesture,
              ),
            ),
          ],
        );
      },
    );
  }

  String _locationLabel(PetLocation location) {
    return switch (location) {
      PetLocation.home => 'Home',
      PetLocation.alimentar => 'el Comedor',
      PetLocation.jugar => 'la Sala de Juegos',
      PetLocation.dormir => 'la Habitación',
      PetLocation.curar => 'Curar',
      PetLocation.banar => 'la Bañera',
    };
  }
}

class _CenteredVetStage extends StatelessWidget {
  final Animation<double> heartAnim;
  final String petType;
  final double petSize;
  final double tableWidth;
  final double petTableSpacing;
  final double glowHeight;
  final bool canShowPet;
  final bool isScanning;
  final String? itemSeleccionado;
  final String? textoEscaneo;
  final bool mostrandoResultado;
  final String? tipoEfectoActivo;
  final String? resumenStats;
  final ValueChanged<String>? onPetScanGesture;

  const _CenteredVetStage({
    required this.heartAnim,
    required this.petType,
    required this.petSize,
    required this.tableWidth,
    required this.petTableSpacing,
    required this.glowHeight,
    required this.canShowPet,
    required this.isScanning,
    required this.itemSeleccionado,
    required this.textoEscaneo,
    required this.mostrandoResultado,
    required this.tipoEfectoActivo,
    required this.resumenStats,
    required this.onPetScanGesture,
  });

  @override
  Widget build(BuildContext context) {
    final messageOffset = (petSize * 0.34).clamp(44.0, 60.0);
    final summaryOffset = (petSize * 0.66).clamp(88.0, 112.0);
    final targetPadding = (petSize * 0.05).clamp(6.0, 10.0);
    return Center(
      child: SizedBox(
        width: tableWidth,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: 26,
              child: Container(
                width: tableWidth * 0.82,
                height: glowHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF9DC99D).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: petSize * 0.62),
              child: _ExamTable(width: tableWidth),
            ),
            Positioned(
              bottom: 26 + petTableSpacing,
              child: DragTarget<String>(
                onWillAcceptWithDetails: (details) =>
                    canShowPet &&
                    !isScanning &&
                    (details.data == 'scanner' ||
                        details.data == 'venda' ||
                        details.data == 'suero' ||
                        details.data == 'aroma'),
                onAcceptWithDetails: (details) =>
                    onPetScanGesture?.call(details.data),
                builder: (context, candidateData, rejectedData) {
                  final resaltado = candidateData.isNotEmpty;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.all(targetPadding),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: resaltado
                          ? Border.all(
                              color: const Color(0xFF8FD3FF),
                              width: 3,
                            )
                          : null,
                      color: resaltado
                          ? const Color(0x558FD3FF)
                          : Colors.transparent,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (canShowPet)
                          _BouncingPet(
                            heartAnim: heartAnim,
                            petType: petType,
                            size: petSize,
                            isScanning: isScanning,
                          )
                        else
                          SizedBox(
                            width: petSize,
                            height: petSize,
                          ),
                        if (isScanning)
                          _ScannerToolVisual(
                            tipoItem: itemSeleccionado,
                            size: petSize * 0.44,
                          ),
                        if (isScanning) _ScannerOverlay(size: petSize + 18),
                        if (textoEscaneo != null &&
                            textoEscaneo!.isNotEmpty)
                          Positioned(
                            bottom: -messageOffset,
                            child: _ResultBubble(text: textoEscaneo!),
                          ),
                        if (tipoEfectoActivo != null)
                          _TreatmentEffect(
                            size: petSize + 22,
                            type: tipoEfectoActivo!,
                          ),
                        if (resumenStats != null)
                          Positioned(
                            top: -summaryOffset,
                            child: _SummaryBanner(text: resumenStats!),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicalPanel extends StatelessWidget {
  final double width;
  final double height;

  const _MedicalPanel({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final scale = (height / 100).clamp(0.82, 1.0);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10 * scale,
            offset: Offset(0, 4 * scale),
          ),
        ],
      ),
      padding: EdgeInsets.all(10 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FakeLine(width: 65 * scale, color: const Color(0xFFD0D8D0)),
          SizedBox(height: 6 * scale),
          _FakeLine(width: 50 * scale, color: const Color(0xFFD0D8D0)),
          SizedBox(height: 10 * scale),
          Row(
            children: [
              _ColorDot(color: const Color(0xFFE8A0A0), size: 16 * scale),
              SizedBox(width: 6 * scale),
              _ColorDot(color: const Color(0xFFA0A8E8), size: 16 * scale),
            ],
          ),
        ],
      ),
    );
  }
}

class _FakeLine extends StatelessWidget {
  final double width;
  final Color color;

  const _FakeLine({required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final double size;

  const _ColorDot({required this.color, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _EcgMonitor extends StatelessWidget {
  final Animation<double> animation;
  final double height;

  const _EcgMonitor({
    required this.animation,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF7A9A7A),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) => CustomPaint(
              painter: _EcgPainter(progress: animation.value),
            ),
          ),
        ),
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  final double progress;

  _EcgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final tracePaint = Paint()
      ..color = const Color(0xFF9DC99D)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final guidePaint = Paint()
      ..color = const Color(0xFF9DC99D).withValues(alpha: 0.18)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final mid = h * 0.55;
    final path = Path();
    final startX = w * 0.06;
    final endX = w * 0.94;
    final pulseWidth = endX - startX;
    final points = [
      Offset(startX, mid),
      Offset(startX + pulseWidth * 0.18, mid),
      Offset(startX + pulseWidth * 0.28, mid - h * 0.12),
      Offset(startX + pulseWidth * 0.36, mid + h * 0.28),
      Offset(startX + pulseWidth * 0.44, mid - h * 0.38),
      Offset(startX + pulseWidth * 0.52, mid),
      Offset(startX + pulseWidth * 0.76, mid),
      Offset(endX, mid),
    ];

    path.moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, guidePaint);

    final metrics = path.computeMetrics().toList();
    final normalizedProgress = progress.clamp(0.0, 1.0);
    const pulseConfigs = <({double phase, double window})>[
      (phase: 0.0, window: 0.55),
      (phase: 0.80, window: 0.82),
    ];

    void drawTrace(double localProgress) {
      final clamped = localProgress.clamp(0.0, 1.0);
      for (final metric in metrics) {
        final traced = metric.extractPath(0, metric.length * clamped);
        canvas.drawPath(traced, tracePaint);
      }
    }

    for (final config in pulseConfigs) {
      final shifted = normalizedProgress - config.phase;
      final wrapped = shifted < 0 ? shifted + 1.0 : shifted;
      final localProgress = wrapped / config.window;
      if (localProgress >= 0 && localProgress <= 1) {
        drawTrace(localProgress);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_EcgPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _BouncingPet extends StatelessWidget {
  final Animation<double> heartAnim;
  final String petType;
  final double size;
  final bool isScanning;

  const _BouncingPet({
    required this.heartAnim,
    required this.petType,
    required this.size,
    required this.isScanning,
  });

  @override
  Widget build(BuildContext context) {
    if (isScanning) {
      return SizedBox(
        width: size,
        height: size,
        child: PetAvatarRive(
          tipoMascota: petType,
          width: size,
          height: size,
        ),
      );
    }

    return AnimatedBuilder(
      animation: heartAnim,
      builder: (context, child) {
        final dy = sin(heartAnim.value * pi) * 4.0;
        return Transform.translate(
          offset: Offset(0, -dy),
          child: child,
        );
      },
      child: SizedBox(
        width: size,
        height: size,
        child: PetAvatarRive(
          tipoMascota: petType,
          width: size,
          height: size,
        ),
      ),
    );
  }
}

class _BotiquinAvailability {
  final bool available;
  final String label;

  const _BotiquinAvailability({
    required this.available,
    required this.label,
  });

  static _BotiquinAvailability fromMascota(
    MascotaModel mascota,
    String tipoItem,
  ) {
    final stock = mascota.inventarioBotiquin[tipoItem] ?? 0;
    if (stock <= 0) {
      return const _BotiquinAvailability(
        available: false,
        label: 'Sin stock',
      );
    }

    if (tipoItem == 'venda') {
      final ultimaCuracion = mascota.ultimaCuracion;
      if (ultimaCuracion != null) {
        final restante =
            const Duration(hours: 2) - DateTime.now().difference(ultimaCuracion);
        if (!restante.isNegative) {
          final horas = restante.inHours;
          final minutos = restante.inMinutes.remainder(60);
          return _BotiquinAvailability(
            available: false,
            label: 'En ${horas}h ${minutos}m',
          );
        }
      }
      return const _BotiquinAvailability(
        available: true,
        label: 'Listo',
      );
    }

    final disponible = switch (tipoItem) {
      'suero' =>
        mascota.nivelEnergia < 40 ||
            mascota.nivelHambre < 40 ||
            mascota.ticksEnergiaBaja >= 1,
      'aroma' =>
        mascota.nivelAfecto < 40 ||
            mascota.nivelLimpieza < 40 ||
            mascota.anomaliaActiva,
      _ => false,
    };

    return _BotiquinAvailability(
      available: disponible,
      label: disponible ? 'Listo' : 'Aun no',
    );
  }
}

class _BotiquinTopDock extends StatelessWidget {
  final bool abierto;
  final MascotaModel mascota;
  final VoidCallback? onToggleBotiquin;
  final ValueChanged<String>? onSelectItem;
  final double closedWidth;
  final double closedHeight;
  final double openWidth;
  final double openHeight;
  final double iconSize;
  final bool compact;
  final _BotiquinAvailability Function(String tipoItem) itemDisponible;

  const _BotiquinTopDock({
    required this.abierto,
    required this.mascota,
    required this.onToggleBotiquin,
    required this.onSelectItem,
    required this.closedWidth,
    required this.closedHeight,
    required this.openWidth,
    required this.openHeight,
    required this.iconSize,
    required this.compact,
    required this.itemDisponible,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        id: 'venda',
        emoji: '🩹',
        title: 'Venda',
        subtitle: 'Salud directa',
        colors: const [Color(0xFF8FC3FF), Color(0xFF5FA8FF)],
      ),
      (
        id: 'suero',
        emoji: '💉',
        title: 'Suero',
        subtitle: 'Energia y hambre',
        colors: const [Color(0xFF95D88A), Color(0xFF5FBF7A)],
      ),
      (
        id: 'aroma',
        emoji: '🌿',
        title: 'Aroma',
        subtitle: 'Calma y limpieza',
        colors: const [Color(0xFFD7C7FF), Color(0xFFB89DFF)],
      ),
    ];

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: abierto ? openWidth : closedWidth,
        height: abierto ? openHeight : closedHeight,
        padding: abierto
            ? EdgeInsets.fromLTRB(
                compact ? 10 : 14,
                compact ? 10 : 12,
                compact ? 10 : 14,
                compact ? 10 : 12,
              )
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: abierto ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: abierto
            ? Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          for (final item in items) ...[
                            Builder(
                              builder: (context) {
                                final availability = itemDisponible(item.id);
                                final stock =
                                    mascota.inventarioBotiquin[item.id] ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _BotiquinItemTile(
                                    id: item.id,
                                    emoji: item.emoji,
                                    title: item.title,
                                    subtitle: item.subtitle,
                                    stock: stock,
                                    available: availability.available,
                                    statusText: availability.label,
                                    compact: compact,
                                    onSelect: onSelectItem,
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onToggleBotiquin,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F7),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.azulPrincipal,
                      ),
                    ),
                  ),
                ],
              )
            : GestureDetector(
                onTap: onToggleBotiquin,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      BotiquinWidget(size: iconSize),
                      SizedBox(height: compact ? 3 : 4),
                      Text(
                        'Botiquin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.azulPrincipal,
                          fontSize: compact ? 11 : 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _BotiquinItemTile extends StatelessWidget {
  final String id;
  final String emoji;
  final String title;
  final String subtitle;
  final int stock;
  final bool available;
  final String statusText;
  final bool compact;
  final ValueChanged<String>? onSelect;

  const _BotiquinItemTile({
    required this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.stock,
    required this.available,
    required this.statusText,
    required this.compact,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final item = _buildBody();
    if (!available) {
      return Opacity(
        opacity: 0.52,
        child: item,
      );
    }

    return Draggable<String>(
      data: id,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.04,
          child: _buildBody(isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.28,
        child: item,
      ),
      onDragStarted: () => onSelect?.call(id),
      child: item,
    );
  }

  Widget _buildBody({bool isDragging = false}) {
    final width = compact ? 96.0 : 108.0;
    final height = compact ? 94.0 : 102.0;
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: available ? const Color(0xFFBFD8F2) : const Color(0xFFD8DEE5),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDragging ? 0.14 : 0.08),
            blurRadius: isDragging ? 14 : 8,
            offset: Offset(0, isDragging ? 8 : 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: TextStyle(fontSize: compact ? 14 : 16)),
          SizedBox(height: compact ? 1 : 2),
          Text(
            title,
            style: TextStyle(
              color: AppColors.azulPrincipal,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.58),
              fontSize: compact ? 7 : 8,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: compact ? 2 : 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 4 : 5,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F1FB),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'x$stock',
                  style: TextStyle(
                    color: AppColors.azulPrincipal,
                    fontSize: compact ? 6.5 : 7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: compact ? 3 : 4),
              Flexible(
                child: Text(
                  statusText,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: available
                        ? const Color(0xFF4C7AA4)
                        : Colors.black.withValues(alpha: 0.42),
                    fontSize: compact ? 7 : 7.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScannerToolDock extends StatelessWidget {
  final String? tipoItem;
  final bool bloqueado;
  final double size;
  final double labelFontSize;

  const _ScannerToolDock({
    required this.tipoItem,
    required this.bloqueado,
    required this.size,
    required this.labelFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final scanner = _ScannerToolVisual(tipoItem: tipoItem, size: size);
    return Opacity(
      opacity: bloqueado ? 0.45 : 1,
      child: Draggable<String>(
        data: 'scanner',
        feedback: Material(
          color: Colors.transparent,
          child: _ScannerToolVisual(tipoItem: tipoItem, size: size * 1.18),
        ),
        childWhenDragging: Opacity(
          opacity: 0.14,
          child: scanner,
        ),
        maxSimultaneousDrags: bloqueado ? 0 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            scanner,
            const SizedBox(height: 4),
            Text(
              'Escaner',
              style: TextStyle(
                color: AppColors.azulPrincipal,
                fontSize: labelFontSize,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerToolVisual extends StatelessWidget {
  final String? tipoItem;
  final double size;

  const _ScannerToolVisual({
    required this.tipoItem,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final accent = switch (tipoItem) {
      'venda' => const Color(0xFF8FC3FF),
      'suero' => const Color(0xFF7FD8C8),
      'aroma' => const Color(0xFFD8B6FF),
      _ => const Color(0xFF8FC3FF),
    };

    return Container(
      width: size,
      height: size * 0.72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(color: accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: size * 0.18,
            right: size * 0.18,
            top: size * 0.18,
            child: Container(
              height: size * 0.12,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Icon(
            Icons.document_scanner_rounded,
            size: size * 0.34,
            color: AppColors.azulPrincipal,
          ),
          Positioned(
            bottom: size * 0.12,
            left: size * 0.18,
            right: size * 0.18,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    accent.withValues(alpha: 0.95),
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
}

class _ScannerOverlay extends StatelessWidget {
  final double size;

  const _ScannerOverlay({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: -size * 0.5, end: size * 0.5),
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: size * 0.5 + value,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0xAAFFFFFF),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.65),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultBubble extends StatelessWidget {
  final String text;

  const _ResultBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = (screenWidth * 0.58).clamp(170.0, 240.0);
    final fontSize = screenWidth < 360 ? 12.0 : 14.0;
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 250),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth < 360 ? 12 : 16,
          vertical: screenWidth < 360 ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.azulPrincipal,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final String text;

  const _SummaryBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 250),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth < 360 ? 12 : 16,
          vertical: screenWidth < 360 ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: const Color(0xEE173D5A),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth < 360 ? 12 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _TreatmentEffect extends StatelessWidget {
  final double size;
  final String type;

  const _TreatmentEffect({
    required this.size,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: switch (type) {
          'venda' => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.75),
                  Colors.white.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          'suero' => Stack(
            alignment: Alignment.center,
            children: const [
              _ParticleBubble(offset: Offset(-28, 18), size: 14),
              _ParticleBubble(offset: Offset(0, -4), size: 18),
              _ParticleBubble(offset: Offset(26, -24), size: 12),
            ],
          ),
          'aroma' => Stack(
            alignment: Alignment.center,
            children: [
              _WaveRing(size: size * 0.42),
              _WaveRing(size: size * 0.62),
              _WaveRing(size: size * 0.82),
            ],
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _ParticleBubble extends StatelessWidget {
  final Offset offset;
  final double size;

  const _ParticleBubble({
    required this.offset,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xAA9AD4FF),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xAA9AD4FF).withValues(alpha: 0.65),
              blurRadius: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveRing extends StatelessWidget {
  final double size;

  const _WaveRing({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xB6D8C2FF),
          width: 3,
        ),
      ),
    );
  }
}

class _ExamTable extends StatelessWidget {
  final double width;

  const _ExamTable({required this.width});

  @override
  Widget build(BuildContext context) {
    final legGap = (width * 0.54).clamp(88.0, 160.0);
    final legHeight = (width * 0.18).clamp(32.0, 54.0);
    final legWidth = (width * 0.06).clamp(12.0, 18.0);

    return Column(
      children: [
        Container(
          width: width,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 60,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD8E8D8),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TableLeg(width: legWidth, height: legHeight),
            SizedBox(width: legGap),
            _TableLeg(width: legWidth, height: legHeight),
          ],
        ),
      ],
    );
  }
}

class _TableLeg extends StatelessWidget {
  final double width;
  final double height;

  const _TableLeg({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}
