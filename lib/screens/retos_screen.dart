import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Models/mascota_model.dart';
import '../application/cubits/mission_cubit.dart';
import '../core/app_colors.dart';
import '../core/app_router.dart';
import '../cubit/pet_cubit.dart';
import '../data/repositories/mission_repository.dart';
import '../data/repositories/user_repository.dart';
import '../domain/entities/pending_disaster.dart';
import '../domain/entities/pending_mission.dart';
import '../domain/enums/disaster_kind.dart';
import '../domain/enums/mission_kind.dart';
import '../domain/enums/pet_location.dart';

class RetosScreen extends StatefulWidget {
  const RetosScreen({super.key});

  @override
  State<RetosScreen> createState() => _RetosScreenState();
}

class _RetosScreenState extends State<RetosScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();
  final MissionRepository _missionRepository = MissionRepository();
  int _coins = 245;
  final Set<String> _claimingMissionIds = <String>{};
  final Set<String> _completingMissionIds = <String>{};
  final Set<String> _exitingMissionIds = <String>{};
  final Set<String> _dismissedMissionIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final coins = await _userRepository.loadCoins(userId);
      if (!mounted) return;
      setState(() => _coins = coins);
    } catch (_) {
      // Conserva el fallback visual actual si falla la carga.
    }
  }

  Future<void> _handleMissionAction(_MissionCardData mission) async {
    if (!mission.canClaimReward) {
      _openRouteByLocation(context, mission.location);
      return;
    }

    final mascotaId = context.read<PetCubit>().state.mascota?.idMascota;
    if (mascotaId == null || mascotaId.isEmpty) return;
    if (_claimingMissionIds.contains(mission.id)) return;

    setState(() {
      _claimingMissionIds.add(mission.id);
      _exitingMissionIds.add(mission.id);
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 280));
      final claimed = await _missionRepository.claimReward(mascotaId, mission.id);
      if (!mounted) return;
      if (claimed > 0) {
        setState(() {
          _coins += claimed;
          _dismissedMissionIds.add(mission.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recibiste $claimed monedas por ${mission.title}.')),
        );
      } else {
        setState(() => _exitingMissionIds.remove(mission.id));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _exitingMissionIds.remove(mission.id));
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _claimingMissionIds.remove(mission.id);
          _exitingMissionIds.remove(mission.id);
        });
      }
    }
  }

  Future<void> _syncCompletedMissions(List<_MissionCardData> missions) async {
    final mascotaId = context.read<PetCubit>().state.mascota?.idMascota;
    if (mascotaId == null || mascotaId.isEmpty) return;

    final candidates = missions
        .where(
          (mission) =>
              mission.shouldAutoComplete &&
              !_completingMissionIds.contains(mission.id),
        )
        .toList();
    if (candidates.isEmpty) return;

    for (final mission in candidates) {
      _completingMissionIds.add(mission.id);
      _missionRepository
          .completeMission(mascotaId, mission.id)
          .whenComplete(() => _completingMissionIds.remove(mission.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MissionCubit, MissionState>(
      builder: (context, missionState) {
        final mascota = context.watch<PetCubit>().state.mascota;
        final activeMissions = missionState.missions
            .map(
              (mission) => _MissionCardData.fromMission(
                mission,
                mascota: mascota,
                disasters: missionState.disasters,
                fallbackLocation: _resolveMissionLocation(
                  mission,
                  missionState.disasters,
                ),
              ),
            )
            .toList();
        final visibleMissions = activeMissions
            .where((mission) => !_dismissedMissionIds.contains(mission.id))
            .toList();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _syncCompletedMissions(activeMissions);
        });
        final pendingDisasters = missionState.disasters
            .map(_DisasterCardData.fromDisaster)
            .toList();

        return Scaffold(
          backgroundColor: AppColors.fondoPrincipal,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity;
              if (velocity == null) return;
              if (velocity < -400) {
                context.goNamed(
                  'curar',
                  extra: 'retos',
                );
              } else if (velocity > 400) {
                context.goNamed(
                  'tienda',
                  extra: 'retos',
                );
              }
            },
            child: SafeArea(
              child: Column(
                children: [
                  _TopHeader(
                    title: 'Retos',
                    subtitle: 'Cuida a tu mascota y gana monedas',
                    coins: _coins,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _SectionHeader(
                          title: 'Misiones activas',
                          trailing: '${visibleMissions.length} visibles',
                        ),
                        const SizedBox(height: 10),
                        if (missionState.isLoading && visibleMissions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.azulPrincipal,
                              ),
                            ),
                          )
                        else if (visibleMissions.isEmpty)
                          const _EmptyListCard(
                            title: 'No hay misiones activas',
                            desc:
                                'Cuando tu mascota necesite algo, apareceran aqui.',
                          )
                        else
                          ...visibleMissions.map(
                            (mission) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ActiveMissionCard(
                                emoji: mission.emoji,
                                title: mission.title,
                                desc: mission.desc,
                                progress: mission.progress,
                                reward: mission.reward,
                                urgent: mission.urgent,
                                completed: mission.canClaimReward,
                                action: mission.actionLabel,
                                exiting: _exitingMissionIds.contains(mission.id),
                                processing: _claimingMissionIds.contains(mission.id),
                                onPressed: () => _handleMissionAction(mission),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        _SectionHeader(
                          title: 'Desastres pendientes',
                          trailing: '${pendingDisasters.length} por limpiar',
                        ),
                        const SizedBox(height: 10),
                        if (pendingDisasters.isEmpty)
                          const _EmptyListCard(
                            title: 'No hay desastres pendientes',
                            desc: 'Todo limpio por ahora. Buen trabajo.',
                          )
                        else
                          ...pendingDisasters.map(
                            (disaster) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RandomMissionCard(
                                emoji: disaster.emoji,
                                title: disaster.title,
                                desc: disaster.desc,
                                progress: disaster.progress,
                                reward: disaster.reward,
                                wayToWin: disaster.wayToWin,
                                onPressed: () => _openRouteByLocation(
                                  context,
                                  disaster.location,
                                ),
                              ),
                            ),
                          ),
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

  PetLocation _resolveMissionLocation(
    PendingMission mission,
    List<PendingDisaster> disasters,
  ) {
    DisasterKind? targetKind;
    switch (mission.kind) {
      case MissionKind.recogerComida:
        targetKind = DisasterKind.comida;
        break;
      case MissionKind.recogerJuguete:
        targetKind = DisasterKind.juguete;
        break;
      case MissionKind.recogerBasura:
        targetKind = DisasterKind.basura;
        break;
      case MissionKind.desconocida:
        return mission.resolvedLocation;
    }

    final matches = disasters.where((disaster) => disaster.kind == targetKind);
    if (matches.isEmpty) return mission.resolvedLocation;

    PendingDisaster? best;
    for (final disaster in matches) {
      if (best == null || disaster.quantity > best.quantity) {
        best = disaster;
      }
    }

    return best?.location ?? mission.resolvedLocation;
  }

  void _openRouteByLocation(BuildContext context, PetLocation location) {
    switch (location) {
      case PetLocation.home:
        context.go(AppRoutes.home);
        return;
      case PetLocation.alimentar:
        context.go(AppRoutes.alimentar);
        return;
      case PetLocation.jugar:
        context.go(AppRoutes.jugar);
        return;
      case PetLocation.dormir:
        context.go(AppRoutes.dormir);
        return;
      case PetLocation.curar:
        context.go(AppRoutes.curar);
        return;
      case PetLocation.banar:
        context.go(AppRoutes.banar);
        return;
    }
  }
}

class _MissionCardData {
  static const int _sleepRecoveryTarget = 25;

  final String id;
  final String emoji;
  final String title;
  final String desc;
  final double progress;
  final int reward;
  final bool urgent;
  final bool canClaimReward;
  final bool shouldAutoComplete;
  final PetLocation location;
  final String actionLabel;

  const _MissionCardData({
    required this.id,
    required this.emoji,
    required this.title,
    required this.desc,
    required this.progress,
    required this.reward,
    required this.urgent,
    required this.canClaimReward,
    required this.shouldAutoComplete,
    required this.location,
    required this.actionLabel,
  });

  factory _MissionCardData.fromMission(
    PendingMission mission, {
    MascotaModel? mascota,
    required List<PendingDisaster> disasters,
    PetLocation? fallbackLocation,
  }) {
    final progress = _resolveMissionProgress(
      mission,
      mascota: mascota,
      disasters: disasters,
    );

    return _MissionCardData(
      id: mission.id,
      emoji: mission.emoji,
      title: mission.title,
      desc: mission.description,
      progress: progress,
      reward: mission.rewardCoins,
      urgent: mission.isUrgent && !mission.canClaimReward,
      canClaimReward: mission.canClaimReward,
      shouldAutoComplete: mission.isPending && progress >= 1.0,
      location: fallbackLocation ?? mission.resolvedLocation,
      actionLabel: mission.canClaimReward ? 'Cobrar' : mission.actionLabel,
    );
  }

  static double _resolveMissionProgress(
    PendingMission mission, {
    MascotaModel? mascota,
    required List<PendingDisaster> disasters,
  }) {
    if (mission.isCompleted) return 1.0;

    if (mission.kind == MissionKind.recogerComida) {
      final targetTotal = mission.targetCount ?? 5;
      final remaining = disasters
          .where(
            (disaster) =>
                disaster.kind == DisasterKind.comida ||
                disaster.kind == DisasterKind.porcion,
          )
          .fold<int>(0, (sum, disaster) => sum + disaster.quantity);
      return _progressFromRemaining(targetTotal, remaining);
    }

    if (mission.kind == MissionKind.recogerJuguete) {
      final targetTotal =
          mission.targetCount ??
          _sumInitialDisasterQuantity(disasters, DisasterKind.juguete);
      final remaining = disasters
          .where((disaster) => disaster.kind == DisasterKind.juguete)
          .fold<int>(0, (sum, disaster) => sum + disaster.quantity);
      return _progressFromRemaining(targetTotal, remaining);
    }

    if (mission.kind == MissionKind.recogerBasura) {
      final linkedDisasters = disasters
          .where(
            (disaster) =>
                disaster.kind == DisasterKind.basura &&
                disaster.missionId == mission.id,
          )
          .toList();
      if (mission.id.toLowerCase() == 'limpiar_residuos' &&
          linkedDisasters.isNotEmpty) {
        final targetTotal =
            mission.targetCount ??
            linkedDisasters.fold<int>(
              0,
              (sum, disaster) => sum + disaster.initialQuantity,
            );
        final remaining = linkedDisasters.fold<int>(
          0,
          (sum, disaster) => sum + disaster.quantity,
        );
        return _progressFromRemaining(targetTotal, remaining);
      }

      final targetTotal =
          mission.targetCount ??
          _sumInitialDisasterQuantity(disasters, DisasterKind.basura);
      final remaining = disasters
          .where((disaster) => disaster.kind == DisasterKind.basura)
          .fold<int>(0, (sum, disaster) => sum + disaster.quantity);
      return _progressFromRemaining(targetTotal, remaining);
    }

    if (mascota == null) return 0.0;

    final missionId = mission.id.toLowerCase();
    final progress = switch (missionId) {
      'cuidar_salud' || 'delicado_curar' => mascota.nivelSalud / 100,
      'alimentar' ||
      'gloton_alimentar_urgente' ||
      'gloton_alimentar_critico' => mascota.nivelHambre / 100,
      'descansar' || 'jugueton_dormir' => _sleepRecoveryProgress(mascota),
      'limpiar' || 'travieso_limpiar' || 'mision_bano' =>
        mascota.nivelLimpieza / 100,
      'jugar_afecto' ||
      'jugar_rutina' ||
      'jugueton_jugar_urgente' ||
      'travieso_calmar' ||
      'carinoso_jugar' ||
      'carinoso_urgente' => mascota.nivelAfecto / 100,
      _ => 0.0,
    };

    return progress.clamp(0.0, 1.0).toDouble();
  }

  static double _sleepRecoveryProgress(MascotaModel mascota) {
    final recoveredEnergy = (mascota.nivelEnergia - mascota.energiaAlAcostar)
        .clamp(0, _sleepRecoveryTarget);
    return recoveredEnergy / _sleepRecoveryTarget;
  }

  static int _sumInitialDisasterQuantity(
    List<PendingDisaster> disasters,
    DisasterKind kind,
  ) {
    return disasters
        .where((disaster) => disaster.kind == kind)
        .fold<int>(0, (sum, disaster) => sum + disaster.initialQuantity);
  }

  static double _progressFromRemaining(int targetTotal, int remaining) {
    if (targetTotal <= 0) {
      return remaining <= 0 ? 1.0 : 0.0;
    }

    final normalized =
        ((targetTotal - remaining.clamp(0, targetTotal)) / targetTotal)
            .toDouble();
    return normalized.clamp(0.0, 1.0);
  }
}

class _DisasterCardData {
  final String emoji;
  final String title;
  final String desc;
  final double progress;
  final int reward;
  final String wayToWin;
  final PetLocation location;
  final String locationLabel;

  const _DisasterCardData({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.progress,
    required this.reward,
    required this.wayToWin,
    required this.location,
    required this.locationLabel,
  });

  factory _DisasterCardData.fromDisaster(PendingDisaster disaster) {
    final locationLabel = _locationLabel(disaster.location);
    final title = switch (disaster.kind) {
      DisasterKind.comida => 'Comida tirada en $locationLabel',
      DisasterKind.juguete => 'Juguetes fuera de lugar en $locationLabel',
      DisasterKind.basura => 'Basura acumulada en $locationLabel',
      DisasterKind.porcion => 'Sobras de comida en $locationLabel',
      DisasterKind.desconocido => 'Desastre pendiente',
    };

    final desc = switch (disaster.kind) {
      DisasterKind.comida =>
        'Tu mascota tiro comida en $locationLabel. Limpia ${disaster.quantity} pieza(s).',
      DisasterKind.juguete =>
        'Recoge ${disaster.quantity} juguete(s) en $locationLabel para ordenar el area de juego.',
      DisasterKind.basura =>
        'Limpia ${disaster.quantity} objeto(s) de basura en $locationLabel.',
      DisasterKind.porcion =>
        'Retira ${disaster.quantity} porcion(es) en $locationLabel para mantener limpio.',
      DisasterKind.desconocido =>
        'Hay objetos pendientes por limpiar en la casa.',
    };

    return _DisasterCardData(
      emoji: disaster.emoji,
      title: title,
      desc: desc,
      progress: _progress(disaster),
      reward: 0,
      wayToWin: 'Ve a $locationLabel para quitarlo de pendientes.',
      location: disaster.location,
      locationLabel: locationLabel,
    );
  }

  static double _progress(PendingDisaster disaster) {
    final target = disaster.initialQuantity;
    if (target <= 0) return 0.0;

    final normalized =
        ((target - disaster.quantity.clamp(0, target)) / target).toDouble();
    return normalized.clamp(0.0, 1.0);
  }

  static String _locationLabel(PetLocation location) {
    switch (location) {
      case PetLocation.home:
        return 'casa';
      case PetLocation.alimentar:
        return 'alimentacion';
      case PetLocation.jugar:
        return 'juego';
      case PetLocation.dormir:
        return 'dormitorio';
      case PetLocation.curar:
        return 'curacion';
      case PetLocation.banar:
        return 'bano';
    }
  }
}

class _TopHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int coins;

  const _TopHeader({
    required this.title,
    required this.subtitle,
    required this.coins,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0x14000000))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.doradoSuave,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.doradoBorde),
            ),
            child: Text(
              '🪙 $coins',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.doradoTexto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textoPrincipal,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;

  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 9,
        backgroundColor: Colors.black.withValues(alpha: 0.06),
        valueColor: const AlwaysStoppedAnimation<Color>(
          AppColors.verdePrincipal,
        ),
      ),
    );
  }
}

class _EmojiBox extends StatelessWidget {
  final String emoji;
  final Color backgroundColor;
  final double size;

  const _EmojiBox({
    required this.emoji,
    required this.backgroundColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.48)),
    );
  }
}

class _ActiveMissionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  final double progress;
  final int reward;
  final bool urgent;
  final bool completed;
  final String action;
  final bool exiting;
  final bool processing;
  final VoidCallback onPressed;

  const _ActiveMissionCard({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.progress,
    required this.reward,
    required this.urgent,
    required this.completed,
    required this.action,
    required this.exiting,
    required this.processing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final done = completed || progress >= 1.0;
    final cardBackground = completed
        ? const Color(0xFFF1FCEB)
        : (urgent ? const Color(0xFFFFF7F8) : Colors.white);
    final cardBorder = completed
        ? const Color(0xFFCBEAB7)
        : (urgent
              ? const Color(0xFFF8C8D2)
              : Colors.black.withValues(alpha: 0.05));
    final emojiBackground = completed
        ? const Color(0xFFE3F7D7)
        : const Color(0xFFF5F8FF);
    final progressLabel = completed ? 'Lista para cobrar' : 'Progreso';

    return AnimatedSlide(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      offset: exiting ? const Offset(0.18, 0) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        opacity: exiting ? 0.0 : 1.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          scale: exiting ? 0.94 : 1.0,
          child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EmojiBox(
            emoji: emoji,
            backgroundColor: emojiBackground,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textoPrincipal,
                      ),
                    ),
                    if (completed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDF7E3),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Completada',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2B7A3D),
                          ),
                        ),
                      )
                    else if (urgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE3EA),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Urgente',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB74263),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Colors.black54,
                  ),
                ),
                if (completed) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD5EECA)),
                    ),
                    child: const Text(
                      'Recompensa lista. Cobra tus monedas desde aqui.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: Color(0xFF3B6C2B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      progressLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                    Text(
                      completed
                          ? '100%'
                          : '${(progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: completed
                            ? const Color(0xFF3B6C2B)
                            : Colors.black45,
                        fontWeight: completed
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _ProgressBar(value: progress),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '🪙 +$reward',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.doradoTexto,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: processing ? null : onPressed,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: completed
                            ? const Color(0xFF2E8B57)
                            : (done
                                  ? AppColors.verdePrincipal
                                  : AppColors.azulPrincipal),
                        foregroundColor: completed
                            ? Colors.white
                            : (done
                                  ? const Color(0xFF173612)
                                  : Colors.white),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: processing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              action,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
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

class _RandomMissionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  final double progress;
  final int reward;
  final String wayToWin;
  final VoidCallback onPressed;

  const _RandomMissionCard({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.progress,
    required this.reward,
    required this.wayToWin,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.azulFondo,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE8FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EmojiBox(emoji: emoji, backgroundColor: Colors.white, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progreso',
                      style: TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _ProgressBar(value: progress),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE4ECFF)),
                  ),
                  child: Text(
                    wayToWin,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: Color(0xFF4A5E9E),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      reward > 0 ? '🪙 +$reward' : 'Sin recompensa directa',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.doradoTexto,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.azulPrincipal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Ir a limpiar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyListCard extends StatelessWidget {
  final String title;
  final String desc;

  const _EmptyListCard({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const _EmojiBox(
            emoji: '✨',
            backgroundColor: Color(0xFFF5F8FF),
            size: 46,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
