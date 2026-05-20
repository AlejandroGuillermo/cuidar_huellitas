import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PetLearningRepository {
  PetLearningRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<PetLearningSnapshot> loadLearningSnapshot({
    required String mascotaId,
  }) async {
    final user = _auth.currentUser;

    if (user == null || mascotaId.isEmpty) {
      return PetLearningSnapshot.empty();
    }

    final base = _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('mascotas')
        .doc(mascotaId);

    final desde = DateTime.now().subtract(const Duration(days: 7));

    final patronSnapshot = await base
        .collection('patron_rutina')
        .where('activo', isEqualTo: true)
        .get();

    final progresoSnapshot = await base
        .collection('progreso')
        .where(
          'fecha_actualizacion',
          isGreaterThanOrEqualTo: Timestamp.fromDate(desde),
        )
        .limit(120)
        .get();

    final scoresFromProgress = _scoresFromProgress(
      progresoSnapshot.docs.map((doc) => _ProgressRow.fromMap(doc.data())).toList(),
    );

    final scoresFromPatterns = _scoresFromPatterns(
      patronSnapshot.docs.map((doc) => doc.data()).toList(),
    );

    final scores = <String, int>{
      ...scoresFromProgress,
      ...scoresFromPatterns,
    };

    final totalMuestrasPatrones = patronSnapshot.docs.fold<int>(0, (
      total,
      doc,
    ) {
      final data = doc.data();
      return total + ((data['total_muestras'] as num?)?.toInt() ?? 0);
    });

    final totalMuestras = totalMuestrasPatrones + progresoSnapshot.docs.length;

    return PetLearningSnapshot(
      rutina: scores['rutina'] ?? 0,
      alimentacion: scores['alimentacion'] ?? 0,
      higiene: scores['higiene'] ?? 0,
      energia: scores['energia'] ?? 0,
      afecto: scores['afecto'] ?? 0,
      totalMuestras: totalMuestras,
      message: _buildMessage(scores, totalMuestras),
    );
  }

  Map<String, int> _scoresFromPatterns(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return {};

    final buckets = <String, List<int>>{
      'rutina': [],
      'alimentacion': [],
      'higiene': [],
      'energia': [],
      'afecto': [],
    };

    for (final row in rows) {
      final accion = _normalize(row['accion']?.toString() ?? '');
      final confianza = _toPercent(row['confianza']);

      buckets['rutina']!.add(confianza);

      if (_matches(accion, const ['alimentar', 'comer', 'plato'])) {
        buckets['alimentacion']!.add(confianza);
      }

      if (_matches(accion, const ['banar', 'bañar', 'limpiar', 'higiene'])) {
        buckets['higiene']!.add(confianza);
      }

      if (_matches(accion, const ['dormir', 'descansar', 'jugar'])) {
        buckets['energia']!.add(confianza);
      }

      if (_matches(accion, const ['jugar', 'acariciar', 'pasear', 'afecto'])) {
        buckets['afecto']!.add(confianza);
      }
    }

    final scores = <String, int>{};

    for (final entry in buckets.entries) {
      if (entry.value.isNotEmpty) {
        scores[entry.key] = _average(entry.value);
      }
    }

    return scores;
  }

  Map<String, int> _scoresFromProgress(List<_ProgressRow> rows) {
    if (rows.isEmpty) {
      return {
        'rutina': 0,
        'alimentacion': 0,
        'higiene': 0,
        'energia': 0,
        'afecto': 0,
      };
    }

    return {
      'rutina': _routineScore(rows),
      'alimentacion': _impactScore(
        rows,
        actions: const ['alimentar', 'comer', 'plato'],
        stats: const ['hambre'],
      ),
      'higiene': _impactScore(
        rows,
        actions: const ['banar', 'bañar', 'limpiar', 'higiene'],
        stats: const ['limpieza'],
      ),
      'energia': _impactScore(
        rows,
        actions: const ['dormir', 'descansar', 'jugar'],
        stats: const ['energia', 'energía'],
      ),
      'afecto': _impactScore(
        rows,
        actions: const ['jugar', 'acariciar', 'pasear', 'afecto'],
        stats: const ['afecto'],
      ),
    };
  }

  int _routineScore(List<_ProgressRow> rows) {
    final byAction = <String, List<double>>{};

    for (final row in rows) {
      byAction.putIfAbsent(row.action, () => []).add(row.hour);
    }

    if (byAction.isEmpty) return 0;

    final actionScores = <double>[];

    for (final hours in byAction.values) {
      if (hours.length == 1) {
        actionScores.add(35);
        continue;
      }

      final mean = hours.reduce((a, b) => a + b) / hours.length;

      final avgDeviation = hours
              .map((hour) => (hour - mean).abs())
              .reduce((a, b) => a + b) /
          hours.length;

      final consistency = 100 - math.min(70, avgDeviation * 18);
      final sampleBonus = math.min(20, hours.length * 4);

      actionScores.add((consistency + sampleBonus).clamp(0, 100).toDouble());
    }

    final average =
        actionScores.reduce((a, b) => a + b) / actionScores.length;

    return _clampPercent(average);
  }

  int _impactScore(
    List<_ProgressRow> rows, {
    required List<String> actions,
    required List<String> stats,
  }) {
    final filtered = rows.where((row) {
      return actions.any((action) => row.action.contains(_normalize(action)));
    }).toList();

    if (filtered.isEmpty) return 0;

    final frequencyScore = math.min(60.0, filtered.length * 16.0);

    var totalDelta = 0.0;
    var deltaCount = 0;

    for (final row in filtered) {
      for (final stat in stats) {
        final key = _normalize(stat);
        final before = row.before[key] ?? 0;
        final after = row.after[key] ?? 0;
        final delta = after - before;

        if (delta > 0) {
          totalDelta += delta;
          deltaCount++;
        }
      }
    }

    final averageDelta = deltaCount == 0 ? 0.0 : totalDelta / deltaCount;
    final impactScore = math.min(40.0, averageDelta * 2.0);

    return _clampPercent(frequencyScore + impactScore);
  }

  String _buildMessage(Map<String, int> scores, int totalMuestras) {
    if (totalMuestras == 0) {
      return 'Aún necesito más acciones para aprender tus rutinas de cuidado.';
    }

    final entries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final strongest = entries.isEmpty ? 'rutina' : entries.first.key;

    switch (strongest) {
      case 'alimentacion':
        return 'Estoy aprendiendo tus horarios de comida y reconozco mejor cuándo me alimentas.';
      case 'higiene':
        return 'Estoy reconociendo tus hábitos de higiene y cuidado.';
      case 'energia':
        return 'Estoy aprendiendo cuándo sueles jugar conmigo o ayudarme a descansar.';
      case 'afecto':
        return 'Estoy aprendiendo tus momentos de cariño y compañía.';
      default:
        return 'Me siento acompañado cuando mantienes mi rutina diaria.';
    }
  }

  int _toPercent(dynamic value) {
    var number = (value as num?)?.toDouble() ?? 0.0;

    if (number <= 1) {
      number *= 100;
    }

    return _clampPercent(number);
  }

  int _average(List<int> values) {
    if (values.isEmpty) return 0;

    final total = values.reduce((a, b) => a + b);
    return _clampPercent(total / values.length);
  }

  int _clampPercent(num value) {
    return value.round().clamp(0, 100).toInt();
  }

  bool _matches(String value, List<String> options) {
    return options.any((option) => value.contains(_normalize(option)));
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }
}

class PetLearningSnapshot {
  final int rutina;
  final int alimentacion;
  final int higiene;
  final int energia;
  final int afecto;
  final int totalMuestras;
  final String message;

  const PetLearningSnapshot({
    required this.rutina,
    required this.alimentacion,
    required this.higiene,
    required this.energia,
    required this.afecto,
    required this.totalMuestras,
    required this.message,
  });

  factory PetLearningSnapshot.empty() {
    return const PetLearningSnapshot(
      rutina: 0,
      alimentacion: 0,
      higiene: 0,
      energia: 0,
      afecto: 0,
      totalMuestras: 0,
      message: 'Aún necesito más acciones para aprender tus rutinas de cuidado.',
    );
  }

  bool get hasData => totalMuestras > 0;

  List<double> get radarValues {
    return [
      rutina / 100,
      afecto / 100,
      alimentacion / 100,
      energia / 100,
      higiene / 100,
    ];
  }
}

class _ProgressRow {
  final String action;
  final double hour;
  final Map<String, int> before;
  final Map<String, int> after;

  const _ProgressRow({
    required this.action,
    required this.hour,
    required this.before,
    required this.after,
  });

  factory _ProgressRow.fromMap(Map<String, dynamic> data) {
    return _ProgressRow(
      action: _normalizeAction(data['accion_realizada']?.toString() ?? ''),
      hour: (data['hora_dia'] as num?)?.toDouble() ?? 0.0,
      before: _parseStats(data['estado_antes']),
      after: _parseStats(data['estado_despues']),
    );
  }

  static String _normalizeAction(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  static Map<String, int> _parseStats(dynamic value) {
    if (value is! Map) return {};

    return value.map((key, rawValue) {
      final normalizedKey = key
          .toString()
          .toLowerCase()
          .replaceAll('á', 'a')
          .replaceAll('é', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ú', 'u')
          .replaceAll('ñ', 'n');

      return MapEntry(
        normalizedKey,
        (rawValue as num?)?.toInt() ?? 0,
      );
    });
  }
}