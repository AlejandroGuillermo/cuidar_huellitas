// ══════════════════════════════════════════════════════════════
// personality_config.dart  —  lib/core/personality_config.dart
// FUENTE ÚNICA DE VERDAD para personalidades.
// Para agregar una nueva: agrega un PersonalityConfig al final
// de _configs. No toques PetCubit ni ninguna pantalla.
// ══════════════════════════════════════════════════════════════

// ── Modificadores de acción ────────────────────────────────────
// Cada valor multiplica el efecto BASE de esa acción.
// Ejemplo: hambreMultiplier: 1.5 en alimentar → sube 50% más hambre
class ActionModifiers {
  // Alimentar
  final double alimentarHambre;
  final double alimentarSalud;
  final double alimentarAfecto;
  final double alimentarVelocidadPlato; // 1.0=normal, 5.0=muy rápido (Glotón)
  final bool   alimentarPuedeTirar;    // genera desastre de comida
  // Jugar
  final double jugarAfecto;
  final double jugarEnergiaCosto;
  final double jugarHambreCosto;
  final double jugarLimpieza;          // negativo = se ensucia más
  final double jugarSaludBonus;        // bonus salud al jugar (Glotón)
  // Bañar
  final double banarLimpieza;
  final double banarAfecto;
  final bool   banarDificil;           // mascota se mueve (Juguetón, gatos)
  final bool   banarEscapa;            // escapa a otras pantallas (Travieso)

  // Dormir
  final double dormirEnergia;
  final double dormirAfecto;           // negativo = extraña al dueño
  final double dormirSaludBonus;       // bonus salud al dormir (Glotón)

  // Curar
  final double curarSalud;
  final double curarAfecto;

  // Pasear
  final double pasearAfecto;
  final double pasearEnergia;
  final double pasearHambreCosto;
  final double pasearVelocidad;        // 0.4 = va lento en pantalla (Glotón)

  const ActionModifiers({
    this.alimentarHambre         = 1.0,
    this.alimentarSalud          = 1.0,
    this.alimentarAfecto         = 1.0,
    this.alimentarVelocidadPlato = 1.0,
    this.alimentarPuedeTirar     = false,
    this.jugarAfecto             = 1.0,
    this.jugarEnergiaCosto       = 1.0,
    this.jugarHambreCosto        = 1.0,
    this.jugarLimpieza           = 0.0,
    this.jugarSaludBonus         = 0.0,
    this.banarLimpieza           = 1.0,
    this.banarAfecto             = 1.0,
    this.banarDificil            = false,
    this.banarEscapa             = false,
    this.dormirEnergia           = 1.0,
    this.dormirAfecto            = 0.0,
    this.dormirSaludBonus        = 0.0,
    this.curarSalud              = 1.0,
    this.curarAfecto             = 1.0,
    this.pasearAfecto            = 1.0,
    this.pasearEnergia           = 1.0,
    this.pasearHambreCosto       = 1.0,
    this.pasearVelocidad         = 1.0,
  });
}

class DecayModifiers {
  final double salud;
  final double energia;
  final double hambre;
  final double limpieza;
  final double afecto;
  final double anomaliaFactor;
  final double ausenciaFactor;    // Delicado: ausencia larga ×2
  final int    umbralHambre;      // hambre < X → −1 salud/tick (base: 25)
  final int    umbralLimpieza;    // limpieza < X → −1 salud/tick (base: 40)

  const DecayModifiers({
    this.salud           = 1.0,
    this.energia         = 1.0,
    this.hambre          = 1.0,
    this.limpieza        = 1.0,
    this.afecto          = 1.0,
    this.anomaliaFactor  = 5.0,
    this.ausenciaFactor  = 1.0,
    this.umbralHambre    = 25,
    this.umbralLimpieza  = 40,
  });
}

class StateReaction {
  final String  nivel;
  final int     umbral;
  final String  estado;
  final String  mensaje;
  final String? misionId;
  final bool    generaAlerta;
  final String? desastreTipo;      // 'comida','juguete','basura','porcion'
  final String? desastreEmoji;
  final int     desastreCantidad;

  const StateReaction({
    required this.nivel,
    required this.umbral,
    required this.estado,
    required this.mensaje,
    this.misionId,
    this.generaAlerta     = false,
    this.desastreTipo,
    this.desastreEmoji,
    this.desastreCantidad = 0,
  });
}

// ── Misión fija de personalidad ────────────────────────────────
// Misiones que SIEMPRE existen para esta personalidad,
// independientemente de lo que haga el niño.
class PersonalityMission {
  final String id;
  final String titulo;
  final String descripcion;
  final String tipo;            // 'diaria','semanal','reactiva','unica'
  final String accionTrigger;
  final String condicion;
  final int    recompensaXp;
  final String educationalTip;
  final bool   esEspecial;

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

  static PersonalityConfig? get(String rasgo) {
    try { return _configs.firstWhere((c) => c.rasgo == rasgo); }
    catch (_) { return _configs.first; }
  }

  static List<String> get rasgos => _configs.map((c) => c.rasgo).toList();

  static const List<PersonalityConfig> _configs = [

    // ── JUGUETÓN ───────────────────────────────────────────
    PersonalityConfig(
      rasgo: 'Juguetón',
      emoji: '⚽',
      descripcion: 'Le encanta jugar y correr todo el tiempo. Necesita mucha actividad.',
      descripcionIa: 'Energía cae 2×. Se ensucia 1.5×. Puede tirar comida y juguetes.',
      acciones: ActionModifiers(
        alimentarPuedeTirar:     true,   // rara vez tira comida
        jugarAfecto:             1.5,    // +1.5× afecto al jugar
        jugarEnergiaCosto:       1.3,
        jugarLimpieza:          -1.5,    // se ensucia más al jugar
        banarDificil:            true,   // se mueve al bañar
        banarLimpieza:           0.85,
        pasearAfecto:            1.4,
      ),
      deterioro: DecayModifiers(
        energia:        2.0,   // gasta energía aún sin jugar
        limpieza:       1.5,
        afecto:         1.5,
        anomaliaFactor: 5.0,
      ),
      reacciones: [
        StateReaction(
          nivel: 'energia', umbral: 20, estado: 'agotado',
          mensaje: '¡Estoy muy cansado! ¡Necesito dormir!',
          misionId: 'jugueton_dormir', generaAlerta: true,
        ),
        StateReaction(
          nivel: 'afecto', umbral: 30, estado: 'aburrido',
          mensaje: '¡Quiero jugar! ¡Estoy muy aburrido!',
          misionId: 'jugueton_jugar_urgente', generaAlerta: true,
          desastreTipo: 'juguete', desastreEmoji: '🎾', desastreCantidad: 3,
        ),
      ],
      misiones: [
        PersonalityMission(
          id: 'jugueton_recoger_comida', titulo: '¡A limpiar el desastre de comida!',
          descripcion: 'Tu mascota tiró comida por todas partes. Toca cada pieza para recogerla.',
          tipo: 'reactiva', accionTrigger: 'alimentar',
          condicion: 'alimentarPuedeTirar ocurrió', recompensaXp: 30,
          educationalTip: 'Los animales juguetones necesitan rutinas de alimentación tranquilas.',
          esEspecial: true,
        ),
        PersonalityMission(
          id: 'jugueton_recoger_juguetes', titulo: '¡Recoge los juguetes!',
          descripcion: 'Tu mascota sacó todos los juguetes de la caja. Recógelos tocando cada uno.',
          tipo: 'reactiva', accionTrigger: 'jugar',
          condicion: 'mascota agarró otro juguete o estuvo sola', recompensaXp: 25,
          educationalTip: 'Enseñar a recoger juguetes es parte del cuidado responsable.',
          esEspecial: true,
        ),
        PersonalityMission(
          id: 'jugueton_jugar_diario', titulo: '¡Hora de jugar!',
          descripcion: 'Juega al menos 2 veces hoy con tu mascota.',
          tipo: 'diaria', accionTrigger: 'jugar',
          condicion: 'jugadas >= 2 en el día', recompensaXp: 25,
          educationalTip: 'Los perros juguetones necesitan al menos 30 minutos de actividad al día.',
        ),
      ],
    ),

    // ── TRAVIESO ───────────────────────────────────────────
    PersonalityConfig(
      rasgo: 'Travieso',
      emoji: '😈',
      descripcion: 'Hace travesuras si lo descuidas. Requiere atención constante.',
      descripcionIa: 'Deterioro ×8 si descuidado. Se ensucia 2×. Escapa al bañar.',
      acciones: ActionModifiers(
        alimentarPuedeTirar: true,
        jugarAfecto:         1.2,
        jugarEnergiaCosto:   1.3,
        jugarLimpieza:      -2.0,
        banarDificil:        true,
        banarEscapa:         true,  // escapa a otras pantallas hasta 3×
        banarLimpieza:       0.6,
        pasearAfecto:        1.3,
      ),
      deterioro: DecayModifiers(
        salud:          0.3,   // + evento especial −1/−2 cada 3–5h
        energia:        1.8,
        limpieza:       2.0,
        anomaliaFactor: 8.0,
        umbralHambre:   25,
        umbralLimpieza: 40,
      ),
      reacciones: [
        StateReaction(
          nivel: 'afecto', umbral: 25, estado: 'muy_travieso',
          mensaje: '¡Si no juegas conmigo haré MÁS travesuras! 😈',
          misionId: 'travieso_calmar', generaAlerta: true,
          desastreTipo: 'basura', desastreEmoji: '🗑️', desastreCantidad: 4,
        ),
        StateReaction(
          nivel: 'limpieza', umbral: 20, estado: 'muy_sucio',
          mensaje: '¡Hice un desastre! ¡Todo está sucio!',
          misionId: 'travieso_limpiar', generaAlerta: true,
        ),
      ],
      misiones: [
        PersonalityMission(
          id: 'travieso_recoger_comida', titulo: '¡Recoge el desastre de comida!',
          descripcion: 'Tu mascota tiró la comida. Recoge cada pieza.',
          tipo: 'reactiva', accionTrigger: 'alimentar',
          condicion: 'siempre al alimentar', recompensaXp: 40,
          educationalTip: 'Los animales traviesos necesitan supervisión al comer.',
          esEspecial: true,
        ),
        PersonalityMission(
          id: 'travieso_recoger_basura', titulo: '¡Limpia la basura!',
          descripcion: 'Tu mascota dejó basura por todas las pantallas. ¡A limpiar!',
          tipo: 'reactiva', accionTrigger: 'cualquiera',
          condicion: 'afecto < 25', recompensaXp: 35,
          educationalTip: 'Los animales que se aburren pueden volverse destructivos.',
          esEspecial: true,
        ),
        PersonalityMission(
          id: 'travieso_rutina', titulo: '¡Establece una rutina!',
          descripcion: 'Alimenta a tu mascota 3 días seguidos a la misma hora.',
          tipo: 'semanal', accionTrigger: 'alimentar',
          condicion: 'streak_alimentar >= 3', recompensaXp: 60,
          educationalTip: 'Las rutinas ayudan a calmar a los animales traviesos.',
        ),
      ],
    ),

    // ── GLOTÓN ─────────────────────────────────────────────
    PersonalityConfig(
      rasgo: 'Glotón',
      emoji: '🍗',
      descripcion: 'Siempre tiene hambre y come muy rápido. Lento pero constante.',
      descripcionIa: 'Hambre cae 3×. Plato se vacía 5× más rápido. Hambre solo sube 10% por toma.',
      acciones: ActionModifiers(
        alimentarHambre:         0.10,  // solo sube 10% (rellena varias veces)
        alimentarVelocidadPlato: 5.0,   // plato ≈ 2 seg visual
        alimentarPuedeTirar:     true,
        jugarSaludBonus:         5.0,   // jugar sube salud
        dormirSaludBonus:        8.0,   // dormir sube salud
        pasearVelocidad:         0.4,   // va más lento
        pasearHambreCosto:       1.5,
        jugarLimpieza:          -1.3,
      ),
      deterioro: DecayModifiers(
        hambre:         3.0,
        energia:        1.2,
        limpieza:       1.3,
        anomaliaFactor: 5.0,
      ),
      reacciones: [
        StateReaction(
          nivel: 'hambre', umbral: 30, estado: 'muy_hambriento',
          mensaje: '¡Tengo MUCHA hambre! ¡Ponme más comida!',
          misionId: 'gloton_alimentar_urgente', generaAlerta: true,
        ),
        StateReaction(
          nivel: 'hambre', umbral: 15, estado: 'hambriento_critico',
          mensaje: '¡No hay nada en mi plato! ¡Me muero de hambre!',
          misionId: 'gloton_alimentar_critico', generaAlerta: true,
          desastreTipo: 'comida', desastreEmoji: '🍖', desastreCantidad: 4,
        ),
      ],
      misiones: [
        PersonalityMission(
          id: 'gloton_alimentar_urgente', titulo: '¡El glotón tiene hambre!',
          descripcion: 'Rellena el plato de tu mascota antes de que se quede sin nada.',
          tipo: 'reactiva', accionTrigger: 'alimentar',
          condicion: 'hambre < 30', recompensaXp: 20,
          educationalTip: 'Los animales glotones necesitan porciones controladas para no enfermarse.',
          esEspecial: true,
        ),
        PersonalityMission(
          id: 'gloton_ejercicio', titulo: '¡A mover el cuerpo!',
          descripcion: 'Tu mascota glotona necesita ejercicio. ¡Juega con ella!',
          tipo: 'diaria', accionTrigger: 'jugar',
          condicion: 'sin jugar en 12h', recompensaXp: 30,
          educationalTip: 'El ejercicio ayuda a los animales a mantenerse sanos aunque coman mucho.',
        ),
      ],
    ),

    // ── CARIÑOSO ───────────────────────────────────────────
    PersonalityConfig(
      rasgo: 'Cariñoso',
      emoji: '🥰',
      descripcion: 'Busca cariño en todo momento. Solo el juego lo llena de verdad.',
      descripcionIa: 'Afecto cae 2×. Acciones dan 0.3× afecto. Jugar da 2× afecto.',
      acciones: ActionModifiers(
        alimentarAfecto:  0.3,   // comer: +3×0.3 = +1
        banarAfecto:      0.3,   // bañar: +10×0.3 = +3
        curarAfecto:      0.3,   // curar: +5×0.3 = +2
        jugarAfecto:      2.0,   // jugar: +15×2 = +30 ← lenguaje de amor
        dormirAfecto:    -0.5,   // extraña al niño
        pasearAfecto:     0.3,
      ),
      deterioro: DecayModifiers(
        afecto:         2.0,
        anomaliaFactor: 5.0,
      ),
      reacciones: [
        StateReaction(
          nivel: 'afecto', umbral: 40, estado: 'triste',
          mensaje: '¿Me olvidaste? Te extraño mucho... 😢',
          misionId: 'carinoso_jugar', generaAlerta: true,
        ),
        StateReaction(
          nivel: 'afecto', umbral: 15, estado: 'muy_triste',
          mensaje: '¡Estoy muy triste! ¡Solo quiero jugar contigo!',
          misionId: 'carinoso_urgente', generaAlerta: true,
        ),
      ],
      misiones: [
        PersonalityMission(
          id: 'carinoso_jugar', titulo: '¡Tu mascota necesita atención!',
          descripcion: 'Juega con tu mascota para que se sienta querida.',
          tipo: 'reactiva', accionTrigger: 'jugar',
          condicion: 'afecto < 40', recompensaXp: 25,
          educationalTip: 'Los animales cariñosos necesitan tiempo de calidad, no solo comida.',
          esEspecial: true,
        ),
        PersonalityMission(
          id: 'carinoso_constancia', titulo: '¡No me olvides!',
          descripcion: 'Juega con tu mascota al menos una vez al día durante 3 días seguidos.',
          tipo: 'semanal', accionTrigger: 'jugar',
          condicion: 'streak_jugar >= 3', recompensaXp: 50,
          educationalTip: 'La constancia es la clave del vínculo con un animal cariñoso.',
        ),
      ],
    ),

    // ── DELICADO ───────────────────────────────────────────
    PersonalityConfig(
      rasgo: 'Delicado',
      emoji: '🤒',
      descripcion: 'Se enferma fácilmente y come muy despacio. Necesita cuidados especiales.',
      descripcionIa: 'Umbrales de salud más altos. Come lento. Ausencia larga ×2. Misma comida = mal estómago.',
      acciones: ActionModifiers(
        alimentarHambre:         0.4,   // come poco a la vez
        alimentarVelocidadPlato: 0.3,   // plato baja muy lento
        jugarLimpieza:          -1.5,   // se ensucia más al jugar
        jugarEnergiaCosto:       1.2,
      ),
      deterioro: DecayModifiers(
        anomaliaFactor:  4.0,
        ausenciaFactor:  2.0,    // ausencia larga = todo ×2
        umbralHambre:    40,     // umbral más alto que el normal (25)
        umbralLimpieza:  55,     // umbral más alto que el normal (40)
      ),
      reacciones: [
        StateReaction(
          nivel: 'salud', umbral: 50, estado: 'delicado_enfermo',
          mensaje: 'No me siento bien... necesito al veterinario...',
          misionId: 'delicado_curar', generaAlerta: true,
        ),
        StateReaction(
          nivel: 'hambre', umbral: 35, estado: 'delicado_hambriento',
          mensaje: 'Tengo un poco de hambre... pero no mucho...',
          generaAlerta: false,
        ),
      ],
      misiones: [
        PersonalityMission(
          id: 'delicado_mal_estomago', titulo: '¡Mal del estómago!',
          descripcion: 'Tu mascota comió siempre lo mismo y se enfermó. Recoge las porciones pequeñas que dejó.',
          tipo: 'reactiva', accionTrigger: 'alimentar',
          condicion: 'misma comida 3+ veces seguidas', recompensaXp: 40,
          educationalTip: 'Una dieta variada es importante para la salud de los animales delicados.',
          esEspecial: true,
        ),
        PersonalityMission(
          id: 'delicado_veterinario', titulo: '¡Visita al veterinario!',
          descripcion: 'Tu mascota delicada necesita revisión médica regular.',
          tipo: 'semanal', accionTrigger: 'curar',
          condicion: 'sin curar en 5 días', recompensaXp: 45,
          educationalTip: 'Los animales delicados necesitan visitas veterinarias más frecuentes.',
          esEspecial: true,
        ),
        PersonalityMission(
          id: 'delicado_variedad', titulo: '¡Varía su dieta!',
          descripcion: 'Dale un alimento diferente al que le diste ayer.',
          tipo: 'diaria', accionTrigger: 'alimentar',
          condicion: 'comida != ultimo_alimento', recompensaXp: 20,
          educationalTip: 'La variedad en la alimentación previene enfermedades digestivas.',
        ),
      ],
    ),

  ]; // fin _configs
}

// ══════════════════════════════════════════════════════════════
// VALORES BASE — sin modificador de personalidad
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
  static const double saludSecundaria   = 1.0;
}