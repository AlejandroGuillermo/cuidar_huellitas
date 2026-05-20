import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;

import '../core/app_colors.dart';
import '../cubit/pet_cubit.dart';
import '../cubit/pet_state.dart';
import '../data/repositories/mission_repository.dart';
import '../domain/entities/pending_mission.dart';
import '../domain/enums/pet_location.dart';
import '../widgets/pet_avatar_rive.dart';
import '../data/repositories/pet_learning_repository.dart';


class LogrosScreen extends StatefulWidget {
  const LogrosScreen({super.key});

  @override
  State<LogrosScreen> createState() => _LogrosScreenState();
}

class _LogrosScreenState extends State<LogrosScreen> {
  final MissionRepository _missionRepository = MissionRepository();
  final PetLearningRepository _learningRepository = PetLearningRepository();

  String? _activeLearningMascotaId;
  bool _isLoadingLearning = false;
  PetLearningSnapshot _learningSnapshot = PetLearningSnapshot.empty();
  String? _activeMascotaId;
  bool _isLoadingCompletedToday = false;
  List<PendingMission> _completedToday = const [];

  Future<void> _loadAiLearning(String mascotaId) async {
    if (mascotaId.isEmpty || _activeLearningMascotaId == mascotaId) return;

    setState(() {
      _activeLearningMascotaId = mascotaId;
      _isLoadingLearning = true;
      _learningSnapshot = PetLearningSnapshot.empty();
    });

    try {
      final snapshot = await _learningRepository.loadLearningSnapshot(
        mascotaId: mascotaId,
      );

      if (!mounted || _activeLearningMascotaId != mascotaId) return;

      setState(() => _learningSnapshot = snapshot);
    } catch (_) {
      if (!mounted || _activeLearningMascotaId != mascotaId) return;

      setState(() => _learningSnapshot = PetLearningSnapshot.empty());
    } finally {
      if (mounted && _activeLearningMascotaId == mascotaId) {
        setState(() => _isLoadingLearning = false);
      }
    }
  }

  Future<void> _loadCompletedToday(String mascotaId) async {
    if (mascotaId.isEmpty || _activeMascotaId == mascotaId) return;

    setState(() {
      _activeMascotaId = mascotaId;
      _isLoadingCompletedToday = true;
      _completedToday = const [];
    });

    try {
      final missions = await _missionRepository.loadCompletedToday(mascotaId);
      if (!mounted || _activeMascotaId != mascotaId) return;
      setState(() => _completedToday = missions);
    } catch (_) {
      if (!mounted || _activeMascotaId != mascotaId) return;
      setState(() => _completedToday = const []);
    } finally {
      if (mounted && _activeMascotaId == mascotaId) {
        setState(() => _isLoadingCompletedToday = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state) {
        final mascota = state.mascota;
        final mascotaId = mascota?.idMascota;
        if (mascotaId != null &&
            mascotaId.isNotEmpty &&
            (_activeMascotaId != mascotaId ||
                _activeLearningMascotaId != mascotaId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _loadCompletedToday(mascotaId);
            _loadAiLearning(mascotaId);
          });
        }

        final nombreMascota = mascota?.nombreMascota ?? 'Tu mascota';
        final tipoMascota = (mascota?.tipoMascota ?? 'perro').toLowerCase();

        final promedio = mascota == null
            ? 0
            : ((mascota.nivelSalud +
                        mascota.nivelEnergia +
                        mascota.nivelHambre +
                        mascota.nivelLimpieza +
                        mascota.nivelAfecto) /
                    5)
                .round();
        final streakDays = (promedio / 18).clamp(1, 7).round();
        final goalDays = 7;
        final progressToGoal = (streakDays / goalDays).clamp(0.0, 1.0);

        final missionCards = _completedToday
            .map(_MissionData.fromPendingMission)
            .toList();
        final claimedCount = _completedToday
            .where((mission) => mission.rewardClaimed)
            .length;
        final coinsToday = _completedToday.fold<int>(
          0,
          (sum, mission) => sum + mission.rewardCoins,
        );

        final stats = [
          _StatData(
            icon: Icons.favorite_rounded,
            value: '${mascota?.nivelAfecto ?? 0}%',
            label: 'Afecto actual',
            accent: AppColors.rosa,
          ),
          _StatData(
            icon: Icons.bedtime_rounded,
            value: '${mascota?.nivelEnergia ?? 0}%',
            label: 'Energia disponible',
            accent: AppColors.azulPrincipal,
          ),
          _StatData(
            icon: Icons.auto_awesome_rounded,
            value: '$promedio%',
            label: 'Balance general',
            accent: AppColors.verdePrincipal,
          ),
        ];

        return Scaffold(
          backgroundColor: AppColors.fondoPrincipal,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.verdeFondo,
                  AppColors.azulFondo.withValues(alpha: 0.75),
                  AppColors.fondoPrincipal,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroLogrosCard(
                      petType: tipoMascota,
                      nombreMascota: nombreMascota,
                      streakDays: streakDays,
                      goalDays: goalDays,
                      progressToGoal: progressToGoal,
                    ),
                    const SizedBox(height: 18),
                    _StatsGrid(stats: stats),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'Misiones cumplidas hoy',
                      icon: Icons.task_alt_rounded,
                      trailing: _TodaySummaryPill(
                        count: missionCards.length,
                        coinsToday: coinsToday,
                      ),
                      child: _CompletedTodaySection(
                        isLoading: _isLoadingCompletedToday,
                        missions: missionCards,
                        claimedCount: claimedCount,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _InsightsSection(
                      nombreMascota: nombreMascota,
                      petType: tipoMascota,
                      snapshot: _learningSnapshot,
                      isLoading: _isLoadingLearning,
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

class _HeroLogrosCard extends StatelessWidget {
  final String petType;
  final String nombreMascota;
  final int streakDays;
  final int goalDays;
  final double progressToGoal;

  const _HeroLogrosCard({
    required this.petType,
    required this.nombreMascota,
    required this.streakDays,
    required this.goalDays,
    required this.progressToGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.96), AppColors.verdeFondo],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.azulPrincipal.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
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
                    const Text(
                      'Logros de cuidado',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$nombreMascota esta orgulloso de ti',
                      style: const TextStyle(
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Cada mision completada fortalece la rutina, el vinculo y la estabilidad de tu mascota.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.verdeClaro, AppColors.verdePrincipal],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.verdePrincipal.withValues(alpha: 0.34),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: PetAvatarRive(
                  tipoMascota: petType,
                  width: 90,
                  height: 90,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.textoPrincipal,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Racha activa',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$streakDays/$goalDays dias',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '$streakDays dias cuidando en equipo',
                  style: const TextStyle(
                    fontSize: 26,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Sigue asi para desbloquear una nueva insignia de rutina saludable.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Color(0xFFE7F4E8),
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progressToGoal,
                    minHeight: 12,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.verdeClaro,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<_StatData> stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Resumen del momento',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textoPrincipal,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;
            final spacing = 12.0;
            final itemWidth = isCompact
                ? constraints.maxWidth
                : (constraints.maxWidth - spacing) / 2;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: stats.map((stat) {
                return SizedBox(
                  width: itemWidth,
                  child: _StatHighlightCard(data: stat),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _StatHighlightCard extends StatelessWidget {
  final _StatData data;

  const _StatHighlightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: data.accent.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: data.accent.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.accent),
          ),
          const SizedBox(height: 18),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w900,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borde.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textoPrincipal, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textoPrincipal,
                  ),
                ),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CompletedTodaySection extends StatelessWidget {
  final bool isLoading;
  final List<_MissionData> missions;
  final int claimedCount;

  const _CompletedTodaySection({
    required this.isLoading,
    required this.missions,
    required this.claimedCount,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.azulPrincipal),
        ),
      );
    }

    if (missions.isEmpty) {
      return const _EmptyMissionHistoryCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.verdeFondo,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.verdeClaro),
          ),
          child: Text(
            'Hoy completaste ${missions.length} mision(es) y ya cobraste $claimedCount recompensa(s).',
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.textoPrincipal,
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < missions.length; i++) ...[
          _MissionCard(data: missions[i]),
          if (i != missions.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _TodaySummaryPill extends StatelessWidget {
  final int count;
  final int coinsToday;

  const _TodaySummaryPill({
    required this.count,
    required this.coinsToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.rosa.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count hoy • +$coinsToday',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.rosa,
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final _MissionData data;

  const _MissionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF9FB), Colors.white],
        ),
        border: Border.all(color: data.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: data.iconBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(data.icon, color: data.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MissionPill(
                      text: data.badge,
                      backgroundColor: data.badgeBackgroundColor,
                      textColor: data.badgeTextColor,
                    ),
                    _MissionPill(
                      text: data.date,
                      backgroundColor: AppColors.azulFondo,
                      textColor: AppColors.azulPrincipal,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 18,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.verdeFondo,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_rounded,
                  size: 18,
                  color: AppColors.textoPrincipal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: AppColors.textoPrincipal,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Estado: ',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: data.tip),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionPill extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const _MissionPill({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

class _InsightsSection extends StatelessWidget {
  final String nombreMascota;
  final String petType;
  final PetLearningSnapshot snapshot;
  final bool isLoading;

  const _InsightsSection({
    required this.nombreMascota,
    required this.petType,
    required this.snapshot,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final rutina = _AiMetricData(
      title: 'Rutina diaria',
      percent: snapshot.rutina,
      icon: Icons.auto_graph_rounded,
    );

    final secondaryMetrics = [
      _AiMetricData(
        title: 'Higiene',
        percent: snapshot.higiene,
        icon: Icons.cleaning_services_rounded,
      ),
      _AiMetricData(
        title: 'Afecto',
        percent: snapshot.afecto,
        icon: Icons.favorite_rounded,
      ),
      _AiMetricData(
        title: 'Energía',
        percent: snapshot.energia,
        icon: Icons.bolt_rounded,
      ),
      _AiMetricData(
        title: 'Alimentación',
        percent: snapshot.alimentacion,
        icon: Icons.restaurant_rounded,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.azulPrincipal, AppColors.azulClaro],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.azulPrincipal.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: PetAvatarRive(
                  tipoMascota: petType,
                  width: 52,
                  height: 52,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Lo que tu mascota ha aprendido de ti',
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$nombreMascota reconoce patrones de cuidado y responde mejor a ellos.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              color: Color(0xFFEAF1FF),
            ),
          ),
          const SizedBox(height: 18),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else ...[
            _LearningRadarChart(snapshot: snapshot),
            const SizedBox(height: 16),
            _AiMetricTile(data: rutina, featured: true),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final itemWidth = (constraints.maxWidth - spacing) / 2;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: secondaryMetrics.map((metric) {
                    return SizedBox(
                      width: itemWidth,
                      child: _AiMetricTile(data: metric),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 14),
            _AiMessageCard(
              text: snapshot.message,
              samples: snapshot.totalMuestras,
            ),
          ],
        ],
      ),
    );
  }
}

class _AiMetricData {
  final String title;
  final int percent;
  final IconData icon;

  const _AiMetricData({
    required this.title,
    required this.percent,
    required this.icon,
  });
}

class _AiMetricTile extends StatelessWidget {
  final _AiMetricData data;
  final bool featured;

  const _AiMetricTile({
    required this.data,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: featured ? 104 : 96,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: featured ? 0.18 : 0.13),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            data.icon,
            color: Colors.white,
            size: featured ? 24 : 20,
          ),
          const SizedBox(height: 10),
          Text(
            '${data.percent}%',
            style: TextStyle(
              fontSize: featured ? 34 : 27,
              height: 0.95,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: featured ? 15 : 12.5,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFEAF1FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiMessageCard extends StatelessWidget {
  final String text;
  final int samples;

  const _AiMessageCard({
    required this.text,
    required this.samples,
  });

  @override
  Widget build(BuildContext context) {
    final sampleText = samples > 0 ? ' • $samples datos analizados' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.psychology_alt_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$text$sampleText',
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningRadarChart extends StatelessWidget {
  final PetLearningSnapshot snapshot;

  const _LearningRadarChart({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'PATRONES APRENDIDOS ESTA SEMANA',
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w900,
                color: Color(0xFFEAF1FF),
              ),
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = math.min(constraints.maxWidth, 260.0);

              return Center(
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _RadarPainter(
                    values: snapshot.radarValues,
                    labels: const [
                      'Rutina',
                      'Afecto',
                      'Alimentación',
                      'Energía',
                      'Higiene',
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  const _RadarPainter({
    required this.values,
    required this.labels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.30;
    final count = labels.length;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (var level = 1; level <= 4; level++) {
      final levelRadius = radius * (level / 4);
      final path = Path();

      for (var i = 0; i < count; i++) {
        final point = _point(center, levelRadius, i, count);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (var i = 0; i < count; i++) {
      final point = _point(center, radius, i, count);
      canvas.drawLine(center, point, axisPaint);
    }

    final valuePath = Path();

    for (var i = 0; i < count; i++) {
      final safeValue = values[i].clamp(0.0, 1.0);
      final point = _point(center, radius * safeValue, i, count);

      if (i == 0) {
        valuePath.moveTo(point.dx, point.dy);
      } else {
        valuePath.lineTo(point.dx, point.dy);
      }
    }

    valuePath.close();
    canvas.drawPath(valuePath, fillPaint);
    canvas.drawPath(valuePath, linePaint);

    for (var i = 0; i < count; i++) {
      final safeValue = values[i].clamp(0.0, 1.0);
      final point = _point(center, radius * safeValue, i, count);
      canvas.drawCircle(point, 5.2, dotPaint);
    }

    for (var i = 0; i < count; i++) {
      final labelPoint = _point(center, radius + 33, i, count);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Color(0xFFEAF1FF),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: 86);

      textPainter.paint(
        canvas,
        Offset(
          labelPoint.dx - textPainter.width / 2,
          labelPoint.dy - textPainter.height / 2,
        ),
      );
    }
  }

  Offset _point(Offset center, double radius, int index, int count) {
    final angle = -math.pi / 2 + (2 * math.pi * index / count);

    return Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
  }
}

class _EmptyMissionHistoryCard extends StatelessWidget {
  const _EmptyMissionHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFF8FBFF),
        border: Border.all(color: AppColors.azulFondo),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Todavia no completas misiones hoy',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textoPrincipal,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Cuando termines una mision en Retos, aparecera aqui con su recompensa y estado de cobro.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionData {
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color borderColor;
  final String badge;
  final Color badgeBackgroundColor;
  final Color badgeTextColor;
  final String date;
  final String title;
  final String description;
  final String tip;

  const _MissionData({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.borderColor,
    required this.badge,
    required this.badgeBackgroundColor,
    required this.badgeTextColor,
    required this.date,
    required this.title,
    required this.description,
    required this.tip,
  });

  factory _MissionData.fromPendingMission(PendingMission mission) {
    final claimed = mission.rewardClaimed;
    return _MissionData(
      icon: _iconForMission(mission),
      iconColor: claimed ? const Color(0xFF2B7A3D) : AppColors.azulPrincipal,
      iconBackgroundColor: claimed
          ? const Color(0xFFDDF7E3)
          : AppColors.azulFondo,
      borderColor: claimed
          ? const Color(0xFFCBEAB7)
          : AppColors.azulFondo.withValues(alpha: 0.75),
      badge: claimed ? 'Cobrada' : 'Por cobrar',
      badgeBackgroundColor: claimed
          ? const Color(0xFFDDF7E3)
          : const Color(0xFFFEE7B8),
      badgeTextColor: claimed
          ? const Color(0xFF2B7A3D)
          : const Color(0xFFA86700),
      date: 'Hoy',
      title: mission.title,
      description: mission.description,
      tip: claimed
          ? 'Ya recibiste ${mission.rewardCoins} monedas por esta mision.'
          : 'La completaste hoy y aun puedes cobrar ${mission.rewardCoins} monedas en Retos.',
    );
  }

  static IconData _iconForMission(PendingMission mission) {
    switch (mission.resolvedLocation) {
      case PetLocation.alimentar:
        return Icons.restaurant_rounded;
      case PetLocation.jugar:
        return Icons.toys_rounded;
      case PetLocation.dormir:
        return Icons.bedtime_rounded;
      case PetLocation.curar:
        return Icons.health_and_safety_rounded;
      case PetLocation.banar:
        return Icons.shower_rounded;
      case PetLocation.home:
        return Icons.cleaning_services_rounded;
    }
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  const _StatData({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });
}
