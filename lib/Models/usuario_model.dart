import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  // ── Atributos ──────────────────────────────────────────
  final String idUsuario;       // Doc ID generado por Firebase
  final String nombre;          // Apodo del niño, ej: "Carlitos"
  final String correo;          // Correo del padre/tutor
  final String tipoUsuario;     // "niño" o "tutor"
  final int totalScore;         // Puntos acumulados por misiones

  // ── Constructor ────────────────────────────────────────
  const UsuarioModel({
    required this.idUsuario,
    required this.nombre,
    required this.correo,
    required this.tipoUsuario,
    this.totalScore = 0,        // Empieza en 0 al registrarse
  });

  // ── fromFirestore ──────────────────────────────────────
  // Se usa cuando LEES un documento de Firestore.
  // El snapshot es el documento crudo de Firebase.
  factory UsuarioModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return UsuarioModel(
      idUsuario: snapshot.id,                        // El Doc ID viene del snapshot
      nombre: data['nombre'] ?? '',
      correo: data['correo'] ?? '',
      tipoUsuario: data['tipo_usuario'] ?? 'niño',
      totalScore: data['totalScore'] ?? 0,
    );
  }

  // ── toFirestore ────────────────────────────────────────
  // Se usa cuando GUARDAS o ACTUALIZAS en Firestore.
  // Devuelve un Map que Firebase entiende.
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'correo': correo,
      'tipo_usuario': tipoUsuario,
      'totalScore': totalScore,
      // Nota: idUsuario NO se guarda aquí, es el Doc ID
    };
  }

  // ── copyWith ───────────────────────────────────────────
  // Útil para actualizar solo un campo sin tocar los demás.
  // Ejemplo: usuario.copyWith(totalScore: usuario.totalScore + 50)
  UsuarioModel copyWith({
    String? nombre,
    String? correo,
    String? tipoUsuario,
    int? totalScore,
  }) {
    return UsuarioModel(
      idUsuario: idUsuario,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      totalScore: totalScore ?? this.totalScore,
    );
  }
}
