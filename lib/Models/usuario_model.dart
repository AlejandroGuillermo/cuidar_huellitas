import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String idUsuario;
  final String nombre;
  final String correo;
  final String tipoUsuario;
  final int monedas;
  final int totalScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UsuarioModel({
    required this.idUsuario,
    required this.nombre,
    required this.correo,
    required this.tipoUsuario,
    this.monedas = 245,
    this.totalScore = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory UsuarioModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    DateTime? tsToDate(dynamic value) =>
        value is Timestamp ? value.toDate() : null;

    return UsuarioModel(
      idUsuario: snapshot.id,
      nombre: data['nombre'] ?? '',
      correo: data['correo'] ?? '',
      tipoUsuario: normalizarTipoUsuario(data['tipo_usuario'] as String?),
      monedas:
          (data['monedas'] as num?)?.toInt() ??
          (data['total_score'] as num?)?.toInt() ??
          (data['totalScore'] as num?)?.toInt() ??
          245,
      totalScore:
          (data['total_score'] as num?)?.toInt() ??
          (data['totalScore'] as num?)?.toInt() ??
          0,
      createdAt: tsToDate(data['created_at']),
      updatedAt: tsToDate(data['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'correo': correo,
      'tipo_usuario': normalizarTipoUsuario(tipoUsuario),
      'monedas': monedas,
      'total_score': totalScore,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  UsuarioModel copyWith({
    String? nombre,
    String? correo,
    String? tipoUsuario,
    int? monedas,
    int? totalScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UsuarioModel(
      idUsuario: idUsuario,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      monedas: monedas ?? this.monedas,
      totalScore: totalScore ?? this.totalScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String normalizarTipoUsuario(String? value) {
    final raw = (value ?? '').trim().toLowerCase();
    if (raw == 'nino' || raw == 'niño' || raw == 'niÃ±o') return 'nino';
    if (raw == 'tutor') return 'tutor';
    return 'nino';
  }
}
