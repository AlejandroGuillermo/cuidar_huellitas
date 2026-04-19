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
import 'domain/enums/pet_activity.dart';
import 'domain/enums/pet_location.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
              final petWorldCubit = context.read<PetWorldCubit>();
              final missionCubit = context.read<MissionCubit>();
              final disasterCubit = context.read<DisasterCubit>();

              await petWorldCubit.bootstrap(mascota);
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
                    clearFood: true,
                    clearToy: true,
                    simulatedAt: DateTime.now(),
                  ),
                );
                return;
              }

              await petWorldCubit.bootstrap(mascota);
            },
          ),
        ],
        child: MaterialApp.router(
          title: 'CuidARHuellitas',
          debugShowCheckedModeBanner: false,
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
            return DisasterOverlay(mascotaId: mascotaId, child: child);
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
}
