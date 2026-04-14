// ══════════════════════════════════════════════════════════════
// personality_config.dart
// lib/core/personality_config.dart
//
// NÚCLEO DE COMPORTAMIENTO DE LA MASCOTA
// Este archivo es la única fuente de verdad para las personalidades.
// Para agregar una nueva personalidad:
//   1. Agrega un nuevo PersonalityConfig a la lista _configs
//   2. Define sus modificadores, misiones y reacciones
//   3. No necesitas tocar ningún otro archivo — el PetCubit
//      y el Motor de IA leen todo desde aquí.
// ══════════════════════════════════════════════════════════════

// ── Modificadores de acción ────────────────────────────────────
// Cada valor multiplica el efecto BASE de esa acción.
// Ejemplo: hambreMultiplier: 1.5 en alimentar → sube 50% más hambre
class ActionModifiers {
  // Alimentar
  final double alimentarHambre;
  final double alimentarSalud;
  final double alimentarAfecto;
  final bool alimentarTiraComida; // genera misión recoger

  // Jugar
  final double jugarAfecto;
  final double jugarEnergiaCosto;
  final double jugarHambreCosto;

  // Bañar
  final double banarLimpieza;
  final double banarAfecto;

  // Dormir
  final double dormirEnergia;
  final double dormirAfecto; // tiernos extrañan al niño

  // Curar
  final double curarSalud;

  // Pasear
  final double pasearAfecto;
  final double pasearEnergia;
  final double pasearHambreCosto;

  const ActionModifiers({
    // Alimentar
    this.alimentarHambre      = 1.0,
    this.alimentarSalud       = 1.0,
    this.alimentarAfecto      = 1.0,
    this.alimentarTiraComida  = false,
    // Jugar
    this.jugarAfecto          = 1.0,
    this.jugarEnergiaCosto    = 1.0,
    this.jugarHambreCosto     = 1.0,
    // Bañar
    this.banarLimpieza        = 1.0,
    this.banarAfecto          = 1.0,
    // Dormir
    this.dormirEnergia        = 1.0,
    this.dormirAfecto         = 0.0, // 0 = sin cambio, negativo = baja
    // Curar
    this.curarSalud           = 1.0,
    // Pasear
    this.pasearAfecto         = 1.0,
    this.pasearEnergia        = 1.0,
    this.pasearHambreCosto    = 1.0,
  });
}

// ── Modificadores de deterioro ─────────────────────────────────
// Multiplican la velocidad a la que bajan los niveles con el tiempo.
// 1.0 = normal, 2.0 = doble de rápido, 0.5 = mitad de rápido
class DecayModifiers {
  final double salud;
  final double energia;
  final double hambre;
  final double limpieza;
  final double afecto;
  final double anomaliaFactor; // multiplicador extra cuando hay anomalía IA

  const DecayModifiers({
    this.salud          = 1.0,
    this.energia        = 1.0,
    this.hambre         = 1.0,
    this.limpieza       = 1.0,
    this.afecto         = 1.0,
    this.anomaliaFactor = 5.0, // por defecto anomalía = ×5
  });
}

// ── Reacciones a estados críticos ─────────────────────────────
// Define cómo reacciona la mascota cuando un nivel llega a cierto umbral.
class StateReaction {
  final String nivel;        // 'hambre','afecto','energia','salud','limpieza'
  final int umbral;          // valor en que se activa (ej: 20)
  final String estado;       // texto del estado visible ('hambriento','triste'...)
  final String mensaje;      // mensaje que muestra la mascota
  final String? misionId;   // si genera misión automática, su id
  final bool generaAlerta;  // si manda notificación push

  const StateReaction({
    required this.nivel,
    required this.umbral,
    required this.estado,
    required this.mensaje,
    this.misionId,
    this.generaAlerta = false,
  });
}

// ── Misión fija de personalidad ────────────────────────────────
// Misiones que SIEMPRE existen para esta personalidad,
// independientemente de lo que haga el niño.
class PersonalityMission {
  final String id;
  final String titulo;
  final String descripcion;
  final String tipo;          // 'diaria', 'semanal', 'unica', 'reactiva'
  final String accionTrigger; // qué acción la activa ('alimentar','jugar',etc.)
  final String condicion;     // cuándo se activa (texto descriptivo)
  final int recompensaXp;
  final String educationalTip;
  final bool esEspecial;      // misión exclusiva de esta personalidad

  const PersonalityMission({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    required this.accionTrigger,
    required this.condicion,
    required this.recompensaXp,
    required this.educationalTip,
    this.esEspecial = false,
  });
}

// ── Configuración completa de personalidad ─────────────────────
class PersonalityConfig {
  final String rasgo;           // clave única: 'Juguetón','Travieso', etc.
  final String emoji;
  final String descripcion;     // descripción para el niño
  final String descripcionIa;   // descripción técnica para el Motor de IA
  final ActionModifiers acciones;
  final DecayModifiers deterioro;
  final List<StateReaction> reacciones;
  final List<PersonalityMission> misiones;

  const PersonalityConfig({
    required this.rasgo,
    required this.emoji,
    required this.descripcion,
    required this.descripcionIa,
    required this.acciones,
    required this.deterioro,
    required this.reacciones,
    required this.misiones,
  });
}

// ══════════════════════════════════════════════════════════════
// CATÁLOGO DE PERSONALIDADES
// Agrega nuevas personalidades al final de esta lista.
// ══════════════════════════════════════════════════════════════
class PersonalityRegistry {

  // Acceso rápido por rasgo
  static PersonalityConfig? get(String rasgo) {
    try {
      return _configs.firstWhere((c) => c.rasgo == rasgo);
    } catch (_) {
      return _configs.first; // Curioso por defecto
    }
  }

  // Lista de todos los rasgos disponibles
  static List<String> get rasgos => _configs.map((c) => c.rasgo).toList();

  static const List<PersonalityConfig> _configs = [

    // ──────────────────────────────────────────────────────────
    // JUGUETÓN
    // ──────────────────────────────────────────────────────────
    PersonalityConfig(
      rasgo: 'Juguetón',
      emoji: '⚽',
      descripcion: 'Le encanta jugar y correr todo el tiempo. Necesita mucha actividad.',
      descripcionIa: 'Energía baja 2× más rápido. Al alimentar tiene 30% de probabilidad de tirar comida.',

      acciones: ActionModifiers(
        alimentarHambre:     1.0,
        alimentarTiraComida: true,  // 30% de veces tira la comida
        jugarAfecto:         1.5,   // le encanta jugar
        jugarEnergiaCosto:   1.3,   // se cansa más
        banarLimpieza:       0.8,   // le cuesta bañarse
        dormirEnergia:       1.0,
        pasearAfecto:        1.4,
        pasearEnergia:       1.2,
      ),

      deterioro: DecayModifiers(
        energia:        2.0,  // se cansa el doble de rápido
        hambre:         1.2,
        afecto:         1.5,  // necesita mucha atención
        anomaliaFactor: 5.0,
      ),

      reacciones: [
        StateReaction(
          nivel: 'energia', umbral: 20,
          estado: 'agotado',
          mensaje: '¡Estoy muy cansado... necesito descansar!',
          misionId: 'dormir_jugueton',
          generaAlerta: true,
        ),
        StateReaction(
          nivel: 'afecto', umbral: 30,
          estado: 'aburrido',
          mensaje: '¡Quiero jugar! ¡Estoy muy aburrido!',
          misionId: 'jugar_urgente',
          generaAlerta: true,
        ),
        StateReaction(
          nivel: 'hambre', umbral: 15,
          estado: 'hambriento',
          mensaje: '¡Me comí toda la comida que tiré! ¡Tengo hambre!',
          generaAlerta: false,
        ),
      ],

      misiones: [
        PersonalityMission(
          id: 'jugueton_recoger_comida',
          titulo: '¡A limpiar el desastre!',
          descripcion: 'Tu mascota tiró la comida por toda la cocina. Recoge cada pieza.',
          tipo: 'reactiva',
          accionTrigger: 'alimentar',
          condicion: 'Se activa cuando alimentarTiraComida ocurre',
          recompensaXp: 30,
          educationalTip: 'Los animales juguetones necesitan rutinas de alimentación tranquilas.',
          esEspecial: true,
        ),
        PersonalityMission(
          id: 'jugueton_jugar_diario',
          titulo: '¡Hora de jugar!',
          descripcion: 'Juega al menos 2 veces hoy con tu mascota.',
          tipo: 'diaria',
          accionTrigger: 'jugar',
          condicion: 'jugadas >= 2 en el día',
          recompensaXp: 25,
          educationalTip: 'Los perros juguetones necesitan al menos 30 minutos de ejercicio al día.',
        ),
        PersonalityMission(
          id: 'jugueton_paseo_energia',
          titulo: '¡Al parque!',
          descripcion: 'Lleva a tu mascota a pasear para gastar su energía.',
          tipo: 'diaria',
          accionTrigger: 'pasear',
          condicion: 'energia > 80',
          recompensaXp: 20,
          educationalTip: 'Un perro con mucha energía necesita espacio para correr.',
        ),
      ],
    ),

    // ──────────────────────────────────────────────────────────
    // TRAVIESO
    // ──────────────────────────────────────────────────────────
    PersonalityConfig(
      rasgo: 'Travieso',
      emoji: '😈',
      descripcion: 'Hace travesuras si lo descuidas. Requiere atención constante.',
      descripcionIa: 'Deterioro ×3 si hay anomalía. Al alimentar tira la comida. Limpieza baja 2× más rápido.',

      acciones: ActionModifiers(
        alimentarHambre:     0.2,   // casi no come, tira todo
        alimentarTiraComida: true,  // siempre tira la comida
        alimentarAfecto:     0.5,
        jugarAfecto:         1.2,
        jugarEnergiaCosto:   0.9,
        banarLimpieza:       0.6,   // se ensucia de nuevo rápido
        banarAfecto:         0.8,   // no le gusta bañarse
        dormirEnergia:       1.2,
        pasearAfecto:        1.3,
        pasearEnergia:       1.1,
      ),

      deterioro: DecayModifiers(
        salud:          1.0,
        energia:        1.0,
        hambre:         1.5,  // se queda con hambre por tirar comida
        limpieza:       2.0,  // se ensucia muy rápido
        afecto:         1.5,
        anomaliaFactor: 8.0, // si lo descuidas se pone muy malo
      ),

      reacciones: [
        StateReaction(
          nivel: 'limpieza', umbral: 25,
          estado: 'sucio',
          mensaje: '¡Hice un desastre! ¡Todo está sucio!',
          misionId: 'travieso_limpiar',
          generaAlerta: true,
        ),
        StateReaction(
          nivel: 'hambre', umbral: 20,
          estado: 'hambriento_travieso',
          mensaje: '¡Tiré mi comida y ahora tengo hambre! 😅',
          misionId: 'travieso_alimentar_cuidado',
          generaAlerta: true,
        ),
        StateReaction(
          nivel: 'afecto', umbral: 20,
          estado: 'muy_travieso',
          mensaje: '¡Si no juegas conmigo haré más travesuras!',
          misionId: 'travieso_calmar',
          generaAlerta: true,
        ),
      ],

      misiones: [
        PersonalityMission(
          id: 'travieso_recoger_comida',
          titulo: '¡Recoge el desastre!',
          descripcion: 'Tu mascota tiró toda la comida. Recoge cada pieza antes de que se eche a perder.',
          tipo: 'reactiva',
          accionTrigger: 'alimentar',
          condicion: 'Siempre al alimentar a mascota traviesa',
          recompensaXp: 40,
          educationalTip: 'Los animales traviesos necesitan supervisión al comer.',
          esEspecial: true,
        ),
        PersonalityMission(
          id: 'travieso_limpiar',
          titulo: '¡A limpiar!',
          descripcion: 'El nivel de limpieza está muy bajo. Baña a tu mascota traviesa.',
          tipo: 'reactiva',
          accionTrigger: 'banar',
          condicion: 'limpieza < 25',
          recompensaXp: 35,
          educationalTip: 'Los animales activos necesitan baños más frecuentes.',
          esEspecial: true,
        ),
        PersonalityMission(
          id: 'travieso_calmar',
          titulo: '¡Cálmalo con amor!',
          descripcion: 'Juega y acaricia a tu mascota para que se calme.',
          tipo: 'reactiva',
          accionTrigger: 'jugar',
          condicion: 'afecto < 20',
          recompensaXp: 30,
          educationalTip: 'Los animales traviesos buscan atención. ¡Dásela antes de que hagan travesuras!',
          esEspecial: true,
        ),
        PersonalityMission(
          id: 'travieso_rutina',
          titulo: '¡Establece una rutina!',
          descripcion: 'Alimenta a tu mascota 3 días seguidos a la misma hora.',
          tipo: 'semanal',
          accionTrigger: 'alimentar',
          condicion: 'streak_alimentar >= 3',
          recompensaXp: 60,
          educationalTip: 'Las rutinas ayudan a calmar a los animales traviesos.',
        ),
      ],
    ),

    // ──────────────────────────────────────────────────────────
    // DORMILÓN
    // ──────────────────────────────────────────────────────────
    PersonalityConfig(
      rasgo: 'Dormilón',
      emoji: '😴',
      descripcion: 'Prefiere descansar. Es tranquilo y poco activo.',
      descripcionIa: 'Energía baja 0.4× más lento. Recupera 1.5× más energía al dormir. Hambre baja más lento.',

      acciones: ActionModifiers(
        alimentarHambre:  1.0,
        jugarAfecto:      0.9,   // no le gusta mucho jugar
        jugarEnergiaCosto:2.0,   // se cansa el doble al jugar
        banarLimpieza:    1.0,
        banarAfecto:      0.9,
        dormirEnergia:    1.5,   // recupera mucho más al dormir
        dormirAfecto:     0.0,
        pasearAfecto:     0.8,   // no le gusta mucho pasear
        pasearEnergia:    0.7,
        pasearHambreCosto:0.8,
      ),

      deterioro: DecayModifiers(
        salud:          0.8,
        energia:        0.4,   // baja muy lento
        hambre:         0.7,   // menos apetito
        limpieza:       0.8,
        afecto:         1.0,
        anomaliaFactor: 3.0,  // menos dramático que otros
      ),

      reacciones: [
        StateReaction(
          nivel: 'energia', umbral: 30,
          estado: 'muy_cansado',
          mensaje: 'Zzz... necesito dormir una siesta...',
          misionId: 'dormilon_siesta',
          generaAlerta: false,
        ),
        StateReaction(
          nivel: 'hambre', umbral: 25,
          estado: 'hambriento_tranquilo',
          mensaje: 'Mmm... creo que tengo un poco de hambre...',
          generaAlerta: false,
        ),
        StateReaction(
          nivel: 'afecto', umbral: 20,
          estado: 'solitario',
          mensaje: 'Me siento solo... ¿puedes quedarte un rato?',
          misionId: 'dormilon_companía',
          generaAlerta: true,
        ),
      ],

      misiones: [
        PersonalityMission(
          id: 'dormilon_siesta',
          titulo: '¡Hora de la siesta!',
          descripcion: 'Tu mascota está cansada. Ponla a dormir en su lugar favorito.',
          tipo: 'reactiva',
          accionTrigger: 'dormir',
          condicion: 'energia < 30',
          recompensaXp: 15,
          educationalTip: 'Los animales necesitan entre 12 y 16 horas de sueño al día.',
          esEspecial: true,
        ),
        PersonalityMission(
          id: 'dormilon_ejercicio',
          titulo: '¡Un poco de ejercicio!',
          descripcion: 'Aunque no le guste mucho, tu mascota necesita moverse. ¡A pasear!',
          tipo: 'diaria',
          accionTrigger: 'pasear',
          condicion: 'sin pasear en 24h',
          recompensaXp: 30,
          educationalTip: 'Incluso los animales tranquilos necesitan ejercicio diario.',
        ),
        PersonalityMission(
          id: 'dormilon_companía',
          titulo: '¡Quédate un rato!',
          descripcion: 'Tu mascota dormilona se siente sola. Juega aunque sea un momento.',
          tipo: 'reactiva',
          accionTrigger: 'jugar',
          condicion: 'afecto < 20',
          recompensaXp: 20,
          educationalTip: 'Aunque sean tranquilos, los animales necesitan compañía y amor.',
          esEspecial: true,
        ),
      ],
    ),

    // ──────────────────────────────────────────────────────────
    // CURIOSO
    // ──────────────────────────────────────────────────────────
    PersonalityConfig(
      rasgo: 'Curioso',
      emoji: '🔍',
      descripcion: 'Explora todo a su alrededor. Le gustan los juguetes nuevos.',
      descripcionIa: 'Afecto sube 1.8× con juguetes nuevos pero 0.7× con repetidos. Necesita variedad.',

      acciones: ActionModifiers(
        alimentarHambre:  1.0,
        alimentarAfecto:  1.2,   // le gusta explorar la comida
        jugarAfecto:      1.8,   // ama los juguetes nuevos
        jugarEnergiaCosto:1.0,
        banarLimpieza:    1.0,
        banarAfecto:      1.3,   // le gusta explorar el agua
        dormirEnergia:    1.0,
        pasearAfecto:     1.6,   // adora explorar nuevos lugares
        pasearEnergia:    1.2,
        pasearHambreCosto:1.2,
      ),

      deterioro: DecayModifiers(
        salud:          1.0,
        energia:        1.0,
        hambre:         1.0,
        limpieza:       1.2,   // se ensucia explorando
        afecto:         1.2,   // necesita variedad o se aburre
        anomaliaFactor: 4.0,
      ),

      reacciones: [
        StateReaction(
          nivel: 'afecto', umbral: 35,
          estado: 'aburrido',
          mensaje: '¡Todo es igual! ¡Quiero explorar algo nuevo!',
          misionId: 'curioso_explorar',
          generaAlerta: true,
        ),
        StateReaction(
          nivel: 'limpieza', umbral: 30,
          estado: 'sucio_explorador',
          mensaje: '¡Me ensucie explorando! ¡Necesito un baño!',
          misionId: 'curioso_banar',
          generaAlerta: false,
        ),
        StateReaction(
          nivel: 'energia', umbral: 20,
          estado: 'explorador_cansado',
          mensaje: 'Exploré tanto que ya no puedo más...',
          generaAlerta: false,
        ),
      ],

      misiones: [
        PersonalityMission(
          id: 'curioso_juguete_nuevo',
          titulo: '¡Juguete sorpresa!',
          descripcion: 'Usa un juguete diferente al que usaste ayer para jugar.',
          tipo: 'diaria',
          accionTrigger: 'jugar',
          condicion: 'juguete != ultimo_juguete_usado',
          recompensaXp: 35,
          educationalTip: 'Los animales curiosos necesitan estimulación mental constante.',
          esEspecial: true,
        ),
        PersonalityMission(
          id: 'curioso_explorar',
          titulo: '¡Nuevo lugar!',
          descripcion: 'Lleva a tu mascota a pasear. ¡Le encanta descubrir cosas nuevas!',
          tipo: 'diaria',
          accionTrigger: 'pasear',
          condicion: 'afecto < 35',
          recompensaXp: 25,
          educationalTip: 'Los ambientes nuevos estimulan el cerebro de los animales.',
        ),
        PersonalityMission(
          id: 'curioso_banar',
          titulo: '¡A explorar el agua!',
          descripcion: 'Tu mascota se ensució explorando. ¡Hora del baño aventurero!',
          tipo: 'reactiva',
          accionTrigger: 'banar',
          condicion: 'limpieza < 30',
          recompensaXp: 20,
          educationalTip: 'Los animales curiosos suelen ensuciarse más por su naturaleza exploradora.',
          esEspecial: true,
        ),
      ],
    ),

    // ──────────────────────────────────────────────────────────
    // TIERNO
    // ──────────────────────────────────────────────────────────
    PersonalityConfig(
      rasgo: 'Tierno',
      emoji: '🥰',
      descripcion: 'Busca cariño y mimos. Se pone triste si lo ignoras.',
      descripcionIa: 'Afecto baja 2× más rápido. Sin interacción >2h genera estado triste. Muy sensible.',

      acciones: ActionModifiers(
        alimentarHambre:  1.0,
        alimentarAfecto:  2.0,   // se emociona mucho al comer con el dueño
        jugarAfecto:      1.5,   // ama la atención
        jugarEnergiaCosto:0.9,
        banarLimpieza:    1.0,
        banarAfecto:      1.4,   // le gusta el contacto físico
        dormirEnergia:    1.0,
        dormirAfecto:    -1.0,   // extraña al niño (negativo = baja afecto)
        pasearAfecto:     1.5,
        pasearEnergia:    1.0,
        pasearHambreCosto:1.0,
      ),

      deterioro: DecayModifiers(
        salud:          1.0,
        energia:        1.0,
        hambre:         1.0,
        limpieza:       1.0,
        afecto:         2.0,   // se pone triste el doble de rápido
        anomaliaFactor: 6.0,  // muy sensible al abandono
      ),

      reacciones: [
        StateReaction(
          nivel: 'afecto', umbral: 40,
          estado: 'triste',
          mensaje: '¿Me olvidaste? Te extraño mucho... 😢',
          misionId: 'tierno_mimos',
          generaAlerta: true,
        ),
        StateReaction(
          nivel: 'afecto', umbral: 20,
          estado: 'muy_triste',
          mensaje: '¡Estoy muy triste! ¡Necesito un abrazo!',
          misionId: 'tierno_urgente',
          generaAlerta: true,
        ),
        StateReaction(
          nivel: 'hambre', umbral: 25,
          estado: 'hambriento_triste',
          mensaje: 'Tengo hambre... y también te extraño... 🥺',
          generaAlerta: false,
        ),
      ],

      misiones: [
        PersonalityMission(
          id: 'tierno_mimos',
          titulo: '¡Tiempo de mimos!',
          descripcion: 'Tu mascota necesita atención. Juega o pasea con ella.',
          tipo: 'reactiva',
          accionTrigger: 'jugar',
          condicion: 'afecto < 40',
          recompensaXp: 20,
          educationalTip: 'Los animales cariñosos necesitan contacto frecuente con su dueño.',
          esEspecial: true,
        ),
        PersonalityMission(
          id: 'tierno_constancia',
          titulo: '¡No me olvides!',
          descripcion: 'Interactúa con tu mascota al menos una vez cada 4 horas.',
          tipo: 'diaria',
          accionTrigger: 'cualquiera',
          condicion: 'tiempo_sin_interaccion < 4h',
          recompensaXp: 40,
          educationalTip: 'Los animales tiernos sufren de ansiedad por separación. ¡La constancia es clave!',
          esEspecial: true,
        ),
        PersonalityMission(
          id: 'tierno_banar_juntos',
          titulo: '¡Baño con amor!',
          descripcion: 'Baña a tu mascota con cuidado. ¡Le encanta el contacto!',
          tipo: 'semanal',
          accionTrigger: 'banar',
          condicion: 'siempre disponible',
          recompensaXp: 30,
          educationalTip: 'El baño es un momento de unión entre el animal y su dueño.',
        ),
      ],
    ),

  ]; // fin de _configs
}

// ══════════════════════════════════════════════════════════════
// VALORES BASE DE CADA ACCIÓN
// Estos son los valores SIN modificador de personalidad.
// El PetCubit los multiplica por ActionModifiers.
// ══════════════════════════════════════════════════════════════
class BaseActionValues {
  static const int alimentarHambre  = 25;
  static const int alimentarSalud   = 5;
  static const int alimentarAfecto  = 3;

  static const int jugarAfecto      = 15;
  static const int jugarEnergia     = -10; // costo
  static const int jugarHambre      = -8;  // costo

  static const int banarLimpieza    = 35;
  static const int banarAfecto      = 10;
  static const int banarSalud       = 2;

  static const int dormirEnergia    = 40;
  static const int dormirSalud      = 3;
  static const int dormirHambre     = -5; // costo

  static const int curarSalud       = 30;
  static const int curarEnergia     = 5;
  static const int curarAfecto      = 5;

  static const int pasearAfecto     = 15;
  static const int pasearEnergia    = 10;
  static const int pasearHambre     = -15; // costo
  static const int pasearSalud      = 2;

  // Deterioro por tick (cada 30 min)
  static const double deterioroSalud    = 1.0;
  static const double deterioroEnergia  = 1.0;
  static const double deterioroHambre   = 2.0;
  static const double deterioroLimpieza = 1.0;
  static const double deterioroAfecto   = 2.0;
}
