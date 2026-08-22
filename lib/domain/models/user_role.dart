enum UserRole {
  petOwner('petOwner', 'Pet Owner', 'Everyday care for your best friend'),
  veterinarian(
    'veterinarian',
    'Veterinarian',
    'Clinical care and patient records',
  ),
  shelterAdmin(
    'shelterAdmin',
    'Shelter Admin',
    'Adoptions and shelter operations',
  );

  const UserRole(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;

  static UserRole? tryParse(String? value) {
    for (final role in values) {
      if (role.value == value) return role;
    }
    return null;
  }
}
