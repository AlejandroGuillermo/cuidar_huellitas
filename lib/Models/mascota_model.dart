import 'package:cloud_firestore/cloud_firestore.dart';

class MascotaModel {
  // ── Atributos ──────────────────────────────────────────
  final String idMascota;
  final String nombreMascota;       // Nombre elegido por el niño
  final String tipoMascota;         // "perro" o "gato"

  // Los 5 niveles — corazón de la mascota (0 a 100)
  final int nivelSalud;             // Baja si no va al veterinario
  final int nivelEnergia;           // Baja si no descansa
  final int nivelHambre;            // Baja rápido. Sube al alimentar
  final int nivelLimpieza;          // Sube al bañar o limpiar arenero
  final int nivelAfecto;            // Sube al jugar o pasear

  final String estado;              // Lo calcula la Lógica Difusa
                                    // Valores: "feliz","triste","hambriento","enfermo"
  final String rasgo;               // Personalidad fija: "juguetón","dormilón","curioso"
  final bool activa;                // true = mascota actual del niño
  final DateTime ultimaInteraccion; // El Motor de IA la lee constantemente

  // Campos del Motor de IA
  final bool deterioroAcelerado;    // true = el ML detectó anomalía, deterioro x5
  final bool anomaliaDetectada;     // true = la UI debe mostrar alerta visual

  // ── Constructor ────────────────────────────────────────
  const MascotaModel({
    required this.idMascota,
    required this.nombreMascota,
    required this.tipoMascota,
    this.nivelSalud = 100,
    this.nivelEnergia = 100,
    this.nivelHambre = 100,
    this.nivelLimpieza = 100,
    this.nivelAfecto = 100,
    this.estado = 'feliz',
    this.rasgo = 'juguetón',
    this.activa = true,
    required this.ultimaInteraccion,
    this.deterioroAcelerado = false,
    this.anomaliaDetectada = false,
  });

  // ── fromFirestore ──────────────────────────────────────
  factory MascotaModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return MascotaModel(
      idMascota: snapshot.id,
      nombreMascota: data['nombre_mascota'] ?? '',
      tipoMascota: data['tipo_mascota'] ?? 'perro',
      nivelSalud: data['nivel_salud'] ?? 100,
      nivelEnergia: data['nivel_energia'] ?? 100,
      nivelHambre: data['nivel_hambre'] ?? 100,
      nivelLimpieza: data['nivel_limpieza'] ?? 100,
      nivelAfecto: data['nivel_afecto'] ?? 100,
      estado: data['estado'] ?? 'feliz',
      rasgo: data['rasgo'] ?? 'juguetón',
      activa: data['activa'] ?? true,
      // Firestore guarda Timestamp, lo convertimos a DateTime
      ultimaInteraccion: (data['ultima_interaccion'] as Timestamp).toDate(),
      deterioroAcelerado: data['deterioro_acelerado'] ?? false,
      anomaliaDetectada: data['anomalia_detectada'] ?? false,
    );
  }
  // ── toFirestore ────────────────────────────────────────
  // Convierte el modelo a un mapa para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nombre_mascota': nombreMascota,
      'tipo_mascota': tipoMascota,
      'nivel_salud': nivelSalud,
      'nivel_energia': nivelEnergia,
      'nivel_hambre': nivelHambre,
      'nivel_limpieza': nivelLimpieza,
      'nivel_afecto': nivelAfecto,
      'estado': estado,
      'rasgo': rasgo,
      'activa': activa,
      // DateTime lo convertimos a Timestamp para Firestore
      'ultima_interaccion': Timestamp.fromDate(ultimaInteraccion),
      'deterioro_acelerado': deterioroAcelerado,
      'anomalia_detectada': anomaliaDetectada,
    };
  }

  // ── copyWith ───────────────────────────────────────────
  // Muy usado por el PetCubit para actualizar niveles
  // Ejemplo: mascota.copyWith(nivelHambre: 80, estado: 'feliz')
  MascotaModel copyWith({
    String? nombreMascota,
    String? tipoMascota,
    int? nivelSalud,
    int? nivelEnergia,
    int? nivelHambre,
    int? nivelLimpieza,
    int? nivelAfecto,
    String? estado,
    String? rasgo,
    bool? activa,
    DateTime? ultimaInteraccion,
    bool? deterioroAcelerado,
    bool? anomaliaDetectada,
  }) {
    return MascotaModel(
      idMascota: idMascota,
      nombreMascota: nombreMascota ?? this.nombreMascota,
      tipoMascota: tipoMascota ?? this.tipoMascota,
      nivelSalud: nivelSalud ?? this.nivelSalud,
      nivelEnergia: nivelEnergia ?? this.nivelEnergia,
      nivelHambre: nivelHambre ?? this.nivelHambre,
      nivelLimpieza: nivelLimpieza ?? this.nivelLimpieza,
      nivelAfecto: nivelAfecto ?? this.nivelAfecto,
      estado: estado ?? this.estado,
      rasgo: rasgo ?? this.rasgo,
      activa: activa ?? this.activa,
      ultimaInteraccion: ultimaInteraccion ?? this.ultimaInteraccion,
      deterioroAcelerado: deterioroAcelerado ?? this.deterioroAcelerado,
      anomaliaDetectada: anomaliaDetectada ?? this.anomaliaDetectada,
    );
  }

  // ── Mapa de niveles ────────────────────────────────────
  // Útil para guardar estado_antes y estado_despues en progreso
  Map<String, int> get nivelesMap => {
    'salud': nivelSalud,
    'energia': nivelEnergia,
    'hambre': nivelHambre,
    'limpieza': nivelLimpieza,
    'afecto': nivelAfecto,
  };
}
