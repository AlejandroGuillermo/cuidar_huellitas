class MascotaStatsModel {
  final double nivelSalud;
  final double nivelEnergia;
  final double nivelHambre;
  final double nivelLimpieza;
  final double nivelAfecto;

  const MascotaStatsModel({
    this.nivelSalud = 100,
    this.nivelEnergia = 100,
    this.nivelHambre = 100,
    this.nivelLimpieza = 100,
    this.nivelAfecto = 100,
  });

  factory MascotaStatsModel.fromMap(Map<String, dynamic> data) {
    return MascotaStatsModel(
      nivelSalud: _asDouble(data['nivel_salud'], 100),
      nivelEnergia: _asDouble(data['nivel_energia'], 100),
      nivelHambre: _asDouble(data['nivel_hambre'], 100),
      nivelLimpieza: _asDouble(data['nivel_limpieza'], 100),
      nivelAfecto: _asDouble(data['nivel_afecto'], 100),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nivel_salud': nivelSalud,
      'nivel_energia': nivelEnergia,
      'nivel_hambre': nivelHambre,
      'nivel_limpieza': nivelLimpieza,
      'nivel_afecto': nivelAfecto,
    };
  }

  MascotaStatsModel copyWith({
    double? nivelSalud,
    double? nivelEnergia,
    double? nivelHambre,
    double? nivelLimpieza,
    double? nivelAfecto,
  }) {
    return MascotaStatsModel(
      nivelSalud: nivelSalud ?? this.nivelSalud,
      nivelEnergia: nivelEnergia ?? this.nivelEnergia,
      nivelHambre: nivelHambre ?? this.nivelHambre,
      nivelLimpieza: nivelLimpieza ?? this.nivelLimpieza,
      nivelAfecto: nivelAfecto ?? this.nivelAfecto,
    );
  }

  Map<String, double> get nivelesMap => {
    'salud': nivelSalud,
    'energia': nivelEnergia,
    'hambre': nivelHambre,
    'limpieza': nivelLimpieza,
    'afecto': nivelAfecto,
  };
}

double _asDouble(dynamic value, double fallback) {
  return value is num ? value.toDouble() : fallback;
}
