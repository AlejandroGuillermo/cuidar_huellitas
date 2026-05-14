import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/models/pet_ai_decision.dart';
import '../core/enums/pet_emotion.dart';
import '../core/enums/pet_need.dart';
import '../data/repositories/user_repository.dart';
import 'app_router.dart';

const String disasterScreenAll = 'all';
const String disasterScreenHome = 'home';
const String disasterScreenAlimentar = 'alimentar';
const String disasterScreenJugar = 'jugar';
const String disasterScreenDormir = 'dormir';
const int _defaultMissionRewardCoins = 5;

enum DisasterType { comida, juguete, basura, porcion }

class DisasterObject {
  final String id;
  final String sourceDocId;
  final DisasterType tipo;
  final String emoji;
  final String pantalla;
  final Offset posicion;
  final double escala;

  const DisasterObject({
    required this.id,
    required this.sourceDocId,
    required this.tipo,
    required this.emoji,
    required this.pantalla,
    required this.posicion,
    required this.escala,
  });
}

class DisasterState {
  final List<DisasterObject> objetos;
  final bool hayDesastre;

  const DisasterState({this.objetos = const [], this.hayDesastre = false});

  DisasterState copyWith({List<DisasterObject>? objetos, bool? hayDesastre}) {
    return DisasterState(
      objetos: objetos ?? this.objetos,
      hayDesastre: hayDesastre ?? this.hayDesastre,
    );
  }
}

class DisasterCubit extends Cubit<DisasterState> {
  final Random _random = Random();
  final UserRepository _userRepository = UserRepository();
  static const List<String> _toyIds = ['1', '2', '3', '4', '5', '6'];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pendingSub;
  String? _activeMascotaId;

  DisasterCubit() : super(const DisasterState());

  Future<void> verificarDesastre(String mascotaId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null || mascotaId.isEmpty) {
        await _stopWatching();
        emit(const DisasterState());
        return;
      }

      if (_activeMascotaId == mascotaId && _pendingSub != null) {
        return;
      }

      await _stopWatching();
      _activeMascotaId = mascotaId;
      _pendingSub = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId)
          .collection('desastres_pendientes')
          .where('recogido', isEqualTo: false)
          .snapshots()
          .listen((snap) {
            emit(_buildStateFromSnapshot(snap));
          });

      final snap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId)
          .collection('desastres_pendientes')
          .where('recogido', isEqualTo: false)
          .get();

      if (snap.docs.isEmpty) {
        emit(const DisasterState());
        return;
      }

      final objetos = <DisasterObject>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final tipo = _parseTipo(data['tipo'] as String? ?? 'comida');
        if (tipo == DisasterType.juguete) {
          continue;
        }
        final cantidad = (data['cantidad'] as int?) ?? 1;
        final pantalla = _normalizarPantalla(data['pantalla'] as String?);

        for (int i = 0; i < cantidad; i++) {
          objetos.add(
            DisasterObject(
              id: '${doc.id}_$i',
              sourceDocId: doc.id,
              tipo: tipo,
              emoji: data['emoji'] as String? ?? '🍖',
              pantalla: pantalla,
              posicion: Offset(
                0.05 + _random.nextDouble() * 0.85,
                0.10 + _random.nextDouble() * 0.70,
              ),
              escala: 0.8 + _random.nextDouble() * 0.6,
            ),
          );
        }
      }

      emit(state.copyWith(objetos: objetos, hayDesastre: objetos.isNotEmpty));
    } catch (e) {
      debugPrint('Error verificando desastre: $e');
    }
  }

  Future<void> generarDesastre({
    required String mascotaId,
    required DisasterType tipo,
    required String emoji,
    required int cantidad,
    String pantalla = disasterScreenAll,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final pantallaNormalizada = _normalizarPantalla(
        tipo == DisasterType.juguete && pantalla == disasterScreenAll
            ? disasterScreenJugar
            : pantalla,
      );
      final toyIds = tipo == DisasterType.juguete
          ? _pickToyIds(cantidad)
          : const <String>[];

      final docRef = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId)
          .collection('desastres_pendientes')
          .add({
            'tipo': tipo.name,
            'emoji': emoji,
            'cantidad': cantidad,
            'pantalla': pantallaNormalizada,
            'recogido': false,
            'fecha': FieldValue.serverTimestamp(),
            if (toyIds.isNotEmpty) 'toy_ids': toyIds,
          });

      if (tipo == DisasterType.juguete) {
        return;
      }

      final nuevos = List<DisasterObject>.from(state.objetos);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      for (int i = 0; i < cantidad; i++) {
        nuevos.add(
          DisasterObject(
            id: 'live_${timestamp}_$i',
            sourceDocId: docRef.id,
            tipo: tipo,
            emoji: emoji,
            pantalla: pantallaNormalizada,
            posicion: Offset(
              0.05 + _random.nextDouble() * 0.85,
              0.10 + _random.nextDouble() * 0.70,
            ),
            escala: 0.8 + _random.nextDouble() * 0.6,
          ),
        );
      }

      emit(state.copyWith(objetos: nuevos, hayDesastre: nuevos.isNotEmpty));
    } catch (e) {
      debugPrint('Error generando desastre: $e');
    }
  }

  Future<void> generarDesastreDistribuido({
    required String mascotaId,
    required DisasterType tipo,
    required String emoji,
    required Map<String, int> cantidadPorPantalla,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final nuevos = List<DisasterObject>.from(state.objetos);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      for (final entry in cantidadPorPantalla.entries) {
        final cantidad = entry.value;
        if (cantidad <= 0) continue;

        final pantalla = _normalizarPantalla(entry.key);

        final docRef = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .collection('mascotas')
            .doc(mascotaId)
            .collection('desastres_pendientes')
            .add({
              'tipo': tipo.name,
              'emoji': emoji,
              'cantidad': cantidad,
              'pantalla': pantalla,
              'recogido': false,
              'fecha': FieldValue.serverTimestamp(),
            });

        for (int i = 0; i < cantidad; i++) {
          nuevos.add(
            DisasterObject(
              id: 'live_${timestamp}_${pantalla}_$i',
              sourceDocId: docRef.id,
              tipo: tipo,
              emoji: emoji,
              pantalla: pantalla,
              posicion: Offset(
                0.05 + _random.nextDouble() * 0.85,
                0.10 + _random.nextDouble() * 0.70,
              ),
              escala: 0.8 + _random.nextDouble() * 0.6,
            ),
          );
        }
      }

      emit(state.copyWith(objetos: nuevos, hayDesastre: nuevos.isNotEmpty));
    } catch (e) {
      debugPrint('Error generando desastre distribuido: $e');
    }
  }

  Future<void> triggerFromAiDecision(PetAiDecision decision) async {
    final mascotaId = _activeMascotaId;
    if (mascotaId == null || mascotaId.isEmpty) return;

    var probability = 0.10;
    var tipo = DisasterType.values[_random.nextInt(DisasterType.values.length)];
    var emoji = '🍂';
    var pantalla = disasterScreenAll;
    var cantidad = 1;

    if (decision.emotion == PetEmotion.dirty ||
        decision.needPriority == PetNeed.hygiene) {
      probability = 0.35;
      tipo = DisasterType.basura;
      emoji = '🗑️';
      pantalla = disasterScreenHome;
      cantidad = 1 + _random.nextInt(decision.anomaliaActiva ? 2 : 1);
    } else if (decision.emotion == PetEmotion.hungry ||
        decision.needPriority == PetNeed.hunger) {
      probability = 0.28;
      tipo = _random.nextBool() ? DisasterType.comida : DisasterType.porcion;
      emoji = tipo == DisasterType.porcion ? '🥣' : '🍖';
      pantalla = disasterScreenAlimentar;
    } else if (decision.emotion == PetEmotion.bored ||
        decision.needPriority == PetNeed.affection) {
      probability = 0.22;
      tipo = DisasterType.juguete;
      emoji = '🧸';
      pantalla = disasterScreenJugar;
    }

    if (decision.anomaliaActiva) {
      probability *= 1.5;
    }

    probability = probability.clamp(0.05, 0.75).toDouble();
    if (_random.nextDouble() > probability) return;

    await generarDesastre(
      mascotaId: mascotaId,
      tipo: tipo,
      emoji: emoji,
      cantidad: cantidad,
      pantalla: pantalla,
    );
  }

  Future<void> recogerObjeto(String objetoId, String mascotaId) async {
    final objetivo = state.objetos.cast<DisasterObject?>().firstWhere(
      (o) => o?.id == objetoId,
      orElse: () => null,
    );
    if (objetivo == null) return;

    await _descontarObjetoPersistido(
      mascotaId: mascotaId,
      sourceDocId: objetivo.sourceDocId,
    );

    final actualizados = state.objetos.where((o) => o.id != objetoId).toList();
    emit(
      state.copyWith(
        objetos: actualizados,
        hayDesastre: actualizados.isNotEmpty,
      ),
    );
  }

  Future<void> _descontarObjetoPersistido({
    required String mascotaId,
    required String sourceDocId,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final disasterRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('mascotas')
        .doc(mascotaId)
        .collection('desastres_pendientes')
        .doc(sourceDocId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(disasterRef);
      if (!snap.exists) return;

      final data = snap.data() ?? <String, dynamic>{};
      final cantidadActual = (data['cantidad'] as num?)?.toInt() ?? 0;
      if (cantidadActual <= 0) {
        tx.set(disasterRef, {'recogido': true}, SetOptions(merge: true));
        return;
      }

      final nuevaCantidad = cantidadActual - 1;
      tx.set(disasterRef, {
        'cantidad': nuevaCantidad,
        'recogido': nuevaCantidad <= 0,
        if (nuevaCantidad <= 0) 'fecha_recogido': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    await _completarMisionesSiYaNoQuedaComida(
      userId: userId,
      mascotaId: mascotaId,
    );
  }

  Future<void> _completarMisionesSiYaNoQuedaComida({
    required String userId,
    required String mascotaId,
  }) async {
    final restantes = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('mascotas')
        .doc(mascotaId)
        .collection('desastres_pendientes')
        .where('recogido', isEqualTo: false)
        .get();

    final quedaComida = restantes.docs.any((doc) {
      final tipo = (doc.data()['tipo'] as String?) ?? '';
      return tipo == 'comida' || tipo == 'porcion';
    });
    if (quedaComida) return;

    final coinsGanadas = await _completarMisionesRecogerComida(
      userId: userId,
      mascotaId: mascotaId,
    );
    if (coinsGanadas > 0) {
      await _sumarMonedasUsuario(userId: userId, coins: coinsGanadas);
    }
  }

  Future<int> _completarMisionesRecogerComida({
    required String userId,
    required String mascotaId,
  }) async {
    try {
      final misionesRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId)
          .collection('misiones_activas');

      final pending = await misionesRef
          .where('estado', isEqualTo: 'pendiente')
          .get();
      final ahora = Timestamp.now();
      final batch = FirebaseFirestore.instance.batch();
      var tieneCambios = false;
      var coinsGanadas = 0;

      for (final doc in pending.docs) {
        final data = doc.data();
        final tipo = _normalizarTipoMision(doc.id, data);
        if (tipo != 'recoger_comida') continue;
        coinsGanadas += _rewardCoinsFromMissionData(data);
        batch.update(doc.reference, {
          'estado': 'completada',
          'fecha_completada': ahora,
        });
        tieneCambios = true;
      }

      if (tieneCambios) await batch.commit();
      return tieneCambios ? coinsGanadas : 0;
    } catch (e) {
      debugPrint('Error completando mision recoger comida: $e');
      return 0;
    }
  }

  int _rewardCoinsFromMissionData(Map<String, dynamic> data) {
    final coins = (data['reward_coins'] as num?)?.toInt() ?? 0;
    return coins > 0 ? coins : _defaultMissionRewardCoins;
  }

  Future<void> _sumarMonedasUsuario({
    required String userId,
    required int coins,
  }) async {
    if (coins <= 0) return;
    await _userRepository.addCoins(userId, coins);
  }

  String _normalizarTipoMision(String idMision, Map<String, dynamic> data) {
    final tipo = (data['tipo'] as String?) ?? '';
    final id = idMision.toLowerCase();
    final normalized = tipo.toLowerCase();
    if (normalized.contains('recoger') && normalized.contains('comida')) {
      return 'recoger_comida';
    }
    if (id.contains('recoger') && id.contains('comida')) {
      return 'recoger_comida';
    }
    return '';
  }

  DisasterType _parseTipo(String tipo) {
    return switch (tipo) {
      'juguete' => DisasterType.juguete,
      'basura' => DisasterType.basura,
      'porcion' => DisasterType.porcion,
      _ => DisasterType.comida,
    };
  }

  String _normalizarPantalla(String? pantalla) {
    return switch (pantalla) {
      disasterScreenHome => disasterScreenHome,
      disasterScreenAlimentar => disasterScreenAlimentar,
      disasterScreenJugar => disasterScreenJugar,
      disasterScreenDormir => disasterScreenDormir,
      _ => disasterScreenAll,
    };
  }

  List<String> _pickToyIds(int cantidad) {
    if (cantidad <= 0) return const [];
    final bolsa = List<String>.from(_toyIds)..shuffle(_random);
    if (cantidad <= bolsa.length) {
      return bolsa.take(cantidad).toList();
    }

    final resultado = <String>[];
    while (resultado.length < cantidad) {
      final restantes = List<String>.from(_toyIds)..shuffle(_random);
      for (final toyId in restantes) {
        if (resultado.length >= cantidad) break;
        resultado.add(toyId);
      }
    }
    return resultado;
  }

  DisasterState _buildStateFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    if (snap.docs.isEmpty) {
      return const DisasterState();
    }

    final objetos = <DisasterObject>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final tipo = _parseTipo(data['tipo'] as String? ?? 'comida');
      if (tipo == DisasterType.juguete) continue;

      final cantidad = (data['cantidad'] as int?) ?? 1;
      final pantalla = _normalizarPantalla(data['pantalla'] as String?);
      for (int i = 0; i < cantidad; i++) {
        objetos.add(
          DisasterObject(
            id: '${doc.id}_$i',
            sourceDocId: doc.id,
            tipo: tipo,
            emoji: data['emoji'] as String? ?? 'ðŸ–',
            pantalla: pantalla,
            posicion: Offset(
              0.05 + _random.nextDouble() * 0.85,
              0.10 + _random.nextDouble() * 0.70,
            ),
            escala: 0.8 + _random.nextDouble() * 0.6,
          ),
        );
      }
    }

    return DisasterState(objetos: objetos, hayDesastre: objetos.isNotEmpty);
  }

  Future<void> _stopWatching() async {
    await _pendingSub?.cancel();
    _pendingSub = null;
    _activeMascotaId = null;
  }

  Future<void> reset() async {
    await _stopWatching();
    emit(const DisasterState());
  }

  @override
  Future<void> close() async {
    await _stopWatching();
    return super.close();
  }
}

class DisasterOverlay extends StatelessWidget {
  final Widget child;
  final String mascotaId;
  final String currentPath;

  const DisasterOverlay({
    super.key,
    required this.child,
    required this.mascotaId,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisasterCubit, DisasterState>(
      builder: (context, state) {
        final visibles = state.objetos
            .where((objeto) => _seMuestraEnRuta(objeto, currentPath))
            .toList();

        return Stack(
          children: [
            child,
            if (visibles.isNotEmpty)
              ...visibles.map(
                (objeto) => _DisasterItem(
                  key: ValueKey(objeto.id),
                  objeto: objeto,
                  mascotaId: mascotaId,
                ),
              ),
            if (visibles.isNotEmpty)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: _DisasterBanner(total: visibles.length),
              ),
          ],
        );
      },
    );
  }

  bool _seMuestraEnRuta(DisasterObject objeto, String ruta) {
    switch (objeto.pantalla) {
      case disasterScreenHome:
        return ruta == AppRoutes.home;
      case disasterScreenAlimentar:
        return ruta.startsWith(AppRoutes.alimentar);
      case disasterScreenJugar:
        return ruta.startsWith(AppRoutes.jugar);
      case disasterScreenDormir:
        return ruta.startsWith(AppRoutes.dormir);
      case disasterScreenAll:
      default:
        return true;
    }
  }
}

class _DisasterItem extends StatefulWidget {
  final DisasterObject objeto;
  final String mascotaId;

  const _DisasterItem({
    super.key,
    required this.objeto,
    required this.mascotaId,
  });

  @override
  State<_DisasterItem> createState() => _DisasterItemState();
}

class _DisasterItemState extends State<_DisasterItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  bool _recogiendo = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _tocar() async {
    if (_recogiendo) return;
    setState(() => _recogiendo = true);
    _ctrl.stop();

    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    context.read<DisasterCubit>().recogerObjeto(
      widget.objeto.id,
      widget.mascotaId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final left = widget.objeto.posicion.dx * size.width - 24;
    final top = widget.objeto.posicion.dy * size.height - 24;

    return Positioned(
      left: left.clamp(0, size.width - 56),
      top: top.clamp(60, size.height - 120),
      child: GestureDetector(
        onTap: _tocar,
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (context, child) => Transform.scale(
            scale: _recogiendo ? 0.0 : _scaleAnim.value * widget.objeto.escala,
            child: child,
          ),
          child: AnimatedOpacity(
            opacity: _recogiendo ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.objeto.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DisasterBanner extends StatelessWidget {
  final int total;

  const _DisasterBanner({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8C42).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tu mascota hizo un desastre. Recoge $total objetos',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
