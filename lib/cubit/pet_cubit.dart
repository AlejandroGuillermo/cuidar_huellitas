import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'pet_state.dart';
import '../models/mascota_model.dart';
import '../core/personality_config.dart';
import '../core/disaster_system.dart';

class PetCubit extends Cubit<PetState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth      _auth      = FirebaseAuth.instance;
  final Random            _random    = Random();

  // Referencia al DisasterCubit para generar desastres
  DisasterCubit? disasterCubit;

  PetCubit() : super(PetState(isLoading: true));

  // ── Cargar mascota ─────────────────────────────────────
  Future<void> cargarMascota() async {
    try {
      emit(state.copyWith(isLoading: true));
      final userId = _auth.currentUser?.uid;
      if (userId == null) { emit(state.copyWith(isLoading: false)); return; }

      final snap = await _firestore
          .collection('usuarios').doc(userId)
          .collection('mascotas')
          .where('activa', isEqualTo: true).limit(1).get();

      if (snap.docs.isNotEmpty) {
        emit(state.copyWith(
          mascota: MascotaModel.fromFirestore(snap.docs.first),
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(clearMascota: true, isLoading: false));
      }
    } catch (e) {
      debugPrint('Error cargarMascota: $e');
      emit(state.copyWith(isLoading: false));
    }
  }

  // ── Calcular deterioro por ausencia ───────────────────
  // Llama esto al abrir la app para aplicar ticks perdidos
  Future<void> calcularDeterieroAusencia() async {
    final mascota = state.mascota;
    if (mascota == null) return;

    final ticks = DateTime.now()
        .difference(mascota.ultimaInteraccion)
        .inMinutes ~/ 3; // 1 tick cada 3 minutos de ausencia

    final config = PersonalityRegistry.get(mascota.rasgo);
    final ausenciaFactor = config?.deterioro.ausenciaFactor ?? 1.0;

    for (var i = 0; i < ticks; i++) {
      await aplicarDeterioro(factorExtra: ausenciaFactor);
    }

    // Verificar desastres pendientes en Firestore
    await disasterCubit?.verificarDesastre(mascota.idMascota);
  }

  // ── Helper: guardar en Firestore + progreso ────────────
  Future<void> _guardarEnFirestore({
    required MascotaModel antes,
    required MascotaModel despues,
    required String accion,
    Map<String, dynamic>? extras,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final mascotaRef = _firestore
          .collection('usuarios').doc(userId)
          .collection('mascotas').doc(antes.idMascota);

      await mascotaRef.update({
        'nivel_salud':         despues.nivelSalud,
        'nivel_energia':       despues.nivelEnergia,
        'nivel_hambre':        despues.nivelHambre,
        'nivel_limpieza':      despues.nivelLimpieza,
        'nivel_afecto':        despues.nivelAfecto,
        'ultima_interaccion':  Timestamp.now(),
        'deterioro_acelerado': despues.deterioroAcelerado,
        'anomalia_detectada':  despues.anomaliaDetectada,
      });

      final ahora = DateTime.now();
      await mascotaRef.collection('progreso').add({
        'id_mision':           accion,
        'accion_realizada':    accion,
        'hora_dia':            ahora.hour + (ahora.minute / 60.0),
        'fecha_actualizacion': Timestamp.now(),
        'estado_antes':        antes.nivelesMap,
        'estado_despues':      despues.nivelesMap,
        'rasgo':               antes.rasgo,
        ...?extras,
      });
    } catch (e) {
      debugPrint('Error Firestore ($accion): $e');
    }
  }

  // ── Helper: crear misión activa ────────────────────────
  Future<void> _crearMisionActiva(String misionId, String mascotaId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    try {
      await _firestore
          .collection('usuarios').doc(userId)
          .collection('mascotas').doc(mascotaId)
          .collection('misiones_activas').doc(misionId).set({
        'id_mision':       misionId,
        'estado':          'pendiente',
        'fecha_asignada':  Timestamp.now(),
        'fecha_completada': null,
        'streak':          0,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error creando misión: $e');
    }
  }

  // ── Helper: verificar reacciones y desastres ───────────
  Future<void> _verificarReacciones(MascotaModel mascota) async {
    final config = PersonalityRegistry.get(mascota.rasgo);
    if (config == null) return;

    for (final r in config.reacciones) {
      final nivel = switch (r.nivel) {
        'salud'    => mascota.nivelSalud,
        'energia'  => mascota.nivelEnergia,
        'hambre'   => mascota.nivelHambre,
        'limpieza' => mascota.nivelLimpieza,
        'afecto'   => mascota.nivelAfecto,
        _          => 100,
      };

      if (nivel <= r.umbral) {
        if (r.misionId != null) {
          await _crearMisionActiva(r.misionId!, mascota.idMascota);
        }
        if (r.desastreTipo != null && disasterCubit != null) {
          await disasterCubit!.generarDesastre(
            mascotaId: mascota.idMascota,
            tipo:      DisasterType.values.byName(r.desastreTipo!),
            emoji:     r.desastreEmoji ?? '🍖',
            cantidad:  r.desastreCantidad,
          );
        }
      }
    }
  }

  // ── Salud secundaria (stats bajas dañan la salud) ─────
  int _calcularSaludSecundaria(MascotaModel m, DecayModifiers dec) {
    int dano = 0;
    if (m.nivelHambre   < dec.umbralHambre)   dano++;
    if (m.nivelLimpieza < dec.umbralLimpieza) dano++;
    if (m.nivelEnergia  == 0)                  dano++;
    return dano;
  }

  // ══════════════════════════════════════════════════════
  // MÉTODOS DE ACCIÓN
  // ══════════════════════════════════════════════════════

  // ── ALIMENTAR ──────────────────────────────────────────
  Future<void> alimentar(int puntosBase, {String? emojiAlimento}) async {
    final antes = state.mascota;
    if (antes == null) return;

    final config = PersonalityRegistry.get(antes.rasgo);
    final mod    = config?.acciones;

    final despues = antes.copyWith(
      nivelHambre: (antes.nivelHambre +
          (puntosBase * (mod?.alimentarHambre ?? 1.0))).round().clamp(0, 100),
      nivelSalud:  (antes.nivelSalud  +
          (BaseActionValues.alimentarSalud  * (mod?.alimentarSalud  ?? 1.0))).round().clamp(0, 100),
      nivelAfecto: (antes.nivelAfecto +
          (BaseActionValues.alimentarAfecto * (mod?.alimentarAfecto ?? 1.0))).round().clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));

    // Probabilidad de tirar comida
    if ((mod?.alimentarPuedeTirar ?? false) && _random.nextDouble() < 0.3) {
      await disasterCubit?.generarDesastre(
        mascotaId: antes.idMascota,
        tipo:      DisasterType.comida,
        emoji:     emojiAlimento ?? '🍖',
        cantidad:  3 + _random.nextInt(4),
      );
    }

    await _guardarEnFirestore(
      antes: antes, despues: despues, accion: 'alimentar',
      extras: {'emoji_alimento': emojiAlimento ?? ''},
    );
    await _verificarReacciones(despues);
  }

  // ── JUGAR ──────────────────────────────────────────────
  Future<void> jugar({int afectoBonus = 15, int energiaCosto = 10, String? emojiJuguete}) async {
    final antes = state.mascota;
    if (antes == null) return;

    final config = PersonalityRegistry.get(antes.rasgo);
    final mod    = config?.acciones;

    final despues = antes.copyWith(
      nivelAfecto:   (antes.nivelAfecto  +
          (afectoBonus  * (mod?.jugarAfecto       ?? 1.0))).round().clamp(0, 100),
      nivelEnergia:  (antes.nivelEnergia -
          (energiaCosto * (mod?.jugarEnergiaCosto ?? 1.0))).round().clamp(0, 100),
      nivelHambre:   (antes.nivelHambre  +
          (BaseActionValues.jugarHambre * (mod?.jugarHambreCosto ?? 1.0))).round().clamp(0, 100),
      nivelLimpieza: (antes.nivelLimpieza +
          (mod?.jugarLimpieza ?? 0.0)).round().clamp(0, 100),
      nivelSalud:    (antes.nivelSalud   +
          (mod?.jugarSaludBonus ?? 0.0)).round().clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(
      antes: antes, despues: despues, accion: 'jugar',
      extras: {'emoji_juguete': emojiJuguete ?? ''},
    );
    await _verificarReacciones(despues);
  }

  // ── BAÑAR ──────────────────────────────────────────────
  Future<void> banar() async {
    final antes = state.mascota;
    if (antes == null) return;

    final config = PersonalityRegistry.get(antes.rasgo);
    final mod    = config?.acciones;

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
    final mod    = config?.acciones;

    final deltaAfecto = (mod?.dormirAfecto ?? 0.0) * 5;

    final despues = antes.copyWith(
      nivelEnergia: (antes.nivelEnergia +
          (BaseActionValues.dormirEnergia * (mod?.dormirEnergia ?? 1.0))).round().clamp(0, 100),
      nivelSalud:   (antes.nivelSalud   +
          BaseActionValues.dormirSalud  + (mod?.dormirSaludBonus ?? 0.0)).round().clamp(0, 100),
      nivelHambre:  (antes.nivelHambre  + BaseActionValues.dormirHambre).clamp(0, 100),
      nivelAfecto:  (antes.nivelAfecto  + deltaAfecto).round().clamp(0, 100),
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
    final mod    = config?.acciones;

    final despues = antes.copyWith(
      nivelSalud:   (antes.nivelSalud   +
          (BaseActionValues.curarSalud   * (mod?.curarSalud   ?? 1.0))).round().clamp(0, 100),
      nivelEnergia: (antes.nivelEnergia + BaseActionValues.curarEnergia).clamp(0, 100),
      nivelAfecto:  (antes.nivelAfecto  +
          (BaseActionValues.curarAfecto  * (mod?.curarAfecto  ?? 1.0))).round().clamp(0, 100),
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
    final mod    = config?.acciones;

    final despues = antes.copyWith(
      nivelAfecto:  (antes.nivelAfecto  +
          (BaseActionValues.pasearAfecto  * (mod?.pasearAfecto        ?? 1.0))).round().clamp(0, 100),
      nivelEnergia: (antes.nivelEnergia +
          (BaseActionValues.pasearEnergia * (mod?.pasearEnergia       ?? 1.0))).round().clamp(0, 100),
      nivelHambre:  (antes.nivelHambre  +
          (BaseActionValues.pasearHambre  * (mod?.pasearHambreCosto   ?? 1.0))).round().clamp(0, 100),
      nivelSalud:   (antes.nivelSalud   + BaseActionValues.pasearSalud).clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'pasear');
    await _verificarReacciones(despues);
  }

  // ── DETERIORO PERIÓDICO ────────────────────────────────
  Future<void> aplicarDeterioro({double factorExtra = 1.0}) async {
    final antes = state.mascota;
    if (antes == null) return;

    final config = PersonalityRegistry.get(antes.rasgo);
    final dec    = config?.deterioro;
    final factor = (antes.anomaliaDetectada
        ? (dec?.anomaliaFactor ?? 5.0)
        : 1.0) * factorExtra;

    // Calcular daño de salud secundaria
    final saludExtra = _calcularSaludSecundaria(antes, dec ?? const DecayModifiers());

    final despues = antes.copyWith(
      nivelSalud:    (antes.nivelSalud    -
          (BaseActionValues.deterioroSalud    * (dec?.salud    ?? 1.0) * factor)
          - saludExtra).round().clamp(0, 100),
      nivelEnergia:  (antes.nivelEnergia  -
          (BaseActionValues.deterioroEnergia  * (dec?.energia  ?? 1.0) * factor)).round().clamp(0, 100),
      nivelHambre:   (antes.nivelHambre   -
          (BaseActionValues.deterioroHambre   * (dec?.hambre   ?? 1.0) * factor)).round().clamp(0, 100),
      nivelLimpieza: (antes.nivelLimpieza -
          (BaseActionValues.deterioroLimpieza * (dec?.limpieza ?? 1.0) * factor)).round().clamp(0, 100),
      nivelAfecto:   (antes.nivelAfecto   -
          (BaseActionValues.deterioroAfecto   * (dec?.afecto   ?? 1.0) * factor)).round().clamp(0, 100),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'deterioro');
    await _verificarReacciones(despues);
  }
}