import '../../Models/mascota_stats_model.dart';
import '../../core/enums/pet_need.dart';

class PetNeedEvaluation {
  final PetNeed need;
  final double score;

  const PetNeedEvaluation({required this.need, required this.score});
}

class PetNeedsEvaluator {
  const PetNeedsEvaluator();

  PetNeedEvaluation evaluate(MascotaStatsModel stats) {
    final activeNeeds = evaluateAll(stats);
    if (activeNeeds.isEmpty) {
      return const PetNeedEvaluation(need: PetNeed.none, score: 0);
    }
    return activeNeeds.first;
  }

  List<PetNeedEvaluation> evaluateAll(MascotaStatsModel stats) {
    final needs = <PetNeedEvaluation>[];

    if (stats.nivelSalud < 25) {
      needs.add(
        PetNeedEvaluation(
          need: PetNeed.health,
          score: 100 + (25 - stats.nivelSalud),
        ),
      );
    }
    if (stats.nivelHambre > 75) {
      needs.add(
        PetNeedEvaluation(
          need: PetNeed.hunger,
          score: 80 + (stats.nivelHambre - 75),
        ),
      );
    }
    if (stats.nivelEnergia < 25) {
      needs.add(
        PetNeedEvaluation(
          need: PetNeed.energy,
          score: 70 + (25 - stats.nivelEnergia),
        ),
      );
    }
    if (stats.nivelLimpieza < 30) {
      needs.add(
        PetNeedEvaluation(
          need: PetNeed.hygiene,
          score: 50 + (30 - stats.nivelLimpieza),
        ),
      );
    }
    if (stats.nivelAfecto < 30) {
      needs.add(
        PetNeedEvaluation(
          need: PetNeed.affection,
          score: 40 + (30 - stats.nivelAfecto),
        ),
      );
    }

    needs.sort((a, b) {
      final priorityCompare = a.need.priority.compareTo(b.need.priority);
      if (priorityCompare != 0) return priorityCompare;
      return b.score.compareTo(a.score);
    });

    return needs;
  }
}
