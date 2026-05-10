class MascotaAiModel {
  final double? deterioroRate;
  final bool anomaliaActiva;
  final String? estadoEmocional;

  const MascotaAiModel({
    this.deterioroRate,
    this.anomaliaActiva = false,
    this.estadoEmocional,
  });

  factory MascotaAiModel.fromMap(Map<String, dynamic> data) {
    return MascotaAiModel(
      deterioroRate: data['deterioro_rate'] is num
          ? (data['deterioro_rate'] as num).toDouble()
          : null,
      anomaliaActiva: data['anomalia_activa'] ?? false,
      estadoEmocional: data['estado_emocional'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deterioro_rate': deterioroRate,
      'anomalia_activa': anomaliaActiva,
      'estado_emocional': estadoEmocional,
    };
  }

  MascotaAiModel copyWith({
    double? deterioroRate,
    bool? anomaliaActiva,
    String? estadoEmocional,
    bool clearDeterioroRate = false,
    bool clearEstadoEmocional = false,
  }) {
    return MascotaAiModel(
      deterioroRate: clearDeterioroRate
          ? null
          : (deterioroRate ?? this.deterioroRate),
      anomaliaActiva: anomaliaActiva ?? this.anomaliaActiva,
      estadoEmocional: clearEstadoEmocional
          ? null
          : (estadoEmocional ?? this.estadoEmocional),
    );
  }
}
