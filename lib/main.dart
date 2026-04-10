import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/app_router.dart';
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
    // Usamos MultiBlocProvider por si en el futuro queremos agregar más cubits.
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PetCubit()..cargarMascota(),
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
      ),
    );
  }
}