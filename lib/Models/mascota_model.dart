import 'package:cloud_firestore/cloud_firestore.dart';

class MascotaModel {
  // ── Atributos base ─────────────────────────────────────
  final String idMascota;
  final String nombreMascota;
  final String tipoMascota;

  // Los 5 niveles (0–100)
  final int nivelSalud;
  final int nivelEnergia;
  final int nivelHambre;
  final int nivelLimpieza;
  final int nivelAfecto;
  final double nivelPlato;

  final String estado;
  final String rasgo;
  final bool   activa;
  final DateTime ultimaInteraccion;

  // Motor de IA
  final bool deterioroAcelerado;
  final bool anomaliaDetectada;

  // ── Sistema de descanso ────────────────────────────────
  // 'despierto' | 'acostado' | 'dormido' | 'siesta'
  final String   estadoDescanso;
  // Momento en que se acostó — para calcular recuperación offline
  final DateTime? inicioDescanso;
  // 'siesta' | 'noche' | ''
  final String   tipoDescanso;
  // Energía que tenía al acostarse — para calcular ganancia y buff
  final int      energiaAlAcostar;
  // Buff: consumo de energía reducido a la mitad durante 1 día
  final bool     buffEnergia;
  final DateTime? buffExpira;
  // Si la cortina está cerrada o abierta
  final bool     cortinasAbiertas;
  // Taps necesarios para despertar (se genera random al acostarse)
  final int      tapsParaDespetarBase;

  // ── Constructor ────────────────────────────────────────
  const MascotaModel({
    required this.idMascota,
    required this.nombreMascota,
    required this.tipoMascota,
    this.nivelSalud           = 100,
    this.nivelEnergia         = 100,
    this.nivelHambre          = 100,
    this.nivelLimpieza        = 100,
    this.nivelAfecto          = 100,
    this.estado               = 'feliz',
    this.rasgo                = 'juguetón',
    this.activa               = true,
    required this.ultimaInteraccion,
    this.deterioroAcelerado   = false,
    this.anomaliaDetectada    = false,
    this.nivelPlato           = 0.0,
    // Descanso
    this.estadoDescanso       = 'despierto',
    this.inicioDescanso,
    this.tipoDescanso         = '',
    this.energiaAlAcostar     = 0,
    this.buffEnergia          = false,
    this.buffExpira,
    this.cortinasAbiertas     = true,
    this.tapsParaDespetarBase = 4,
  });

  // ── fromFirestore ──────────────────────────────────────
  factory MascotaModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    // Helper para leer Timestamp nullable
    DateTime? _tsToDate(dynamic v) =>
        v == null ? null : (v as Timestamp).toDate();

    return MascotaModel(
      idMascota:           snapshot.id,
      nombreMascota:       data['nombre_mascota']        ?? '',
      tipoMascota:         data['tipo_mascota']          ?? 'perro',
      nivelSalud:          data['nivel_salud']           ?? 100,
      nivelEnergia:        data['nivel_energia']         ?? 100,
      nivelHambre:         data['nivel_hambre']          ?? 100,
      nivelLimpieza:       data['nivel_limpieza']        ?? 100,
      nivelAfecto:         data['nivel_afecto']          ?? 100,
      estado:              data['estado']                ?? 'feliz',
      rasgo:               data['rasgo']                 ?? 'juguetón',
      activa:              data['activa']                ?? true,
      ultimaInteraccion:   _tsToDate(data['ultima_interaccion']) ?? DateTime.now(),
      deterioroAcelerado:  data['deterioro_acelerado']   ?? false,
      anomaliaDetectada:   data['anomalia_detectada']    ?? false,
      nivelPlato:          (data['nivel_plato']          ?? 0.0).toDouble(),
      // Descanso
      estadoDescanso:      data['estado_descanso']       ?? 'despierto',
      inicioDescanso:      _tsToDate(data['inicio_descanso']),
      tipoDescanso:        data['tipo_descanso']         ?? '',
      energiaAlAcostar:    data['energia_al_acostar']    ?? 0,
      buffEnergia:         data['buff_energia']          ?? false,
      buffExpira:          _tsToDate(data['buff_expira']),
      cortinasAbiertas:    data['cortinas_abiertas']     ?? true,
      tapsParaDespetarBase:data['taps_para_despertar']   ?? 4,
    );
  }

  // ── toFirestore ────────────────────────────────────────
  Map<String, dynamic> toFirestore() {
    return {
      'nombre_mascota':      nombreMascota,
      'tipo_mascota':        tipoMascota,
      'nivel_salud':         nivelSalud,
      'nivel_energia':       nivelEnergia,
      'nivel_hambre':        nivelHambre,
      'nivel_limpieza':      nivelLimpieza,
      'nivel_afecto':        nivelAfecto,
      'estado':              estado,
      'rasgo':               rasgo,
      'activa':              activa,
      'ultima_interaccion':  Timestamp.fromDate(ultimaInteraccion),
      'deterioro_acelerado': deterioroAcelerado,
      'anomalia_detectada':  anomaliaDetectada,
      'nivel_plato':         nivelPlato,
      // Descanso
      'estado_descanso':     estadoDescanso,
      'inicio_descanso':     inicioDescanso != null
          ? Timestamp.fromDate(inicioDescanso!) : null,
      'tipo_descanso':       tipoDescanso,
      'energia_al_acostar':  energiaAlAcostar,
      'buff_energia':        buffEnergia,
      'buff_expira':         buffExpira != null
          ? Timestamp.fromDate(buffExpira!) : null,
      'cortinas_abiertas':   cortinasAbiertas,
      'taps_para_despertar': tapsParaDespetarBase,
    };
  }

  // ── copyWith ───────────────────────────────────────────
  MascotaModel copyWith({
    String?   nombreMascota,
    String?   tipoMascota,
    int?      nivelSalud,
    int?      nivelEnergia,
    int?      nivelHambre,
    int?      nivelLimpieza,
    int?      nivelAfecto,
    String?   estado,
    String?   rasgo,
    bool?     activa,
    DateTime? ultimaInteraccion,
    bool?     deterioroAcelerado,
    bool?     anomaliaDetectada,
    double?   nivelPlato,
    // Descanso
    String?   estadoDescanso,
    DateTime? inicioDescanso,
    bool      clearInicioDescanso = false,
    String?   tipoDescanso,
    int?      energiaAlAcostar,
    bool?     buffEnergia,
    DateTime? buffExpira,
    bool      clearBuffExpira = false,
    bool?     cortinasAbiertas,
    int?      tapsParaDespetarBase,
  }) {
    return MascotaModel(
      idMascota:           idMascota,
      nombreMascota:       nombreMascota       ?? this.nombreMascota,
      tipoMascota:         tipoMascota         ?? this.tipoMascota,
      nivelSalud:          nivelSalud          ?? this.nivelSalud,
      nivelEnergia:        nivelEnergia        ?? this.nivelEnergia,
      nivelHambre:         nivelHambre         ?? this.nivelHambre,
      nivelLimpieza:       nivelLimpieza       ?? this.nivelLimpieza,
      nivelAfecto:         nivelAfecto         ?? this.nivelAfecto,
      estado:              estado              ?? this.estado,
      rasgo:               rasgo               ?? this.rasgo,
      activa:              activa              ?? this.activa,
      ultimaInteraccion:   ultimaInteraccion   ?? this.ultimaInteraccion,
      deterioroAcelerado:  deterioroAcelerado  ?? this.deterioroAcelerado,
      anomaliaDetectada:   anomaliaDetectada   ?? this.anomaliaDetectada,
      nivelPlato:          nivelPlato          ?? this.nivelPlato,
      // Descanso — clearInicioDescanso permite poner null explícitamente
      estadoDescanso:      estadoDescanso      ?? this.estadoDescanso,
      inicioDescanso:      clearInicioDescanso ? null : (inicioDescanso ?? this.inicioDescanso),
      tipoDescanso:        tipoDescanso        ?? this.tipoDescanso,
      energiaAlAcostar:    energiaAlAcostar    ?? this.energiaAlAcostar,
      buffEnergia:         buffEnergia         ?? this.buffEnergia,
      buffExpira:          clearBuffExpira ? null : (buffExpira ?? this.buffExpira),
      cortinasAbiertas:    cortinasAbiertas    ?? this.cortinasAbiertas,
      tapsParaDespetarBase:tapsParaDespetarBase ?? this.tapsParaDespetarBase,
    );
  }

  // ── Helpers ────────────────────────────────────────────
  bool get estaDescansando =>
      estadoDescanso == 'acostado' ||
      estadoDescanso == 'dormido'  ||
      estadoDescanso == 'siesta';

  bool get buffActivo =>
      buffEnergia && (buffExpira?.isAfter(DateTime.now()) ?? false);

  Map<String, int> get nivelesMap => {
    'salud':    nivelSalud,
    'energia':  nivelEnergia,
    'hambre':   nivelHambre,
    'limpieza': nivelLimpieza,
    'afecto':   nivelAfecto,
  };
}