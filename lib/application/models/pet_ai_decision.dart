import '../../core/enums/pet_emotion.dart';
import '../../core/enums/pet_need.dart';

class PetAiDecision {
  final PetNeed needPriority;
  final double needScore;
  final PetEmotion emotion;
  final double deterioroRate;
  final String? misionRecomendada;
  final String? mensaje;
  final bool generarDesastre;
  final DateTime calculadoAt;

  const PetAiDecision({
    required this.needPriority,
    required this.needScore,
    required this.emotion,
    required this.deterioroRate,
    required this.misionRecomendada,
    required this.mensaje,
    required this.generarDesastre,
    required this.calculadoAt,
  });

  factory PetAiDecision.neutral() {
    return PetAiDecision(
      needPriority: PetNeed.none,
      needScore: 0,
      emotion: PetEmotion.neutral,
      deterioroRate: 1.0,
      misionRecomendada: null,
      mensaje: null,
      generarDesastre: false,
      calculadoAt: DateTime.now(),
    );
  }
}
