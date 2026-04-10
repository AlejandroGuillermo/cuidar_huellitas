import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  final Widget leftContent;
  final Widget rightContent;

  const HeaderWidget({
    super.key,
    required this.leftContent,
    required this.rightContent,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenemos las medidas dinámicas
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final paddingLateral = screenWidth * 0.05;

    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 16, // Cubre la barra de estado dinámicamente
        bottom: 16,
        left: paddingLateral,
        right: paddingLateral,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center, // Centra verticalmente los elementos
        children: [
          // Lado izquierdo: Ocupa todo el espacio disponible
          Expanded(
            child: leftContent,
          ),
          
          // Espacio dinámico central
          SizedBox(width: screenWidth * 0.02),
          
          // Lado derecho: Ocupa solo lo necesario
          rightContent,
        ],
      ),
    );
  }
}