enum PetEmotion {
  happy,
  sad,
  sick,
  dirty,
  tired,
  hungry,
  bored,
  neutral;

  String toDisplayString() {
    return switch (this) {
      PetEmotion.happy => 'Feliz',
      PetEmotion.sad => 'Triste',
      PetEmotion.sick => 'Enfermo',
      PetEmotion.dirty => 'Sucio',
      PetEmotion.tired => 'Cansado',
      PetEmotion.hungry => 'Hambriento',
      PetEmotion.bored => 'Aburrido',
      PetEmotion.neutral => 'Neutral',
    };
  }

  String toFirestoreString() => name;
}
