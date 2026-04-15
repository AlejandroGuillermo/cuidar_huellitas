import 'package:cuidar_huellitas/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_router.dart';
import '../widgets/action_screen_header.dart';

class DormirScreen extends StatefulWidget {
  const DormirScreen({super.key});

  @override
  State<DormirScreen> createState() => _DormirScreenState();
}

class _DormirScreenState extends State<DormirScreen> {
  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Azul muy oscuro (Noche)
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          // Deslizar hacia la DERECHA (dx positivo)
          if (details.delta.dx > 0) {
            setState(() => _dragOffset =
                (_dragOffset + details.delta.dx).clamp(0, size.width));
          }
        },
        onHorizontalDragEnd: (details) {
          if (_dragOffset > size.width * 0.3 ||
              (details.primaryVelocity ?? 0) > 500) {
            context.go(AppRoutes.home);
          } else {
            setState(() => _dragOffset = 0);
          }
        },
        child: Stack(
          children: [
            // Pantalla de Home "asomándose" por la derecha al volver
            Transform.translate(
              offset: Offset(_dragOffset - size.width, 0),
              child: Container(color: const Color(0xFF8AE670)),
            ),

            // Contenido de la habitación
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: _buildDormirBody(size),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDormirBody(Size size) {
    return Stack(
      children: [
        // Estrellas y Luna
        const Positioned(top: 100, right: 50, child: Text('🌙', style: TextStyle(fontSize: 60))),
        const Positioned(top: 150, left: 80, child: Text('⭐', style: TextStyle(fontSize: 20))),
        
        Column(
          children: [
            ActionScreenHeader(
              icon: Icons.bed,
              title: 'Habitación',
              subtitlePrefix: '¡Shhh! Está descansando',
              statLabel: 'Energía:',
              statSelector: (m) => m.nivelEnergia,
              barColors: [const Color(0xFFF9A857), AppColors.nivelEnergia],
            ),
            const Spacer(),
            const Text('💤', style: TextStyle(fontSize: 40)),
            const Text('🐶', style: TextStyle(fontSize: 100)), // Aquí irá tu mascota
            const SizedBox(height: 100),
          ],
        ),
      ],
    );
  }
}