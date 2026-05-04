import 'package:cloud_firestore/cloud_firestore.dart';

class InventarioCosmeticosModel {
  final Map<String, bool> poseidos;
  final Map<String, String?> equipadoEn;

  const InventarioCosmeticosModel({
    required this.poseidos,
    required this.equipadoEn,
  });

  factory InventarioCosmeticosModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    return InventarioCosmeticosModel.fromMap(data);
  }

  factory InventarioCosmeticosModel.fromMap(Map<String, dynamic> data) {
    return InventarioCosmeticosModel(
      poseidos: _boolMap(data['poseidos']),
      equipadoEn: _nullableStringMap(data['equipado_en']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'poseidos': poseidos,
      'equipado_en': equipadoEn,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  InventarioCosmeticosModel copyWith({
    Map<String, bool>? poseidos,
    Map<String, String?>? equipadoEn,
  }) {
    return InventarioCosmeticosModel(
      poseidos: poseidos ?? this.poseidos,
      equipadoEn: equipadoEn ?? this.equipadoEn,
    );
  }

  static Map<String, bool> _boolMap(dynamic value) {
    final raw = value is Map<String, dynamic> ? value : <String, dynamic>{};
    return raw.map((key, value) {
      return MapEntry(key, value == true || (value is num && value > 0));
    });
  }

  static Map<String, String?> _nullableStringMap(dynamic value) {
    final raw = value is Map<String, dynamic> ? value : <String, dynamic>{};
    return raw.map((key, value) {
      return MapEntry(key, value is String && value.isNotEmpty ? value : null);
    });
  }
}
