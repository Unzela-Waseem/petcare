class Pet {
  const Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.gender,
  });

  final String id;
  final String ownerId;
  final String name;
  final String species;
  final String breed;
  final int age;
  final String gender;
}
