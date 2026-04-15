import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/app_router.dart';
import 'core/disaster_system.dart';
import 'cubit/pet_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PetCubit()..cargarMascota(),
        ),
        BlocProvider(
          create: (context) => DisasterCubit(),
        ),
      ],
      child: MaterialApp.router(
        title: 'CuidARHuellitas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8AE670)),
          fontFamily: 'Nunito',
        ),
        routerConfig: appRouter,
        // DisasterOverlay envuelve toda la app — los objetos flotan sobre cualquier pantalla
        builder: (context, child) {
          final mascotaId = context.watch<PetCubit>().state.mascota?.idMascota ?? '';
          return DisasterOverlay(
            mascotaId: mascotaId,
            child: child!,
          );
        },
      ),
    );
  }
}