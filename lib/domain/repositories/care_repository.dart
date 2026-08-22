import '../models/app_user.dart';
import '../models/care_models.dart';
import '../models/pet.dart';

abstract interface class CareRepository {
  Stream<List<Pet>> watchOwnedPets(String ownerId);
  Stream<List<Pet>> watchAssignedPets(String veterinarianId);
  Future<String> savePet(Pet pet);
  Future<void> deletePet(Pet pet);

  Stream<List<HealthRecord>> watchHealthRecords(String petId);
  Future<String> saveHealthRecord({
    required AppUser actor,
    required HealthRecord record,
  });
  Future<void> deleteHealthRecord({
    required AppUser actor,
    required HealthRecord record,
  });

  Stream<List<VeterinarianProfile>> watchVeterinarians();
  Stream<List<AvailabilitySlot>> watchAvailability({String? veterinarianId});
  Future<String> createAvailability({
    required String veterinarianId,
    required DateTime start,
    required DateTime end,
  });
  Future<void> deleteAvailability(AvailabilitySlot slot);
  Stream<List<CareAppointment>> watchAppointments(AppUser user);
  Future<String> bookAppointment({
    required AppUser owner,
    required Pet pet,
    required VeterinarianProfile veterinarian,
    required AvailabilitySlot slot,
    required String reason,
  });
  Future<String> rescheduleAppointment({
    required AppUser actor,
    required CareAppointment appointment,
    required AvailabilitySlot newSlot,
  });
  Future<void> updateAppointmentStatus({
    required CareAppointment appointment,
    required AppointmentStatus status,
  });

  Stream<List<ShelterProfile>> watchShelters();
  Future<String> saveShelter(ShelterProfile shelter);
  Stream<List<AdoptionListing>> watchAdoptionListings({String? shelterId});
  Future<String> saveAdoptionListing(AdoptionListing listing);
  Future<void> deleteAdoptionListing(AdoptionListing listing);
  Stream<List<AdoptionRequest>> watchAdoptionRequests(AppUser user);
  Future<String> submitAdoptionRequest({
    required AppUser owner,
    required AdoptionListing listing,
    required String message,
  });
  Future<void> updateAdoptionRequest({
    required AdoptionRequest request,
    required RequestStatus status,
  });
  Stream<List<SuccessStory>> watchSuccessStories({String? shelterId});
  Future<String> saveSuccessStory(SuccessStory story);
  Future<void> deleteSuccessStory(SuccessStory story);

  Stream<List<CommunityRequest>> watchVolunteerRequests(AppUser user);
  Stream<List<CommunityRequest>> watchContactMessages(AppUser user);
  Future<String> submitCommunityRequest({
    required AppUser user,
    required String shelterId,
    required String kind,
    required String message,
  });
  Future<void> updateCommunityRequestStatus({
    required CommunityRequest request,
    required String status,
  });

  Stream<List<ProductItem>> watchProducts();
  Stream<Set<String>> watchWishlist(String uid);
  Future<void> setWishlist({
    required String uid,
    required String productId,
    required bool saved,
  });
  Stream<List<BlogArticle>> watchBlogs();
  Stream<Set<String>> watchBookmarks(String uid);
  Future<void> setBookmark({
    required String uid,
    required String blogId,
    required bool saved,
  });

  Stream<List<UserNotification>> watchNotifications(String uid);
  Future<void> markNotificationRead({
    required String uid,
    required String notificationId,
  });
  Future<String> submitFeedback({
    required AppUser user,
    required String type,
    required String message,
  });
  Future<void> updateProfile({
    required AppUser user,
    required String name,
    required String phone,
    String? photoPath,
    String? photoUrl,
  });
  Stream<Map<String, bool>> watchNotificationPreferences(String uid);
  Future<void> updateNotificationPreferences({
    required String uid,
    required Map<String, bool> preferences,
  });
}

class CareFailure implements Exception {
  const CareFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
