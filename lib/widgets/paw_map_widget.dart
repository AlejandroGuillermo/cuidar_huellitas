import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_colors.dart';
import '../core/app_router.dart';

Future<void> mostrarMapaHuella(BuildContext context) async {
  final selectedAction = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
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
                  color: Color(0xFF708BE6),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 300,
                height: 300,
                child: const PawMapWidget(),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (!context.mounted || selectedAction == null) return;

  switch (selectedAction) {
    case 'alimentar':
      context.go(AppRoutes.alimentar);
      break;
    case 'jugar':
      context.go(AppRoutes.jugar);
      break;
    case 'curar':
      context.go(AppRoutes.curar);
      break;
    case 'banar':
      context.go(AppRoutes.banar);
      break;
    case 'dormir':
      context.go(AppRoutes.dormir);
      break;
  }
}

class PawMapWidget extends StatelessWidget {
  const PawMapWidget({super.key});

  void _openAction(BuildContext context, String actionId) {
    Navigator.of(context, rootNavigator: true).pop(actionId);
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {
        'icon': Icons.flatware,
        'label': 'Alimentar',
        'id': 'alimentar',
        'align': const Alignment(-0.6, -0.7),
      },
      {
        'icon': Icons.toys_outlined,
        'label': 'Jugar',
        'id': 'jugar',
        'align': const Alignment(0.6, -0.7),
      },
      {
        'icon': Icons.local_hospital,
        'label': 'Curar',
        'id': 'curar',
        'align': const Alignment(0.0, -0.3),
      },
      {
        'icon': Icons.bathtub,
        'label': 'Bañar',
        'id': 'banar',
        'align': const Alignment(-0.8, 0.3),
      },
      {
        'icon': Icons.king_bed_outlined,
        'label': 'Dormir',
        'id': 'dormir',
        'align': const Alignment(0.8, 0.3),
      },
    ];

    return Stack(
      children: [
        Align(
          alignment: const Alignment(0.0, 0.8),
          child: Container(
            width: 120,
            height: 100,
            decoration: BoxDecoration(
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
                final actionId = action['id'] as String;

                if (actionId == 'alimentar' ||
                    actionId == 'jugar' ||
                    actionId == 'curar' ||
                    actionId == 'banar' ||
                    actionId == 'dormir') {
                  _openAction(context, actionId);
                } else {
                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Próximamente: ${action['label']} 🐾'),
                    ),
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
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      action['icon'],
                      size: 32,
                      color: AppColors.verdePrincipal,
                    ),
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
