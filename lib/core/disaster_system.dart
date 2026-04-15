// ══════════════════════════════════════════════════════════════
// disaster_system.dart
// lib/core/disaster_system.dart
//
// Sistema global de desastre — objetos flotantes sobre TODAS
// las pantallas. Se activa al volver a la app si la mascota
// generó un desastre mientras el niño no estaba.
//
// Cómo funciona:
//   1. Al abrir la app, DisasterCubit consulta Firestore
//   2. Si hay objetos pendientes, los esparce aleatoriamente
//   3. DisasterOverlay los pinta encima de CUALQUIER pantalla
//   4. Al tocar un objeto, desaparece y se registra en Firestore
// ══════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── Tipos de objeto en el desastre ────────────────────────────
enum DisasterType {
  comida,   // montaña de comida — Juguetón, Travieso, Glotón
  juguete,  // juguete fuera de caja — Juguetón, Travieso
  basura,   // basura del baño — Travieso
  porcion,  // porción pequeña — Delicado (mal del estómago)
}

// ── Objeto individual del desastre ────────────────────────────
class DisasterObject {
  final String id;
  final DisasterType tipo;
  final String emoji;
  final Offset posicion;     // posición en % de pantalla (0.0–1.0)
  final double escala;       // tamaño aleatorio para variedad visual

  const DisasterObject({
    required this.id,
    required this.tipo,
    required this.emoji,
    required this.posicion,
    required this.escala,
  });
}

// ── Estado del sistema ─────────────────────────────────────────
class DisasterState {
  final List<DisasterObject> objetos;
  final bool hayDesastre;

  const DisasterState({
    this.objetos = const [],
    this.hayDesastre = false,
  });

  DisasterState copyWith({
    List<DisasterObject>? objetos,
    bool? hayDesastre,
  }) {
    return DisasterState(
      objetos:     objetos     ?? this.objetos,
      hayDesastre: hayDesastre ?? this.hayDesastre,
    );
  }
}

// ── Cubit del sistema de desastre ─────────────────────────────
class DisasterCubit extends Cubit<DisasterState> {
  final Random _random = Random();

  DisasterCubit() : super(const DisasterState());

  // ── Verificar desastre al abrir la app ────────────────────
  // Llama esto en main.dart o en el primer build del router
  Future<void> verificarDesastre(String mascotaId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snap = await FirebaseFirestore.instance
          .collection('usuarios').doc(userId)
          .collection('mascotas').doc(mascotaId)
          .collection('desastres_pendientes')
          .where('recogido', isEqualTo: false)
          .get();

      if (snap.docs.isEmpty) return;

      final objetos = <DisasterObject>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        final tipo = _parseTipo(data['tipo'] as String? ?? 'comida');
        final cantidad = (data['cantidad'] as int?) ?? 1;

        // Esparcir la cantidad de objetos en posiciones aleatorias
        for (int i = 0; i < cantidad; i++) {
          objetos.add(DisasterObject(
            id:       '${doc.id}_$i',
            tipo:     tipo,
            emoji:    data['emoji'] as String? ?? '🍖',
            posicion: Offset(
              0.05 + _random.nextDouble() * 0.85, // 5%–90% horizontal
              0.10 + _random.nextDouble() * 0.70, // 10%–80% vertical
            ),
            escala: 0.8 + _random.nextDouble() * 0.6, // 0.8×–1.4×
          ));
        }
      }

      emit(state.copyWith(objetos: objetos, hayDesastre: objetos.isNotEmpty));
    } catch (e) {
      debugPrint('Error verificando desastre: $e');
    }
  }

  // ── Generar desastre desde personalidad ───────────────────
  // Llamado por PetCubit cuando ocurre un evento de desastre
  Future<void> generarDesastre({
    required String mascotaId,
    required DisasterType tipo,
    required String emoji,
    required int cantidad,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Guardar en Firestore para persistir entre sesiones
      await FirebaseFirestore.instance
          .collection('usuarios').doc(userId)
          .collection('mascotas').doc(mascotaId)
          .collection('desastres_pendientes')
          .add({
        'tipo':      tipo.name,
        'emoji':     emoji,
        'cantidad':  cantidad,
        'recogido':  false,
        'fecha':     FieldValue.serverTimestamp(),
      });

      // Agregar inmediatamente al overlay si el niño está en la app
      final nuevos = List<DisasterObject>.from(state.objetos);
      for (int i = 0; i < cantidad; i++) {
        nuevos.add(DisasterObject(
          id:       'live_${DateTime.now().millisecondsSinceEpoch}_$i',
          tipo:     tipo,
          emoji:    emoji,
          posicion: Offset(
            0.05 + _random.nextDouble() * 0.85,
            0.10 + _random.nextDouble() * 0.70,
          ),
          escala: 0.8 + _random.nextDouble() * 0.6,
        ));
      }

      emit(state.copyWith(objetos: nuevos, hayDesastre: true));
    } catch (e) {
      debugPrint('Error generando desastre: $e');
    }
  }

  // ── Recoger un objeto ─────────────────────────────────────
  Future<void> recogerObjeto(String objetoId, String mascotaId) async {
    final actualizados = state.objetos.where((o) => o.id != objetoId).toList();
    emit(state.copyWith(
      objetos:     actualizados,
      hayDesastre: actualizados.isNotEmpty,
    ));

    // Si ya no hay objetos, marcar desastres como recogidos en Firestore
    if (actualizados.isEmpty) {
      await _marcarTodosRecogidos(mascotaId);
    }
  }

  Future<void> _marcarTodosRecogidos(String mascotaId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snap = await FirebaseFirestore.instance
          .collection('usuarios').doc(userId)
          .collection('mascotas').doc(mascotaId)
          .collection('desastres_pendientes')
          .where('recogido', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'recogido': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marcando recogidos: $e');
    }
  }

  DisasterType _parseTipo(String tipo) {
    return switch (tipo) {
      'juguete' => DisasterType.juguete,
      'basura'  => DisasterType.basura,
      'porcion' => DisasterType.porcion,
      _         => DisasterType.comida,
    };
  }
}

// ══════════════════════════════════════════════════════════════
// DisasterOverlay — widget global que flota sobre TODAS
// las pantallas. Se coloca en main.dart envolviendo el router.
// ══════════════════════════════════════════════════════════════
class DisasterOverlay extends StatelessWidget {
  final Widget child;
  final String mascotaId;

  const DisasterOverlay({
    super.key,
    required this.child,
    required this.mascotaId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisasterCubit, DisasterState>(
      builder: (context, state) {
        return Stack(
          children: [
            // La app normal debajo
            child,

            // Objetos flotantes encima de todo
            if (state.hayDesastre)
              ...state.objetos.map((objeto) => _DisasterItem(
                key:       ValueKey(objeto.id),
                objeto:    objeto,
                mascotaId: mascotaId,
              )),

            // Banner informativo cuando hay desastre
            if (state.hayDesastre)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16, right: 16,
                child: _DisasterBanner(total: state.objetos.length),
              ),
          ],
        );
      },
    );
  }
}

// ── Ítem individual flotante ───────────────────────────────────
class _DisasterItem extends StatefulWidget {
  final DisasterObject objeto;
  final String mascotaId;

  const _DisasterItem({super.key, required this.objeto, required this.mascotaId});

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
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tocar() async {
    if (_recogiendo) return;
    setState(() => _recogiendo = true);
    _ctrl.stop();

    // Animación de recoger
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      context.read<DisasterCubit>().recogerObjeto(
        widget.objeto.id,
        widget.mascotaId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final left = widget.objeto.posicion.dx * size.width  - 24;
    final top  = widget.objeto.posicion.dy * size.height - 24;

    return Positioned(
      left: left.clamp(0, size.width  - 56),
      top:  top.clamp(60, size.height - 120),
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

// ── Banner informativo ─────────────────────────────────────────
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '¡Tu mascota hizo un desastre! Recoge los $total objetos 🧹',
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
