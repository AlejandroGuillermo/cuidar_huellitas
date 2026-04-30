import '../../domain/enums/pet_location.dart';
import '../../Models/mascota_model.dart';

class PetLocationResolver {
  PetLocationResolver();

  PetLocation resolve(MascotaModel mascota) {
    if (mascota.estadoDescanso == 'dormido' ||
        mascota.estadoDescanso == 'siesta') {
      return PetLocation.dormir;
    }

    return PetLocation.home;
  }
}
