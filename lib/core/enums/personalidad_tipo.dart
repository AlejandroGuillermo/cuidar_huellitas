enum PersonalidadTipo {
  jugueton,
  travieso,
  gloton,
  carinoso,
  delicado;

  static PersonalidadTipo fromString(String? value) {
    final clean = value?.trim().toLowerCase();

    switch (clean) {
      case 'jugueton':
      case 'juguetón':
      case 'juguetã³n':
      case 'juguetãƒâ³n':
      case 'juguetãƒâƒã‚â³n':
        return PersonalidadTipo.jugueton;
      case 'travieso':
        return PersonalidadTipo.travieso;
      case 'gloton':
      case 'glotón':
      case 'glotã³n':
        return PersonalidadTipo.gloton;
      case 'carinoso':
      case 'cariñoso':
      case 'cariã±oso':
        return PersonalidadTipo.carinoso;
      case 'delicado':
        return PersonalidadTipo.delicado;
      default:
        return PersonalidadTipo.jugueton;
    }
  }

  String toFirestoreString() {
    return switch (this) {
      PersonalidadTipo.jugueton => 'Juguetón',
      PersonalidadTipo.travieso => 'Travieso',
      PersonalidadTipo.gloton => 'Glotón',
      PersonalidadTipo.carinoso => 'Cariñoso',
      PersonalidadTipo.delicado => 'Delicado',
    };
  }

  String toDisplayString() => toFirestoreString();
}
