enum PublicPetSourceType {
  ownedPet('ownedPet'),
  shelterListing('shelterListing');

  const PublicPetSourceType(this.value);

  final String value;

  static PublicPetSourceType parse(String? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => PublicPetSourceType.ownedPet,
  );
}

class PublicPetProfile {
  const PublicPetProfile({
    required this.id,
    required this.sourceId,
    required this.sourceType,
    required this.managerId,
    required this.petName,
    required this.species,
    required this.age,
    required this.gender,
    required this.contactName,
    required this.contactPhone,
    this.breed = '',
    this.photoUrl,
    this.description = '',
    this.allergies = '',
    this.emergencyNotes = '',
    this.isLost = false,
    this.active = true,
    this.updatedAt,
  });

  final String id;
  final String sourceId;
  final PublicPetSourceType sourceType;
  final String managerId;
  final String petName;
  final String species;
  final String breed;
  final int age;
  final String gender;
  final String? photoUrl;
  final String description;
  final String allergies;
  final String emergencyNotes;
  final String contactName;
  final String contactPhone;
  final bool isLost;
  final bool active;
  final DateTime? updatedAt;

  PublicPetProfile copyWith({
    String? id,
    String? sourceId,
    PublicPetSourceType? sourceType,
    String? managerId,
    String? petName,
    String? species,
    String? breed,
    String? photoUrl,
    int? age,
    String? gender,
    String? description,
    String? allergies,
    String? emergencyNotes,
    String? contactName,
    String? contactPhone,
    bool? isLost,
    bool? active,
    DateTime? updatedAt,
  }) => PublicPetProfile(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    sourceType: sourceType ?? this.sourceType,
    managerId: managerId ?? this.managerId,
    petName: petName ?? this.petName,
    species: species ?? this.species,
    breed: breed ?? this.breed,
    photoUrl: photoUrl ?? this.photoUrl,
    age: age ?? this.age,
    gender: gender ?? this.gender,
    description: description ?? this.description,
    allergies: allergies ?? this.allergies,
    emergencyNotes: emergencyNotes ?? this.emergencyNotes,
    contactName: contactName ?? this.contactName,
    contactPhone: contactPhone ?? this.contactPhone,
    isLost: isLost ?? this.isLost,
    active: active ?? this.active,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
