import 'package:cloud_firestore/cloud_firestore.dart';

class InventarioComidaModel {
  final Map<String, double> cantidades;
  final Map<String, bool> desbloqueados;

  const InventarioComidaModel({
    required this.cantidades,
    required this.desbloqueados,
  });

  factory InventarioComidaModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    return InventarioComidaModel.fromMap(data);
  }

  factory InventarioComidaModel.fromMap(Map<String, dynamic> data) {
    return InventarioComidaModel(
      cantidades: _doubleMap(data['cantidades']),
      desbloqueados: _boolMap(data['desbloqueados']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cantidades': cantidades,
      'desbloqueados': desbloqueados,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  InventarioComidaModel copyWith({
    Map<String, double>? cantidades,
    Map<String, bool>? desbloqueados,
  }) {
    return InventarioComidaModel(
      cantidades: cantidades ?? this.cantidades,
      desbloqueados: desbloqueados ?? this.desbloqueados,
    );
  }

  static Map<String, double> _doubleMap(dynamic value) {
    final raw = value is Map<String, dynamic> ? value : <String, dynamic>{};
    return raw.map((key, value) {
      final number = value is num ? value.toDouble() : 0.0;
      return MapEntry(key, number);
    });
  }

  static Map<String, bool> _boolMap(dynamic value) {
    final raw = value is Map<String, dynamic> ? value : <String, dynamic>{};
    return raw.map((key, value) {
      return MapEntry(key, value == true || (value is num && value > 0));
    });
  }
}
