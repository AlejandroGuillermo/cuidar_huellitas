import '../../Models/mascota_runtime_model.dart';
import '../../Models/mascota_stats_model.dart';
import '../../core/enums/personalidad_tipo.dart';
import '../../core/enums/pet_emotion.dart';

class PetEmotionResolver {
  const PetEmotionResolver();

  PetEmotion resolve(
    MascotaStatsModel stats,
    MascotaRuntimeModel runtime,
    PersonalidadTipo personalidad,
  ) {
    if (stats.nivelSalud < 20) {
      return PetEmotion.sick;
    }
    if (stats.nivelLimpieza < 20) {
      return PetEmotion.dirty;
    }
    if (stats.nivelHambre > 80) {
      return PetEmotion.hungry;
    }
    if (stats.nivelEnergia < 15) {
      return PetEmotion.tired;
    }
    if (stats.nivelAfecto < 20) {
      return PetEmotion.sad;
    }
    if (stats.nivelAfecto < 35 && personalidad == PersonalidadTipo.carinoso) {
      return PetEmotion.sad;
    }
    if (DateTime.now().difference(runtime.ultimaInteraccion).inHours > 4) {
      return PetEmotion.bored;
    }
    if (stats.nivelSalud > 60 &&
        stats.nivelEnergia > 60 &&
        stats.nivelHambre > 60 &&
        stats.nivelLimpieza > 60 &&
        stats.nivelAfecto > 60) {
      return PetEmotion.happy;
    }
    return PetEmotion.neutral;
  }
}
