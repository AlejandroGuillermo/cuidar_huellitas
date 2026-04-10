import '../models/mascota_model.dart';

class PetState {
  final MascotaModel? mascota;
  final bool isLoading;

  PetState({this.mascota, this.isLoading = false});

  PetState copyWith({
    MascotaModel? mascota,
    bool? isLoading,
    bool clearMascota = false,
  }) {
    return PetState(
      mascota: clearMascota ? null : (mascota ?? this.mascota),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
