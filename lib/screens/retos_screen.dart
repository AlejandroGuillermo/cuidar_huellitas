import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../application/cubits/mission_cubit.dart';
import '../core/app_colors.dart';
import '../core/app_router.dart';
import '../domain/entities/pending_disaster.dart';
import '../domain/entities/pending_mission.dart';
import '../domain/enums/disaster_kind.dart';
import '../domain/enums/mission_kind.dart';
import '../domain/enums/pet_location.dart';

class RetosScreen extends StatelessWidget {
  const RetosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MissionCubit, MissionState>(
      builder: (context, missionState) {
        final activeMissions = missionState.missions
            .map(_MissionCardData.fromMission)
            .toList();
        final pendingDisasters = missionState.disasters
            .map(_DisasterCardData.fromDisaster)
            .toList();

        return Scaffold(
          backgroundColor: AppColors.fondoPrincipal,
          body: SafeArea(
            child: Column(
              children: [
                const _TopHeader(
                  title: 'Retos',
                  subtitle: 'Cuida a tu mascota y gana monedas',
                  coins: 245,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _SectionHeader(
                        title: 'Misiones activas',
                        trailing: '${activeMissions.length} pendientes',
                      ),
                      const SizedBox(height: 10),
                      if (missionState.isLoading && activeMissions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.azulPrincipal,
                            ),
                          ),
                        )
                      else if (activeMissions.isEmpty)
                        const _EmptyListCard(
                          title: 'No hay misiones activas',
                          desc:
                              'Cuando tu mascota necesite algo, apareceran aqui.',
                        )
                      else
                        ...activeMissions.map(
                          (mission) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ActiveMissionCard(
                              emoji: mission.emoji,
                              title: mission.title,
                              desc: mission.desc,
                              progress: mission.progress,
                              reward: mission.reward,
                              urgent: mission.urgent,
                              action: 'Ir a completar',
                              onPressed: () => _openRouteByLocation(
                                context,
                                mission.location,
                              ),
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
                              progress: 0.0,
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
        );
      },
    );
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
  final String emoji;
  final String title;
  final String desc;
  final double progress;
  final int reward;
  final bool urgent;
  final PetLocation location;

  const _MissionCardData({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.progress,
    required this.reward,
    required this.urgent,
    required this.location,
  });

  factory _MissionCardData.fromMission(PendingMission mission) {
    final title = switch (mission.kind) {
      MissionKind.recogerComida => 'Recoge la comida tirada',
      MissionKind.recogerJuguete => 'Recoge los juguetes',
      MissionKind.recogerBasura => 'Limpia la basura',
      MissionKind.desconocida => 'Mision activa',
    };

    final desc = switch (mission.kind) {
      MissionKind.recogerComida =>
        'Recoge la comida para mantener limpio el espacio de tu mascota.',
      MissionKind.recogerJuguete =>
        'Recoge los juguetes que quedaron fuera de lugar.',
      MissionKind.recogerBasura =>
        'Limpia la basura para que tu mascota este comoda y sana.',
      MissionKind.desconocida =>
        'Revisa la mision pendiente y completala desde la pantalla indicada.',
    };

    final emoji =
        mission.relatedItemId ??
        switch (mission.kind) {
          MissionKind.recogerComida => '🍖',
          MissionKind.recogerJuguete => '🎾',
          MissionKind.recogerBasura => '🧹',
          MissionKind.desconocida => '🚨',
        };

    return _MissionCardData(
      emoji: emoji,
      title: title,
      desc: desc,
      progress: 0.0,
      reward: mission.rewardCoins,
      urgent: true,
      location: mission.location,
    );
  }
}

class _DisasterCardData {
  final String emoji;
  final String title;
  final String desc;
  final int reward;
  final String wayToWin;
  final PetLocation location;

  const _DisasterCardData({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.reward,
    required this.wayToWin,
    required this.location,
  });

  factory _DisasterCardData.fromDisaster(PendingDisaster disaster) {
    final title = switch (disaster.kind) {
      DisasterKind.comida => 'Comida tirada',
      DisasterKind.juguete => 'Juguetes fuera de lugar',
      DisasterKind.basura => 'Basura acumulada',
      DisasterKind.porcion => 'Sobras de comida',
      DisasterKind.desconocido => 'Desastre pendiente',
    };

    final desc = switch (disaster.kind) {
      DisasterKind.comida =>
        'Tu mascota tiro comida. Limpia ${disaster.quantity} pieza(s).',
      DisasterKind.juguete =>
        'Recoge ${disaster.quantity} juguete(s) para ordenar el area de juego.',
      DisasterKind.basura =>
        'Limpia ${disaster.quantity} objeto(s) de basura en casa.',
      DisasterKind.porcion =>
        'Retira ${disaster.quantity} porcion(es) para mantener limpio.',
      DisasterKind.desconocido =>
        'Hay objetos pendientes por limpiar en la casa.',
    };

    return _DisasterCardData(
      emoji: disaster.emoji,
      title: title,
      desc: desc,
      reward: 0,
      wayToWin: 'Limpialo en su pantalla para quitarlo de pendientes.',
      location: disaster.location,
    );
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
  final String action;
  final VoidCallback onPressed;

  const _ActiveMissionCard({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.progress,
    required this.reward,
    required this.urgent,
    required this.action,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final done = progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: urgent ? const Color(0xFFFFF7F8) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: urgent
              ? const Color(0xFFF8C8D2)
              : Colors.black.withValues(alpha: 0.05),
        ),
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
            backgroundColor: const Color(0xFFF5F8FF),
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
                    if (urgent)
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
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: done
                            ? AppColors.verdePrincipal
                            : AppColors.azulPrincipal,
                        foregroundColor: done
                            ? const Color(0xFF173612)
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
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
