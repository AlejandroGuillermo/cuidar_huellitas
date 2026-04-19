import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'pet_state.dart';
import '../Models/mascota_model.dart';
import '../core/personality_config.dart';
import '../core/disaster_system.dart';

class PetCubit extends Cubit<PetState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Random _random = Random();

  DisasterCubit? disasterCubit;

  PetCubit() : super(PetState(isLoading: true));

  // ══════════════════════════════════════════════════════
  // CARGA Y AUSENCIA
  // ══════════════════════════════════════════════════════

  Future<void> cargarMascota() async {
    try {
      emit(state.copyWith(clearMascota: true, isLoading: true));
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        emit(state.copyWith(clearMascota: true, isLoading: false));
        return;
      }

      final snap = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('mascotas')
          .where('activa', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final mascota = MascotaModel.fromFirestore(snap.docs.first);
        emit(state.copyWith(mascota: mascota, isLoading: false));

        // Si estaba descansando, calcular recuperación offline primero
        if (mascota.estaDescansando) {
          await calcularRecuperacionOffline();
        } else {
          await calcularDeterieroAusencia();
        }
      } else {
        emit(state.copyWith(clearMascota: true, isLoading: false));
      }
    } catch (e) {
      debugPrint('Error cargarMascota: $e');
      emit(state.copyWith(clearMascota: true, isLoading: false));
    }
  }

  // ── Recuperación offline (estaba durmiendo) ────────────
  Future<void> calcularRecuperacionOffline() async {
    final mascota = state.mascota;
    if (mascota == null || !mascota.estaDescansando) return;
    final inicio = mascota.inicioDescanso;
    if (inicio == null) return;

    final minutosTranscurridos = DateTime.now()
        .difference(inicio)
        .inMinutes
        .clamp(0, 600);
    final esNoche = mascota.tipoDescanso == 'noche';

    // Tasa de recuperación: noche=2/min, siesta=0.8/min
    final tasa = esNoche ? 2.0 : 0.8;
    final energiaGanada = (minutosTranscurridos * tasa)
        .clamp(0, 100 - mascota.energiaAlAcostar)
        .round();
    final nuevaEnergia = (mascota.energiaAlAcostar + energiaGanada).clamp(
      0,
      100,
    );

    // Buff si ganó +20 o más
    final buff = energiaGanada >= 20;
    final buffExpira = buff
        ? DateTime.now().add(const Duration(days: 1))
        : mascota.buffExpira;

    // Efectos nocturnos si llegó al 100%
    int hambre = mascota.nivelHambre;
    int limpieza = mascota.nivelLimpieza;
    int afecto = mascota.nivelAfecto;
    if (esNoche && nuevaEnergia >= 100) {
      hambre = (hambre - 10).clamp(0, 100);
      limpieza = (limpieza - 5).clamp(0, 100);
    }
    if (!esNoche && nuevaEnergia >= 100) {
      afecto = (afecto + 5).clamp(0, 100); // bonus siesta completa
    }

    final estadoFinal = nuevaEnergia >= 100
        ? 'despierto'
        : mascota.estadoDescanso;

    final despues = mascota.copyWith(
      nivelEnergia: nuevaEnergia,
      nivelHambre: hambre,
      nivelLimpieza: limpieza,
      nivelAfecto: afecto,
      buffEnergia: buff || mascota.buffEnergia,
      buffExpira: buffExpira,
      estadoDescanso: estadoFinal,
      clearInicioDescanso: estadoFinal == 'despierto',
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarDescansoEnFirestore(antes: mascota, despues: despues);
    await _guardarEnFirestore(
      antes: mascota,
      despues: despues,
      accion: 'recuperacion_offline',
      extras: {
        'duracion_minutos': minutosTranscurridos,
        'energia_recuperada': energiaGanada,
        'buff_obtenido': buff,
        'tipo_descanso': mascota.tipoDescanso,
      },
    );
  }

  // ── Deterioro por ausencia (estaba despierta) ─────────
  Future<void> calcularDeterieroAusencia() async {
    final mascota = state.mascota;
    if (mascota == null) return;

    final ticks =
        DateTime.now().difference(mascota.ultimaInteraccion).inMinutes ~/ 3;

    final config = PersonalityRegistry.get(mascota.rasgo);
    final ausenciaFactor = config?.deterioro.ausenciaFactor ?? 1.0;
    final ticksAplicados = ticks.clamp(0, 120);
    if (ticksAplicados <= 0 || mascota.estaDescansando) return;

    var despues = mascota;
    for (var i = 0; i < ticksAplicados; i++) {
      despues = _calcularDeterioro(despues, factorExtra: ausenciaFactor);
    }

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(
      antes: mascota,
      despues: despues,
      accion: 'deterioro_ausencia',
      extras: {
        'ticks_aplicados': ticksAplicados,
        'factor_ausencia': ausenciaFactor,
      },
    );
    await _verificarReacciones(despues);
    await disasterCubit?.verificarDesastre(mascota.idMascota);
  }

  // ══════════════════════════════════════════════════════
  // SISTEMA DE DESCANSO
  // ══════════════════════════════════════════════════════

  // ── Intentar acostar (con lógica de rebelde) ──────────
  // Retorna: 'ok' | 'rebelde_cuarto' | 'rebelde_escapado'
  Future<String> intentarAcostar({required bool esNoche}) async {
    final mascota = state.mascota;
    if (mascota == null) return 'ok';
    final rasgo = mascota.rasgo;

    // Verificar si es rebelde
    final esRebelde =
        mascota.nivelEnergia < 30 &&
        (rasgo == 'Juguetón' || rasgo == 'Travieso');

    if (esRebelde) {
      final obedece = _random.nextDouble() > 0.5;
      if (!obedece) {
        // No obedece
        emit(state.copyWith(estadoMision: 'perro_rebelde'));
        if (rasgo == 'Travieso') {
          await disasterCubit?.generarDesastre(
            mascotaId: mascota.idMascota,
            tipo: DisasterType.basura,
            emoji: '💨',
            cantidad: 3,
          );
          return 'rebelde_escapado';
        }
        return 'rebelde_cuarto';
      }
      // Obedece a medias — se acuesta pero puede interrumpirse
      await _acostarse(esNoche: esNoche, obedeceAMedias: true);
      return 'ok';
    }

    await _acostarse(esNoche: esNoche, obedeceAMedias: false);
    return 'ok';
  }

  Future<void> _acostarse({
    required bool esNoche,
    required bool obedeceAMedias,
  }) async {
    final mascota = state.mascota;
    if (mascota == null) return;

    final tapsBase = 3 + _random.nextInt(4); // 3–6
    final esCarinoso = mascota.rasgo == 'Cariñoso';
    final cariciasBase = esNoche
        ? (esCarinoso ? 4 + _random.nextInt(5) : 3 + _random.nextInt(5))
        : 0;

    final despues = mascota.copyWith(
      estadoDescanso: esNoche ? 'acostado' : 'siesta',
      tipoDescanso: esNoche ? 'noche' : 'siesta',
      inicioDescanso: null, // se pone al dormirse, no al acostarse
      energiaAlAcostar: mascota.nivelEnergia,
      tapsParaDespetarBase: tapsBase,
      ultimaInteraccion: DateTime.now(),
    );

    emit(
      state.copyWith(
        mascota: despues,
        estadoMision: 'ninguna',
        cariciasTotal: cariciasBase,
        cariciasHechas: 0,
        tapsDespertar: 0,
      ),
    );

    await _guardarDescansoEnFirestore(antes: mascota, despues: despues);

    // Si obedece a medias, programar interrupción aleatoria
    if (obedeceAMedias) {
      final delayMinutos = 2 + _random.nextInt(4); // 2–5 min
      Future.delayed(Duration(minutes: delayMinutos), () {
        if (state.mascota?.estadoDescanso == 'dormido' ||
            state.mascota?.estadoDescanso == 'siesta') {
          _interrumpirSueno();
        }
      });
    }
  }

  // ── Registrar caricia (noche) ──────────────────────────
  Future<bool> registrarCaricia() async {
    final mascota = state.mascota;
    if (mascota == null) return false;

    final nuevasHechas = state.cariciasHechas + 1;
    final afectoGanado = 3;

    final despues = mascota.copyWith(
      nivelAfecto: (mascota.nivelAfecto + afectoGanado).clamp(0, 100),
    );

    emit(state.copyWith(mascota: despues, cariciasHechas: nuevasHechas));

    // ¿Completó las caricias necesarias? → La mascota se duerme
    if (nuevasHechas >= state.cariciasTotal) {
      await _dormirse();
      return true; // señal de que se durmió
    }
    return false;
  }

  Future<void> _dormirse() async {
    final mascota = state.mascota;
    if (mascota == null) return;

    final despues = mascota.copyWith(
      estadoDescanso: 'dormido',
      inicioDescanso: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarDescansoEnFirestore(antes: mascota, despues: despues);
  }

  // ── Tick online de recuperación (Timer cada 30s) ──────
  Future<void> tickDescanso() async {
    final mascota = state.mascota;
    if (mascota == null || !mascota.estaDescansando) return;

    final esNoche = mascota.tipoDescanso == 'noche';
    final esSiesta = mascota.tipoDescanso == 'siesta';

    // Solo tick de energía si ya está dormida (no solo acostada en noche)
    final debeRecuperar =
        esSiesta || (esNoche && mascota.estadoDescanso == 'dormido');
    if (!debeRecuperar) return;

    // Tasa: noche 2/tick (30s), siesta 1/tick
    final ganancia = esNoche ? 2 : 1;
    final nuevaEnergia = (mascota.nivelEnergia + ganancia).clamp(0, 100);

    final bool lleg100 = nuevaEnergia >= 100;
    int hambre = mascota.nivelHambre;
    int limpieza = mascota.nivelLimpieza;
    int afecto = mascota.nivelAfecto;

    if (lleg100) {
      if (esNoche) {
        hambre = (hambre - 10).clamp(0, 100);
        limpieza = (limpieza - 5).clamp(0, 100);
      } else {
        afecto = (afecto + 5).clamp(0, 100);
      }
    }

    final buff = lleg100 || (nuevaEnergia - mascota.energiaAlAcostar >= 20);

    final despues = mascota.copyWith(
      nivelEnergia: nuevaEnergia,
      nivelHambre: hambre,
      nivelLimpieza: limpieza,
      nivelAfecto: afecto,
      estadoDescanso: lleg100 ? 'despierto' : mascota.estadoDescanso,
      clearInicioDescanso: lleg100,
      buffEnergia: buff || mascota.buffEnergia,
      buffExpira: buff && !mascota.buffActivo
          ? DateTime.now().add(const Duration(days: 1))
          : mascota.buffExpira,
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));

    // Guardar en Firestore solo cada 4 ticks (~2 min) para no saturar
    if (_random.nextInt(4) == 0 || lleg100) {
      await _guardarDescansoEnFirestore(antes: mascota, despues: despues);
      if (lleg100) {
        await _guardarEnFirestore(
          antes: mascota,
          despues: despues,
          accion: 'despertar_automatico',
          extras: {
            'tipo_descanso': mascota.tipoDescanso,
            'buff_obtenido': buff,
          },
        );
      }
    }
  }

  // ── Tap para despertar ─────────────────────────────────
  // Retorna true cuando se completan los taps necesarios
  Future<bool> registrarTapDespertar() async {
    final mascota = state.mascota;
    if (mascota == null) return false;

    // Noche: solo despertable si cortinas abiertas
    if (mascota.tipoDescanso == 'noche' && mascota.cortinasAbiertas == false) {
      return false;
    }

    final nuevosTaps = state.tapsDespertar + 1;
    emit(state.copyWith(tapsDespertar: nuevosTaps));

    if (nuevosTaps >= mascota.tapsParaDespetarBase) {
      await _despertar();
      return true;
    }
    return false;
  }

  Future<void> _despertar() async {
    final mascota = state.mascota;
    if (mascota == null) return;

    final inicio = mascota.inicioDescanso;
    final minutosDescansados = inicio != null
        ? DateTime.now().difference(inicio).inMinutes
        : 0;
    final energiaGanada = mascota.nivelEnergia - mascota.energiaAlAcostar;
    final buff = energiaGanada >= 20;

    final despues = mascota.copyWith(
      estadoDescanso: 'despierto',
      clearInicioDescanso: true,
      tipoDescanso: '',
      buffEnergia: buff || mascota.buffEnergia,
      buffExpira: buff && !mascota.buffActivo
          ? DateTime.now().add(const Duration(days: 1))
          : mascota.buffExpira,
      ultimaInteraccion: DateTime.now(),
    );

    emit(
      state.copyWith(
        mascota: despues,
        tapsDespertar: 0,
        estadoMision: 'ninguna',
      ),
    );

    await _guardarDescansoEnFirestore(antes: mascota, despues: despues);
    await _guardarEnFirestore(
      antes: mascota,
      despues: despues,
      accion: 'despertar_manual',
      extras: {
        'duracion_minutos': minutosDescansados,
        'energia_ganada': energiaGanada,
        'buff_obtenido': buff,
        'tipo_descanso': mascota.tipoDescanso,
      },
    );
  }

  // ── Interrupción aleatoria (obedece a medias) ─────────
  void _interrumpirSueno() {
    final mascota = state.mascota;
    if (mascota == null) return;

    final rasgo = mascota.rasgo;

    if (rasgo == 'Travieso') {
      // Escapa a otra pantalla
      disasterCubit?.generarDesastre(
        mascotaId: mascota.idMascota,
        tipo: DisasterType.basura,
        emoji: '💨',
        cantidad: 2,
      );
      emit(state.copyWith(estadoMision: 'rebelde_escapado'));
    } else {
      // Juguetón: se levanta pero queda en el cuarto
      emit(state.copyWith(estadoMision: 'rebelde_cuarto'));
    }

    final despues = mascota.copyWith(
      estadoDescanso: 'despierto',
      clearInicioDescanso: true,
    );
    emit(state.copyWith(mascota: despues));
  }

  // ── Calmar rebelde (taps) ──────────────────────────────
  // Retorna true cuando está calmado
  Future<bool> registrarTapCalmar() async {
    final nuevosTaps = state.tapsCalmar + 1;
    emit(state.copyWith(tapsCalmar: nuevosTaps));
    final mascota = state.mascota;
    final limite = 3 + _random.nextInt(4); // 3–6

    if (nuevosTaps >= limite) {
      emit(state.copyWith(estadoMision: 'ninguna', tapsCalmar: 0));
      // Regresa al cuarto si era travieso escapado
      if (mascota != null) {
        final despues = mascota.copyWith(estadoDescanso: 'despierto');
        emit(state.copyWith(mascota: despues));
      }
      return true;
    }
    return false;
  }

  // ── Alternar cortinas ──────────────────────────────────
  Future<void> toggleCortinas() async {
    final mascota = state.mascota;
    if (mascota == null) return;

    final despues = mascota.copyWith(
      cortinasAbiertas: !mascota.cortinasAbiertas,
    );
    emit(state.copyWith(mascota: despues));

    // Solo guardar el campo de cortinas (sin registrar en progreso)
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    try {
      await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('mascotas')
          .doc(mascota.idMascota)
          .update({'cortinas_abiertas': despues.cortinasAbiertas});
    } catch (e) {
      debugPrint('Error toggle cortinas: $e');
    }
  }

  // ══════════════════════════════════════════════════════
  // HELPERS INTERNOS
  // ══════════════════════════════════════════════════════

  // Guarda solo los campos de descanso en Firestore
  Future<void> _guardarDescansoEnFirestore({
    required MascotaModel antes,
    required MascotaModel despues,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    try {
      await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('mascotas')
          .doc(antes.idMascota)
          .update({
            'nivel_energia': despues.nivelEnergia,
            'nivel_hambre': despues.nivelHambre,
            'nivel_limpieza': despues.nivelLimpieza,
            'nivel_afecto': despues.nivelAfecto,
            'estado_descanso': despues.estadoDescanso,
            'inicio_descanso': despues.inicioDescanso != null
                ? Timestamp.fromDate(despues.inicioDescanso!)
                : null,
            'tipo_descanso': despues.tipoDescanso,
            'energia_al_acostar': despues.energiaAlAcostar,
            'buff_energia': despues.buffEnergia,
            'buff_expira': despues.buffExpira != null
                ? Timestamp.fromDate(despues.buffExpira!)
                : null,
            'cortinas_abiertas': despues.cortinasAbiertas,
            'taps_para_despertar': despues.tapsParaDespetarBase,
            'ultima_interaccion': Timestamp.now(),
          });
    } catch (e) {
      debugPrint('Error guardarDescanso: $e');
    }
  }

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
          .collection('usuarios')
          .doc(userId)
          .collection('mascotas')
          .doc(antes.idMascota);

      await mascotaRef.update({
        'nivel_salud': despues.nivelSalud,
        'nivel_energia': despues.nivelEnergia,
        'nivel_hambre': despues.nivelHambre,
        'nivel_limpieza': despues.nivelLimpieza,
        'nivel_afecto': despues.nivelAfecto,
        'ultima_interaccion': Timestamp.now(),
        'deterioro_acelerado': despues.deterioroAcelerado,
        'anomalia_detectada': despues.anomaliaDetectada,
      });

      final ahora = DateTime.now();
      await mascotaRef.collection('progreso').add({
        'id_mision': accion,
        'accion_realizada': accion,
        'hora_dia': ahora.hour + (ahora.minute / 60.0),
        'fecha_actualizacion': Timestamp.now(),
        'estado_antes': antes.nivelesMap,
        'estado_despues': despues.nivelesMap,
        'rasgo': antes.rasgo,
        ...?extras,
      });
    } catch (e) {
      debugPrint('Error Firestore ($accion): $e');
    }
  }

  Future<void> _crearMisionActiva(String misionId, String mascotaId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    try {
      await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId)
          .collection('misiones_activas')
          .doc(misionId)
          .set({
            'id_mision': misionId,
            'estado': 'pendiente',
            'fecha_asignada': Timestamp.now(),
            'fecha_completada': null,
            'streak': 0,
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error mision: $e');
    }
  }

  Future<void> _verificarReacciones(MascotaModel mascota) async {
    final config = PersonalityRegistry.get(mascota.rasgo);
    if (config == null) return;

    for (final r in config.reacciones) {
      final nivel = switch (r.nivel) {
        'salud' => mascota.nivelSalud,
        'energia' => mascota.nivelEnergia,
        'hambre' => mascota.nivelHambre,
        'limpieza' => mascota.nivelLimpieza,
        'afecto' => mascota.nivelAfecto,
        _ => 100,
      };
      if (nivel <= r.umbral) {
        if (r.misionId != null) {
          await _crearMisionActiva(r.misionId!, mascota.idMascota);
        }
        if (r.desastreTipo != null && disasterCubit != null) {
          await disasterCubit!.generarDesastre(
            mascotaId: mascota.idMascota,
            tipo: DisasterType.values.byName(r.desastreTipo!),
            emoji: r.desastreEmoji ?? '🍖',
            cantidad: r.desastreCantidad,
          );
        }
      }
    }
  }

  int _calcularSaludSecundaria(MascotaModel m, DecayModifiers dec) {
    int dano = 0;
    if (m.nivelHambre < dec.umbralHambre) dano++;
    if (m.nivelLimpieza < dec.umbralLimpieza) dano++;
    if (m.nivelEnergia == 0) dano++;
    return dano;
  }

  // ══════════════════════════════════════════════════════
  // ACCIONES DEL JUEGO
  // ══════════════════════════════════════════════════════

  Future<void> alimentar(int puntosBase, {String? emojiAlimento}) async {
    final antes = state.mascota;
    if (antes == null) return;
    final config = PersonalityRegistry.get(antes.rasgo);
    final mod = config?.acciones;

    final despues = antes.copyWith(
      nivelHambre:
          (antes.nivelHambre + (puntosBase * (mod?.alimentarHambre ?? 1.0)))
              .round()
              .clamp(0, 100),
      nivelSalud:
          (antes.nivelSalud +
                  (BaseActionValues.alimentarSalud *
                      (mod?.alimentarSalud ?? 1.0)))
              .round()
              .clamp(0, 100),
      nivelAfecto:
          (antes.nivelAfecto +
                  (BaseActionValues.alimentarAfecto *
                      (mod?.alimentarAfecto ?? 1.0)))
              .round()
              .clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));

    if ((mod?.alimentarPuedeTirar ?? false) && _random.nextDouble() < 0.3) {
      await disasterCubit?.generarDesastre(
        mascotaId: antes.idMascota,
        tipo: DisasterType.comida,
        emoji: emojiAlimento ?? '🍖',
        cantidad: 3 + _random.nextInt(4),
      );
    }

    await _guardarEnFirestore(
      antes: antes,
      despues: despues,
      accion: 'alimentar',
      extras: {'emoji_alimento': emojiAlimento ?? ''},
    );
    await _verificarReacciones(despues);
  }

  Future<void> jugar({
    int afectoBonus = 15,
    int energiaCosto = 10,
    String? emojiJuguete,
  }) async {
    final antes = state.mascota;
    if (antes == null) return;
    final config = PersonalityRegistry.get(antes.rasgo);
    final mod = config?.acciones;

    final despues = antes.copyWith(
      nivelAfecto:
          (antes.nivelAfecto + (afectoBonus * (mod?.jugarAfecto ?? 1.0)))
              .round()
              .clamp(0, 100),
      nivelEnergia:
          (antes.nivelEnergia -
                  (energiaCosto * (mod?.jugarEnergiaCosto ?? 1.0)))
              .round()
              .clamp(0, 100),
      nivelHambre:
          (antes.nivelHambre +
                  (BaseActionValues.jugarHambre *
                      (mod?.jugarHambreCosto ?? 1.0)))
              .round()
              .clamp(0, 100),
      nivelLimpieza: (antes.nivelLimpieza + (mod?.jugarLimpieza ?? 0.0))
          .round()
          .clamp(0, 100),
      nivelSalud: (antes.nivelSalud + (mod?.jugarSaludBonus ?? 0.0))
          .round()
          .clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(
      antes: antes,
      despues: despues,
      accion: 'jugar',
      extras: {'emoji_juguete': emojiJuguete ?? ''},
    );
    await _verificarReacciones(despues);
  }

  Future<void> banar() async {
    final antes = state.mascota;
    if (antes == null) return;
    final config = PersonalityRegistry.get(antes.rasgo);
    final mod = config?.acciones;

    final despues = antes.copyWith(
      nivelLimpieza:
          (antes.nivelLimpieza +
                  (BaseActionValues.banarLimpieza *
                      (mod?.banarLimpieza ?? 1.0)))
              .round()
              .clamp(0, 100),
      nivelAfecto:
          (antes.nivelAfecto +
                  (BaseActionValues.banarAfecto * (mod?.banarAfecto ?? 1.0)))
              .round()
              .clamp(0, 100),
      nivelSalud: (antes.nivelSalud + BaseActionValues.banarSalud).clamp(
        0,
        100,
      ),
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'banar');
    await _verificarReacciones(despues);
  }

  Future<void> curar() async {
    final antes = state.mascota;
    if (antes == null) return;
    final config = PersonalityRegistry.get(antes.rasgo);
    final mod = config?.acciones;

    final despues = antes.copyWith(
      nivelSalud:
          (antes.nivelSalud +
                  (BaseActionValues.curarSalud * (mod?.curarSalud ?? 1.0)))
              .round()
              .clamp(0, 100),
      nivelEnergia: (antes.nivelEnergia + BaseActionValues.curarEnergia).clamp(
        0,
        100,
      ),
      nivelAfecto:
          (antes.nivelAfecto +
                  (BaseActionValues.curarAfecto * (mod?.curarAfecto ?? 1.0)))
              .round()
              .clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'curar');
    await _verificarReacciones(despues);
  }

  Future<void> pasear() async {
    final antes = state.mascota;
    if (antes == null) return;
    final config = PersonalityRegistry.get(antes.rasgo);
    final mod = config?.acciones;

    final despues = antes.copyWith(
      nivelAfecto:
          (antes.nivelAfecto +
                  (BaseActionValues.pasearAfecto * (mod?.pasearAfecto ?? 1.0)))
              .round()
              .clamp(0, 100),
      nivelEnergia:
          (antes.nivelEnergia +
                  (BaseActionValues.pasearEnergia *
                      (mod?.pasearEnergia ?? 1.0)))
              .round()
              .clamp(0, 100),
      nivelHambre:
          (antes.nivelHambre +
                  (BaseActionValues.pasearHambre *
                      (mod?.pasearHambreCosto ?? 1.0)))
              .round()
              .clamp(0, 100),
      nivelSalud: (antes.nivelSalud + BaseActionValues.pasearSalud).clamp(
        0,
        100,
      ),
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'pasear');
    await _verificarReacciones(despues);
  }

  Future<void> aplicarDeterioro({double factorExtra = 1.0}) async {
    final antes = state.mascota;
    if (antes == null || antes.estaDescansando) {
      return; // no deteriorar si descansa
    }

    final despues = _calcularDeterioro(antes, factorExtra: factorExtra);

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(
      antes: antes,
      despues: despues,
      accion: 'deterioro',
    );
    await _verificarReacciones(despues);
  }

  MascotaModel _calcularDeterioro(
    MascotaModel mascota, {
    double factorExtra = 1.0,
  }) {
    final config = PersonalityRegistry.get(mascota.rasgo);
    final dec = config?.deterioro;
    final factor =
        (mascota.anomaliaDetectada ? (dec?.anomaliaFactor ?? 5.0) : 1.0) *
        factorExtra;

    // Buff activo: energía cae a la mitad
    final factorEnergia = mascota.buffActivo ? 0.5 : 1.0;
    final saludExtra = _calcularSaludSecundaria(
      mascota,
      dec ?? const DecayModifiers(),
    );

    return mascota.copyWith(
      nivelSalud:
          (mascota.nivelSalud -
                  (BaseActionValues.deterioroSalud *
                      (dec?.salud ?? 1.0) *
                      factor) -
                  saludExtra)
              .round()
              .clamp(0, 100),
      nivelEnergia:
          (mascota.nivelEnergia -
                  (BaseActionValues.deterioroEnergia *
                      (dec?.energia ?? 1.0) *
                      factor *
                      factorEnergia))
              .round()
              .clamp(0, 100),
      nivelHambre:
          (mascota.nivelHambre -
                  (BaseActionValues.deterioroHambre *
                      (dec?.hambre ?? 1.0) *
                      factor))
              .round()
              .clamp(0, 100),
      nivelLimpieza:
          (mascota.nivelLimpieza -
                  (BaseActionValues.deterioroLimpieza *
                      (dec?.limpieza ?? 1.0) *
                      factor))
              .round()
              .clamp(0, 100),
      nivelAfecto:
          (mascota.nivelAfecto -
                  (BaseActionValues.deterioroAfecto *
                      (dec?.afecto ?? 1.0) *
                      factor))
              .round()
              .clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );
  }
}
