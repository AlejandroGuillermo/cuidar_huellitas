import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'pet_state.dart';
import '../models/mascota_model.dart';
import '../core/personality_config.dart';

class PetCubit extends Cubit<PetState> {
  // Instancias de Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PetCubit() : super(PetState(isLoading: true));

  // ── FUNCIÓN PARA CARGAR DESDE FIREBASE ──
  Future<void> cargarMascota() async {
    try {
      emit(state.copyWith(isLoading: true));
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        emit(state.copyWith(isLoading: false));
        return;
      }

      // Buscamos la mascota activa del usuario
      final snapshot = await _firestore
          .collection('usuarios').doc(userId)
          .collection('mascotas')
          .where('activa', isEqualTo: true).limit(1).get();
      // Si encontramos una mascota activa, la cargamos en el estado
      if (snapshot.docs.isNotEmpty) {
        emit(state.copyWith(
          mascota: MascotaModel.fromFirestore(snapshot.docs.first),
          isLoading: false,
        ));
      } else {
        // No tiene mascota activa
        emit(state.copyWith(clearMascota: true, isLoading: false));
      }
    } catch (e) {
      debugPrint('Error al cargar mascota: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  // ── FUNCIÓN PARA GUARDAR EN FIREBASE ──
  Future<void> _guardarEnFirestore({
    required MascotaModel antes,
    required MascotaModel despues,
    required String accion,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final mascotaRef = _firestore
          .collection('usuarios').doc(userId)
          .collection('mascotas').doc(antes.idMascota);

      await mascotaRef.update({
        'nivel_salud':          despues.nivelSalud,
        'nivel_energia':        despues.nivelEnergia,
        'nivel_hambre':         despues.nivelHambre,
        'nivel_limpieza':       despues.nivelLimpieza,
        'nivel_afecto':         despues.nivelAfecto,
        'ultima_interaccion':   Timestamp.now(),
        'deterioro_acelerado':  despues.deterioroAcelerado,
        'anomalia_detectada':   despues.anomaliaDetectada,
      });

      final ahora = DateTime.now();
      await mascotaRef.collection('progreso').add({
        'id_mision':           accion,
        'accion_realizada':    accion,
        'hora_dia':            ahora.hour + (ahora.minute / 60.0),
        'fecha_actualizacion': Timestamp.now(),
        'estado_antes':        antes.nivelesMap,
        'estado_despues':      despues.nivelesMap,
      });
    } catch (e) {
      debugPrint('Error Firestore ($accion): $e');
    }
  }

  // ── Helper: crear misión activa en Firestore ───────────
  Future<void> _crearMisionActiva(String misionId, String userId, String mascotaId) async {
    try {
      await _firestore
          .collection('usuarios').doc(userId)
          .collection('mascotas').doc(mascotaId)
          .collection('misiones_activas').doc(misionId).set({
        'id_mision':      misionId,
        'estado':         'pendiente',
        'fecha_asignada': Timestamp.now(),
        'fecha_completada': null,
        'streak':         0,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error creando misión $misionId: $e');
    }
  }

  // ── Helper: verificar reacciones y crear misiones ──────
  Future<void> _verificarReacciones(MascotaModel mascota) async {
    final config = PersonalityRegistry.get(mascota.rasgo);
    if (config == null) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    for (final reaccion in config.reacciones) {
      final nivelActual = switch (reaccion.nivel) {
        'salud'    => mascota.nivelSalud,
        'energia'  => mascota.nivelEnergia,
        'hambre'   => mascota.nivelHambre,
        'limpieza' => mascota.nivelLimpieza,
        'afecto'   => mascota.nivelAfecto,
        _          => 100,
      };

      if (nivelActual <= reaccion.umbral && reaccion.misionId != null) {
        await _crearMisionActiva(reaccion.misionId!, userId, mascota.idMascota);
      }
    }
  }

  // ── ALIMENTAR ──────────────────────────────────────────
  Future<void> alimentar(int puntosBase) async {
    final antes = state.mascota;
    if (antes == null) return;

    final config = PersonalityRegistry.get(antes.rasgo);
    final mod = config?.acciones;

    final nuevoHambre = (antes.nivelHambre +
        (puntosBase * (mod?.alimentarHambre ?? 1.0))).round().clamp(0, 100);
    final nuevaSalud  = (antes.nivelSalud  +
        (BaseActionValues.alimentarSalud  * (mod?.alimentarSalud  ?? 1.0))).round().clamp(0, 100);
    final nuevoAfecto = (antes.nivelAfecto +
        (BaseActionValues.alimentarAfecto * (mod?.alimentarAfecto ?? 1.0))).round().clamp(0, 100);

    final despues = antes.copyWith(
      nivelHambre: nuevoHambre,
      nivelSalud:  nuevaSalud,
      nivelAfecto: nuevoAfecto,
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'alimentar');
    await _verificarReacciones(despues);
  }

  // ── JUGAR ──────────────────────────────────────────────
  Future<void> jugar({int afectoBonus = 15, int energiaCosto = 10}) async {
    final antes = state.mascota;
    if (antes == null) return;

    final config = PersonalityRegistry.get(antes.rasgo);
    final mod = config?.acciones;

    final nuevoAfecto  = (antes.nivelAfecto  +
        (afectoBonus  * (mod?.jugarAfecto       ?? 1.0))).round().clamp(0, 100);
    final nuevoEnergia = (antes.nivelEnergia -
        (energiaCosto * (mod?.jugarEnergiaCosto ?? 1.0))).round().clamp(0, 100);
    final nuevoHambre  = (antes.nivelHambre  +
        (BaseActionValues.jugarHambre * (mod?.jugarHambreCosto ?? 1.0))).round().clamp(0, 100);

    final despues = antes.copyWith(
      nivelAfecto:  nuevoAfecto,
      nivelEnergia: nuevoEnergia,
      nivelHambre:  nuevoHambre,
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'jugar');
    await _verificarReacciones(despues);
  }

  // ── BAÑAR ──────────────────────────────────────────────
  Future<void> banar() async {
    final antes = state.mascota;
    if (antes == null) return;

    final config = PersonalityRegistry.get(antes.rasgo);
    final mod = config?.acciones;

    final despues = antes.copyWith(
      nivelLimpieza: (antes.nivelLimpieza +
          (BaseActionValues.banarLimpieza * (mod?.banarLimpieza ?? 1.0))).round().clamp(0, 100),
      nivelAfecto:   (antes.nivelAfecto   +
          (BaseActionValues.banarAfecto   * (mod?.banarAfecto   ?? 1.0))).round().clamp(0, 100),
      nivelSalud:    (antes.nivelSalud    + BaseActionValues.banarSalud).clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'banar');
    await _verificarReacciones(despues);
  }

  // ── DORMIR ─────────────────────────────────────────────
  Future<void> dormir() async {
    final antes = state.mascota;
    if (antes == null) return;

    final config = PersonalityRegistry.get(antes.rasgo);
    final mod = config?.acciones;

    // dormirAfecto puede ser negativo (tiernos extrañan al niño)
    final deltaAfecto = (mod?.dormirAfecto ?? 0.0) * 5;

    final despues = antes.copyWith(
      nivelEnergia: (antes.nivelEnergia +
          (BaseActionValues.dormirEnergia * (mod?.dormirEnergia ?? 1.0))).round().clamp(0, 100),
      nivelSalud:   (antes.nivelSalud  + BaseActionValues.dormirSalud).clamp(0, 100),
      nivelHambre:  (antes.nivelHambre + BaseActionValues.dormirHambre).clamp(0, 100),
      nivelAfecto:  (antes.nivelAfecto + deltaAfecto).round().clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'dormir');
    await _verificarReacciones(despues);
  }

  // ── CURAR ──────────────────────────────────────────────
  Future<void> curar() async {
    final antes = state.mascota;
    if (antes == null) return;

    final config = PersonalityRegistry.get(antes.rasgo);
    final mod = config?.acciones;

    final despues = antes.copyWith(
      nivelSalud:   (antes.nivelSalud   +
          (BaseActionValues.curarSalud   * (mod?.curarSalud ?? 1.0))).round().clamp(0, 100),
      nivelEnergia: (antes.nivelEnergia + BaseActionValues.curarEnergia).clamp(0, 100),
      nivelAfecto:  (antes.nivelAfecto  + BaseActionValues.curarAfecto).clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'curar');
    await _verificarReacciones(despues);
  }

  // ── PASEAR ─────────────────────────────────────────────
  Future<void> pasear() async {
    final antes = state.mascota;
    if (antes == null) return;

    final config = PersonalityRegistry.get(antes.rasgo);
    final mod = config?.acciones;

    final despues = antes.copyWith(
      nivelAfecto:  (antes.nivelAfecto  +
          (BaseActionValues.pasearAfecto  * (mod?.pasearAfecto  ?? 1.0))).round().clamp(0, 100),
      nivelEnergia: (antes.nivelEnergia +
          (BaseActionValues.pasearEnergia * (mod?.pasearEnergia ?? 1.0))).round().clamp(0, 100),
      nivelHambre:  (antes.nivelHambre  +
          (BaseActionValues.pasearHambre  * (mod?.pasearHambreCosto ?? 1.0))).round().clamp(0, 100),
      nivelSalud:   (antes.nivelSalud   + BaseActionValues.pasearSalud).clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'pasear');
    await _verificarReacciones(despues);
  }

  // ── DETERIORO PERIÓDICO (Motor de IA) ──────────────────
  // Llámalo desde un Timer en HomeScreen cada 30 minutos
  Future<void> aplicarDeterioro() async {
    final antes = state.mascota;
    if (antes == null) return;

    final config = PersonalityRegistry.get(antes.rasgo);
    final mod = config?.deterioro;
    final factor = antes.anomaliaDetectada
        ? (mod?.anomaliaFactor ?? 5.0)
        : 1.0;

    final despues = antes.copyWith(
      nivelSalud:    (antes.nivelSalud    - (BaseActionValues.deterioroSalud    * (mod?.salud    ?? 1.0) * factor)).round().clamp(0, 100),
      nivelEnergia:  (antes.nivelEnergia  - (BaseActionValues.deterioroEnergia  * (mod?.energia  ?? 1.0) * factor)).round().clamp(0, 100),
      nivelHambre:   (antes.nivelHambre   - (BaseActionValues.deterioroHambre   * (mod?.hambre   ?? 1.0) * factor)).round().clamp(0, 100),
      nivelLimpieza: (antes.nivelLimpieza - (BaseActionValues.deterioroLimpieza * (mod?.limpieza ?? 1.0) * factor)).round().clamp(0, 100),
      nivelAfecto:   (antes.nivelAfecto   - (BaseActionValues.deterioroAfecto   * (mod?.afecto   ?? 1.0) * factor)).round().clamp(0, 100),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'deterioro');
    await _verificarReacciones(despues);
  }
}