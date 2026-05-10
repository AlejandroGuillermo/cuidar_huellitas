import '../../core/enums/pet_emotion.dart';
import '../../core/enums/pet_need.dart';

class PetAiDecision {
  final PetNeed needPriority;
  final double needScore;
  final PetEmotion emotion;
  final double deterioroRate;
  final bool anomaliaActiva;
  final String? misionRecomendada;
  final String? mensaje;
  final bool generarDesastre;
  final DateTime calculadoAt;

  const PetAiDecision({
    required this.needPriority,
    required this.needScore,
    required this.emotion,
    required this.deterioroRate,
    required this.anomaliaActiva,
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
      anomaliaActiva: false,
      misionRecomendada: null,
      mensaje: null,
      generarDesastre: false,
      calculadoAt: DateTime.now(),
    );
  }

  PetAiDecision copyWith({
    PetNeed? needPriority,
    double? needScore,
    PetEmotion? emotion,
    double? deterioroRate,
    bool? anomaliaActiva,
    String? misionRecomendada,
    bool clearMisionRecomendada = false,
    String? mensaje,
    bool clearMensaje = false,
    bool? generarDesastre,
    DateTime? calculadoAt,
  }) {
    return PetAiDecision(
      needPriority: needPriority ?? this.needPriority,
      needScore: needScore ?? this.needScore,
      emotion: emotion ?? this.emotion,
      deterioroRate: deterioroRate ?? this.deterioroRate,
      anomaliaActiva: anomaliaActiva ?? this.anomaliaActiva,
      misionRecomendada: clearMisionRecomendada
          ? null
          : (misionRecomendada ?? this.misionRecomendada),
      mensaje: clearMensaje ? null : (mensaje ?? this.mensaje),
      generarDesastre: generarDesastre ?? this.generarDesastre,
      calculadoAt: calculadoAt ?? this.calculadoAt,
    );
  }
}
