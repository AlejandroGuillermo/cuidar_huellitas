import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/personalidad_tipo.dart';
import 'mascota_ai_model.dart';
import 'mascota_runtime_model.dart';
import 'mascota_stats_model.dart';

class MascotaModel {
  final String idMascota;
  final String nombreMascota;
  final String tipoMascota;
  final String rasgo;
  final MascotaStatsModel stats;
  final MascotaRuntimeModel runtime;
  final MascotaAiModel ai;

  MascotaModel({
    required this.idMascota,
    required this.nombreMascota,
    required this.tipoMascota,
    String rasgo = 'Juguetón',
    int nivelSalud = 100,
    int nivelEnergia = 100,
    int nivelHambre = 100,
    int nivelLimpieza = 100,
    int nivelAfecto = 100,
    String estado = 'feliz',
    bool activa = true,
    DateTime? ultimaInteraccion,
    DateTime? ultimaComida,
    DateTime? ultimoJuego,
    DateTime? ultimoBano,
    DateTime? ultimaCuracion,
    DateTime? ultimoPaseo,
    bool deterioroAcelerado = false,
    bool anomaliaDetectada = false,
    int ticksEnergiaBaja = 0,
    double nivelPlato = 0.0,
    String platoAlimentoId = '',
    String platoEmoji = '',
    DateTime? platoActualizado,
    bool platoComiendo = false,
    String itemCabezaId = '',
    String estadoDescanso = 'despierto',
    DateTime? inicioDescanso,
    String tipoDescanso = '',
    int energiaAlAcostar = 0,
    bool buffEnergia = false,
    DateTime? buffExpira,
    bool cortinasAbiertas = true,
    int tapsParaDespetarBase = 4,
    String? inicioDescansoTipo,
    DateTime? residuosHambreAltaDesde,
    int? residuosObjetivoMinutos,
    DateTime? residuosUltimaGeneracion,
    String? ultimoAlimentoConsumidoId,
    int residuosMismaComidaStreak = 0,
    double? deterioroRate,
    bool anomaliaActiva = false,
    String? estadoEmocional,
    MascotaStatsModel? stats,
    MascotaRuntimeModel? runtime,
    MascotaAiModel? ai,
  }) : rasgo = PersonalidadTipo.fromString(rasgo).toFirestoreString(),
       stats =
           stats ??
           MascotaStatsModel(
             nivelSalud: nivelSalud.toDouble(),
             nivelEnergia: nivelEnergia.toDouble(),
             nivelHambre: nivelHambre.toDouble(),
             nivelLimpieza: nivelLimpieza.toDouble(),
             nivelAfecto: nivelAfecto.toDouble(),
           ),
       runtime =
           runtime ??
           MascotaRuntimeModel(
             estadoDescanso: estadoDescanso,
             inicioDescanso: inicioDescanso,
             tipoDescanso: tipoDescanso,
             nivelPlato: nivelPlato,
             platoAlimentoId: platoAlimentoId,
             platoEmoji: platoEmoji,
             platoActualizado: platoActualizado,
             platoComiendo: platoComiendo,
             itemCabezaId: itemCabezaId,
             estado: estado,
             activa: activa,
             ultimaInteraccion: ultimaInteraccion ?? DateTime.now(),
             ultimaComida: ultimaComida,
             ultimoJuego: ultimoJuego,
             ultimoBano: ultimoBano,
             ultimaCuracion: ultimaCuracion,
             ultimoPaseo: ultimoPaseo,
             deterioroAcelerado: deterioroAcelerado,
             anomaliaDetectada: anomaliaDetectada,
             ticksEnergiaBaja: ticksEnergiaBaja,
             energiaAlAcostar: energiaAlAcostar.toDouble(),
             buffEnergia: buffEnergia,
             buffExpira: buffExpira,
             cortinasAbiertas: cortinasAbiertas,
             tapsParaDespetarBase: tapsParaDespetarBase,
             inicioDescansoTipo: inicioDescansoTipo,
             residuosHambreAltaDesde: residuosHambreAltaDesde,
             residuosObjetivoMinutos: residuosObjetivoMinutos,
             residuosUltimaGeneracion: residuosUltimaGeneracion,
             ultimoAlimentoConsumidoId: ultimoAlimentoConsumidoId,
             residuosMismaComidaStreak: residuosMismaComidaStreak,
           ),
       ai =
           ai ??
           MascotaAiModel(
             deterioroRate: deterioroRate,
             anomaliaActiva: anomaliaActiva,
             estadoEmocional: estadoEmocional,
           );

  factory MascotaModel.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return MascotaModel(
      idMascota: snapshot.id,
      nombreMascota: data['nombre_mascota'] ?? '',
      tipoMascota: data['tipo_mascota'] ?? 'perro',
      rasgo: data['rasgo'] ?? 'Jugueton',
      stats: MascotaStatsModel.fromMap(data),
      runtime: MascotaRuntimeModel.fromMap(data),
      ai: MascotaAiModel.fromMap(data),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre_mascota': nombreMascota,
      'tipo_mascota': tipoMascota,
      'rasgo': personalidad.toFirestoreString(),
      ...stats.toMap(),
      ...runtime.toMap(),
      ...ai.toMap(),
      'nivel_salud': nivelSalud,
      'nivel_energia': nivelEnergia,
      'nivel_hambre': nivelHambre,
      'nivel_limpieza': nivelLimpieza,
      'nivel_afecto': nivelAfecto,
      'energia_al_acostar': energiaAlAcostar,
    };
  }

  MascotaModel copyWith({
    String? nombreMascota,
    String? tipoMascota,
    String? rasgo,
    int? nivelSalud,
    int? nivelEnergia,
    int? nivelHambre,
    int? nivelLimpieza,
    int? nivelAfecto,
    String? estado,
    bool? activa,
    DateTime? ultimaInteraccion,
    DateTime? ultimaComida,
    DateTime? ultimoJuego,
    DateTime? ultimoBano,
    DateTime? ultimaCuracion,
    DateTime? ultimoPaseo,
    bool? deterioroAcelerado,
    bool? anomaliaDetectada,
    int? ticksEnergiaBaja,
    double? nivelPlato,
    String? platoAlimentoId,
    bool clearPlatoAlimentoId = false,
    String? platoEmoji,
    bool clearPlatoEmoji = false,
    DateTime? platoActualizado,
    bool clearPlatoActualizado = false,
    bool? platoComiendo,
    String? itemCabezaId,
    bool clearItemCabezaId = false,
    String? estadoDescanso,
    DateTime? inicioDescanso,
    bool clearInicioDescanso = false,
    String? tipoDescanso,
    int? energiaAlAcostar,
    bool? buffEnergia,
    DateTime? buffExpira,
    bool clearBuffExpira = false,
    bool? cortinasAbiertas,
    int? tapsParaDespetarBase,
    String? inicioDescansoTipo,
    bool clearInicioDescansoTipo = false,
    DateTime? residuosHambreAltaDesde,
    bool clearResiduosHambreAltaDesde = false,
    int? residuosObjetivoMinutos,
    bool clearResiduosObjetivoMinutos = false,
    DateTime? residuosUltimaGeneracion,
    bool clearResiduosUltimaGeneracion = false,
    String? ultimoAlimentoConsumidoId,
    bool clearUltimoAlimentoConsumidoId = false,
    int? residuosMismaComidaStreak,
    double? deterioroRate,
    bool? anomaliaActiva,
    String? estadoEmocional,
    bool clearDeterioroRate = false,
    bool clearEstadoEmocional = false,
    MascotaStatsModel? stats,
    MascotaRuntimeModel? runtime,
    MascotaAiModel? ai,
  }) {
    final nextStats = (stats ?? this.stats).copyWith(
      nivelSalud: nivelSalud?.toDouble(),
      nivelEnergia: nivelEnergia?.toDouble(),
      nivelHambre: nivelHambre?.toDouble(),
      nivelLimpieza: nivelLimpieza?.toDouble(),
      nivelAfecto: nivelAfecto?.toDouble(),
    );

    final runtimeBase = runtime ?? this.runtime;
    final nextRuntime = runtimeBase.copyWith(
      estadoDescanso: estadoDescanso,
      inicioDescanso: inicioDescanso,
      clearInicioDescanso: clearInicioDescanso,
      tipoDescanso: tipoDescanso,
      nivelPlato: nivelPlato,
      platoAlimentoId: clearPlatoAlimentoId
          ? ''
          : (platoAlimentoId ?? runtimeBase.platoAlimentoId ?? ''),
      platoEmoji: clearPlatoEmoji ? '' : platoEmoji,
      platoActualizado: platoActualizado,
      clearPlatoActualizado: clearPlatoActualizado,
      platoComiendo: platoComiendo,
      itemCabezaId: clearItemCabezaId
          ? ''
          : (itemCabezaId ?? runtimeBase.itemCabezaId ?? ''),
      estado: estado,
      activa: activa,
      ultimaInteraccion: ultimaInteraccion,
      ultimaComida: ultimaComida,
      ultimoJuego: ultimoJuego,
      ultimoBano: ultimoBano,
      ultimaCuracion: ultimaCuracion,
      ultimoPaseo: ultimoPaseo,
      deterioroAcelerado: deterioroAcelerado,
      anomaliaDetectada: anomaliaDetectada,
      ticksEnergiaBaja: ticksEnergiaBaja,
      energiaAlAcostar: energiaAlAcostar?.toDouble(),
      buffEnergia: buffEnergia,
      buffExpira: buffExpira,
      clearBuffExpira: clearBuffExpira,
      cortinasAbiertas: cortinasAbiertas,
      tapsParaDespetarBase: tapsParaDespetarBase,
      inicioDescansoTipo: inicioDescansoTipo,
      clearInicioDescansoTipo: clearInicioDescansoTipo,
      residuosHambreAltaDesde: residuosHambreAltaDesde,
      clearResiduosHambreAltaDesde: clearResiduosHambreAltaDesde,
      residuosObjetivoMinutos: residuosObjetivoMinutos,
      clearResiduosObjetivoMinutos: clearResiduosObjetivoMinutos,
      residuosUltimaGeneracion: residuosUltimaGeneracion,
      clearResiduosUltimaGeneracion: clearResiduosUltimaGeneracion,
      ultimoAlimentoConsumidoId: ultimoAlimentoConsumidoId,
      clearUltimoAlimentoConsumidoId: clearUltimoAlimentoConsumidoId,
      residuosMismaComidaStreak: residuosMismaComidaStreak,
    );

    final nextAi = (ai ?? this.ai).copyWith(
      deterioroRate: deterioroRate,
      anomaliaActiva: anomaliaActiva,
      estadoEmocional: estadoEmocional,
      clearDeterioroRate: clearDeterioroRate,
      clearEstadoEmocional: clearEstadoEmocional,
    );

    return MascotaModel(
      idMascota: idMascota,
      nombreMascota: nombreMascota ?? this.nombreMascota,
      tipoMascota: tipoMascota ?? this.tipoMascota,
      rasgo: rasgo ?? this.rasgo,
      stats: nextStats,
      runtime: nextRuntime,
      ai: nextAi,
    );
  }

  int get nivelSalud => stats.nivelSalud.round();
  int get nivelEnergia => stats.nivelEnergia.round();
  int get nivelHambre => stats.nivelHambre.round();
  int get nivelLimpieza => stats.nivelLimpieza.round();
  int get nivelAfecto => stats.nivelAfecto.round();

  String get estado => runtime.estado;
  bool get activa => runtime.activa;
  DateTime get ultimaInteraccion => runtime.ultimaInteraccion;
  DateTime? get ultimaComida => runtime.ultimaComida;
  DateTime? get ultimoJuego => runtime.ultimoJuego;
  DateTime? get ultimoBano => runtime.ultimoBano;
  DateTime? get ultimaCuracion => runtime.ultimaCuracion;
  DateTime? get ultimoPaseo => runtime.ultimoPaseo;

  bool get deterioroAcelerado => runtime.deterioroAcelerado;
  bool get anomaliaDetectada => runtime.anomaliaDetectada;
  int get ticksEnergiaBaja => runtime.ticksEnergiaBaja;

  String get estadoDescanso => runtime.estadoDescanso;
  DateTime? get inicioDescanso => runtime.inicioDescanso;
  String get tipoDescanso => runtime.tipoDescanso;
  double get nivelPlato => runtime.nivelPlato;
  String get platoAlimentoId => runtime.platoAlimentoId ?? '';
  String get platoEmoji => runtime.platoEmoji;
  DateTime? get platoActualizado => runtime.platoActualizado;
  bool get platoComiendo => runtime.platoComiendo;
  String get itemCabezaId => runtime.itemCabezaId ?? '';
  int get energiaAlAcostar => runtime.energiaAlAcostar.round();
  bool get buffEnergia => runtime.buffEnergia;
  DateTime? get buffExpira => runtime.buffExpira;
  bool get cortinasAbiertas => runtime.cortinasAbiertas;
  int get tapsParaDespetarBase => runtime.tapsParaDespetarBase;
  String? get inicioDescansoTipo => runtime.inicioDescansoTipo;
  DateTime? get residuosHambreAltaDesde => runtime.residuosHambreAltaDesde;
  int? get residuosObjetivoMinutos => runtime.residuosObjetivoMinutos;
  DateTime? get residuosUltimaGeneracion => runtime.residuosUltimaGeneracion;
  Map<String, int> get inventarioBotiquin => runtime.inventarioBotiquin;
  String get ultimoAlimentoConsumidoId =>
      runtime.ultimoAlimentoConsumidoId ?? '';
  int get residuosMismaComidaStreak => runtime.residuosMismaComidaStreak;

  double? get deterioroRate => ai.deterioroRate;
  bool get anomaliaActiva => ai.anomaliaActiva;
  String? get estadoEmocional => ai.estadoEmocional;

  bool get estaDescansando =>
      estadoDescanso == 'acostado' ||
      estadoDescanso == 'dormido' ||
      estadoDescanso == 'siesta';

  bool get buffActivo =>
      buffEnergia && (buffExpira?.isAfter(DateTime.now()) ?? false);

  PersonalidadTipo get personalidad => PersonalidadTipo.fromString(rasgo);

  String get estadoSuciedad {
    if (nivelLimpieza < 45) return 'manchas_fuertes';
    if (nivelLimpieza <= 65) return 'manchas_leves';
    return 'limpio';
  }

  bool get tieneManchasLeves => estadoSuciedad == 'manchas_leves';
  bool get tieneManchasFuertes => estadoSuciedad == 'manchas_fuertes';

  Map<String, int> get nivelesMap => {
    'salud': nivelSalud,
    'energia': nivelEnergia,
    'hambre': nivelHambre,
    'limpieza': nivelLimpieza,
    'afecto': nivelAfecto,
  };
}
