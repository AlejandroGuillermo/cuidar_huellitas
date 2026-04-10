import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_router.dart';
import '../core/app_colors.dart';

// ── FUNCIÓN GLOBAL PARA ABRIR EL MAPA DESDE CUALQUIER PANTALLA ──
void mostrarMapaHuella(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🐾 Mapa de Acciones',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  // Cambia esto si tu color azul se llama diferente en AppColors
                  color: Color(0xFF708BE6), 
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 300,
                height: 300,
                child: PawMapWidget(), // Llamamos al widget de abajo
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ── WIDGET DEL MAPA DE HUELLAS ──
class PawMapWidget extends StatelessWidget {
  const PawMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {'emoji': '🍖', 'label': 'Alimentar', 'id': 'alimentar', 'align': const Alignment(-0.6, -0.7)},
      {'emoji': '🎾', 'label': 'Jugar',     'id': 'jugar',     'align': const Alignment(0.6, -0.7)},
      {'emoji': '💊', 'label': 'Curar',     'id': 'curar',     'align': const Alignment(0.0, -0.3)},
      {'emoji': '🛁', 'label': 'Bañar',     'id': 'banar',     'align': const Alignment(-0.8, 0.3)},
      {'emoji': '😴', 'label': 'Dormir',    'id': 'dormir',    'align': const Alignment(0.8, 0.3)},
    ];

    return Stack(
      children: [
        Align(
          alignment: const Alignment(0.0, 0.8),
          child: Container(
            width: 120,
            height: 100,
            decoration: BoxDecoration(
              // Usé tu AppColors aquí
              color: AppColors.verdeClaro.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
        ...actions.map((action) {
          return Align(
            alignment: action['align'] as Alignment,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context); // Cierra el modal
                
                if (action['id'] == 'alimentar') {
                  context.go(AppRoutes.alimentar);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Próximamente: ${action['label']} 🐾')),
                  );
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.verdeClaro, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(action['emoji'], style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    action['label'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}