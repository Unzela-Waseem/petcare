class Pet {
  const Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.gender,
    this.photoPath,
    this.photoUrl,
    this.description = '',
  });

  final String id;
  final String ownerId;
  final String name;
  final String species;
  final String breed;
  final int age;
  final String gender;
  final String? photoPath;
  final String? photoUrl;
  final String description;

  Pet copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? species,
    String? breed,
    int? age,
    String? gender,
    String? photoPath,
    String? photoUrl,
    String? description,
  }) => Pet(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    name: name ?? this.name,
    species: species ?? this.species,
    breed: breed ?? this.breed,
    age: age ?? this.age,
    gender: gender ?? this.gender,
    photoPath: photoPath ?? this.photoPath,
    photoUrl: photoUrl ?? this.photoUrl,
    description: description ?? this.description,
  );
}
