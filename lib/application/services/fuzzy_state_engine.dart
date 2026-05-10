import 'dart:math';

import '../../Models/mascota_stats_model.dart';
import '../../core/enums/personalidad_tipo.dart';

class FuzzyStateEngine {
  final Random _random;

  FuzzyStateEngine({Random? random}) : _random = random ?? Random();

  double evaluate(
    MascotaStatsModel stats,
    PersonalidadTipo personalidad, {
    bool anomaliaActiva = false,
  }) {
    var rate = _baseRate(stats);

    switch (personalidad) {
      case PersonalidadTipo.gloton:
        if (stats.nivelHambre > 60) {
          rate += 0.5;
        }
        break;
      case PersonalidadTipo.delicado:
        if (stats.nivelLimpieza < 40) {
          rate += 0.4;
        }
        if (stats.nivelSalud < 50) {
          rate += 0.3;
        }
        break;
      case PersonalidadTipo.carinoso:
        if (stats.nivelAfecto < 30) {
          rate += 0.5;
        }
        if (stats.nivelAfecto < 15) {
          rate += 0.3;
        }
        break;
      case PersonalidadTipo.jugueton:
        if (stats.nivelEnergia < 20) {
          rate += 0.4;
        }
        break;
      case PersonalidadTipo.travieso:
        rate += (_random.nextDouble() * 0.4) - 0.2;
        break;
    }

    if (anomaliaActiva) {
      rate *= 1.3;
    }

    return rate.clamp(0.5, 3.0).toDouble();
  }

  double _baseRate(MascotaStatsModel stats) {
    if (stats.nivelHambre > 70 && stats.nivelEnergia < 30) {
      return 2.0;
    }
    if (stats.nivelSalud < 30) {
      return 1.8;
    }
    if (stats.nivelLimpieza < 20) {
      return 1.6;
    }
    if (stats.nivelAfecto < 20) {
      return 1.4;
    }
    return 1.0;
  }
}
