import 'package:flutter_test/flutter_test.dart';
import 'package:cuidar_huellitas/models/mision_activa_model.dart';

// MisionModel solo expone fromFirestore/toFirestore — requiere DocumentSnapshot
// real de Firestore, por lo que no se prueba aquí (quedaria fuera del alcance
// de pruebas unitarias puras). Ver: lib/models/mision_model.dart
//
// MisionActivaModel sí es testeable: su constructor es puro y tiene copyWith.

MisionActivaModel _base() => MisionActivaModel(
      idMision: 'mision_001',
      estado: 'pendiente',
      fechaAsignada: DateTime(2024, 6, 1, 9, 0),
    );

void main() {
  group('MisionActivaModel — constructor', () {
    test('crea instancia con valores requeridos correctamente', () {
      final m = _base();
      expect(m.idMision, 'mision_001');
      expect(m.estado, 'pendiente');
      expect(m.fechaAsignada, DateTime(2024, 6, 1, 9, 0));
    });

    test('fechaCompletada es null por defecto', () {
      expect(_base().fechaCompletada, isNull);
    });

    test('streak es 0 por defecto', () {
      expect(_base().streak, 0);
    });

    test('acepta fechaCompletada y streak explícitos', () {
      final m = MisionActivaModel(
        idMision: 'mision_002',
        estado: 'completada',
        fechaAsignada: DateTime(2024, 6, 1),
        fechaCompletada: DateTime(2024, 6, 1, 10, 0),
        streak: 5,
      );
      expect(m.fechaCompletada, isNotNull);
      expect(m.streak, 5);
    });
  });

  group('MisionActivaModel.copyWith', () {
    test('sin argumentos produce objeto con valores idénticos', () {
      final original = _base();
      final copia = original.copyWith();
      expect(copia.idMision, original.idMision);
      expect(copia.estado, original.estado);
      expect(copia.fechaAsignada, original.fechaAsignada);
      expect(copia.streak, original.streak);
    });

    test('idMision no cambia nunca (no está en copyWith)', () {
      final original = _base();
      final modificado = original.copyWith(estado: 'completada');
      expect(modificado.idMision, original.idMision);
    });

    test('cambiar estado a "completada" no afecta los demás campos', () {
      final original = _base();
      final modificado = original.copyWith(estado: 'completada');
      expect(modificado.estado, 'completada');
      expect(modificado.fechaAsignada, original.fechaAsignada);
      expect(modificado.streak, original.streak);
    });

    test('cambiar estado a "fallida" funciona correctamente', () {
      final modificado = _base().copyWith(estado: 'fallida');
      expect(modificado.estado, 'fallida');
    });

    test('asignar fechaCompletada no muta el original', () {
      final original = _base();
      final fecha = DateTime(2024, 6, 1, 15, 30);
      original.copyWith(fechaCompletada: fecha);
      expect(original.fechaCompletada, isNull); // original intacto
    });

    test('incrementar streak preserva el resto de campos', () {
      final original = MisionActivaModel(
        idMision: 'mision_003',
        estado: 'completada',
        fechaAsignada: DateTime(2024, 6, 1),
        streak: 3,
      );
      final modificado = original.copyWith(streak: 4);
      expect(modificado.streak, 4);
      expect(modificado.estado, original.estado);
      expect(modificado.idMision, original.idMision);
    });

    test('completar misión: cambiar estado + asignar fecha en un solo copyWith', () {
      final pendiente = _base();
      final fecha = DateTime(2024, 6, 1, 12, 0);
      final completada = pendiente.copyWith(
        estado: 'completada',
        fechaCompletada: fecha,
        streak: 1,
      );
      expect(completada.estado, 'completada');
      expect(completada.fechaCompletada, fecha);
      expect(completada.streak, 1);
      // Original intacto
      expect(pendiente.estado, 'pendiente');
      expect(pendiente.fechaCompletada, isNull);
    });
  });
}