import '../Models/mascota_model.dart';

class PetState {
  final MascotaModel? mascota;
  final bool isLoading;

  // ── Sistema de descanso ────────────────────────────────
  // 'ninguna' | 'perro_rebelde' | 'rebelde_escapado'
  final String estadoMision;
  // Caricias necesarias para dormir (generado al acostarse)
  final int cariciasTotal;
  // Caricias que ya hizo el niño
  final int cariciasHechas;
  // Taps del niño para despertar a la mascota
  final int tapsDespertar;
  // Taps para calmar rebelde
  final int tapsCalmar;

  PetState({
    this.mascota,
    this.isLoading      = false,
    this.estadoMision   = 'ninguna',
    this.cariciasTotal  = 0,
    this.cariciasHechas = 0,
    this.tapsDespertar  = 0,
    this.tapsCalmar     = 0,
  });

  PetState copyWith({
    MascotaModel? mascota,
    bool?  isLoading,
    bool   clearMascota    = false,
    String? estadoMision,
    int?   cariciasTotal,
    int?   cariciasHechas,
    int?   tapsDespertar,
    int?   tapsCalmar,
  }) {
    return PetState(
      mascota:        clearMascota ? null : (mascota ?? this.mascota),
      isLoading:      isLoading      ?? this.isLoading,
      estadoMision:   estadoMision   ?? this.estadoMision,
      cariciasTotal:  cariciasTotal  ?? this.cariciasTotal,
      cariciasHechas: cariciasHechas ?? this.cariciasHechas,
      tapsDespertar:  tapsDespertar  ?? this.tapsDespertar,
      tapsCalmar:     tapsCalmar     ?? this.tapsCalmar,
    );
  }
}
