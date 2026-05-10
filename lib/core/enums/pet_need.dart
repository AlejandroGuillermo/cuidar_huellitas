enum PetNeed {
  health,
  hunger,
  energy,
  hygiene,
  affection,
  none;

  String toDisplayString() {
    return switch (this) {
      PetNeed.health => 'Salud',
      PetNeed.hunger => 'Hambre',
      PetNeed.energy => 'Energia',
      PetNeed.hygiene => 'Limpieza',
      PetNeed.affection => 'Afecto',
      PetNeed.none => 'Sin necesidad',
    };
  }

  int get priority {
    return switch (this) {
      PetNeed.health => 1,
      PetNeed.hunger => 2,
      PetNeed.energy => 3,
      PetNeed.hygiene => 4,
      PetNeed.affection => 5,
      PetNeed.none => 6,
    };
  }
}
