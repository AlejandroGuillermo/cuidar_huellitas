import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuidar_huellitas/Models/mascota_model.dart';
import 'package:cuidar_huellitas/Models/usuario_model.dart';
import 'package:cuidar_huellitas/application/cubits/mission_cubit.dart';
import 'package:cuidar_huellitas/application/cubits/pet_world_cubit.dart';
import 'package:cuidar_huellitas/cubit/pet_state.dart';
import 'package:cuidar_huellitas/cubit/pet_cubit.dart';
import 'package:cuidar_huellitas/core/app_colors.dart';
import 'package:cuidar_huellitas/core/app_router.dart';
import 'package:cuidar_huellitas/core/disaster_system.dart';
import 'package:cuidar_huellitas/domain/entities/pet_world_state.dart';
import 'package:cuidar_huellitas/domain/enums/pet_activity.dart';
import 'package:cuidar_huellitas/domain/enums/pet_location.dart';
import 'package:cuidar_huellitas/widgets/header_widget.dart';
import 'package:cuidar_huellitas/widgets/paw_map_widget.dart';
import 'package:cuidar_huellitas/widgets/pet_avatar_rive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const int _slowPetCalmTarget = 4;
  String? showFeedback;
  Timer? _feedbackTimer;
  final List<_HomeHeart> _calmHearts = <_HomeHeart>[];
  final Random _escapeRandom = Random();
  Alignment _escapedPetAlignment = const Alignment(0, 0.2);
  Timer? _escapedPetTimer;
  DateTime? _lastSlowPetAt;

  late final AnimationController _floatingController;
  late final Animation<double> _floatingAnimation;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation =
        Tween<double>(begin: 1, end: 1.1).animate(
          CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _bounceController.reverse();
          }
        });

    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWorldEntry());
  }

  Future<void> _syncWorldEntry() async {
    if (!mounted) return;
    final mascota = context.read<PetCubit>().state.mascota;
    if (mascota == null) return;

    final worldCubit = context.read<PetWorldCubit>();
    final disasterCubit = context.read<DisasterCubit>();

    await worldCubit.syncScreenEntry(
      mascota: mascota,
      location: PetLocation.home,
      fallbackActivity: PetActivity.roaming,
    );
    if (!mounted) return;
    await disasterCubit.verificarDesastre(mascota.idMascota);
  }

  void _openArScreen() {
    context.push(AppRoutes.ar);
  }

  Future<void> _openProfileSheet() async {
    final petCubit = context.read<PetCubit>();
    final result = await showGeneralDialog<_ProfileSheetResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Perfil',
      barrierColor: Colors.transparent,
      pageBuilder: (dialogContext, animation1, animation2) {
        return _ProfilePetsSheet(
          activePet: petCubit.state.mascota,
          onPetChanged: () async {
            await petCubit.cargarMascota();
            if (!mounted) return;
            await _syncWorldEntry();
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              FadeTransition(
                opacity: curved,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 12 * animation.value,
                    sigmaY: 12 * animation.value,
                  ),
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.35 * animation.value,
                    ),
                  ),
                ),
              ),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    if (result == _ProfileSheetResult.adopt) {
      final adopted = await context.push<bool>(
        '${AppRoutes.adopcion}?fromHome=true',
      );
      if (!mounted) return;
      if (adopted == true) {
        await petCubit.cargarMascota();
        if (!mounted) return;
        await _syncWorldEntry();
      }
    }
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _bounceController.dispose();
    _feedbackTimer?.cancel();
    _escapedPetTimer?.cancel();
    super.dispose();
  }

  void _startEscapedPetRoaming() {
    _escapedPetTimer?.cancel();
    _moveEscapedPet();
    _escapedPetTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      _moveEscapedPet();
    });
  }

  void _stopEscapedPetRoaming() {
    _escapedPetTimer?.cancel();
    _escapedPetTimer = null;
    if (!mounted) return;
    setState(() => _escapedPetAlignment = const Alignment(0, 0.2));
  }

  void _moveEscapedPet() {
    if (!mounted) return;
    setState(() {
      _escapedPetAlignment = Alignment(
        -0.78 + _escapeRandom.nextDouble() * 1.56,
        -0.05 + _escapeRandom.nextDouble() * 0.95,
      );
    });
  }

  Future<void> _releaseEscapedPetLockIfNeeded() async {
    if (!mounted) return;
    final mascota = context.read<PetCubit>().state.mascota;
    if (mascota == null) return;

    final worldCubit = context.read<PetWorldCubit>();
    final world = worldCubit.state;
    final shouldRelease =
        world.isLocationLocked &&
        world.location == PetLocation.home &&
        world.activity == PetActivity.roaming;
    if (!shouldRelease) return;

    await worldCubit.updateWorld(
      mascota: mascota,
      next: world.copyWith(
        location: PetLocation.home,
        activity: PetActivity.idle,
        isLocationLocked: false,
        isNapTime: false,
        simulatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _onEscapedPetPanUpdate(DragUpdateDetails details) async {
    final petState = context.read<PetCubit>().state;
    if (petState.estadoMision != 'rebelde_escapado') return;

    final now = DateTime.now();
    final distance = details.delta.distance;
    final elapsedMs = _lastSlowPetAt == null
        ? 999
        : now.difference(_lastSlowPetAt!).inMilliseconds;
    final isSlowStroke = distance >= 3 && distance <= 16 && elapsedMs >= 260;
    if (!isSlowStroke) return;

    _lastSlowPetAt = now;
    final calmado = await context.read<PetCubit>().registrarCariciaCalmar();
    if (!mounted) return;

    final id = DateTime.now().microsecondsSinceEpoch;
    setState(() {
      _calmHearts.add(_HomeHeart(id: id, position: details.globalPosition));
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _calmHearts.removeWhere((heart) => heart.id == id));
    });

    if (calmado) {
      _stopEscapedPetRoaming();
    }
  }

  Widget _buildEscapedPetProgress(int current, int total) {
    final percent = total > 0 ? ((current / total) * 100).round() : 0;
    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Calmando $percent%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: total > 0 ? current / total : 0,
              minHeight: 8,
              backgroundColor: const Color(0xFFE7EAF0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFF8A65),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$current/$total caricias suaves',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscapedPetHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Tu mascota se escapo. Acariciala despacio para calmarla.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEscapeHeart(_HomeHeart heart) {
    return Positioned(
      left: heart.position.dx - 14,
      top: heart.position.dy - 48,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(heart.id),
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 850),
        builder: (context, value, child) => Opacity(
          opacity: 1 - value,
          child: Transform.translate(
            offset: Offset(0, -value * 36),
            child: const Icon(
              Icons.favorite,
              color: Color(0xFFFF6F91),
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetCubit, PetState>(
      buildWhen: (previous, current) {
        return previous.isLoading != current.isLoading ||
            previous.mascota?.nombreMascota != current.mascota?.nombreMascota ||
            previous.mascota?.itemCabezaId != current.mascota?.itemCabezaId ||
            previous.estadoMision != current.estadoMision ||
            previous.tapsCalmar != current.tapsCalmar;
      },
      builder: (context, petState) {
        final mascota = petState.mascota;
        if (petState.isLoading) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.azulPrincipal),
                  SizedBox(height: 16),
                  Text(
                    'Despertando mascota...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        if (mascota == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.go(AppRoutes.adopcion);
          });

          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.azulPrincipal),
                  SizedBox(height: 16),
                  Text(
                    'Redirigiendo a adopcion...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        final petEmoji = mascota.tipoMascota.toLowerCase();

        return BlocListener<PetCubit, PetState>(
          listenWhen: (previous, current) =>
              previous.estadoMision != current.estadoMision,
          listener: (context, state) async {
            if (state.estadoMision == 'rebelde_escapado') {
              _lastSlowPetAt = null;
              _startEscapedPetRoaming();
              return;
            }
            _stopEscapedPetRoaming();
            await _releaseEscapedPetLockIfNeeded();
          },
          child: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () => mostrarMapaHuella(context),
              backgroundColor: AppColors.verdeFondo,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.pets,
                color: AppColors.azulPrincipal,
                size: 28,
              ),
            ),
            body: SizedBox.expand(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity;
                  if (velocity == null) return;
                  if (velocity < 0) {
                    context.push(AppRoutes.dormir);
                  } else if (velocity > 0) {
                    context.goNamed(
                      'alimentar',
                      extra: 'home',
                    );
                  }
                },
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFA3FF88),
                              Color(0xFF8AE670),
                              Color(0xFFA3FF88),
                            ],
                          ),
                        ),
                      ),
                    ),
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
                                onTap: _openArScreen,
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.03,
                              ),
                              _HeaderButton(
                                icon: Icons.menu,
                                color: AppColors.azulPrincipal,
                                onTap: _openProfileSheet,
                              ),
                            ],
                          ),
                        ),
                        const _WorldSummaryCard(),
                        Expanded(
                          child: BlocBuilder<PetWorldCubit, PetWorldState>(
                            builder: (context, worldState) {
                              final isEscaped =
                                  petState.estadoMision == 'rebelde_escapado';
                              final canShowPet =
                                  !worldState.isLocationLocked ||
                                  worldState.location == PetLocation.home;
                              if (!canShowPet) {
                                return const Center(
                                  child: SizedBox(width: 1, height: 1),
                                );
                              }

                              return Center(
                                child: isEscaped
                                    ? SizedBox.expand(
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            ..._calmHearts.map(_buildEscapeHeart),
                                            AnimatedAlign(
                                              duration: const Duration(
                                                milliseconds: 850,
                                              ),
                                              curve: Curves.easeInOut,
                                              alignment: _escapedPetAlignment,
                                              child: GestureDetector(
                                                onPanUpdate:
                                                    _onEscapedPetPanUpdate,
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Stack(
                                                      clipBehavior: Clip.none,
                                                      alignment:
                                                          Alignment.topCenter,
                                                      children: [
                                                        PetAvatarRive(
                                                          tipoMascota: petEmoji,
                                                          width: 230,
                                                          height: 230,
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    _buildEscapedPetProgress(
                                                      petState.tapsCalmar,
                                                      _slowPetCalmTarget,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              left: 28,
                                              right: 28,
                                              bottom: 28,
                                              child: _buildEscapedPetHint(),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Positioned(
                                            bottom: 40,
                                            child: AnimatedBuilder(
                                              animation: _floatingController,
                                              builder: (context, child) {
                                                final scale =
                                                    1.0 -
                                                    (_floatingAnimation.value.abs() /
                                                        100);
                                                return Transform.scale(
                                                  scale: scale,
                                                  child: Container(
                                                    width: 120,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withValues(
                                                        alpha: 0.15,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(50),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          AnimatedBuilder(
                                            animation: Listenable.merge([
                                              _floatingController,
                                              _bounceController,
                                            ]),
                                            builder: (context, child) {
                                              return Transform.translate(
                                                offset: Offset(
                                                  0,
                                                  _floatingAnimation.value,
                                                ),
                                                child: Transform.scale(
                                                  scale: _bounceAnimation.value,
                                                  child: Stack(
                                                    clipBehavior: Clip.none,
                                                    alignment: Alignment.topCenter,
                                                    children: [
                                                      PetAvatarRive(
                                                        tipoMascota: petEmoji,
                                                        width: 260,
                                                        height: 260,
                                                      ),
                                                      if (showFeedback != null)
                                                        Positioned(
                                                          top: -30,
                                                          child: Text(
                                                            showFeedback!,
                                                            style: const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight.bold,
                                                              color: Colors.black,
                                                            ),
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
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeHeart {
  const _HomeHeart({required this.id, required this.position});

  final int id;
  final Offset position;
}

class _WorldSummaryCard extends StatelessWidget {
  const _WorldSummaryCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetWorldCubit, PetWorldState>(
      builder: (context, worldState) {
        return BlocBuilder<MissionCubit, MissionState>(
          builder: (context, missionState) {
            if (worldState.isLoading) {
              return const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  color: AppColors.azulPrincipal,
                  backgroundColor: Colors.white54,
                ),
              );
            }

            final pendingCount =
                missionState.missions.length + missionState.disasters.length;

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.explore_outlined,
                      color: AppColors.azulPrincipal,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ubicacion actual: ${_locationText(worldState.location)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textoPrincipal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Actividad: ${_activityText(worldState.activity)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pendingCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.verdeFondo,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '$pendingCount pendientes',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textoPrincipal,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _locationText(PetLocation location) {
    switch (location) {
      case PetLocation.home:
        return 'Home';
      case PetLocation.alimentar:
        return 'Alimentar';
      case PetLocation.jugar:
        return 'Jugar';
      case PetLocation.dormir:
        return 'Dormir';
      case PetLocation.curar:
        return 'Curar';
      case PetLocation.banar:
        return 'Banar';
    }
  }

  static String _activityText(PetActivity activity) {
    switch (activity) {
      case PetActivity.idle:
        return 'descansando';
      case PetActivity.roaming:
        return 'explorando';
      case PetActivity.eating:
        return 'comiendo';
      case PetActivity.playing:
        return 'jugando';
      case PetActivity.sleeping:
        return 'durmiendo';
    }
  }
}

enum _ProfileSheetTab { profile, pets }

enum _ProfileSheetResult { adopt }

class _ProfilePetsSheet extends StatefulWidget {
  const _ProfilePetsSheet({
    required this.activePet,
    required this.onPetChanged,
  });

  final MascotaModel? activePet;
  final Future<void> Function() onPetChanged;

  @override
  State<_ProfilePetsSheet> createState() => _ProfilePetsSheetState();
}

class _ProfilePetsSheetState extends State<_ProfilePetsSheet> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  static const List<String> _petSubcollectionsToDelete = <String>[
    'misiones_activas',
    'desastres_pendientes',
    'patron_rutina',
    'progreso',
    'ai_history',
    'world_state',
  ];

  late _ProfileSheetTab _tab;
  late final Future<UsuarioModel?> _userFuture;
  bool _switchingPet = false;
  String? _switchingPetId;
  bool _normalizingActivePets = false;

  @override
  void initState() {
    super.initState();
    _tab = _ProfileSheetTab.profile;
    _userFuture = _loadUser();
  }

  Future<UsuarioModel?> _loadUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snapshot = await _firestore
        .collection('usuarios')
        .doc(user.uid)
        .get();
    if (!snapshot.exists) return null;
    return UsuarioModel.fromFirestore(snapshot);
  }

  Future<void> _switchActivePet(MascotaModel pet) async {
    final user = _auth.currentUser;
    if (user == null || widget.activePet == null || _switchingPet) return;
    if (pet.idMascota == widget.activePet!.idMascota) return;

    setState(() {
      _switchingPet = true;
      _switchingPetId = pet.idMascota;
    });
    try {
      final petsRef = _firestore
          .collection('usuarios')
          .doc(user.uid)
          .collection('mascotas');

      final batch = _firestore.batch();
      final activeQuery = await petsRef.where('activa', isEqualTo: true).get();
      for (final doc in activeQuery.docs) {
        batch.update(doc.reference, {'activa': false});
      }
      batch.update(petsRef.doc(pet.idMascota), {'activa': true});
      await batch.commit();

      await widget.onPetChanged();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cambiar la mascota: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _switchingPet = false;
          _switchingPetId = null;
        });
      }
    }
  }

  Future<void> _normalizeActivePets(
    List<MascotaModel> pets, {
    String? preferredPetId,
  }) async {
    final user = _auth.currentUser;
    if (user == null || pets.isEmpty || _normalizingActivePets) return;

    final activePets = pets.where((pet) => pet.activa).toList();
    if (activePets.length <= 1) return;

    _normalizingActivePets = true;
    try {
      final keepPetId =
          preferredPetId ??
          _switchingPetId ??
          widget.activePet?.idMascota ??
          activePets.first.idMascota;

      final petsRef = _firestore
          .collection('usuarios')
          .doc(user.uid)
          .collection('mascotas');
      final batch = _firestore.batch();

      for (final pet in pets) {
        batch.update(petsRef.doc(pet.idMascota), {
          'activa': pet.idMascota == keepPetId,
        });
      }

      await batch.commit();
      await widget.onPetChanged();
    } catch (_) {
      // If normalization fails, keep the UI usable with an effective active id.
    } finally {
      _normalizingActivePets = false;
    }
  }

  Future<void> _deletePet(MascotaModel pet, int totalPets) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (pet.activa) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No puedes eliminar la mascota activa. Cambia a otra primero.',
          ),
        ),
      );
      return;
    }

    if (totalPets <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes eliminar tu unica mascota.')),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Eliminar mascota'),
          content: Text(
            'Vas a eliminar a ${pet.nombreMascota}. Esta accion no se puede deshacer. Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.rosa,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      final petRef = _firestore
          .collection('usuarios')
          .doc(user.uid)
          .collection('mascotas')
          .doc(pet.idMascota);

      for (final name in _petSubcollectionsToDelete) {
        final subcollection = await petRef.collection(name).get();
        if (subcollection.docs.isEmpty) continue;
        final batch = _firestore.batch();
        for (final doc in subcollection.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      await petRef.delete();
      await widget.onPetChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${pet.nombreMascota} fue eliminado.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la mascota: $error')),
      );
    }
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Cerrar sesion'),
          content: const Text(
            '¿Seguro que quieres cerrar sesion? Tendras que volver a iniciar sesion para seguir cuidando a tu mascota.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.rosa,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar sesion'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true || !mounted) return;
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    final missionCubit = context.read<MissionCubit>();
    final disasterCubit = context.read<DisasterCubit>();

    await missionCubit.reset();
    await disasterCubit.reset();
    navigator.pop();
    await FirebaseAuth.instance.signOut();
    router.go(AppRoutes.login);
  }

  Future<void> _openAdoption() async {
    final shouldAdopt = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Adoptar otra mascota'),
          content: const Text(
            'Vas a salir de esta pantalla para iniciar una nueva adopcion. ¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.azulPrincipal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );

    if (shouldAdopt != true || !mounted) return;
    Navigator.of(context).pop(_ProfileSheetResult.adopt);
  }

  void _openAchievements() {
    Navigator.of(context).pop();
    context.go(AppRoutes.logros);
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final petsStream = user == null
        ? const Stream<QuerySnapshot<Map<String, dynamic>>>.empty()
        : _firestore
              .collection('usuarios')
              .doc(user.uid)
              .collection('mascotas')
              .snapshots();

    return SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(-8, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 28, 18, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F4F7),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _SheetTabButton(
                                      label: 'Mi Perfil',
                                      active: _tab == _ProfileSheetTab.profile,
                                      onTap: () {
                                        setState(() {
                                          _tab = _ProfileSheetTab.profile;
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: _SheetTabButton(
                                      label: 'Mis Mascotas',
                                      active: _tab == _ProfileSheetTab.pets,
                                      onTap: () {
                                        setState(() {
                                          _tab = _ProfileSheetTab.pets;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F6F8),
                                borderRadius: BorderRadius.circular(21),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFF1A2E1A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: petsStream,
                        builder: (context, snapshot) {
                          final pets =
                              snapshot.data?.docs
                                  .map(MascotaModel.fromFirestore)
                                  .toList() ??
                              const <MascotaModel>[];
                          final activePets = pets
                              .where((pet) => pet.activa)
                              .toList();
                          final effectiveActiveId = activePets.isNotEmpty
                              ? (_switchingPetId != null &&
                                        pets.any(
                                          (pet) =>
                                              pet.idMascota ==
                                                  _switchingPetId &&
                                              pet.activa,
                                        )
                                    ? _switchingPetId
                                    : activePets.first.idMascota)
                              : widget.activePet?.idMascota;

                          if (activePets.length > 1) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _normalizeActivePets(
                                pets,
                                preferredPetId: effectiveActiveId,
                              );
                            });
                          }
                          final activePet = pets
                              .cast<MascotaModel?>()
                              .firstWhere(
                                (pet) => pet?.idMascota == effectiveActiveId,
                                orElse: () => widget.activePet,
                              );

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) {
                              final isProfile =
                                  child.key == const ValueKey('profile');
                              final begin = Offset(isProfile ? -0.06 : 0.06, 0);
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: begin,
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _tab == _ProfileSheetTab.profile
                                ? _ProfileTabView(
                                    key: const ValueKey('profile'),
                                    userFuture: _userFuture,
                                    activePet: activePet,
                                    totalPets: pets.length,
                                    onShowPets: () {
                                      setState(() {
                                        _tab = _ProfileSheetTab.pets;
                                      });
                                    },
                                    onAdopt: _openAdoption,
                                    onInfo: _openAchievements,
                                    onLogout: _signOut,
                                  )
                                : _PetsTabView(
                                    key: const ValueKey('pets'),
                                    pets: pets,
                                    activePetId: effectiveActiveId,
                                    switchingPetId: _switchingPetId,
                                    onAdopt: _openAdoption,
                                    onSwitchPet: _switchActivePet,
                                    onDeletePet: _deletePet,
                                  ),
                          );
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
}

class _ProfileTabView extends StatelessWidget {
  const _ProfileTabView({
    super.key,
    required this.userFuture,
    required this.activePet,
    required this.totalPets,
    required this.onShowPets,
    required this.onAdopt,
    required this.onInfo,
    required this.onLogout,
  });

  final Future<UsuarioModel?> userFuture;
  final MascotaModel? activePet;
  final int totalPets;
  final VoidCallback onShowPets;
  final VoidCallback onAdopt;
  final VoidCallback onInfo;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final pet = activePet;
    return FutureBuilder<UsuarioModel?>(
      future: userFuture,
      builder: (context, snapshot) {
        final authUser = FirebaseAuth.instance.currentUser;
        final userName = snapshot.data?.nombre.isNotEmpty == true
            ? snapshot.data!.nombre
            : (authUser?.displayName?.isNotEmpty == true
                  ? authUser!.displayName!
                  : 'Cuidador');

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.azulPrincipal, AppColors.azulClaro],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido de vuelta',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mascota activa: ${pet?.nombreMascota ?? 'Sin mascota'}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (pet != null)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.verdeFondo,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTADO DE ${pet.nombreMascota.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 18),
                    StatBar(
                      icon: Icons.favorite,
                      label: 'Salud',
                      value: pet.nivelSalud,
                      color: AppColors.nivelSalud,
                    ),
                    const SizedBox(height: 14),
                    StatBar(
                      icon: Icons.bolt,
                      label: 'Energia',
                      value: pet.nivelEnergia,
                      color: AppColors.nivelEnergia,
                    ),
                    const SizedBox(height: 14),
                    StatBar(
                      icon: Icons.restaurant,
                      label: 'Hambre',
                      value: pet.nivelHambre,
                      color: AppColors.nivelHambre,
                    ),
                    const SizedBox(height: 14),
                    StatBar(
                      icon: Icons.water_drop,
                      label: 'Limpieza',
                      value: pet.nivelLimpieza,
                      color: AppColors.nivelLimpieza,
                    ),
                    const SizedBox(height: 14),
                    StatBar(
                      icon: Icons.auto_awesome,
                      label: 'Afecto',
                      value: pet.nivelAfecto,
                      color: AppColors.nivelAfecto,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Personalidad',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textoSecundario,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pet.rasgo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textoPrincipal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Cambiar mascota',
                    gradient: const [
                      AppColors.azulPrincipal,
                      AppColors.azulClaro,
                    ],
                    textColor: Colors.white,
                    onTap: onShowPets,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.pets_rounded,
                    title: 'Adoptar otra mascota',
                    gradient: const [
                      AppColors.azulPrincipal,
                      AppColors.azulClaro,
                    ],
                    textColor: Colors.white,
                    onTap: onAdopt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _MenuRow(
                    icon: Icons.description_outlined,
                    title:
                        'Ver informacion de ${pet?.nombreMascota ?? 'tu mascota'}',
                    onTap: onInfo,
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),
                  // _MenuRow(
                  //   icon: Icons.settings_outlined,
                  //   title: 'Configuracion',
                  //   onTap: onSettings,
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'CUENTA',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 16),
            _DashedActionCard(
              color: AppColors.rosa,
              onTap: () => onLogout(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: AppColors.rosa),
                  SizedBox(width: 10),
                  Text(
                    'Cerrar sesion',
                    style: TextStyle(
                      color: AppColors.rosa,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Mascotas registradas: $totalPets',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textoSecundario,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PetsTabView extends StatelessWidget {
  const _PetsTabView({
    super.key,
    required this.pets,
    required this.activePetId,
    required this.switchingPetId,
    required this.onAdopt,
    required this.onSwitchPet,
    required this.onDeletePet,
  });

  final List<MascotaModel> pets;
  final String? activePetId;
  final String? switchingPetId;
  final VoidCallback onAdopt;
  final Future<void> Function(MascotaModel pet) onSwitchPet;
  final Future<void> Function(MascotaModel pet, int totalPets) onDeletePet;

  @override
  Widget build(BuildContext context) {
    void handlePetTap(MascotaModel pet) {
      final isPetActive = pet.idMascota == activePetId;
      if (isPetActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pet.nombreMascota} ya es tu mascota activa.'),
          ),
        );
        return;
      }
      onSwitchPet(pet);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        const SizedBox(height: 4),
        Text(
          'TUS MASCOTAS (${pets.length})',
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: AppColors.textoSecundario,
          ),
        ),
        const SizedBox(height: 14),
        ...pets.map((pet) {
          final isPetActive = pet.idMascota == activePetId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Dismissible(
              key: ValueKey('pet-${pet.idMascota}'),
              direction: isPetActive
                  ? DismissDirection.none
                  : DismissDirection.endToStart,
              confirmDismiss: (_) async {
                await onDeletePet(pet, pets.length);
                return false;
              },
              background: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: AppColors.rosa.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.centerRight,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Eliminar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              child: _PetCard(
                pet: pet,
                isActive: isPetActive,
                isSwitching: switchingPetId == pet.idMascota,
                onTap: () => handlePetTap(pet),
                onSwitch: isPetActive ? null : () => handlePetTap(pet),
              ),
            ),
          );
        }),
        _DashedActionCard(
          color: AppColors.azulPrincipal.withValues(alpha: 0.5),
          onTap: onAdopt,
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.azulPrincipal, AppColors.azulClaro],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  '+ Adoptar nueva mascota',
                  style: TextStyle(
                    color: AppColors.azulPrincipal,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.azulPrincipal,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetTabButton extends StatelessWidget {
  const _SheetTabButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(99),
        boxShadow: active
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active
                  ? AppColors.azulPrincipal
                  : AppColors.textoSecundario,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.gradient,
    required this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final List<Color> gradient;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        constraints: const BoxConstraints(minHeight: 104),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: textColor),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.azulPrincipal),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textoPrincipal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textoSecundario,
            ),
          ],
        ),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.pet,
    required this.isActive,
    required this.isSwitching,
    required this.onTap,
    required this.onSwitch,
  });

  final MascotaModel pet;
  final bool isActive;
  final bool isSwitching;
  final VoidCallback onTap;
  final VoidCallback? onSwitch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final labelFontSize = (width * 0.034).clamp(9.0, 10.5);
        final traitFontSize = (width * 0.05).clamp(13.0, 16.0);
        final nameFontSize = (width * 0.043).clamp(11.5, 13.5);
        final typeFontSize = (width * 0.04).clamp(11.0, 13.0);
        final badgeFontSize = (width * 0.036).clamp(10.0, 11.5);
        final percentFontSize = (width * 0.042).clamp(12.0, 14.0);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isSwitching ? null : onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFF3FFF0) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isActive
                      ? AppColors.verdePrincipal
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: PetAvatarRive(
                            tipoMascota: pet.tipoMascota,
                            width: 48,
                            height: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pet.tipoMascota.toLowerCase() == 'gato' ||
                                pet.tipoMascota.toLowerCase() == 'cat'
                            ? 'Gato'
                            : 'Perro',
                        style: TextStyle(
                          color: AppColors.textoSecundario,
                          fontWeight: FontWeight.w600,
                          fontSize: typeFontSize,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Personalidad',
                                    style: TextStyle(
                                      fontSize: labelFontSize,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textoSecundario,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pet.rasgo,
                                    style: TextStyle(
                                      fontSize: traitFontSize,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textoPrincipal,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: true,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pet.nombreMascota,
                                    style: TextStyle(
                                      fontSize: nameFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textoSecundario,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.verdePrincipal,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  'Activa ✓',
                                  style: TextStyle(
                                    fontSize: badgeFontSize,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textoPrincipal,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: AppColors.rosa,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniHealthBar(
                                value: pet.nivelSalud,
                                color: AppColors.rosa,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${pet.nivelSalud}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textoPrincipal,
                                fontSize: percentFontSize,
                              ),
                            ),
                          ],
                        ),
                        if (!isActive) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: isSwitching ? null : onSwitch,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.azulPrincipal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                              ),
                              child: isSwitching
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Cambiar'),
                            ),
                          ),
                        ],
                      ],
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

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (value.clamp(0, 100)) / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$value%',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}

class StatBar extends StatefulWidget {
  const StatBar({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  State<StatBar> createState() => _StatBarState();
}

class _StatBarState extends State<StatBar> with SingleTickerProviderStateMixin {
  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
      lowerBound: 0.45,
      upperBound: 1,
    );
    _syncBlink();
  }

  @override
  void didUpdateWidget(covariant StatBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBlink();
  }

  void _syncBlink() {
    if (widget.value < 30) {
      _blinkController.repeat(reverse: true);
    } else {
      _blinkController.stop();
      _blinkController.value = 1;
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value.clamp(0, 100);
    return Column(
      children: [
        Row(
          children: [
            Icon(widget.icon, color: AppColors.textoPrincipal, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: AppColors.textoPrincipal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$value%',
              style: const TextStyle(
                color: AppColors.textoPrincipal,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 14,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(99),
          ),
          alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            animation: _blinkController,
            builder: (context, child) {
              return Opacity(
                opacity: _blinkController.value,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: value / 100),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, _) {
                    return FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.color,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniHealthBar extends StatelessWidget {
  const _MiniHealthBar({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0, 100) / 100,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}

class _DashedActionCard extends StatelessWidget {
  const _DashedActionCard({
    required this.color,
    required this.child,
    required this.onTap,
  });

  final Color color;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRoundedRectPainter(color: color),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    const dashWidth = 7.0;
    const dashSpace = 5.0;
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

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
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
