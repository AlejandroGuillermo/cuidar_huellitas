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
  final bool cortinasAbiertas;
  final int tapsParaDespetarBase;
  final String? inicioDescansoTipo;

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
    this.cortinasAbiertas = true,
    this.tapsParaDespetarBase = 4,
    this.inicioDescansoTipo,
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
      cortinasAbiertas: data['cortinas_abiertas'] ?? true,
      tapsParaDespetarBase: _asInt(data['taps_para_despertar'], 4),
      inicioDescansoTipo: data['inicio_descanso_tipo'],
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
      'cortinas_abiertas': cortinasAbiertas,
      'taps_para_despertar': tapsParaDespetarBase,
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
    bool? cortinasAbiertas,
    int? tapsParaDespetarBase,
    String? inicioDescansoTipo,
    bool clearInicioDescansoTipo = false,
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
      cortinasAbiertas: cortinasAbiertas ?? this.cortinasAbiertas,
      tapsParaDespetarBase: tapsParaDespetarBase ?? this.tapsParaDespetarBase,
      inicioDescansoTipo: clearInicioDescansoTipo
          ? null
          : (inicioDescansoTipo ?? this.inicioDescansoTipo),
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
