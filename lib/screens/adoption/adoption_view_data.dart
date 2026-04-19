import '../../core/personality_config.dart';

class OpcionMascotaAdopcion {
  const OpcionMascotaAdopcion({
    required this.id,
    required this.nombre,
    required this.emoji,
    required this.etiqueta,
    required this.descripcion,
    required this.colorAcentoValor,
    required this.colorAcentoSuaveValor,
  });

  final String id;
  final String nombre;
  final String emoji;
  final String etiqueta;
  final String descripcion;
  final int colorAcentoValor;
  final int colorAcentoSuaveValor;
}

class OpcionPersonalidadAdopcion {
  const OpcionPersonalidadAdopcion({
    required this.nombre,
    required this.emoji,
    required this.resumen,
    required this.comportamientos,
    required this.colorAcentoValor,
  });

  final String nombre;
  final String emoji;
  final String resumen;
  final List<String> comportamientos;
  final int colorAcentoValor;
}

const opcionesMascotaAdopcion = <OpcionMascotaAdopcion>[
  OpcionMascotaAdopcion(
    id: 'perro',
    nombre: 'Perro',
    emoji: '🐶',
    etiqueta: 'Leal, activo y muy expresivo',
    descripcion: 'Ideal si quieres una energia mas juguetona.',
    colorAcentoValor: 0xFF6F88E8,
    colorAcentoSuaveValor: 0xFFEAEFFF,
  ),
  OpcionMascotaAdopcion(
    id: 'gato',
    nombre: 'Gato',
    emoji: '🐱',
    etiqueta: 'Curioso, sereno e independiente',
    descripcion: 'Perfecto si buscas una compania tranquila.',
    colorAcentoValor: 0xFFF07A94,
    colorAcentoSuaveValor: 0xFFFFEEF2,
  ),
];

const nombresPerroAdopcion = <String>[
  'Firulais',
  'Rocky',
  'Max',
  'Bruno',
  'Toby',
  'Charlie',
  'Zeus',
  'Coco',
  'Beto',
  'Canelo',
];

const nombresGatoAdopcion = <String>[
  'Luna',
  'Michi',
  'Nala',
  'Sombra',
  'Pelusa',
  'Milo',
  'Simba',
  'Oreo',
  'Canela',
  'Mora',
];

final opcionesPersonalidadAdopcion = PersonalityRegistry.rasgos
    .map(_construirOpcionPersonalidad)
    .toList(growable: false);

OpcionPersonalidadAdopcion _construirOpcionPersonalidad(String rasgo) {
  final configuracion = PersonalityRegistry.get(rasgo)!;

  return OpcionPersonalidadAdopcion(
    nombre: configuracion.rasgo,
    emoji: configuracion.emoji,
    resumen: configuracion.descripcion,
    comportamientos: _comportamientosPorRasgo(configuracion.rasgo),
    colorAcentoValor: _colorAcentoPorRasgo(configuracion.rasgo),
  );
}

List<String> _comportamientosPorRasgo(String rasgo) {
  switch (rasgo) {
    case 'Juguetón':
      return const [
        'Se emociona rapido cuando juegas con el.',
        'Gasta energia y se ensucia con mas facilidad.',
        'Necesita mas actividad para sentirse bien.',
      ];
    case 'Travieso':
      return const [
        'Puede dejar pequenos desastres a su paso.',
        'Te pedira atencion para mantenerse tranquilo.',
        'Se mueve mucho y necesita supervision constante.',
      ];
    case 'Glotón':
      return const [
        'Pedira comida con bastante frecuencia.',
        'Se entusiasma mucho a la hora de comer.',
        'Necesita una rutina constante para mantenerse estable.',
      ];
    case 'Cariñoso':
      return const [
        'Responde muy bien a tus caricias y juegos.',
        'Te buscara con frecuencia para convivir.',
        'Se siente mejor cuando pasas tiempo con el.',
      ];
    case 'Delicado':
      return const [
        'Come con calma y puede necesitar mas cuidado.',
        'Se cansa o enferma con mayor facilidad.',
        'Le favorecen las rutinas tranquilas y constantes.',
      ];
    default:
      return const [
        'Tiene una personalidad unica.',
        'Necesita atencion y una rutina constante.',
        'Aprenderas a conocerlo con el tiempo.',
      ];
  }
}

int _colorAcentoPorRasgo(String rasgo) {
  switch (rasgo) {
    case 'Juguetón':
      return 0xFF8AE670;
    case 'Travieso':
      return 0xFFFFC15C;
    case 'Glotón':
      return 0xFFFFA063;
    case 'Cariñoso':
      return 0xFFF7A7B7;
    case 'Delicado':
      return 0xFF8AA2FF;
    default:
      return 0xFF8AA2FF;
  }
}
