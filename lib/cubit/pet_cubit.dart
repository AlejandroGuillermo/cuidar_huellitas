import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'pet_state.dart';
import '../models/mascota_model.dart'; // Ajusta la ruta

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

  // ── ACCIÓN DE ALIMENTAR (ACTUALIZA FIREBASE Y LOCAL) ──
  Future<void> alimentar(int puntos) async {
    final antes = state.mascota;
    if (antes == null) return;
    final despues = antes.copyWith(
      nivelHambre: (antes.nivelHambre + puntos).clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );
    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'alimentar');
  }

  Future<void> jugar() async {
    final antes = state.mascota;
    if (antes == null) return;
    final despues = antes.copyWith(
      nivelAfecto:  (antes.nivelAfecto  + 20).clamp(0, 100),
      nivelEnergia: (antes.nivelEnergia - 15).clamp(0, 100),
      nivelHambre:  (antes.nivelHambre  - 10).clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );
    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'jugar');
  }

  Future<void> banar() async {
    final antes = state.mascota;
    if (antes == null) return;
    final despues = antes.copyWith(
      nivelLimpieza: (antes.nivelLimpieza + 35).clamp(0, 100),
      nivelAfecto:   (antes.nivelAfecto   + 10).clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );
    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'banar');
  }

  Future<void> dormir() async {
    final antes = state.mascota;
    if (antes == null) return;
    final despues = antes.copyWith(
      nivelEnergia: (antes.nivelEnergia + 40).clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );
    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'dormir');
  }

  Future<void> curar() async {
    final antes = state.mascota;
    if (antes == null) return;
    final despues = antes.copyWith(
      nivelSalud: (antes.nivelSalud + 30).clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );
    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'curar');
  }

  Future<void> pasear() async {
    final antes = state.mascota;
    if (antes == null) return;
    final despues = antes.copyWith(
      nivelAfecto:  (antes.nivelAfecto  + 15).clamp(0, 100),
      nivelEnergia: (antes.nivelEnergia + 10).clamp(0, 100),
      nivelHambre:  (antes.nivelHambre  - 15).clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );
    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'pasear');
  }
  Future<void> aplicarDeterioro() async {
    final antes = state.mascota;
    if (antes == null) return;
    final factor = antes.anomaliaDetectada ? 5 : 1;
    final esJuguetonOTravieso = antes.rasgo == 'Juguetón' || antes.rasgo == 'Travieso';
    final despues = antes.copyWith(
      nivelHambre:   (antes.nivelHambre   - (2 * factor)).clamp(0, 100),
      nivelEnergia:  (antes.nivelEnergia  - (esJuguetonOTravieso ? 3 : 1) * factor).clamp(0, 100),
      nivelLimpieza: (antes.nivelLimpieza - (1 * factor)).clamp(0, 100),
      nivelAfecto:   (antes.nivelAfecto   - (2 * factor)).clamp(0, 100),
    );
    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'deterioro');
  }
}