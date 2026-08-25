enum HealthRecordType {
  vaccination('vaccination', 'Vaccination'),
  deworming('deworming', 'Deworming'),
  allergy('allergy', 'Allergy'),
  medical('medical', 'Medical');

  const HealthRecordType(this.value, this.label);
  final String value;
  final String label;

  static HealthRecordType parse(String? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => HealthRecordType.medical,
  );
}

class HealthRecord {
  const HealthRecord({
    required this.id,
    required this.petId,
    required this.type,
    required this.title,
    required this.date,
    this.veterinarianId,
    this.diagnosis = '',
    this.treatment = '',
    this.prescription = '',
    this.notes = '',
    this.dueDate,
    this.followUpDate,
    this.reportPaths = const [],
  });

  final String id;
  final String petId;
  final String? veterinarianId;
  final HealthRecordType type;
  final String title;
  final String diagnosis;
  final String treatment;
  final String prescription;
  final String notes;
  final DateTime date;
  final DateTime? dueDate;
  final DateTime? followUpDate;
  final List<String> reportPaths;
}

class VeterinarianProfile {
  const VeterinarianProfile({
    required this.uid,
    required this.name,
    this.clinicName = '',
    this.specialty = '',
    this.location = '',
    this.photoUrl,
  });

  final String uid;
  final String name;
  final String clinicName;
  final String specialty;
  final String location;
  final String? photoUrl;
}

class AvailabilitySlot {
  const AvailabilitySlot({
    required this.id,
    required this.veterinarianId,
    required this.start,
    required this.end,
    required this.isBooked,
    this.bookingOwnerId,
  });

  final String id;
  final String veterinarianId;
  final DateTime start;
  final DateTime end;
  final bool isBooked;
  final String? bookingOwnerId;
}

enum AppointmentStatus {
  pending('pending', 'Pending'),
  confirmed('confirmed', 'Confirmed'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  const AppointmentStatus(this.value, this.label);
  final String value;
  final String label;

  static AppointmentStatus parse(String? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => AppointmentStatus.pending,
  );
}

class CareAppointment {
  const CareAppointment({
    required this.id,
    required this.slotId,
    required this.petId,
    required this.petName,
    required this.ownerId,
    required this.veterinarianId,
    required this.veterinarianName,
    required this.dateTime,
    required this.reason,
    required this.status,
  });

  final String id;
  final String slotId;
  final String petId;
  final String petName;
  final String ownerId;
  final String veterinarianId;
  final String veterinarianName;
  final DateTime dateTime;
  final String reason;
  final AppointmentStatus status;
}

class ShelterProfile {
  const ShelterProfile({
    required this.id,
    required this.adminId,
    required this.name,
    required this.location,
    this.phone = '',
    this.description = '',
  });

  final String id;
  final String adminId;
  final String name;
  final String location;
  final String phone;
  final String description;
}

enum AdoptionStatus {
  available('available', 'Available'),
  pending('pending', 'Pending'),
  adopted('adopted', 'Adopted');

  const AdoptionStatus(this.value, this.label);
  final String value;
  final String label;

  static AdoptionStatus parse(String? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => AdoptionStatus.available,
  );
}

class AdoptionListing {
  const AdoptionListing({
    required this.id,
    required this.shelterId,
    required this.adminId,
    required this.petName,
    required this.species,
    required this.age,
    required this.gender,
    required this.healthStatus,
    required this.status,
    this.description = '',
    this.photoPath,
    this.photoUrl,
  });

  final String id;
  final String shelterId;
  final String adminId;
  final String petName;
  final String species;
  final int age;
  final String gender;
  final String healthStatus;
  final AdoptionStatus status;
  final String description;
  final String? photoPath;
  final String? photoUrl;
}

enum RequestStatus {
  pending('pending', 'Pending'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected');

  const RequestStatus(this.value, this.label);
  final String value;
  final String label;

  static RequestStatus parse(String? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => RequestStatus.pending,
  );
}

class AdoptionRequest {
  const AdoptionRequest({
    required this.id,
    required this.listingId,
    required this.petName,
    required this.ownerId,
    required this.ownerName,
    required this.shelterId,
    required this.shelterAdminId,
    required this.status,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String listingId;
  final String petName;
  final String ownerId;
  final String ownerName;
  final String shelterId;
  final String shelterAdminId;
  final RequestStatus status;
  final String message;
  final DateTime createdAt;
}

class SuccessStory {
  const SuccessStory({
    required this.id,
    required this.shelterId,
    required this.adminId,
    required this.title,
    required this.story,
    required this.published,
    this.photoPath,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String shelterId;
  final String adminId;
  final String title;
  final String story;
  final bool published;
  final String? photoPath;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SuccessStory copyWith({
    String? id,
    String? shelterId,
    String? adminId,
    String? title,
    String? story,
    bool? published,
    String? photoPath,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SuccessStory(
    id: id ?? this.id,
    shelterId: shelterId ?? this.shelterId,
    adminId: adminId ?? this.adminId,
    title: title ?? this.title,
    story: story ?? this.story,
    published: published ?? this.published,
    photoPath: photoPath ?? this.photoPath,
    photoUrl: photoUrl ?? this.photoUrl,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class CommunityRequest {
  const CommunityRequest({
    required this.id,
    required this.shelterId,
    required this.userId,
    required this.userName,
    required this.kind,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String shelterId;
  final String userId;
  final String userName;
  final String kind;
  final String message;
  final String status;
  final DateTime createdAt;
}

class ProductItem {
  const ProductItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.purchaseUrl,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String purchaseUrl;
  final String? imageUrl;
}

class BlogArticle {
  const BlogArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.content,
    required this.publishedAt,
    this.imageUrl,
    this.authorId,
    this.authorName,
    this.tags = const <String>[],
    this.published = true,
  });

  final String id;
  final String title;
  final String category;
  final String summary;
  final String content;
  final DateTime publishedAt;
  final String? imageUrl;
  final String? authorId;
  final String? authorName;
  final List<String> tags;
  final bool published;

  BlogArticle copyWith({
    String? id,
    String? title,
    String? category,
    String? summary,
    String? content,
    DateTime? publishedAt,
    String? imageUrl,
    String? authorId,
    String? authorName,
    List<String>? tags,
    bool? published,
  }) => BlogArticle(
    id: id ?? this.id,
    title: title ?? this.title,
    category: category ?? this.category,
    summary: summary ?? this.summary,
    content: content ?? this.content,
    publishedAt: publishedAt ?? this.publishedAt,
    imageUrl: imageUrl ?? this.imageUrl,
    authorId: authorId ?? this.authorId,
    authorName: authorName ?? this.authorName,
    tags: tags ?? this.tags,
    published: published ?? this.published,
  );
}

class UserNotification {
  const UserNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.readAt,
    this.resourceId,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? resourceId;
}
