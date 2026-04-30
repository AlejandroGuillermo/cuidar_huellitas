import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'application/cubits/mission_cubit.dart';
import 'application/cubits/pet_world_cubit.dart';
import 'application/services/pet_activity_resolver.dart';
import 'application/services/pet_bootstrap_service.dart';
import 'application/services/pet_location_resolver.dart';
import 'core/app_router.dart';
import 'core/disaster_system.dart';
import 'cubit/pet_cubit.dart';
import 'cubit/pet_state.dart';
import 'data/repositories/disaster_repository.dart';
import 'data/repositories/mission_repository.dart';
import 'data/repositories/world_repository.dart';
import 'domain/entities/pending_mission.dart';
import 'domain/enums/pet_activity.dart';
import 'domain/enums/mission_kind.dart';
import 'domain/enums/pet_location.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  static bool _missionNotificationsReady = false;
  static Set<String> _knownMissionIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final bootstrapService = PetBootstrapService(
      worldRepository: WorldRepository(),
      locationResolver: PetLocationResolver(),
      activityResolver: PetActivityResolver(),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => DisasterCubit()),
        BlocProvider(
          create: (context) {
            final petCubit = PetCubit()
              ..disasterCubit = context.read<DisasterCubit>()
              ..cargarMascota();
            return petCubit;
          },
        ),
        BlocProvider(
          create: (context) =>
              PetWorldCubit(bootstrapService: bootstrapService),
        ),
        BlocProvider(
          create: (context) => MissionCubit(
            missionRepository: MissionRepository(),
            disasterRepository: DisasterRepository(),
          ),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<PetCubit, PetState>(
            listenWhen: (previous, current) =>
                previous.mascota?.idMascota != current.mascota?.idMascota,
            listener: (context, state) async {
              final mascota = state.mascota;
              if (mascota == null) return;
              final petCubit = context.read<PetCubit>();
              final petWorldCubit = context.read<PetWorldCubit>();
              final missionCubit = context.read<MissionCubit>();
              final disasterCubit = context.read<DisasterCubit>();

              await petWorldCubit.bootstrap(mascota, randomizeIfUnlocked: true);

              final world = petWorldCubit.state;
              final currentPet = petCubit.state.mascota;
              if (currentPet != null &&
                  world.isLocationLocked &&
                  world.location == PetLocation.alimentar &&
                  currentPet.nivelPlato > 0 &&
                  !currentPet.platoComiendo) {
                await petCubit.iniciarComidaPlato();
              }
              if (currentPet != null &&
                  world.isLocationLocked &&
                  world.location == PetLocation.dormir &&
                  !currentPet.estaDescansando) {
                await petCubit.forzarDescansoOffline(siesta: world.isNapTime);
              }

              await missionCubit.hydrate(mascota.idMascota);
              await disasterCubit.verificarDesastre(mascota.idMascota);
            },
          ),
          BlocListener<PetCubit, PetState>(
            listenWhen: (previous, current) =>
                previous.mascota?.estadoDescanso !=
                current.mascota?.estadoDescanso,
            listener: (context, state) async {
              final mascota = state.mascota;
              if (mascota == null) return;

              final petWorldCubit = context.read<PetWorldCubit>();
              final estaDormida =
                  mascota.estadoDescanso == 'dormido' ||
                  mascota.estadoDescanso == 'siesta';

              if (estaDormida) {
                await petWorldCubit.updateWorld(
                  mascota: mascota,
                  next: petWorldCubit.state.copyWith(
                    location: PetLocation.dormir,
                    activity: PetActivity.sleeping,
                    isLocationLocked: true,
                    isNapTime: mascota.estadoDescanso == 'siesta',
                    clearFood: true,
                    clearToy: true,
                    simulatedAt: DateTime.now(),
                  ),
                );
                return;
              }

              if (petWorldCubit.state.isLocationLocked &&
                  petWorldCubit.state.location == PetLocation.dormir) {
                await petWorldCubit.updateWorld(
                  mascota: mascota,
                  next: petWorldCubit.state.copyWith(
                    location: PetLocation.dormir,
                    activity: PetActivity.idle,
                    isLocationLocked: false,
                    isNapTime: false,
                    clearFood: true,
                    clearToy: true,
                    simulatedAt: DateTime.now(),
                  ),
                );
              }
            },
          ),
          BlocListener<PetCubit, PetState>(
            listenWhen: (previous, current) =>
                previous.mascota?.platoComiendo !=
                    current.mascota?.platoComiendo ||
                previous.mascota?.nivelPlato != current.mascota?.nivelPlato,
            listener: (context, state) async {
              final mascota = state.mascota;
              if (mascota == null) return;

              final petWorldCubit = context.read<PetWorldCubit>();
              if (petWorldCubit.state.isLoading) return;

              if (mascota.platoComiendo && mascota.nivelPlato > 0) {
                await petWorldCubit.updateWorld(
                  mascota: mascota,
                  next: petWorldCubit.state.copyWith(
                    location: PetLocation.alimentar,
                    activity: PetActivity.eating,
                    currentFoodId: mascota.platoAlimentoId.isNotEmpty
                        ? mascota.platoAlimentoId
                        : petWorldCubit.state.currentFoodId,
                    isLocationLocked: true,
                    isNapTime: false,
                    clearToy: true,
                    simulatedAt: DateTime.now(),
                  ),
                );
                return;
              }

              if (petWorldCubit.state.isLocationLocked &&
                  petWorldCubit.state.location == PetLocation.alimentar) {
                await petWorldCubit.updateWorld(
                  mascota: mascota,
                  next: petWorldCubit.state.copyWith(
                    activity: PetActivity.idle,
                    isLocationLocked: false,
                    isNapTime: false,
                    clearFood: true,
                    simulatedAt: DateTime.now(),
                  ),
                );
              }
            },
          ),
          BlocListener<MissionCubit, MissionState>(
            listenWhen: (previous, current) =>
                previous.missions != current.missions ||
                previous.hasLoadedOnce != current.hasLoadedOnce,
            listener: (context, state) {
              if (!state.hasLoadedOnce) {
                _missionNotificationsReady = false;
                _knownMissionIds = <String>{};
                return;
              }

              final currentIds = state.missions.map((m) => m.id).toSet();
              if (!_missionNotificationsReady) {
                _knownMissionIds = currentIds;
                _missionNotificationsReady = true;
                return;
              }

              final nuevas = state.missions
                  .where((mission) => !_knownMissionIds.contains(mission.id))
                  .toList();
              _knownMissionIds = currentIds;
              if (nuevas.isEmpty) return;

              final message = nuevas.length == 1
                  ? 'Nueva mision: ${_missionTitle(nuevas.first)}'
                  : 'Tienes ${nuevas.length} misiones nuevas';

              final messenger = _messengerKey.currentState;
              messenger?.hideCurrentSnackBar();
              messenger?.showSnackBar(
                SnackBar(
                  content: Text(message),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
        child: MaterialApp.router(
          title: 'CuidARHuellitas',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: _messengerKey,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF8AE670),
            ),
            fontFamily: 'Nunito',
          ),
          routerConfig: appRouter,
          builder: (context, child) {
            final currentPath =
                appRouter.routeInformationProvider.value.uri.path;
            final shouldShowDisasterOverlay = _shouldShowDisasterOverlay(
              currentPath,
            );

            if (!shouldShowDisasterOverlay || child == null) {
              return child ?? const SizedBox.shrink();
            }

            final mascotaId =
                context.watch<PetCubit>().state.mascota?.idMascota ?? '';
            return DisasterOverlay(
              mascotaId: mascotaId,
              currentPath: currentPath,
              child: child,
            );
          },
        ),
      ),
    );
  }

  bool _shouldShowDisasterOverlay(String path) {
    return !(path == AppRoutes.login ||
        path == AppRoutes.register ||
        path == AppRoutes.adopcion);
  }

  static String _missionTitle(PendingMission mission) {
    switch (mission.kind) {
      case MissionKind.recogerComida:
        return 'Recoge la comida tirada';
      case MissionKind.recogerJuguete:
        return 'Recoge los juguetes';
      case MissionKind.recogerBasura:
        return 'Limpia la basura';
      case MissionKind.desconocida:
        return 'Nueva mision activa';
    }
  }
}
