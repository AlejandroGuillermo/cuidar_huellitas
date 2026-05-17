import 'package:flutter/material.dart';

import '../../application/cubits/pet_world_cubit.dart';
import '../../core/disaster_system.dart';
import '../../cubit/pet_cubit.dart';
import '../../domain/enums/pet_activity.dart';
import '../../domain/enums/pet_location.dart';
import 'alimentar_cubit.dart';

class AlimentarController {
  static Future<void> syncWorldEntry({
    required PetCubit petCubit,
    required PetWorldCubit worldCubit,
    required DisasterCubit disasterCubit,
    required bool isEating,
  }) async {
    final mascota = petCubit.state.mascota;
    if (mascota == null) return;

    await worldCubit.syncScreenEntry(
      mascota: mascota,
      location: PetLocation.alimentar,
      fallbackActivity: isEating ? PetActivity.eating : PetActivity.idle,
    );
    await disasterCubit.verificarDesastre(mascota.idMascota);
  }

  static Future<void> ensureLockedEatingState({
    required PetCubit petCubit,
    required PetWorldCubit worldCubit,
  }) async {
    final world = worldCubit.state;
    final mascota = petCubit.state.mascota;
    if (mascota == null) return;

    if (world.isLocationLocked &&
        world.location == PetLocation.alimentar &&
        world.activity == PetActivity.eating &&
        mascota.nivelPlato > 0 &&
        !mascota.platoComiendo) {
      await petCubit.iniciarComidaPlato();
    }
  }

  static Future<void> syncEatingAnchor({
    required PetCubit petCubit,
    required PetWorldCubit worldCubit,
    required bool isEatingNow,
    required String? plateFoodId,
  }) async {
    final mascota = petCubit.state.mascota;
    if (mascota == null) return;

    if (isEatingNow) {
      await worldCubit.updateWorld(
        mascota: mascota,
        next: worldCubit.state.copyWith(
          location: PetLocation.alimentar,
          activity: PetActivity.eating,
          currentFoodId: plateFoodId ?? worldCubit.state.currentFoodId,
          clearToy: true,
          isLocationLocked: true,
          isNapTime: false,
          simulatedAt: DateTime.now(),
        ),
      );
      return;
    }

    if (worldCubit.state.isLocationLocked &&
        worldCubit.state.location == PetLocation.alimentar) {
      await worldCubit.updateWorld(
        mascota: mascota,
        next: worldCubit.state.copyWith(
          activity: PetActivity.idle,
          clearFood: true,
          isLocationLocked: false,
          isNapTime: false,
          simulatedAt: DateTime.now(),
        ),
      );
    }
  }

  static Future<void> persistPlateAfterPour({
    required AlimentarCubit alimentarCubit,
    required PetCubit petCubit,
    required bool isEating,
  }) async {
    await alimentarCubit.stopPouring();
    await alimentarCubit.persistInventoryAndPlate(
      eating: isEating,
      persistPlate:
          ({
            required double nivelPlato,
            required String? platoAlimentoId,
            required bool clearPlatoAlimentoId,
            required String? platoEmoji,
            required bool clearPlatoEmoji,
            required bool platoComiendo,
          }) async {
            await petCubit.actualizarEstadoPlato(
              nivelPlato: nivelPlato,
              platoAlimentoId: platoAlimentoId,
              clearPlatoAlimentoId: clearPlatoAlimentoId,
              platoEmoji: platoEmoji,
              clearPlatoEmoji: clearPlatoEmoji,
              platoComiendo: platoComiendo,
              platoActualizado: DateTime.now(),
            );
          },
    );
  }

  static bool isPointerOverPlate({
    required GlobalKey plateVisualKey,
    required Offset globalPosition,
  }) {
    final plateContext = plateVisualKey.currentContext;
    if (plateContext == null) return false;

    final renderObject = plateContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return false;

    final localPosition = renderObject.globalToLocal(globalPosition);
    return localPosition.dx >= 0 &&
        localPosition.dy >= 0 &&
        localPosition.dx <= renderObject.size.width &&
        localPosition.dy <= renderObject.size.height;
  }

  static Future<void> handleFeedPet({
    required AlimentarCubit alimentarCubit,
    required PetCubit petCubit,
    required PetWorldCubit worldCubit,
    required double plateLevel,
    required String? plateFoodId,
    required String plateEmoji,
  }) async {
    if (!petCubit.puedeIniciarComidaPlato(
      nivelPlato: plateLevel,
      platoAlimentoId: plateFoodId,
    )) {
      return;
    }

    if (petCubit.deberiaTirarComida()) {
      await throwFood(
        alimentarCubit: alimentarCubit,
        petCubit: petCubit,
        plateEmoji: plateEmoji,
      );
      final puntos = petCubit.puntosPorTirarComida(plateFoodId);
      await petCubit.alimentar(puntos, emojiAlimento: plateEmoji);
      await petCubit.detenerComidaPlato();
      return;
    }

    await petCubit.iniciarComidaPlato();
    await syncEatingAnchor(
      petCubit: petCubit,
      worldCubit: worldCubit,
      isEatingNow: true,
      plateFoodId: plateFoodId,
    );
  }

  static Future<void> detenerComidaManual({
    required PetCubit petCubit,
    required PetWorldCubit worldCubit,
    required String? plateFoodId,
  }) async {
    await petCubit.detenerComidaPlato();
    await syncEatingAnchor(
      petCubit: petCubit,
      worldCubit: worldCubit,
      isEatingNow: false,
      plateFoodId: plateFoodId,
    );
  }

  static Future<void> throwFood({
    required AlimentarCubit alimentarCubit,
    required PetCubit petCubit,
    required String plateEmoji,
  }) async {
    alimentarCubit.clearPlateLocally();
    await petCubit.procesarComidaTiradaEnAlimentar(emojiComida: plateEmoji);
  }
}
