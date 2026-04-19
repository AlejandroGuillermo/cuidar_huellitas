import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../screens/adoption/adoption_view_data.dart';

class BarraHeaderAdopcion extends StatelessWidget {
  const BarraHeaderAdopcion({super.key, required this.alRegresar});

  final VoidCallback alRegresar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: alRegresar,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textoPrincipal,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Text(
            'Adopcion',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textoSecundario,
            ),
          ),
        ),
      ],
    );
  }
}

class TarjetaHeroAdopcion extends StatelessWidget {
  const TarjetaHeroAdopcion({
    super.key,
    required this.mascota,
    required this.personalidad,
    required this.nombre,
    required this.animacionFlotacion,
  });

  final OpcionMascotaAdopcion mascota;
  final OpcionPersonalidadAdopcion personalidad;
  final String nombre;
  final Animation<double> animacionFlotacion;

  @override
  Widget build(BuildContext context) {
    final colorAcento = Color(mascota.colorAcentoValor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorAcento,
            colorAcento.withValues(alpha: 0.82),
            AppColors.azulClaro,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colorAcento.withValues(alpha: 0.26),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Tu companero digital',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Adopta una mascota con mas personalidad',
            style: TextStyle(
              fontSize: 28,
              height: 1.05,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Elige el tipo, define su personalidad y ponle un nombre antes de comenzar.',
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          _EscenarioMascota(
            mascota: mascota,
            animacionFlotacion: animacionFlotacion,
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Text(
                nombre,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${mascota.nombre} • ${personalidad.nombre}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _PildoraHero(valor: mascota.etiqueta),
                  _PildoraHero(valor: personalidad.resumen),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SelectorTipoAdopcion extends StatelessWidget {
  const SelectorTipoAdopcion({
    super.key,
    required this.opciones,
    required this.tipoSeleccionado,
    required this.alSeleccionar,
  });

  final List<OpcionMascotaAdopcion> opciones;
  final String tipoSeleccionado;
  final ValueChanged<String> alSeleccionar;

  @override
  Widget build(BuildContext context) {
    return TarjetaSeccionAdopcion(
      titulo: '1. Elige quien te va a acompanar',
      hijo: Row(
        children: opciones.map((opcion) {
          final estaSeleccionada = opcion.id == tipoSeleccionado;
          final colorAcento = Color(opcion.colorAcentoValor);

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: opcion.id == opciones.first.id ? 10 : 0,
              ),
              child: GestureDetector(
                onTap: () => alSeleccionar(opcion.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: estaSeleccionada
                        ? Color(opcion.colorAcentoSuaveValor)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: estaSeleccionada ? colorAcento : AppColors.borde,
                      width: estaSeleccionada ? 2.3 : 1.2,
                    ),
                    boxShadow: estaSeleccionada
                        ? [
                            BoxShadow(
                              color: colorAcento.withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            opcion.emoji,
                            style: const TextStyle(fontSize: 34),
                          ),
                          const Spacer(),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: estaSeleccionada
                                  ? colorAcento
                                  : const Color(0xFFF1F3EA),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              estaSeleccionada ? 'Activo' : 'Elegir',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: estaSeleccionada
                                    ? Colors.white
                                    : AppColors.textoSecundario,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        opcion.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        opcion.etiqueta,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textoSecundario,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          opcion.descripcion,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textoPrincipal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class TarjetaNombreAdopcion extends StatelessWidget {
  const TarjetaNombreAdopcion({
    super.key,
    required this.controlador,
    required this.valorCompania,
    required this.valorEstilo,
    required this.colorConexionValor,
    required this.colorCompaniaValor,
    required this.alCambiar,
    required this.alGenerarOtro,
  });

  final TextEditingController controlador;
  final String valorCompania;
  final String valorEstilo;
  final int colorConexionValor;
  final int colorCompaniaValor;
  final ValueChanged<String> alCambiar;
  final VoidCallback alGenerarOtro;

  @override
  Widget build(BuildContext context) {
    return TarjetaSeccionAdopcion(
      titulo: '3. Dale su nombre',
      hijo: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borde),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_rounded, color: AppColors.azulPrincipal),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controlador,
                    onChanged: alCambiar,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textoPrincipal,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Escribe un nombre',
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: alGenerarOtro,
                  icon: const Icon(Icons.casino_outlined, size: 18),
                  label: const Text('Otro'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.azulPrincipal,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PildoraMiniInfo(
                  icono: Icons.favorite_rounded,
                  etiqueta: 'Conexion',
                  valor: 'Alta',
                  colorAcento: Color(colorConexionValor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PildoraMiniInfo(
                  icono: Icons.pets_rounded,
                  etiqueta: 'Compania',
                  valor: valorCompania,
                  colorAcento: Color(colorCompaniaValor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PildoraMiniInfo(
                  icono: Icons.auto_awesome_rounded,
                  etiqueta: 'Estilo',
                  valor: valorEstilo,
                  colorAcento: AppColors.verdePrincipal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BarraInferiorAdopcion extends StatelessWidget {
  const BarraInferiorAdopcion({
    super.key,
    required this.titulo,
    required this.textoBoton,
    required this.colorBotonValor,
    required this.estaCargando,
    required this.alPresionar,
  });

  final String titulo;
  final String textoBoton;
  final int colorBotonValor;
  final bool estaCargando;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 18,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Listo para adoptar',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textoPrincipal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: estaCargando ? null : alPresionar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(colorBotonValor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: estaCargando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        textoBoton,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SeccionPersonalidad extends StatelessWidget {
  const SeccionPersonalidad({
    super.key,
    required this.personalidades,
    required this.personalidadSeleccionada,
    required this.alSeleccionar,
  });

  final List<Map<String, dynamic>> personalidades;
  final Map<String, dynamic> personalidadSeleccionada;
  final ValueChanged<Map<String, dynamic>> alSeleccionar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5EBDD)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '2. Define su personalidad',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A2E1A),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: personalidades.map((personalidad) {
                final estaSeleccionada =
                    personalidad['nombre'] ==
                    personalidadSeleccionada['nombre'];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => alSeleccionar(personalidad),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: estaSeleccionada
                            ? const Color(0xFF6F88E8)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: estaSeleccionada
                              ? const Color(0xFF6F88E8)
                              : const Color(0xFFE2E8DA),
                        ),
                        boxShadow: estaSeleccionada
                            ? const [
                                BoxShadow(
                                  color: Color.fromRGBO(111, 136, 232, 0.18),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            personalidad['emoji'] as String,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            personalidad['nombre'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: estaSeleccionada
                                  ? Colors.white
                                  : const Color(0xFF1A2E1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD9E6FF)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.04),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        personalidadSeleccionada['emoji'] as String,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            personalidadSeleccionada['nombre'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5E79D8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            personalidadSeleccionada['resumen'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Color(0xFF24324A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  children:
                      (personalidadSeleccionada['comportamientos']
                              as List<String>)
                          .map(
                            (item) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    margin: const EdgeInsets.only(top: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF8AE670,
                                      ).withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      '✓',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2C7A2C),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.35,
                                        color: Color(0xFF1A2E1A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SeccionResumenAdopcion extends StatelessWidget {
  const SeccionResumenAdopcion({
    super.key,
    required this.nombreMascota,
    required this.tipoMascota,
    required this.emojiMascota,
    required this.personalidadSeleccionada,
  });

  final String nombreMascota;
  final String tipoMascota;
  final String emojiMascota;
  final Map<String, dynamic> personalidadSeleccionada;

  @override
  Widget build(BuildContext context) {
    final chips = (personalidadSeleccionada['comportamientos'] as List<String>)
        .take(3)
        .toList();

    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 120),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5EBDD)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen antes de adoptar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A2E1A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Asi se vera tu companero al comenzar la experiencia',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B786A)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Vista final',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5E79D8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD9E6FF)),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF6F9FF), Color(0xFFEEF5FF)],
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombreMascota,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A2E1A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$tipoMascota • ${personalidadSeleccionada['nombre']}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B786A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFDCE6FF)),
                        ),
                        child: const Text(
                          'Tu mascota',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6F88E8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 240),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white70),
                      gradient: const RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.15,
                        colors: [
                          Colors.white,
                          Color(0xFFF4F9EE),
                          Color(0xFFEAF6E4),
                        ],
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 64,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color.fromRGBO(138, 230, 112, 0.0),
                                  Color.fromRGBO(138, 230, 112, 0.16),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 18,
                          child: Container(
                            width: 112,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFB8D8B2,
                              ).withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFB8D8B2,
                                  ).withValues(alpha: 0.18),
                                  blurRadius: 14,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          emojiMascota,
                          style: const TextStyle(fontSize: 112, height: 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < chips.length; i++)
                _ChipResumen(
                  etiqueta: chips[i],
                  fondo: _fondoChip(i),
                  colorTexto: _colorTextoChip(i),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9EFE1)),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Color(0xFF1A2E1A),
                ),
                children: [
                  const TextSpan(
                    text: 'Que puedes esperar: ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: personalidadSeleccionada['resumen'] as String),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9EFE1)),
            ),
            child: const Text(
              'Todo listo para comenzar una experiencia de cuidado responsable.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Color(0xFF6B786A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _fondoChip(int indice) {
    switch (indice % 3) {
      case 0:
        return const Color(0xFFEEF3FF);
      case 1:
        return const Color(0xFFF0FFF0);
      default:
        return const Color(0xFFFFF4F6);
    }
  }

  Color _colorTextoChip(int indice) {
    switch (indice % 3) {
      case 0:
        return const Color(0xFF5E79D8);
      case 1:
        return const Color(0xFF2A5C14);
      default:
        return const Color(0xFFC95C7B);
    }
  }
}

class TarjetaSeccionAdopcion extends StatelessWidget {
  const TarjetaSeccionAdopcion({
    super.key,
    required this.titulo,
    required this.hijo,
  });

  final String titulo;
  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textoPrincipal,
            ),
          ),
          const SizedBox(height: 16),
          hijo,
        ],
      ),
    );
  }
}

class OrbeBrilloAdopcion extends StatelessWidget {
  const OrbeBrilloAdopcion({
    super.key,
    required this.tamano,
    required this.color,
  });

  final double tamano;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _EscenarioMascota extends StatelessWidget {
  const _EscenarioMascota({
    required this.mascota,
    required this.animacionFlotacion,
  });

  final OpcionMascotaAdopcion mascota;
  final Animation<double> animacionFlotacion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Container(
        height: 320,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  mascota.etiqueta,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 64,
              left: 22,
              right: 22,
              bottom: 26,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 18,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.28),
                              Colors.white.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 18,
                      child: Container(
                        width: 168,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      child: Container(
                        width: 190,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: animacionFlotacion,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, animacionFlotacion.value),
                          child: child,
                        );
                      },
                      child: Text(
                        mascota.emoji,
                        style: const TextStyle(fontSize: 132, height: 1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PildoraHero extends StatelessWidget {
  const _PildoraHero({required this.valor});

  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        valor,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ChipResumen extends StatelessWidget {
  const _ChipResumen({
    required this.etiqueta,
    required this.fondo,
    required this.colorTexto,
  });

  final String etiqueta;
  final Color fondo;
  final Color colorTexto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        etiqueta,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colorTexto,
        ),
      ),
    );
  }
}

class _PildoraMiniInfo extends StatelessWidget {
  const _PildoraMiniInfo({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.colorAcento,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;
  final Color colorAcento;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: colorAcento),
          const SizedBox(height: 8),
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}
