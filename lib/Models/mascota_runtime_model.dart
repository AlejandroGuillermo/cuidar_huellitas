import 'package:cloud_firestore/cloud_firestore.dart';

class MascotaRuntimeModel {
  final String estadoDescanso;
  final DateTime? inicioDescanso;
  final String tipoDescanso;
  final double nivelPlato;
  final String? platoAlimentoId;
  final String platoEmoji;
  final DateTime? platoActualizado;
  final bool platoComiendo;
  final String? itemCabezaId;
  final String estado;
  final bool activa;
  final DateTime ultimaInteraccion;
  final DateTime? ultimaComida;
  final DateTime? ultimoJuego;
  final DateTime? ultimoBano;
  final DateTime? ultimaCuracion;
  final DateTime? ultimoPaseo;
  final bool deterioroAcelerado;
  final bool anomaliaDetectada;
  final int ticksEnergiaBaja;
  final double energiaAlAcostar;
  final bool buffEnergia;
  final DateTime? buffExpira;
  final DateTime? buffBanoExpira;
  final bool cortinasAbiertas;
  final int tapsParaDespetarBase;
  final String? inicioDescansoTipo;
  final DateTime? residuosHambreAltaDesde;
  final int? residuosObjetivoMinutos;
  final DateTime? residuosUltimaGeneracion;
  final String? ultimoAlimentoConsumidoId;
  final int residuosMismaComidaStreak;
  final Map<String, int> inventarioBotiquin;

  const MascotaRuntimeModel({
    this.estadoDescanso = 'despierto',
    this.inicioDescanso,
    this.tipoDescanso = '',
    this.nivelPlato = 0.0,
    this.platoAlimentoId = '',
    this.platoEmoji = '',
    this.platoActualizado,
    this.platoComiendo = false,
    this.itemCabezaId = '',
    this.estado = 'feliz',
    this.activa = true,
    required this.ultimaInteraccion,
    this.ultimaComida,
    this.ultimoJuego,
    this.ultimoBano,
    this.ultimaCuracion,
    this.ultimoPaseo,
    this.deterioroAcelerado = false,
    this.anomaliaDetectada = false,
    this.ticksEnergiaBaja = 0,
    this.energiaAlAcostar = 0,
    this.buffEnergia = false,
    this.buffExpira,
    this.buffBanoExpira,
    this.cortinasAbiertas = true,
    this.tapsParaDespetarBase = 4,
    this.inicioDescansoTipo,
    this.residuosHambreAltaDesde,
    this.residuosObjetivoMinutos,
    this.residuosUltimaGeneracion,
    this.ultimoAlimentoConsumidoId,
    this.residuosMismaComidaStreak = 0,
    this.inventarioBotiquin = const {'venda': 2, 'suero': 2, 'aroma': 2},
  });

  factory MascotaRuntimeModel.fromMap(Map<String, dynamic> data) {
    return MascotaRuntimeModel(
      estadoDescanso: data['estado_descanso'] ?? 'despierto',
      inicioDescanso: _timestampToDate(data['inicio_descanso']),
      tipoDescanso: data['tipo_descanso'] ?? '',
      nivelPlato: _asDouble(data['nivel_plato'], 0),
      platoAlimentoId: data['plato_alimento_id'] ?? '',
      platoEmoji: data['plato_emoji'] ?? '',
      platoActualizado: _timestampToDate(data['plato_actualizado']),
      platoComiendo: data['plato_comiendo'] ?? false,
      itemCabezaId: data['item_cabeza_id'] ?? '',
      estado: data['estado'] ?? 'feliz',
      activa: data['activa'] ?? true,
      ultimaInteraccion:
          _timestampToDate(data['ultima_interaccion']) ?? DateTime.now(),
      ultimaComida: _timestampToDate(data['ultima_comida']),
      ultimoJuego: _timestampToDate(data['ultimo_juego']),
      ultimoBano: _timestampToDate(data['ultimo_bano']),
      ultimaCuracion: _timestampToDate(data['ultima_curacion']),
      ultimoPaseo: _timestampToDate(data['ultimo_paseo']),
      deterioroAcelerado: data['deterioro_acelerado'] ?? false,
      anomaliaDetectada:
          data['anomalia_detectada'] ??
          data['anomaliaActiva'] ??
          data['anomalia_activa'] ??
          false,
      ticksEnergiaBaja: _asInt(data['ticks_energia_baja'], 0),
      energiaAlAcostar: _asDouble(data['energia_al_acostar'], 0),
      buffEnergia: data['buff_energia'] ?? false,
      buffExpira: _timestampToDate(data['buff_expira']),
      buffBanoExpira: _timestampToDate(data['buff_bano_expira']),
      cortinasAbiertas: data['cortinas_abiertas'] ?? true,
      tapsParaDespetarBase: _asInt(data['taps_para_despertar'], 4),
      inicioDescansoTipo: data['inicio_descanso_tipo'],
      residuosHambreAltaDesde: _timestampToDate(
        data['residuos_hambre_alta_desde'],
      ),
      residuosObjetivoMinutos: _asNullableInt(data['residuos_objetivo_minutos']),
      residuosUltimaGeneracion: _timestampToDate(
        data['residuos_ultima_generacion'],
      ),
      ultimoAlimentoConsumidoId: data['ultimo_alimento_consumido_id'],
      residuosMismaComidaStreak: _asInt(
        data['residuos_misma_comida_streak'],
        0,
      ),
      inventarioBotiquin: _asBotiquinMap(data['inventario_botiquin']),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'estado_descanso': estadoDescanso,
      'inicio_descanso': inicioDescanso != null
          ? Timestamp.fromDate(inicioDescanso!)
          : null,
      'tipo_descanso': tipoDescanso,
      'nivel_plato': nivelPlato,
      'plato_alimento_id': platoAlimentoId ?? '',
      'plato_emoji': platoEmoji,
      'plato_actualizado': platoActualizado != null
          ? Timestamp.fromDate(platoActualizado!)
          : null,
      'plato_comiendo': platoComiendo,
      'item_cabeza_id': itemCabezaId ?? '',
      'estado': estado,
      'activa': activa,
      'ultima_interaccion': Timestamp.fromDate(ultimaInteraccion),
      'ultima_comida': ultimaComida != null
          ? Timestamp.fromDate(ultimaComida!)
          : null,
      'ultimo_juego': ultimoJuego != null
          ? Timestamp.fromDate(ultimoJuego!)
          : null,
      'ultimo_bano': ultimoBano != null
          ? Timestamp.fromDate(ultimoBano!)
          : null,
      'ultima_curacion': ultimaCuracion != null
          ? Timestamp.fromDate(ultimaCuracion!)
          : null,
      'ultimo_paseo': ultimoPaseo != null
          ? Timestamp.fromDate(ultimoPaseo!)
          : null,
      'deterioro_acelerado': deterioroAcelerado,
      'anomalia_detectada': anomaliaDetectada,
      'anomaliaActiva': anomaliaDetectada,
      'ticks_energia_baja': ticksEnergiaBaja,
      'energia_al_acostar': energiaAlAcostar,
      'buff_energia': buffEnergia,
      'buff_expira': buffExpira != null
          ? Timestamp.fromDate(buffExpira!)
          : null,
      'buff_bano_expira': buffBanoExpira != null
          ? Timestamp.fromDate(buffBanoExpira!)
          : null,
      'cortinas_abiertas': cortinasAbiertas,
      'taps_para_despertar': tapsParaDespetarBase,
      'residuos_hambre_alta_desde': residuosHambreAltaDesde != null
          ? Timestamp.fromDate(residuosHambreAltaDesde!)
          : null,
      'residuos_objetivo_minutos': residuosObjetivoMinutos,
      'residuos_ultima_generacion': residuosUltimaGeneracion != null
          ? Timestamp.fromDate(residuosUltimaGeneracion!)
          : null,
      'ultimo_alimento_consumido_id': ultimoAlimentoConsumidoId,
      'residuos_misma_comida_streak': residuosMismaComidaStreak,
      'inventario_botiquin': inventarioBotiquin,
    };

    if (inicioDescansoTipo != null) {
      map['inicio_descanso_tipo'] = inicioDescansoTipo;
    }

    return map;
  }

  MascotaRuntimeModel copyWith({
    String? estadoDescanso,
    DateTime? inicioDescanso,
    bool clearInicioDescanso = false,
    String? tipoDescanso,
    double? nivelPlato,
    String? platoAlimentoId,
    bool clearPlatoAlimentoId = false,
    String? platoEmoji,
    DateTime? platoActualizado,
    bool clearPlatoActualizado = false,
    bool? platoComiendo,
    String? itemCabezaId,
    bool clearItemCabezaId = false,
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
    double? energiaAlAcostar,
    bool? buffEnergia,
    DateTime? buffExpira,
    bool clearBuffExpira = false,
    DateTime? buffBanoExpira,
    bool clearBuffBanoExpira = false,
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
    Map<String, int>? inventarioBotiquin,
  }) {
    return MascotaRuntimeModel(
      estadoDescanso: estadoDescanso ?? this.estadoDescanso,
      inicioDescanso: clearInicioDescanso
          ? null
          : (inicioDescanso ?? this.inicioDescanso),
      tipoDescanso: tipoDescanso ?? this.tipoDescanso,
      nivelPlato: nivelPlato ?? this.nivelPlato,
      platoAlimentoId: clearPlatoAlimentoId
          ? null
          : (platoAlimentoId ?? this.platoAlimentoId),
      platoEmoji: platoEmoji ?? this.platoEmoji,
      platoActualizado: clearPlatoActualizado
          ? null
          : (platoActualizado ?? this.platoActualizado),
      platoComiendo: platoComiendo ?? this.platoComiendo,
      itemCabezaId: clearItemCabezaId
          ? null
          : (itemCabezaId ?? this.itemCabezaId),
      estado: estado ?? this.estado,
      activa: activa ?? this.activa,
      ultimaInteraccion: ultimaInteraccion ?? this.ultimaInteraccion,
      ultimaComida: ultimaComida ?? this.ultimaComida,
      ultimoJuego: ultimoJuego ?? this.ultimoJuego,
      ultimoBano: ultimoBano ?? this.ultimoBano,
      ultimaCuracion: ultimaCuracion ?? this.ultimaCuracion,
      ultimoPaseo: ultimoPaseo ?? this.ultimoPaseo,
      deterioroAcelerado: deterioroAcelerado ?? this.deterioroAcelerado,
      anomaliaDetectada: anomaliaDetectada ?? this.anomaliaDetectada,
      ticksEnergiaBaja: ticksEnergiaBaja ?? this.ticksEnergiaBaja,
      energiaAlAcostar: energiaAlAcostar ?? this.energiaAlAcostar,
      buffEnergia: buffEnergia ?? this.buffEnergia,
      buffExpira: clearBuffExpira ? null : (buffExpira ?? this.buffExpira),
      buffBanoExpira: clearBuffBanoExpira
          ? null
          : (buffBanoExpira ?? this.buffBanoExpira),
      cortinasAbiertas: cortinasAbiertas ?? this.cortinasAbiertas,
      tapsParaDespetarBase: tapsParaDespetarBase ?? this.tapsParaDespetarBase,
      inicioDescansoTipo: clearInicioDescansoTipo
          ? null
          : (inicioDescansoTipo ?? this.inicioDescansoTipo),
      residuosHambreAltaDesde: clearResiduosHambreAltaDesde
          ? null
          : (residuosHambreAltaDesde ?? this.residuosHambreAltaDesde),
      residuosObjetivoMinutos: clearResiduosObjetivoMinutos
          ? null
          : (residuosObjetivoMinutos ?? this.residuosObjetivoMinutos),
      residuosUltimaGeneracion: clearResiduosUltimaGeneracion
          ? null
          : (residuosUltimaGeneracion ?? this.residuosUltimaGeneracion),
      ultimoAlimentoConsumidoId: clearUltimoAlimentoConsumidoId
          ? null
          : (ultimoAlimentoConsumidoId ?? this.ultimoAlimentoConsumidoId),
      residuosMismaComidaStreak:
          residuosMismaComidaStreak ?? this.residuosMismaComidaStreak,
      inventarioBotiquin: inventarioBotiquin ?? this.inventarioBotiquin,
    );
  }
}

DateTime? _timestampToDate(dynamic value) {
  return value is Timestamp ? value.toDate() : null;
}

double _asDouble(dynamic value, double fallback) {
  return value is num ? value.toDouble() : fallback;
}

int _asInt(dynamic value, int fallback) {
  return value is num ? value.toInt() : fallback;
}

int? _asNullableInt(dynamic value) {
  return value is num ? value.toInt() : null;
}

Map<String, int> _asBotiquinMap(dynamic value) {
  const fallback = <String, int>{'venda': 2, 'suero': 2, 'aroma': 2};
  if (value is! Map) return fallback;

  final mapped = value.cast<String, dynamic>().map(
    (key, item) => MapEntry(key, item is num ? item.toInt() : 0),
  );

  return {
    'venda': mapped['venda'] ?? 0,
    'suero': mapped['suero'] ?? 0,
    'aroma': mapped['aroma'] ?? 0,
  };
}
