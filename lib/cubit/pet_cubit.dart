import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'pet_state.dart';
import '../Models/mascota_model.dart';
import '../Models/mision_activa_model.dart';
import '../application/models/pet_ai_decision.dart';
import '../application/services/pet_ai_engine.dart';
import '../application/services/routine_analyzer.dart';
import '../application/services/notification_service.dart';
import '../core/personality_config.dart';
import '../core/disaster_system.dart';
import '../core/enums/personalidad_tipo.dart';
import '../core/food_catalog.dart';
import '../data/repositories/ai_state_repository.dart';
import '../data/repositories/inventory_repository.dart';
import '../data/repositories/mission_repository.dart';
import '../data/repositories/pet_repository.dart';

class PetCubit extends Cubit<PetState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final InventoryRepository _inventoryRepository = InventoryRepository();
  final PetRepository _petRepository;
  final PetAiEngine _petAiEngine;
  final RoutineAnalyzer? _routineAnalyzer;
  final AiStateRepository? _aiStateRepository;
  final MissionRepository? _missionRepository;
  final Random _random = Random();
  Timer? _deterioroTimer;
  Timer? _platoComidaTimer;

  static const Duration _deterioroIntervalo = Duration(minutes: 30);
  static const Duration _platoPasoIntervalo = Duration(seconds: 30);
  static const int _maxTicksPlatoAusencia = 48; // 24h maximo
  static const int _maxTicksAusencia = 48; // 24 horas maximo
  static const int _umbralHambreSalud = 20;
  static const int _umbralLimpiezaSalud = 20;
  static const int _umbralAfectoSalud = 10;
  static const int _umbralEnergiaBaja = 12;
  static const int _ticksEnergiaBajaParaDano = 2;
  static const int _defaultMissionRewardCoins = 5;
  static const int _jugarSuciedadBase = 4;
  static const String _bathMissionId = 'mision_bano';
  static const int _bathMissionThreshold = 50;
  static const int _bathMissionUrgentThreshold = 25;

  DisasterCubit? disasterCubit;

  PetCubit({
    required PetAiEngine petAiEngine,
    PetRepository? petRepository,
    RoutineAnalyzer? routineAnalyzer,
    AiStateRepository? aiStateRepository,
    MissionRepository? missionRepository,
  }) : _petAiEngine = petAiEngine,
       _petRepository = petRepository ?? PetRepository(),
       _routineAnalyzer = routineAnalyzer,
       _aiStateRepository = aiStateRepository,
       _missionRepository = missionRepository,
       super(PetState(isLoading: true));

  int _umbralBuffPorDescanso(String tipoDescanso) {
    return tipoDescanso == 'siesta' ? 10 : 20;
  }

  // ══════════════════════════════════════════════════════
  // CARGA Y AUSENCIA
  // ══════════════════════════════════════════════════════

  Future<void> cargarMascota() async {
    try {
      emit(state.copyWith(clearMascota: true, isLoading: true));
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _detenerDeterioroOnline();
        _detenerComidaPlatoOnline();
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
        _iniciarDeterioroOnline();

        // Si estaba descansando, calcular recuperación offline primero
        if (mascota.estaDescansando) {
          await calcularRecuperacionOffline();
        } else {
          await calcularDeterieroAusencia();
        }
        final comioOffline = await sincronizarPlatoOffline();
        await _evaluarMisionRecogerComidaOffline(comioOffline);
        _iniciarComidaPlatoOnlineSiAplica();
        await disasterCubit?.verificarDesastre(mascota.idMascota);
      } else {
        _detenerDeterioroOnline();
        _detenerComidaPlatoOnline();
        emit(state.copyWith(clearMascota: true, isLoading: false));
      }
    } catch (e) {
      debugPrint('Error cargarMascota: $e');
      _detenerDeterioroOnline();
      _detenerComidaPlatoOnline();
      emit(state.copyWith(clearMascota: true, isLoading: false));
    }
  }

  // ── Recuperación offline (estaba durmiendo) ────────────
  Future<void> calcularRecuperacionOffline() async {
    final mascota = state.mascota;
    if (mascota == null || !mascota.estaDescansando) return;
    final esNoche = mascota.tipoDescanso == 'noche';
    final referenciaInicio =
        mascota.inicioDescanso ?? (esNoche ? null : mascota.ultimaInteraccion);
    if (referenciaInicio == null) return;

    final minutosTranscurridos = DateTime.now()
        .difference(referenciaInicio)
        .inMinutes
        .clamp(0, 600)
        .toInt();

    // Noche: recuperación fuerte. Siesta: 3 energía cada 15 min (=1 cada 5 min).
    final energiaGanada = esNoche
        ? (minutosTranscurridos * 2.0)
              .clamp(0, 100 - mascota.energiaAlAcostar)
              .round()
        : (minutosTranscurridos ~/ 5)
              .clamp(0, 100 - mascota.energiaAlAcostar)
              .toInt();
    final nuevaEnergia = (mascota.energiaAlAcostar + energiaGanada).clamp(
      0,
      100,
    );

    // Buff por recuperación: siesta con umbral más accesible.
    final buff = energiaGanada >= _umbralBuffPorDescanso(mascota.tipoDescanso);
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
      ticksEnergiaBaja: nuevaEnergia < _umbralEnergiaBaja
          ? mascota.ticksEnergiaBaja
          : 0,
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
    await _sincronizarMisionBano(despues);
  }

  // ── Deterioro por ausencia (estaba despierta) ─────────
  Future<void> calcularDeterieroAusencia() async {
    final mascota = state.mascota;
    if (mascota == null) return;

    final ticks =
        DateTime.now().difference(mascota.ultimaInteraccion).inMinutes ~/
        _deterioroIntervalo.inMinutes;

    final config = PersonalityRegistry.get(mascota.rasgo);
    final ausenciaFactor = config?.deterioro.ausenciaFactor ?? 1.0;
    final ticksAplicados = ticks.clamp(0, _maxTicksAusencia);
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
    await _sincronizarMisionBano(despues);
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
    final personalidad = mascota.personalidad;
    final esJuguetonOTravieso =
        personalidad == PersonalidadTipo.jugueton ||
        personalidad == PersonalidadTipo.travieso;

    if (!esNoche && mascota.cortinasAbiertas) {
      return 'siesta_requiere_cortina';
    }

    // Rebeldía general para Juguetón y Travieso.
    final esRebelde = esJuguetonOTravieso;

    if (esRebelde) {
      // 45% de probabilidad de no obedecer cuando entra en modo rebelde.
      final obedece = _random.nextDouble() > 0.45;
      if (!obedece) {
        // No obedece
        emit(state.copyWith(estadoMision: 'perro_rebelde'));
        if (personalidad == PersonalidadTipo.travieso) {
          await disasterCubit?.generarDesastre(
            mascotaId: mascota.idMascota,
            tipo: DisasterType.basura,
            emoji: '💨',
            cantidad: 3,
          );
          await _aplicarSuciedadPorDesastre(
            _puntosSuciedadPorDesastre(DisasterType.basura),
            accion: 'desastre_rebeldia',
            extras: {'tipo_desastre': DisasterType.basura.name},
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
    final esCarinoso = mascota.personalidad == PersonalidadTipo.carinoso;
    final requiereCariciasParaSiesta = !esNoche && esCarinoso;
    final requiereCaricias = esNoche || requiereCariciasParaSiesta;
    final cariciasBase = requiereCaricias
        ? (esCarinoso ? 4 + _random.nextInt(5) : 3 + _random.nextInt(5))
        : 0;

    final despues = mascota.copyWith(
      estadoDescanso: requiereCaricias ? 'acostado' : 'siesta',
      tipoDescanso: esNoche ? 'noche' : 'siesta',
      inicioDescanso: requiereCaricias ? null : DateTime.now(),
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
    final estadoFinal = mascota.tipoDescanso == 'siesta' ? 'siesta' : 'dormido';

    final despues = mascota.copyWith(
      estadoDescanso: estadoFinal,
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

    int nuevaEnergia;
    if (esNoche) {
      // Noche: recuperación fuerte y continua.
      nuevaEnergia = (mascota.nivelEnergia + 2).clamp(0, 100);
    } else {
      // Siesta: 3 cada 15 min (1 cada 5 min), con cálculo por tiempo transcurrido.
      final inicio = mascota.inicioDescanso ?? mascota.ultimaInteraccion;
      final bloquesRecuperados =
          DateTime.now().difference(inicio).inMinutes ~/ 5;
      final energiaObjetivo = (mascota.energiaAlAcostar + bloquesRecuperados)
          .clamp(0, 100)
          .toInt();
      nuevaEnergia = max(mascota.nivelEnergia, energiaObjetivo);
    }

    if (nuevaEnergia == mascota.nivelEnergia) return;

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

    final buff =
        lleg100 ||
        (nuevaEnergia - mascota.energiaAlAcostar >=
            _umbralBuffPorDescanso(mascota.tipoDescanso));

    final despues = mascota.copyWith(
      nivelEnergia: nuevaEnergia,
      nivelHambre: hambre,
      nivelLimpieza: limpieza,
      nivelAfecto: afecto,
      ticksEnergiaBaja: nuevaEnergia < _umbralEnergiaBaja
          ? mascota.ticksEnergiaBaja
          : 0,
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
      await _sincronizarMisionBano(despues);
    }
  }

  // ── Tap para despertar ─────────────────────────────────
  // Retorna true cuando se completan los taps necesarios
  Future<bool> registrarTapDespertar({
    bool despertarInstantaneo = false,
  }) async {
    final mascota = state.mascota;
    if (mascota == null) return false;

    // Si está descansando (noche/siesta), solo despertable con cortinas abiertas.
    if ((mascota.tipoDescanso == 'noche' || mascota.tipoDescanso == 'siesta') &&
        mascota.cortinasAbiertas == false) {
      return false;
    }

    if (despertarInstantaneo) {
      await _despertar();
      return true;
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
    final buff = energiaGanada >= _umbralBuffPorDescanso(mascota.tipoDescanso);

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

    final personalidad = mascota.personalidad;

    if (personalidad == PersonalidadTipo.travieso) {
      // Escapa a otra pantalla
      disasterCubit?.generarDesastre(
        mascotaId: mascota.idMascota,
        tipo: DisasterType.basura,
        emoji: '💨',
        cantidad: 2,
      );
      unawaited(
        _aplicarSuciedadPorDesastre(
          _puntosSuciedadPorDesastre(DisasterType.basura),
          accion: 'desastre_interrupcion_sueno',
          extras: {'tipo_desastre': DisasterType.basura.name},
        ),
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
  Future<void> setCortinasAbiertas(bool abiertas) async {
    final mascota = state.mascota;
    if (mascota == null) return;
    if (mascota.cortinasAbiertas == abiertas) return;

    final despues = mascota.copyWith(cortinasAbiertas: abiertas);
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
      debugPrint('Error set cortinas: $e');
    }
  }

  Future<void> toggleCortinas() async {
    final mascota = state.mascota;
    if (mascota == null) return;
    await setCortinasAbiertas(!mascota.cortinasAbiertas);
  }

  Future<void> promoverSiestaANocheSiAplica({
    required bool esNocheActual,
  }) async {
    final mascota = state.mascota;
    if (mascota == null) return;
    if (!esNocheActual) return;
    if (mascota.tipoDescanso != 'siesta') return;

    final nuevoEstado = mascota.estadoDescanso == 'siesta'
        ? 'dormido'
        : mascota.estadoDescanso;
    final nuevaInicioDescanso = mascota.inicioDescanso ?? DateTime.now();

    final despues = mascota.copyWith(
      tipoDescanso: 'noche',
      estadoDescanso: nuevoEstado,
      inicioDescanso: nuevaInicioDescanso,
    );

    emit(state.copyWith(mascota: despues));
    await _guardarDescansoEnFirestore(antes: mascota, despues: despues);
  }

  // ══════════════════════════════════════════════════════
  Future<void> forzarDescansoOffline({required bool siesta}) async {
    final mascota = state.mascota;
    if (mascota == null || mascota.estaDescansando) return;

    final tapsBase = 3 + _random.nextInt(4); // 3-6
    final despues = mascota.copyWith(
      estadoDescanso: siesta ? 'siesta' : 'dormido',
      tipoDescanso: siesta ? 'siesta' : 'noche',
      inicioDescanso: DateTime.now(),
      energiaAlAcostar: mascota.nivelEnergia,
      tapsParaDespetarBase: tapsBase,
      ultimaInteraccion: DateTime.now(),
    );

    emit(
      state.copyWith(
        mascota: despues,
        estadoMision: 'ninguna',
        cariciasTotal: 0,
        cariciasHechas: 0,
        tapsDespertar: 0,
      ),
    );
    await _guardarDescansoEnFirestore(antes: mascota, despues: despues);
  }

  Future<bool> equiparItemCabeza(String itemId) async {
    final mascota = state.mascota;
    final userId = _auth.currentUser?.uid;
    if (mascota == null || userId == null || itemId.isEmpty) return false;

    try {
      final cosmetics = await _inventoryRepository.loadCosmeticsInventory(
        userId,
      );
      if (cosmetics.poseidos[itemId] != true) return false;

      final despues = mascota.copyWith(itemCabezaId: itemId);
      emit(state.copyWith(mascota: despues));

      final mascotaRef = _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('mascotas')
          .doc(mascota.idMascota);
      final cosmeticsRef = _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('inventario')
          .doc('cosmeticos');
      final batch = _firestore.batch();
      batch.update(mascotaRef, {'item_cabeza_id': itemId});
      final inventoryUpdates = <String, dynamic>{
        'equipado_en.$itemId': mascota.idMascota,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (mascota.itemCabezaId.isNotEmpty && mascota.itemCabezaId != itemId) {
        inventoryUpdates['equipado_en.${mascota.itemCabezaId}'] = null;
      }
      batch.update(cosmeticsRef, inventoryUpdates);
      await batch.commit();

      return true;
    } catch (e) {
      debugPrint('Error equipar item cabeza: $e');
      return false;
    }
  }

  Future<void> quitarItemCabeza() async {
    final mascota = state.mascota;
    final userId = _auth.currentUser?.uid;
    if (mascota == null || userId == null) return;

    try {
      final despues = mascota.copyWith(clearItemCabezaId: true);
      emit(state.copyWith(mascota: despues));
      await _inventoryRepository.ensureDefaultInventory(userId);
      final mascotaRef = _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('mascotas')
          .doc(mascota.idMascota);
      final cosmeticsRef = _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('inventario')
          .doc('cosmeticos');
      final batch = _firestore.batch();
      batch.update(mascotaRef, {'item_cabeza_id': ''});
      if (mascota.itemCabezaId.isNotEmpty) {
        batch.update(cosmeticsRef, {
          'equipado_en.${mascota.itemCabezaId}': null,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error quitar item cabeza: $e');
    }
  }

  // HELPERS INTERNOS
  // ══════════════════════════════════════════════════════

  Future<void> actualizarEstadoPlato({
    double? nivelPlato,
    String? platoAlimentoId,
    bool clearPlatoAlimentoId = false,
    String? platoEmoji,
    bool clearPlatoEmoji = false,
    bool? platoComiendo,
    DateTime? platoActualizado,
  }) async {
    final mascota = state.mascota;
    if (mascota == null) return;

    final despues = mascota.copyWith(
      nivelPlato: nivelPlato ?? mascota.nivelPlato,
      platoAlimentoId: platoAlimentoId,
      clearPlatoAlimentoId: clearPlatoAlimentoId,
      platoEmoji: platoEmoji,
      clearPlatoEmoji: clearPlatoEmoji,
      platoComiendo: platoComiendo ?? mascota.platoComiendo,
      platoActualizado: platoActualizado ?? DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarSoloPlatoEnFirestore(antes: mascota, despues: despues);

    if (despues.platoComiendo && despues.nivelPlato > 0) {
      _iniciarComidaPlatoOnlineSiAplica();
    } else {
      _detenerComidaPlatoOnline();
    }
  }

  Future<void> iniciarComidaPlato() async {
    final mascota = state.mascota;
    if (mascota == null || mascota.nivelPlato <= 0) return;
    await actualizarEstadoPlato(
      platoComiendo: true,
      platoActualizado: DateTime.now(),
    );
  }

  Future<void> detenerComidaPlato() async {
    final mascota = state.mascota;
    if (mascota == null) return;
    await actualizarEstadoPlato(
      platoComiendo: false,
      platoActualizado: DateTime.now(),
    );
  }

  Future<bool> sincronizarPlatoOffline() async {
    final antes = state.mascota;
    if (antes == null || antes.nivelPlato <= 0) return false;

    final desde = antes.platoActualizado ?? antes.ultimaInteraccion;
    final ticks =
        DateTime.now().difference(desde).inMinutes ~/
        _deterioroIntervalo.inMinutes;
    final ticksAplicados = ticks.clamp(0, _maxTicksPlatoAusencia).toInt();
    if (ticksAplicados <= 0) return false;

    var plato = antes.nivelPlato;
    var hambre = antes.nivelHambre;
    var afecto = antes.nivelAfecto;
    var comioEnAusencia = false;
    final probComer = _chanceComerPlato(antes.rasgo);
    final puntosPaso = _puntosHambrePorPaso(antes.platoAlimentoId);

    for (var i = 0; i < ticksAplicados; i++) {
      if (plato <= 0) break;

      plato = (plato - 10).clamp(0, 100);
      if (plato <= 0) break;

      if (_random.nextDouble() <= probComer) {
        plato = (plato - 5).clamp(0, 100);
        hambre = (hambre + puntosPaso).clamp(0, 100).toInt();
        afecto = (afecto + 1).clamp(0, 100).toInt();
        comioEnAusencia = true;
      }
    }

    final despues = antes.copyWith(
      nivelPlato: plato.toDouble(),
      nivelHambre: hambre,
      nivelAfecto: afecto,
      platoActualizado: DateTime.now(),
      platoComiendo: plato > 0 ? antes.platoComiendo : false,
      clearPlatoAlimentoId: plato <= 0,
      clearPlatoEmoji: plato <= 0,
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(
      antes: antes,
      despues: despues,
      accion: 'plato_offline_sync',
      extras: {
        'ticks_plato_aplicados': ticksAplicados,
        'nivel_plato_antes': antes.nivelPlato,
        'nivel_plato_despues': despues.nivelPlato,
      },
    );
    return comioEnAusencia;
  }

  void _iniciarComidaPlatoOnlineSiAplica() {
    final mascota = state.mascota;
    if (mascota == null || !mascota.platoComiendo || mascota.nivelPlato <= 0) {
      _detenerComidaPlatoOnline();
      return;
    }

    _platoComidaTimer?.cancel();
    _platoComidaTimer = Timer.periodic(_platoPasoIntervalo, (_) async {
      await _tickComidaPlatoOnline();
    });
  }

  void _detenerComidaPlatoOnline() {
    _platoComidaTimer?.cancel();
    _platoComidaTimer = null;
  }

  Future<void> _tickComidaPlatoOnline() async {
    final antes = state.mascota;
    if (antes == null || !antes.platoComiendo) {
      _detenerComidaPlatoOnline();
      return;
    }

    if (antes.nivelPlato <= 0) {
      final vacio = antes.copyWith(
        nivelPlato: 0,
        platoComiendo: false,
        clearPlatoAlimentoId: true,
        clearPlatoEmoji: true,
        platoActualizado: DateTime.now(),
      );
      emit(state.copyWith(mascota: vacio));
      await _guardarSoloPlatoEnFirestore(antes: antes, despues: vacio);
      _detenerComidaPlatoOnline();
      return;
    }

    final chanceComer = _chanceComerPlato(antes.rasgo);
    final comio = _random.nextDouble() <= chanceComer;

    final nuevoPlato = (antes.nivelPlato - 5).clamp(0, 100).toDouble();
    final nuevaHambre = comio
        ? (antes.nivelHambre + _puntosHambrePorPaso(antes.platoAlimentoId))
              .clamp(0, 100)
              .toInt()
        : antes.nivelHambre;
    final nuevoAfecto = comio
        ? (antes.nivelAfecto + 1).clamp(0, 100).toInt()
        : antes.nivelAfecto;
    final sigueComiendo = comio && nuevoPlato > 0;

    final despues = antes.copyWith(
      nivelPlato: nuevoPlato,
      nivelHambre: nuevaHambre,
      nivelAfecto: nuevoAfecto,
      platoComiendo: sigueComiendo,
      platoActualizado: DateTime.now(),
      clearPlatoAlimentoId: nuevoPlato <= 0,
      clearPlatoEmoji: nuevoPlato <= 0,
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(
      antes: antes,
      despues: despues,
      accion: 'comer_plato_online',
      extras: {
        'comio': comio,
        'nivel_plato_antes': antes.nivelPlato,
        'nivel_plato_despues': despues.nivelPlato,
      },
    );

    if (!sigueComiendo) {
      _detenerComidaPlatoOnline();
    }
  }

  double _chanceComerPlato(String rasgo) {
    return PersonalidadTipo.fromString(rasgo) == PersonalidadTipo.gloton
        ? 0.60
        : 0.55;
  }

  int _puntosHambrePorPaso(String? foodId) {
    final food = FoodCatalog.byId(foodId);
    if (food == null) return 5;
    final base = (food.hungerPoints * 0.25).round();
    return base.clamp(2, 12).toInt();
  }

  double _chanceTirarComidaPorRasgo(String rasgo) {
    final personalidad = PersonalidadTipo.fromString(rasgo);
    if (personalidad == PersonalidadTipo.travieso) return 0.45;
    if (personalidad == PersonalidadTipo.jugueton) return 0.30;
    return 0.0;
  }

  String? _misionRecogerComidaPorRasgo(String rasgo) {
    final personalidad = PersonalidadTipo.fromString(rasgo);
    if (personalidad == PersonalidadTipo.travieso) {
      return 'travieso_recoger_comida';
    }
    if (personalidad == PersonalidadTipo.jugueton) {
      return 'jugueton_recoger_comida';
    }
    return null;
  }

  int _recompensaCoinsPorMision(String misionId) {
    switch (misionId) {
      case _bathMissionId:
        return 15;
      case 'travieso_recoger_comida':
      case 'jugueton_recoger_comida':
      case 'recoger_comida':
        return _defaultMissionRewardCoins;
      default:
        return _defaultMissionRewardCoins;
    }
  }

  String? _tipoPorMision(String misionId) {
    switch (misionId) {
      case _bathMissionId:
        return 'bano';
      case 'travieso_recoger_comida':
      case 'jugueton_recoger_comida':
      case 'recoger_comida':
        return 'recoger_comida';
      default:
        return null;
    }
  }

  Map<String, int> _distribucionComidaTravieso(int totalPiezas) {
    final pantallas = <String>[
      disasterScreenDormir,
      disasterScreenHome,
      disasterScreenAlimentar,
    ];
    final resultado = <String, int>{
      disasterScreenDormir: 0,
      disasterScreenHome: 0,
      disasterScreenAlimentar: 0,
    };

    for (var i = 0; i < totalPiezas; i++) {
      final pantalla = pantallas[_random.nextInt(pantallas.length)];
      resultado[pantalla] = (resultado[pantalla] ?? 0) + 1;
    }
    return resultado;
  }

  Future<void> _evaluarMisionRecogerComidaOffline(bool comioOffline) async {
    final mascota = state.mascota;
    if (mascota == null || !comioOffline) return;

    final chanceTirar = _chanceTirarComidaPorRasgo(mascota.rasgo);
    if (chanceTirar <= 0 || _random.nextDouble() > chanceTirar) return;

    final misionId = _misionRecogerComidaPorRasgo(mascota.rasgo);
    if (misionId == null) return;

    await _crearMisionActiva(misionId, mascota.idMascota);

    const piezas = 5;
    final emojiComida = mascota.platoEmoji.isNotEmpty
        ? mascota.platoEmoji
        : 'ðŸ–';

    if (mascota.personalidad == PersonalidadTipo.travieso) {
      await disasterCubit?.generarDesastreDistribuido(
        mascotaId: mascota.idMascota,
        tipo: DisasterType.comida,
        emoji: emojiComida,
        cantidadPorPantalla: _distribucionComidaTravieso(piezas),
      );
      await _aplicarSuciedadPorDesastre(
        _puntosSuciedadPorDesastre(DisasterType.comida),
        accion: 'desastre_comida_offline',
        extras: {
          'tipo_desastre': DisasterType.comida.name,
          'cantidad_piezas': piezas,
          'distribuido': true,
        },
      );
      return;
    }

    await disasterCubit?.generarDesastre(
      mascotaId: mascota.idMascota,
      tipo: DisasterType.comida,
      emoji: emojiComida,
      cantidad: piezas,
      pantalla: disasterScreenAlimentar,
    );
    await _aplicarSuciedadPorDesastre(
      _puntosSuciedadPorDesastre(DisasterType.comida),
      accion: 'desastre_comida_offline',
      extras: {
        'tipo_desastre': DisasterType.comida.name,
        'cantidad_piezas': piezas,
        'distribuido': false,
      },
    );
  }

  void _iniciarDeterioroOnline() {
    _deterioroTimer?.cancel();
    _deterioroTimer = Timer.periodic(_deterioroIntervalo, (_) async {
      await aplicarDeterioro();
    });
  }

  void _detenerDeterioroOnline() {
    _deterioroTimer?.cancel();
    _deterioroTimer = null;
  }

  @override
  Future<void> close() {
    _detenerDeterioroOnline();
    _detenerComidaPlatoOnline();
    return super.close();
  }

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
            'ticks_energia_baja': despues.ticksEnergiaBaja,
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

      final updateData = <String, dynamic>{
        'nivel_salud': despues.nivelSalud,
        'nivel_energia': despues.nivelEnergia,
        'nivel_hambre': despues.nivelHambre,
        'nivel_limpieza': despues.nivelLimpieza,
        'nivel_afecto': despues.nivelAfecto,
        'nivel_plato': despues.nivelPlato,
        'plato_alimento_id': despues.platoAlimentoId,
        'plato_emoji': despues.platoEmoji,
        'plato_actualizado': despues.platoActualizado != null
            ? Timestamp.fromDate(despues.platoActualizado!)
            : null,
        'plato_comiendo': despues.platoComiendo,
        'ticks_energia_baja': despues.ticksEnergiaBaja,
        'ultima_interaccion': Timestamp.now(),
        'deterioro_acelerado': despues.deterioroAcelerado,
        'anomalia_detectada': despues.anomaliaDetectada,
        'anomaliaActiva': despues.anomaliaDetectada,
      };

      switch (accion) {
        case 'alimentar':
          updateData['ultima_comida'] = Timestamp.now();
          break;
        case 'jugar':
          updateData['ultimo_juego'] = Timestamp.now();
          break;
        case 'banar':
          updateData['ultimo_bano'] = Timestamp.now();
          break;
        case 'curar':
          updateData['ultima_curacion'] = Timestamp.now();
          break;
        case 'pasear':
          updateData['ultimo_paseo'] = Timestamp.now();
          break;
      }

      await mascotaRef.update(updateData);

      final ahora = DateTime.now();
      await mascotaRef.collection('progreso').add({
        'id_mision': accion,
        'accion_realizada': accion,
        'hora_dia': ahora.hour + (ahora.minute / 60.0),
        'fecha_actualizacion': Timestamp.now(),
        'estado_antes': antes.nivelesMap,
        'estado_despues': despues.nivelesMap,
        'rasgo': antes.personalidad.toFirestoreString(),
        ...?extras,
      });
    } catch (e) {
      debugPrint('Error Firestore ($accion): $e');
    }
  }

  Future<void> _guardarSoloPlatoEnFirestore({
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
            'nivel_plato': despues.nivelPlato,
            'plato_alimento_id': despues.platoAlimentoId,
            'plato_emoji': despues.platoEmoji,
            'plato_actualizado': despues.platoActualizado != null
                ? Timestamp.fromDate(despues.platoActualizado!)
                : null,
            'plato_comiendo': despues.platoComiendo,
            'ultima_interaccion': Timestamp.now(),
          });
    } catch (e) {
      debugPrint('Error guardar plato: $e');
    }
  }

  Future<void> _crearMisionActiva(
    String misionId,
    String mascotaId, {
    int? urgencia,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    try {
      final rewardCoins = _recompensaCoinsPorMision(misionId);
      final tipo = _tipoPorMision(misionId);
      final data = <String, dynamic>{
        'id_mision': misionId,
        'estado': 'pendiente',
        'fecha_asignada': Timestamp.now(),
        'fecha_completada': null,
        'streak': 0,
      };
      if (tipo != null) {
        data['tipo'] = tipo;
      }
      if (rewardCoins > 0) {
        data['reward_coins'] = rewardCoins;
      }
      if (urgencia != null) {
        data['urgencia'] = urgencia;
      }

      await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId)
          .collection('misiones_activas')
          .doc(misionId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error mision: $e');
    }
  }

  Future<void> _sincronizarMisionBano(MascotaModel mascota) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final nivelLimpieza = mascota.nivelLimpieza;
    if (nivelLimpieza >= _bathMissionThreshold) return;

    final esUrgente = nivelLimpieza < _bathMissionUrgentThreshold;
    final rewardCoins = esUrgente ? 30 : 15;
    final titulo = esUrgente ? 'Baño urgente' : 'Baño necesario';
    final descripcion = esUrgente
        ? 'Tu mascota esta muy sucia. Dale un baño completo cuanto antes.'
        : 'Tu mascota necesita un baño para recuperar su limpieza.';

    try {
      await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('mascotas')
          .doc(mascota.idMascota)
          .collection('misiones_activas')
          .doc(_bathMissionId)
          .set({
            'id_mision': _bathMissionId,
            'titulo': titulo,
            'descripcion': descripcion,
            'tipo': 'bano',
            'categoria': 'bano',
            'accion_trigger': 'banar',
            'condicion': 'nivel_limpieza < $_bathMissionThreshold',
            'estado': 'pendiente',
            'fecha_asignada': Timestamp.now(),
            'fecha_completada': null,
            'streak': 0,
            'reward_coins': rewardCoins,
            'nivel_limpieza_inicial': nivelLimpieza,
            'urgencia_bano': esUrgente ? 'urgente' : 'normal',
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error mision bano: $e');
    }
  }

  Future<void> _completarMisionBano(MascotaModel mascota) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final missionRef = _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('mascotas')
          .doc(mascota.idMascota)
          .collection('misiones_activas')
          .doc(_bathMissionId);

      final snap = await missionRef.get();
      if (!snap.exists) return;

      final data = snap.data() ?? <String, dynamic>{};
      if ((data['estado'] as String?) != 'pendiente') return;

      await missionRef.set({
        'estado': 'completada',
        'fecha_completada': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error completar mision bano: $e');
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
          await _aplicarSuciedadPorDesastre(
            _puntosSuciedadPorDesastre(
              DisasterType.values.byName(r.desastreTipo!),
            ),
            accion: 'reaccion_desastre',
            extras: {
              'tipo_desastre': r.desastreTipo!,
              'cantidad_desastre': r.desastreCantidad,
              'origen': r.nivel,
            },
          );
        }
      }
    }
  }

  int _puntosSuciedadPorDesastre(DisasterType tipo) {
    return switch (tipo) {
      DisasterType.comida => 10,
      DisasterType.basura => 12,
      DisasterType.juguete => 6,
      DisasterType.porcion => 8,
    };
  }

  Future<void> _aplicarSuciedadPorDesastre(
    int puntos, {
    required String accion,
    Map<String, dynamic>? extras,
  }) async {
    final antes = state.mascota;
    if (antes == null || puntos <= 0) return;

    final despues = antes.copyWith(
      nivelLimpieza: (antes.nivelLimpieza - puntos).clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(
      antes: antes,
      despues: despues,
      accion: accion,
      extras: {'puntos_limpieza': -puntos, ...?extras},
    );
    await _reprogramarRecordatorioCuidado();
  }

  int _calcularDanoSaludCondicional({
    required int nivelHambre,
    required int nivelLimpieza,
    required int nivelAfecto,
    required int ticksEnergiaBaja,
  }) {
    final condicionActiva =
        nivelHambre < _umbralHambreSalud ||
        nivelLimpieza < _umbralLimpiezaSalud ||
        nivelAfecto < _umbralAfectoSalud ||
        ticksEnergiaBaja >= _ticksEnergiaBajaParaDano;

    return condicionActiva ? 2 : 0;
  }

  // ══════════════════════════════════════════════════════
  // ACCIONES DEL JUEGO
  // ══════════════════════════════════════════════════════

  Future<void> alimentar(
    int puntosBase, {
    String? emojiAlimento,
    bool skipDisasterRoll = false,
  }) async {
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
      ultimaComida: DateTime.now(),
    );

    final generoDesastreComida =
        !skipDisasterRoll &&
        (mod?.alimentarPuedeTirar ?? false) &&
        _random.nextDouble() < 0.3;

    emit(state.copyWith(mascota: despues));

    if (generoDesastreComida) {
      await disasterCubit?.generarDesastre(
        mascotaId: antes.idMascota,
        tipo: DisasterType.comida,
        emoji: emojiAlimento ?? '🍖',
        cantidad: 3 + _random.nextInt(4),
      );
      await _aplicarSuciedadPorDesastre(
        _puntosSuciedadPorDesastre(DisasterType.comida),
        accion: 'desastre_comida_alimentar',
        extras: {'tipo_desastre': DisasterType.comida.name},
      );
    }

    await _guardarEnFirestore(
      antes: antes,
      despues: despues,
      accion: 'alimentar',
      extras: {'emoji_alimento': emojiAlimento ?? ''},
    );
    await _reprogramarRecordatorioCuidado();
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
    final suciedadAlJugar =
        _jugarSuciedadBase + (mod?.jugarLimpieza.abs().round() ?? 0);

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
      nivelLimpieza: (antes.nivelLimpieza - suciedadAlJugar)
          .round()
          .clamp(0, 100),
      nivelSalud: (antes.nivelSalud + (mod?.jugarSaludBonus ?? 0.0))
          .round()
          .clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
      ultimoJuego: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(
      antes: antes,
      despues: despues,
      accion: 'jugar',
      extras: {
        'emoji_juguete': emojiJuguete ?? '',
        'puntos_limpieza': -suciedadAlJugar,
      },
    );
    await _sincronizarMisionBano(despues);
    await _reprogramarRecordatorioCuidado();
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
      ultimoBano: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'banar');
    await _completarMisionBano(despues);
    await _reprogramarRecordatorioCuidado();
    await _verificarReacciones(despues);
  }

  Future<void> aumentarLimpieza(
    int puntos, {
    String accion = 'aumentar_limpieza',
  }) async {
    final antes = state.mascota;
    if (antes == null || puntos == 0) return;

    final despues = antes.copyWith(
      nivelLimpieza: (antes.nivelLimpieza + puntos).clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(
      antes: antes,
      despues: despues,
      accion: accion,
      extras: {'puntos_limpieza': puntos},
    );
    await _sincronizarMisionBano(despues);
    await _reprogramarRecordatorioCuidado();
    await _verificarReacciones(despues);
  }

  Future<void> aumentarAfecto(
    int puntos, {
    String accion = 'aumentar_afecto',
  }) async {
    final antes = state.mascota;
    if (antes == null || puntos == 0) return;

    final despues = antes.copyWith(
      nivelAfecto: (antes.nivelAfecto + puntos).clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(
      antes: antes,
      despues: despues,
      accion: accion,
      extras: {'puntos_afecto': puntos},
    );
    await _reprogramarRecordatorioCuidado();
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
      ticksEnergiaBaja:
          (antes.nivelEnergia + BaseActionValues.curarEnergia) >=
              _umbralEnergiaBaja
          ? 0
          : antes.ticksEnergiaBaja,
      nivelAfecto:
          (antes.nivelAfecto +
                  (BaseActionValues.curarAfecto * (mod?.curarAfecto ?? 1.0)))
              .round()
              .clamp(0, 100),
      ultimaInteraccion: DateTime.now(),
      ultimaCuracion: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'curar');
    await _reprogramarRecordatorioCuidado();
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
      ticksEnergiaBaja:
          ((antes.nivelEnergia +
                      (BaseActionValues.pasearEnergia *
                          (mod?.pasearEnergia ?? 1.0)))
                  .round()) >=
              _umbralEnergiaBaja
          ? 0
          : antes.ticksEnergiaBaja,
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
      ultimoPaseo: DateTime.now(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(antes: antes, despues: despues, accion: 'pasear');
    await _reprogramarRecordatorioCuidado();
    await _verificarReacciones(despues);
  }

  Future<void> aplicarDeterioro({double factorExtra = 1.0}) async {
    final antes = state.mascota;
    if (antes == null || antes.estaDescansando) {
      return; // no deteriorar si descansa
    }

    final userId = _auth.currentUser?.uid;
    final missionRepository = _missionRepository;
    final List<MisionActivaModel> misionesActivas = missionRepository != null
        ? await missionRepository.loadActiveMissionModels(antes.idMascota)
        : const <MisionActivaModel>[];
    final previewDecision = userId != null
        ? await _petAiEngine.evaluateAsync(
            antes,
            userId,
            misionesActivas: misionesActivas,
          )
        : _petAiEngine.evaluate(antes);
    final despuesBase = _calcularDeterioro(
      antes,
      factorExtra: factorExtra * previewDecision.deterioroRate,
    );
    final decision = userId != null
        ? await _petAiEngine.evaluateAsync(
            despuesBase,
            userId,
            misionesActivas: misionesActivas,
          )
        : _petAiEngine.evaluate(despuesBase);
    final despues = despuesBase.copyWith(
      deterioroRate: decision.deterioroRate,
      anomaliaActiva: decision.anomaliaActiva,
      anomaliaDetectada: decision.anomaliaActiva,
      estadoEmocional: decision.emotion.toFirestoreString(),
    );

    emit(state.copyWith(mascota: despues));
    await _guardarEnFirestore(
      antes: antes,
      despues: despues,
      accion: 'deterioro',
    );
    await _persistirDecisionAi(despues, decision.deterioroRate);
    await _aplicarDecisionMision(despues, decision);
    if (decision.generarDesastre) {
      await disasterCubit?.triggerFromAiDecision(decision);
      await _aplicarSuciedadPorDesastre(
        _puntosSuciedadPorDesastre(DisasterType.basura),
        accion: 'desastre_ai',
        extras: {'tipo_desastre': DisasterType.basura.name},
      );
    }
    await _guardarAiHistory(despues, decision);
    await _sincronizarMisionBano(despues);
    await _verificarReacciones(despues);
  }

  MascotaModel _calcularDeterioro(
    MascotaModel mascota, {
    double factorExtra = 1.0,
  }) {
    final config = PersonalityRegistry.get(mascota.rasgo);
    final dec = config?.deterioro;
    final factor = factorExtra;

    // Buff activo: energia cae a la mitad
    final factorEnergia = mascota.buffActivo ? 0.5 : 1.0;
    final energiaNueva =
        (mascota.nivelEnergia -
                (BaseActionValues.deterioroEnergia *
                    (dec?.energia ?? 1.0) *
                    factor *
                    factorEnergia))
            .round()
            .clamp(0, 100);
    final hambreNueva =
        (mascota.nivelHambre -
                (BaseActionValues.deterioroHambre *
                    (dec?.hambre ?? 1.0) *
                    factor))
            .round()
            .clamp(0, 100);
    final limpiezaNueva =
        (mascota.nivelLimpieza -
                (BaseActionValues.deterioroLimpieza *
                    (dec?.limpieza ?? 1.0) *
                    factor))
            .round()
            .clamp(0, 100);
    final afectoNuevo =
        (mascota.nivelAfecto -
                (BaseActionValues.deterioroAfecto *
                    (dec?.afecto ?? 1.0) *
                    factor))
            .round()
            .clamp(0, 100);
    final ticksEnergiaBajaNuevo = energiaNueva < _umbralEnergiaBaja
        ? (mascota.ticksEnergiaBaja + 1).clamp(0, 999)
        : 0;
    final danoSalud = _calcularDanoSaludCondicional(
      nivelHambre: hambreNueva,
      nivelLimpieza: limpiezaNueva,
      nivelAfecto: afectoNuevo,
      ticksEnergiaBaja: ticksEnergiaBajaNuevo,
    );

    return mascota.copyWith(
      nivelSalud: (mascota.nivelSalud - danoSalud).clamp(0, 100),
      nivelEnergia: energiaNueva,
      nivelHambre: hambreNueva,
      nivelLimpieza: limpiezaNueva,
      nivelAfecto: afectoNuevo,
      ticksEnergiaBaja: ticksEnergiaBajaNuevo,
      ultimaInteraccion: DateTime.now(),
    );
  }

  Future<void> _reprogramarRecordatorioCuidado() async {
    try {
      await NotificationService.instance.rescheduleCareReminderForCurrentUser();
    } catch (error) {
      debugPrint('Error recordatorio cuidado: $error');
    }
  }

  Future<void> _persistirDecisionAi(
    MascotaModel mascota,
    double deterioroRate,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _petRepository.updatePetFields(userId, mascota.idMascota, {
        'deterioro_rate': deterioroRate,
        'anomalia_activa': mascota.anomaliaActiva,
        'anomalia_detectada': mascota.anomaliaActiva,
        'anomaliaActiva': mascota.anomaliaActiva,
        'estado_emocional': mascota.estadoEmocional,
      });
    } catch (error) {
      debugPrint('Error persistiendo decision AI: $error');
    }
  }

  Future<void> _aplicarDecisionMision(
    MascotaModel mascota,
    PetAiDecision decision,
  ) async {
    final missionId = decision.misionRecomendada;
    if (missionId == null || missionId.isEmpty) return;

    try {
      final missionRepository = _missionRepository;
      if (missionRepository != null &&
          decision.reemplazarActiva &&
          decision.misionesAReemplazar.isNotEmpty) {
        await missionRepository.cancelActiveMissions(
          mascota.idMascota,
          decision.misionesAReemplazar,
        );
      }

      await _crearMisionActiva(
        missionId,
        mascota.idMascota,
        urgencia: decision.urgenciaMision,
      );
    } catch (error) {
      debugPrint('Error aplicando decision de mision: $error');
    }
  }

  Future<void> triggerRoutineAnalysis() async {
    final userId = _auth.currentUser?.uid;
    final mascota = state.mascota;
    if (userId == null || mascota == null) return;

    try {
      await _routineAnalyzer?.analyzeAndUpdate(userId, mascota.idMascota);
    } catch (error) {
      debugPrint('Error analizando rutina: $error');
    }
  }

  Future<void> _guardarAiHistory(
    MascotaModel mascota,
    PetAiDecision decision,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || _aiStateRepository == null) return;

    try {
      await _aiStateRepository.saveEntry(
        userId,
        mascota.idMascota,
        AiHistoryEntry(
          id: '',
          createdAt: DateTime.now(),
          deterioroRate: decision.deterioroRate,
          anomaliaActiva: decision.anomaliaActiva,
          estadoEmocional: decision.emotion.toFirestoreString(),
          necesidadPrioritaria: decision.needPriority.toDisplayString(),
          misionRecomendada: decision.misionRecomendada,
          mensaje: decision.mensaje,
          source: 'tick',
        ),
      );
      await _aiStateRepository.deleteOldEntries(userId, mascota.idMascota);
    } catch (error) {
      debugPrint('Error guardando ai_history: $error');
    }
  }
}
