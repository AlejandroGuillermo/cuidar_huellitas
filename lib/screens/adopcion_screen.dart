import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuidar_huellitas/cubit/pet_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../Models/mascota_model.dart';
import '../core/app_colors.dart';
import '../core/app_router.dart';
import 'adoption/adoption_view_data.dart';
import '../widgets/adoption/adoption_widgets.dart';

class AdopcionScreen extends StatefulWidget {
  const AdopcionScreen({super.key});

  @override
  State<AdopcionScreen> createState() => _AdopcionScreenState();
}

class _AdopcionScreenState extends State<AdopcionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controladorHero;
  late final Animation<double> _animacionFlotacion;
  late final AnimationController _controladorContenido;
  late final Animation<double> _animacionEntrada;
  late final Animation<Offset> _animacionDesplazamiento;
  late final TextEditingController _controladorNombre;

  String _tipoSeleccionado = opcionesMascotaAdopcion.first.id;
  String _personalidadSeleccionada = opcionesPersonalidadAdopcion.first.nombre;
  String _nombreActual = '';
  bool _guardando = false;
  bool _mostrarCelebracion = false;

  OpcionMascotaAdopcion get _mascotaSeleccionada => opcionesMascotaAdopcion
      .firstWhere((opcion) => opcion.id == _tipoSeleccionado);

  OpcionPersonalidadAdopcion get _opcionPersonalidadSeleccionada =>
      opcionesPersonalidadAdopcion.firstWhere(
        (opcion) => opcion.nombre == _personalidadSeleccionada,
      );

  Map<String, dynamic> get _mapaPersonalidadSeleccionada => <String, dynamic>{
    'nombre': _opcionPersonalidadSeleccionada.nombre,
    'emoji': _opcionPersonalidadSeleccionada.emoji,
    'resumen': _opcionPersonalidadSeleccionada.resumen,
    'comportamientos': _opcionPersonalidadSeleccionada.comportamientos,
  };

  bool get _openedFromHome =>
      GoRouterState.of(context).uri.queryParameters['fromHome'] == 'true';

  @override
  void initState() {
    super.initState();
    _asignarSeleccionAleatoria();
    _controladorNombre = TextEditingController(text: _nombreActual);

    _controladorHero = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animacionFlotacion = Tween<double>(begin: -8, end: 10).animate(
      CurvedAnimation(parent: _controladorHero, curve: Curves.easeInOut),
    );

    _controladorContenido = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
    _animacionEntrada = CurvedAnimation(
      parent: _controladorContenido,
      curve: Curves.easeOutCubic,
    );
    _animacionDesplazamiento = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_animacionEntrada);
  }

  @override
  void dispose() {
    _controladorHero.dispose();
    _controladorContenido.dispose();
    _controladorNombre.dispose();
    super.dispose();
  }

  void _asignarSeleccionAleatoria() {
    final random = Random();
    _nombreActual = _nombreAleatorioPorTipo(_tipoSeleccionado, random);
    _personalidadSeleccionada =
        opcionesPersonalidadAdopcion[random.nextInt(
              opcionesPersonalidadAdopcion.length,
            )]
            .nombre;
  }

  String _nombreAleatorioPorTipo(String tipo, [Random? random]) {
    final origen = tipo == opcionesMascotaAdopcion.first.id
        ? nombresPerroAdopcion
        : nombresGatoAdopcion;
    final selector = random ?? Random();
    return origen[selector.nextInt(origen.length)];
  }

  void _seleccionarTipo(String tipo) {
    if (_tipoSeleccionado == tipo) return;

    _controladorContenido
      ..reset()
      ..forward();

    setState(() {
      _tipoSeleccionado = tipo;
      _asignarSeleccionAleatoria();
      _controladorNombre.text = _nombreActual;
    });
  }

  void _generarOtroNombre() {
    final nombreAleatorio = _nombreAleatorioPorTipo(_tipoSeleccionado);
    setState(() {
      _nombreActual = nombreAleatorio;
      _controladorNombre.text = nombreAleatorio;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final espacioSuperior = media.padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F2),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF7E4), Color(0xFFF7F9F2)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -50,
              child: OrbeBrilloAdopcion(
                tamano: 210,
                color: Color(
                  _mascotaSeleccionada.colorAcentoValor,
                ).withValues(alpha: 0.18),
              ),
            ),
            Positioned(
              top: 180,
              left: -30,
              child: OrbeBrilloAdopcion(
                tamano: 120,
                color: AppColors.verdePrincipal.withValues(alpha: 0.18),
              ),
            ),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        espacioSuperior > 0 ? 8 : 20,
                        20,
                        0,
                      ),
                      child: BarraHeaderAdopcion(
                        alRegresar: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _animacionEntrada,
                      child: SlideTransition(
                        position: _animacionDesplazamiento,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                          child: Column(
                            children: [
                              TarjetaHeroAdopcion(
                                mascota: _mascotaSeleccionada,
                                personalidad: _opcionPersonalidadSeleccionada,
                                nombre: _nombreActual,
                                animacionFlotacion: _animacionFlotacion,
                              ),
                              const SizedBox(height: 18),
                              SelectorTipoAdopcion(
                                opciones: opcionesMascotaAdopcion,
                                tipoSeleccionado: _tipoSeleccionado,
                                alSeleccionar: _seleccionarTipo,
                              ),
                              const SizedBox(height: 18),
                              SeccionPersonalidad(
                                personalidades: opcionesPersonalidadAdopcion
                                    .map(
                                      (opcion) => <String, dynamic>{
                                        'nombre': opcion.nombre,
                                        'emoji': opcion.emoji,
                                        'resumen': opcion.resumen,
                                        'comportamientos':
                                            opcion.comportamientos,
                                      },
                                    )
                                    .toList(),
                                personalidadSeleccionada:
                                    _mapaPersonalidadSeleccionada,
                                alSeleccionar: (personalidad) {
                                  setState(() {
                                    _personalidadSeleccionada =
                                        personalidad['nombre'] as String;
                                  });
                                },
                              ),
                              const SizedBox(height: 18),
                              TarjetaNombreAdopcion(
                                controlador: _controladorNombre,
                                valorCompania: _mascotaSeleccionada.nombre,
                                valorEstilo:
                                    _opcionPersonalidadSeleccionada.nombre,
                                colorConexionValor:
                                    _opcionPersonalidadSeleccionada
                                        .colorAcentoValor,
                                colorCompaniaValor:
                                    _mascotaSeleccionada.colorAcentoValor,
                                alCambiar: (valor) =>
                                    setState(() => _nombreActual = valor),
                                alGenerarOtro: _generarOtroNombre,
                              ),
                              const SizedBox(height: 18),
                              SeccionResumenAdopcion(
                                nombreMascota: _nombreActual.isEmpty
                                    ? 'Sin nombre'
                                    : _nombreActual,
                                tipoMascota: _mascotaSeleccionada.nombre,
                                emojiMascota: _mascotaSeleccionada.id,
                                personalidadSeleccionada:
                                    _mapaPersonalidadSeleccionada,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            BarraInferiorAdopcion(
              titulo:
                  'Adoptar a ${_nombreActual.isEmpty ? 'tu mascota' : _nombreActual}',
              textoBoton: 'Adoptar',
              colorBotonValor: _mascotaSeleccionada.colorAcentoValor,
              estaCargando: _guardando,
              alPresionar: _adoptar,
            ),
            if (_mostrarCelebracion)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.18),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 360),
                          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 26,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.celebration_rounded,
                                    color: AppColors.azulPrincipal,
                                    size: 24,
                                  ),
                                  SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      'Felicidades',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(
                                    Icons.celebration_rounded,
                                    color: AppColors.azulPrincipal,
                                    size: 24,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Adoptaste a $_nombreActual.\n'
                                'Es un $_tipoSeleccionado $_personalidadSeleccionada.\n\n'
                                '${_opcionPersonalidadSeleccionada.resumen}',
                                style: const TextStyle(
                                  color: AppColors.textoPrincipal,
                                  fontSize: 15,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.azulPrincipal,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: _irAHomeTrasAdopcion,
                                  child: const Text('Vamos'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _irAHomeTrasAdopcion() {
    FocusScope.of(context).unfocus();
    if (_openedFromHome) {
      Navigator.of(context).pop(true);
      return;
    }
    appRouter.go(AppRoutes.home);
  }

  Future<void> _adoptar() async {
    setState(() => _guardando = true);
    final petCubit = context.read<PetCubit>();

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('No hay un usuario con sesion iniciada');
      }

      FocusScope.of(context).unfocus();

      final mascotasRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('mascotas');
      final referenciaMascota = mascotasRef.doc();

      final mascota = MascotaModel(
        idMascota: referenciaMascota.id,
        nombreMascota: _nombreActual,
        tipoMascota: _tipoSeleccionado,
        rasgo: _personalidadSeleccionada,
        ultimaInteraccion: DateTime.now(),
      );

      final batch = FirebaseFirestore.instance.batch();
      final mascotasActivas = await mascotasRef
          .where('activa', isEqualTo: true)
          .get();
      for (final doc in mascotasActivas.docs) {
        batch.update(doc.reference, {'activa': false});
      }
      batch.set(referenciaMascota, mascota.toFirestore());
      await batch.commit();
      await petCubit.cargarMascota();

      if (!mounted) return;
      setState(() => _mostrarCelebracion = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hubo un error al adoptar: $e')));
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }
}
