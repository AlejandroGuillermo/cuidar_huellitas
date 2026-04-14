import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/pet_cubit.dart';
import '../cubit/pet_state.dart';
import '../models/mascota_model.dart';
import 'header_widget.dart';

class ActionScreenHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitlePrefix; // Ej: "Hora de comer"
  final String statLabel;      // Ej: "Hambre:"
  
  // ¡MAGIA!: Una función para decirle qué estadística de la mascota debe leer
  final int Function(MascotaModel) statSelector; 
  final List<Color> barColors;

  const ActionScreenHeader({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitlePrefix,
    required this.statLabel,
    required this.statSelector,
    required this.barColors,
  });

  @override
  Widget build(BuildContext context) {
    // El BlocBuilder vive AQUÍ adentro, no en tus pantallas.
    return BlocBuilder<PetCubit, PetState>(
      builder: (context, state) {
        final mascota = state.mascota;
        final String nombre = mascota?.nombreMascota ?? 'Cargando...';
        
        // Usamos la función que nos pasaron para sacar el valor correcto (hambre, energía, etc.)
        final int statValue = mascota != null ? statSelector(mascota) : 0;
        final barraWidth = MediaQuery.of(context).size.width * 0.25;

        return HeaderWidget(
          leftContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Color(0xFF708BE6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$subtitlePrefix $nombre',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
          rightContent: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                statLabel,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: barraWidth,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (statValue / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: barColors),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$statValue%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      // Cambia el color si es muy bajo (opcional)
                      color: statValue < 30 ? const Color(0xFFE24B4A) : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}