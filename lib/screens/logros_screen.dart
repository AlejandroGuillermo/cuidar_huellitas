import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/app_colors.dart';
import '../cubit/pet_cubit.dart';
import '../cubit/pet_state.dart';

class LogrosScreen extends StatelessWidget {
  const LogrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state) {
        final mascota = state.mascota;
        final nombreMascota = mascota?.nombreMascota ?? 'Tu mascota';
        final tipoMascota = (mascota?.tipoMascota ?? 'perro').toLowerCase();
        final petEmoji = tipoMascota == 'gato' ? '🐱' : '🐶';

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

        final missions = [
          _MissionData(
            icon: Icons.restaurant_rounded,
            badge: 'Nuevo',
            date: 'Hoy',
            title: 'Rutina de comida estable',
            description:
                '$nombreMascota respondió bien a una secuencia de cuidados constante.',
            tip: 'Seguir horarios similares ayuda a que coma con más calma.',
          ),
          _MissionData(
            icon: Icons.clean_hands_rounded,
            badge: 'Desbloqueado',
            date: 'Esta semana',
            title: 'Espacio limpio y seguro',
            description:
                'Mantienes su entorno ordenado y eso mejora su bienestar diario.',
            tip: 'La limpieza frecuente reduce estrés y refuerza hábitos sanos.',
          ),
          _MissionData(
            icon: Icons.favorite_rounded,
            badge: 'Especial',
            date: 'Reciente',
            title: 'Vínculo afectivo fuerte',
            description:
                '$nombreMascota busca más tu compañía y se siente en confianza contigo.',
            tip: 'Las interacciones pequeñas y frecuentes fortalecen el apego.',
          ),
        ];

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
            label: 'Energía disponible',
            accent: AppColors.azulPrincipal,
          ),
          _StatData(
            icon: Icons.auto_awesome_rounded,
            value: '$promedio%',
            label: 'Balance general',
            accent: AppColors.verdePrincipal,
          ),
        ];

        final insights = [
          'Me siento acompañado cuando mantienes mi rutina diaria.',
          'Disfruto más jugar contigo cuando primero me ayudas a estar tranquilo.',
          'Cuando cuidas mis niveles seguido, descanso y me recupero mejor.',
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
                      petEmoji: petEmoji,
                      nombreMascota: nombreMascota,
                      streakDays: streakDays,
                      goalDays: goalDays,
                      progressToGoal: progressToGoal,
                    ),
                    const SizedBox(height: 18),
                    _StatsGrid(stats: stats),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'Logros desbloqueados',
                      icon: Icons.workspace_premium_rounded,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rosa.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${missions.length} activos',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.rosa,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < missions.length; i++) ...[
                            _MissionCard(data: missions[i]),
                            if (i != missions.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _InsightsSection(
                      nombreMascota: nombreMascota,
                      petEmoji: petEmoji,
                      insights: insights,
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
  final String petEmoji;
  final String nombreMascota;
  final int streakDays;
  final int goalDays;
  final double progressToGoal;

  const _HeroLogrosCard({
    required this.petEmoji,
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
          colors: [
            Colors.white.withValues(alpha: 0.96),
            AppColors.verdeFondo,
          ],
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
                      'Cada cuidado suma confianza, estabilidad y mejores hábitos.',
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
                    colors: [
                      AppColors.verdeClaro,
                      AppColors.verdePrincipal,
                    ],
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
                child: Text(
                  petEmoji,
                  style: const TextStyle(fontSize: 38),
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
        border: Border.all(
          color: data.accent.withValues(alpha: 0.18),
        ),
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
            child: Icon(
              data.icon,
              color: data.accent,
            ),
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
        border: Border.all(
          color: AppColors.borde.withValues(alpha: 0.55),
        ),
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
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
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
          colors: [
            Color(0xFFFFF9FB),
            Colors.white,
          ],
        ),
        border: Border.all(
          color: AppColors.rosa.withValues(alpha: 0.18),
        ),
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
                  color: AppColors.rosa.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  data.icon,
                  color: AppColors.rosa,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MissionPill(
                      text: data.badge,
                      backgroundColor: AppColors.rosa.withValues(alpha: 0.14),
                      textColor: AppColors.rosa,
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
                          text: 'Lo que aprendiste: ',
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
  final String petEmoji;
  final List<String> insights;

  const _InsightsSection({
    required this.nombreMascota,
    required this.petEmoji,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.azulPrincipal,
            AppColors.azulClaro,
          ],
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
                child: Text(
                  petEmoji,
                  style: const TextStyle(fontSize: 24),
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
          const SizedBox(height: 16),
          for (var i = 0; i < insights.length; i++) ...[
            _InsightCard(text: insights[i]),
            if (i != insights.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String text;

  const _InsightCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.pets_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
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

class _MissionData {
  final IconData icon;
  final String badge;
  final String date;
  final String title;
  final String description;
  final String tip;

  const _MissionData({
    required this.icon,
    required this.badge,
    required this.date,
    required this.title,
    required this.description,
    required this.tip,
  });
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
