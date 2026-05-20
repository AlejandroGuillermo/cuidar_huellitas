import 'package:flutter_test/flutter_test.dart';
import 'package:cuidar_huellitas/models/mascota_stats_model.dart';

void main() {
  // Claves reales del modelo: snake_case con prefijo nivel_
  const mapaBase = <String, dynamic>{
    'nivel_salud': 90.0,
    'nivel_energia': 50.0,
    'nivel_hambre': 80.0,
    'nivel_limpieza': 70.0,
    'nivel_afecto': 60.0,
  };

  // ---------------------------------------------------------------------------
  group('MascotaStatsModel.fromMap', () {
    test('carga correctamente todos los campos desde un mapa válido', () {
      final stats = MascotaStatsModel.fromMap(mapaBase);
      expect(stats.nivelSalud, 90.0);
      expect(stats.nivelEnergia, 50.0);
      expect(stats.nivelHambre, 80.0);
      expect(stats.nivelLimpieza, 70.0);
      expect(stats.nivelAfecto, 60.0);
    });

    test('usa 100.0 como fallback cuando una clave está ausente', () {
      final stats = MascotaStatsModel.fromMap({});
      expect(stats.nivelSalud, 100.0);
      expect(stats.nivelEnergia, 100.0);
      expect(stats.nivelHambre, 100.0);
      expect(stats.nivelLimpieza, 100.0);
      expect(stats.nivelAfecto, 100.0);
    });

    test('usa 100.0 como fallback cuando el valor es null', () {
      final stats = MascotaStatsModel.fromMap({
        'nivel_salud': null,
        'nivel_hambre': null,
      });
      expect(stats.nivelSalud, 100.0);
      expect(stats.nivelHambre, 100.0);
    });

    test('acepta enteros (int) y los convierte a double', () {
      final stats = MascotaStatsModel.fromMap({
        'nivel_salud': 90,
        'nivel_energia': 50,
        'nivel_hambre': 80,
        'nivel_limpieza': 70,
        'nivel_afecto': 60,
      });
      expect(stats.nivelSalud, 90.0);
      expect(stats.nivelSalud, isA<double>());
    });

    test('valores en límite inferior (0.0) se cargan sin error', () {
      final mapa = Map<String, dynamic>.from(mapaBase)
        ..updateAll((_, _) => 0.0);
      final stats = MascotaStatsModel.fromMap(mapa);
      expect(stats.nivelSalud, 0.0);
      expect(stats.nivelHambre, 0.0);
    });

    test('valores en límite superior (100.0) se cargan sin error', () {
      final mapa = Map<String, dynamic>.from(mapaBase)
        ..updateAll((_, _) => 100.0);
      final stats = MascotaStatsModel.fromMap(mapa);
      expect(stats.nivelSalud, 100.0);
      expect(stats.nivelAfecto, 100.0);
    });
  });

  // ---------------------------------------------------------------------------
  group('MascotaStatsModel.toMap', () {
    test('contiene exactamente las cinco claves snake_case esperadas', () {
      final mapa = MascotaStatsModel.fromMap(mapaBase).toMap();
      expect(mapa.keys, containsAll([
        'nivel_salud',
        'nivel_energia',
        'nivel_hambre',
        'nivel_limpieza',
        'nivel_afecto',
      ]));
      expect(mapa.length, 5);
    });

    test('los valores en toMap coinciden con los originales', () {
      final stats = MascotaStatsModel.fromMap(mapaBase);
      final mapa = stats.toMap();
      expect(mapa['nivel_salud'], 90.0);
      expect(mapa['nivel_energia'], 50.0);
      expect(mapa['nivel_hambre'], 80.0);
      expect(mapa['nivel_limpieza'], 70.0);
      expect(mapa['nivel_afecto'], 60.0);
    });

    test('round-trip fromMap → toMap → fromMap es idempotente', () {
      final original = MascotaStatsModel.fromMap(mapaBase);
      final restaurado = MascotaStatsModel.fromMap(original.toMap());
      expect(restaurado.nivelSalud, original.nivelSalud);
      expect(restaurado.nivelEnergia, original.nivelEnergia);
      expect(restaurado.nivelHambre, original.nivelHambre);
      expect(restaurado.nivelLimpieza, original.nivelLimpieza);
      expect(restaurado.nivelAfecto, original.nivelAfecto);
    });
  });

  // ---------------------------------------------------------------------------
  group('MascotaStatsModel.copyWith', () {
    test('sin argumentos produce un objeto con valores idénticos', () {
      final original = MascotaStatsModel.fromMap(mapaBase);
      final copia = original.copyWith();
      expect(copia.nivelSalud, original.nivelSalud);
      expect(copia.nivelEnergia, original.nivelEnergia);
      expect(copia.nivelHambre, original.nivelHambre);
      expect(copia.nivelLimpieza, original.nivelLimpieza);
      expect(copia.nivelAfecto, original.nivelAfecto);
    });

    test('modifica solo nivelHambre y deja los demás intactos', () {
      final original = MascotaStatsModel.fromMap(mapaBase);
      final modificado = original.copyWith(nivelHambre: 30.0);
      expect(modificado.nivelHambre, 30.0);
      expect(modificado.nivelSalud, original.nivelSalud);
      expect(modificado.nivelEnergia, original.nivelEnergia);
      expect(modificado.nivelLimpieza, original.nivelLimpieza);
      expect(modificado.nivelAfecto, original.nivelAfecto);
    });

    test('no muta el objeto original (inmutabilidad)', () {
      final original = MascotaStatsModel.fromMap(mapaBase);
      original.copyWith(nivelSalud: 10.0);
      expect(original.nivelSalud, 90.0);
    });

    test('permite actualizar múltiples campos a la vez', () {
      final original = MascotaStatsModel.fromMap(mapaBase);
      final modificado = original.copyWith(
        nivelSalud: 55.0,
        nivelEnergia: 25.0,
      );
      expect(modificado.nivelSalud, 55.0);
      expect(modificado.nivelEnergia, 25.0);
      expect(modificado.nivelHambre, original.nivelHambre);
    });

    test('acepta 0.0 como valor explícito (no usa fallback)', () {
      final original = MascotaStatsModel.fromMap(mapaBase);
      final modificado = original.copyWith(nivelAfecto: 0.0);
      expect(modificado.nivelAfecto, 0.0);
    });
  });

  // ---------------------------------------------------------------------------
  group('MascotaStatsModel.nivelesMap', () {
    test('contiene las cinco claves sin prefijo nivel_', () {
      final stats = MascotaStatsModel.fromMap(mapaBase);
      expect(stats.nivelesMap.keys,
          containsAll(['salud', 'energia', 'hambre', 'limpieza', 'afecto']));
    });

    test('los valores de nivelesMap coinciden con las propiedades del objeto', () {
      final stats = MascotaStatsModel.fromMap(mapaBase);
      expect(stats.nivelesMap['salud'], stats.nivelSalud);
      expect(stats.nivelesMap['energia'], stats.nivelEnergia);
      expect(stats.nivelesMap['hambre'], stats.nivelHambre);
      expect(stats.nivelesMap['limpieza'], stats.nivelLimpieza);
      expect(stats.nivelesMap['afecto'], stats.nivelAfecto);
    });
  });
}