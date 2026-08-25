import 'dart:async';

import '../../domain/models/app_user.dart';
import '../../domain/models/care_models.dart';
import '../../domain/models/pet.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/care_repository.dart';

class DemoCareRepository implements CareRepository {
  DemoCareRepository()
    : _pets = [
        const Pet(
          id: 'demo-luna',
          ownerId: 'demo-owner',
          name: 'Luna',
          species: 'Dog',
          breed: 'Siberian Husky',
          age: 3,
          gender: 'Female',
          description: 'Snow-loving, gentle, and always ready for a walk.',
        ),
        const Pet(
          id: 'demo-milo',
          ownerId: 'demo-owner',
          name: 'Milo',
          species: 'Cat',
          breed: 'Orange Tabby',
          age: 2,
          gender: 'Male',
        ),
      ],
      _products = const [
        ProductItem(
          id: 'nutrition',
          name: 'Everyday Nutrition',
          description: 'Balanced adult pet food.',
          price: 24,
          category: 'Food',
          purchaseUrl:
              'https://www.google.com/search?q=balanced+adult+pet+food',
        ),
        ProductItem(
          id: 'grooming',
          name: 'Gentle Grooming Kit',
          description: 'Brush, shampoo, and paw balm.',
          price: 32,
          category: 'Grooming',
          purchaseUrl: 'https://www.google.com/search?q=pet+grooming+kit',
        ),
        ProductItem(
          id: 'toy',
          name: 'Enrichment Puzzle Toy',
          description: 'A reusable treat puzzle for supervised play.',
          price: 18,
          category: 'Toys',
          purchaseUrl: 'https://www.google.com/search?q=pet+puzzle+toy',
        ),
        ProductItem(
          id: 'health',
          name: 'Pet First-Aid Kit',
          description: 'Practical supplies for minor emergencies.',
          price: 29,
          category: 'Health',
          purchaseUrl: 'https://www.google.com/search?q=pet+first+aid+kit',
        ),
      ],
      _blogs = [
        BlogArticle(
          id: 'calm-vet',
          title: 'A calmer first vet visit',
          category: 'Training',
          summary: 'Simple preparation steps for a low-stress visit.',
          content:
              'Practice short carrier or car sessions, reward calm behavior, and bring familiar treats. Share behavior concerns with the clinic before arrival.',
          publishedAt: DateTime(2026, 8, 12),
          authorName: 'Dr. Maya Chen (DVM)',
          tags: const ['Training', 'Behavior', 'Clinic Visit'],
        ),
        BlogArticle(
          id: 'first-aid',
          title: 'Pet first-aid essentials',
          category: 'First Aid',
          summary: 'What belongs in a practical pet first-aid kit.',
          content:
              'Keep gauze, saline, gloves, a digital thermometer, emergency contacts, and current medication details together. First aid never replaces veterinary care.',
          publishedAt: DateTime(2026, 8, 10),
          authorName: 'Dr. Marcus Vance (BVSc)',
          tags: const ['First Aid', 'Emergency', 'Safety'],
        ),
        BlogArticle(
          id: 'nutrition-basics',
          title: 'Everyday nutrition basics',
          category: 'Nutrition',
          summary: 'Build a consistent and balanced feeding routine.',
          content:
              'Choose food formulated for your pet’s species and life stage, measure portions, provide fresh water, and discuss weight changes with a veterinarian.',
          publishedAt: DateTime(2026, 8, 8),
          authorName: 'Dr. Maya Chen (DVM)',
          tags: const ['Nutrition', 'Diet', 'Wellness'],
        ),
        BlogArticle(
          id: 'daily-care',
          title: 'A simple daily pet-care checklist',
          category: 'Pet Care',
          summary: 'Small daily habits that support long-term wellbeing.',
          content:
              'Check appetite, water intake, energy, toileting, coat, eyes, and mobility. Record meaningful changes and seek veterinary advice when symptoms persist.',
          publishedAt: DateTime(2026, 8, 6),
          authorName: 'PawfectCare Editorial',
          tags: const ['Pet Care', 'Checklist', 'Health'],
        ),
      ] {
    final start = DateTime.now().add(const Duration(days: 2));
    _slots.add(
      AvailabilitySlot(
        id: 'demo-open-slot',
        veterinarianId: 'demo-veterinarian',
        start: start,
        end: start.add(const Duration(minutes: 30)),
        isBooked: false,
      ),
    );
  }

  final List<Pet> _pets;
  final List<CareAppointment> _appointments = [];
  final List<AvailabilitySlot> _slots = [];
  final List<AdoptionRequest> _adoptionRequests = [];
  final List<CommunityRequest> _communityRequests = [];
  final List<SuccessStory> _successStories = [];
  final StreamController<void> _successStoryChanges =
      StreamController<void>.broadcast();
  final StreamController<void> _blogChanges =
      StreamController<void>.broadcast();
  final List<ProductItem> _products;
  final List<BlogArticle> _blogs;
  final Set<String> _wishlist = {};
  final Set<String> _bookmarks = {};

  @override
  Stream<List<Pet>> watchOwnedPets(String ownerId) =>
      Stream.value(_pets.where((pet) => pet.ownerId == ownerId).toList());

  @override
  Stream<List<Pet>> watchAssignedPets(String veterinarianId) =>
      Stream.value(List.unmodifiable(_pets));

  @override
  Future<String> savePet(Pet pet) async {
    final id = pet.id.isEmpty
        ? 'demo-pet-${DateTime.now().microsecondsSinceEpoch}'
        : pet.id;
    _pets.removeWhere((item) => item.id == id);
    _pets.add(pet.copyWith(id: id));
    return id;
  }

  @override
  Future<void> deletePet(Pet pet) async =>
      _pets.removeWhere((item) => item.id == pet.id);

  final Map<String, List<HealthRecord>> _healthRecordsStore = {};

  @override
  Stream<List<HealthRecord>> watchHealthRecords(String petId) {
    if (!_healthRecordsStore.containsKey(petId)) {
      _healthRecordsStore[petId] = [
        HealthRecord(
          id: 'demo-health-$petId',
          petId: petId,
          type: HealthRecordType.vaccination,
          title: 'Rabies vaccination',
          date: DateTime.now().subtract(const Duration(days: 30)),
          dueDate: DateTime.now().add(const Duration(days: 5)),
          notes: 'Annual booster reminder.',
        ),
      ];
    }
    return Stream.value(_healthRecordsStore[petId]!);
  }

  @override
  Future<String> saveHealthRecord({
    required AppUser actor,
    required HealthRecord record,
  }) async {
    final petId = record.petId;
    final records = _healthRecordsStore[petId] ?? [];
    final id = record.id.isEmpty
        ? 'demo-health-${DateTime.now().microsecondsSinceEpoch}'
        : record.id;
    final updatedRecord = HealthRecord(
      id: id,
      petId: record.petId,
      type: record.type,
      title: record.title,
      date: record.date,
      veterinarianId: record.veterinarianId,
      diagnosis: record.diagnosis,
      treatment: record.treatment,
      prescription: record.prescription,
      dueDate: record.dueDate,
      followUpDate: record.followUpDate,
      notes: record.notes,
      reportPaths: record.reportPaths,
    );
    final index = records.indexWhere((r) => r.id == id);
    if (index >= 0) {
      records[index] = updatedRecord;
    } else {
      records.add(updatedRecord);
    }
    _healthRecordsStore[petId] = records;

    if (record.dueDate != null) {
      _addNotification(
        title: '${record.type.label} Reminder Set',
        body: 'Reminder set for ${record.title} (Due: ${record.dueDate!.day}/${record.dueDate!.month}/${record.dueDate!.year}).',
        type: 'vaccination',
        targetUserId: actor.uid,
      );
    }
    return id;
  }

  @override
  Future<void> deleteHealthRecord({
    required AppUser actor,
    required HealthRecord record,
  }) async {
    _healthRecordsStore[record.petId]?.removeWhere((r) => r.id == record.id);
  }

  @override
  Stream<List<VeterinarianProfile>> watchVeterinarians() => Stream.value(const [
    VeterinarianProfile(
      uid: 'demo-veterinarian',
      name: 'Dr. Maya Chen',
      clinicName: 'City Care Clinic',
      specialty: 'Companion Animals',
      location: 'Lahore, Pakistan',
    ),
  ]);

  @override
  Stream<List<AvailabilitySlot>> watchAvailability({String? veterinarianId}) =>
      Stream.value(
        _slots
            .where(
              (slot) =>
                  veterinarianId == null ||
                  slot.veterinarianId == veterinarianId,
            )
            .toList(),
      );

  @override
  Future<String> createAvailability({
    required String veterinarianId,
    required DateTime start,
    required DateTime end,
  }) async {
    final id = 'demo-slot-${start.microsecondsSinceEpoch}';
    _slots.add(
      AvailabilitySlot(
        id: id,
        veterinarianId: veterinarianId,
        start: start,
        end: end,
        isBooked: false,
      ),
    );
    return id;
  }

  @override
  Future<void> deleteAvailability(AvailabilitySlot slot) async =>
      _slots.removeWhere((item) => item.id == slot.id);

  @override
  Stream<List<CareAppointment>> watchAppointments(AppUser user) => Stream.value(
    _appointments
        .where(
          (item) => item.ownerId == user.uid || item.veterinarianId == user.uid,
        )
        .toList(),
  );

  @override
  Future<String> bookAppointment({
    required AppUser owner,
    required Pet pet,
    required VeterinarianProfile veterinarian,
    required AvailabilitySlot slot,
    required String reason,
  }) async {
    final slotIndex = _slots.indexWhere((item) => item.id == slot.id);
    if (slotIndex < 0 || _slots[slotIndex].isBooked) {
      throw const CareFailure('That appointment time is no longer open.');
    }
    _slots[slotIndex] = AvailabilitySlot(
      id: slot.id,
      veterinarianId: slot.veterinarianId,
      start: slot.start,
      end: slot.end,
      isBooked: true,
      bookingOwnerId: owner.uid,
    );
    _appointments.add(
      CareAppointment(
        id: slot.id,
        slotId: slot.id,
        petId: pet.id,
        petName: pet.name,
        ownerId: owner.uid,
        veterinarianId: veterinarian.uid,
        veterinarianName: veterinarian.name,
        dateTime: slot.start,
        reason: reason,
        status: AppointmentStatus.pending,
      ),
    );
    _addNotification(
      title: 'Appointment Booked',
      body: 'Your appointment for ${pet.name} with ${veterinarian.name} is booked.',
      type: 'appointment',
      targetUserId: owner.uid,
    );
    _addNotification(
      title: 'New Appointment Booking',
      body: '${owner.name} booked an appointment for ${pet.name} on ${slot.start.day}/${slot.start.month} at ${slot.start.hour}:${slot.start.minute.toString().padLeft(2, '0')}.',
      type: 'appointment',
      targetUserId: veterinarian.uid,
    );
    return slot.id;
  }

  @override
  Future<String> rescheduleAppointment({
    required AppUser actor,
    required CareAppointment appointment,
    required AvailabilitySlot newSlot,
  }) async {
    await updateAppointmentStatus(
      appointment: appointment,
      status: AppointmentStatus.cancelled,
    );
    final slotIndex = _slots.indexWhere((item) => item.id == newSlot.id);
    if (slotIndex < 0 || _slots[slotIndex].isBooked) {
      throw const CareFailure('That appointment time is no longer open.');
    }
    _slots[slotIndex] = AvailabilitySlot(
      id: newSlot.id,
      veterinarianId: newSlot.veterinarianId,
      start: newSlot.start,
      end: newSlot.end,
      isBooked: true,
      bookingOwnerId: appointment.ownerId,
    );
    _appointments.add(
      CareAppointment(
        id: newSlot.id,
        slotId: newSlot.id,
        petId: appointment.petId,
        petName: appointment.petName,
        ownerId: appointment.ownerId,
        veterinarianId: appointment.veterinarianId,
        veterinarianName: appointment.veterinarianName,
        dateTime: newSlot.start,
        reason: appointment.reason,
        status: AppointmentStatus.pending,
      ),
    );
    _addNotification(
      title: 'Appointment Rescheduled',
      body: 'Appointment for ${appointment.petName} has been rescheduled to ${newSlot.start.day}/${newSlot.start.month} at ${newSlot.start.hour}:${newSlot.start.minute.toString().padLeft(2, '0')}.',
      type: 'appointment',
      targetUserId: appointment.ownerId,
    );
    return newSlot.id;
  }

  @override
  Future<void> updateAppointmentStatus({
    required CareAppointment appointment,
    required AppointmentStatus status,
  }) async {
    final index = _appointments.indexWhere((item) => item.id == appointment.id);
    if (index < 0) return;
    _appointments[index] = CareAppointment(
      id: appointment.id,
      slotId: appointment.slotId,
      petId: appointment.petId,
      petName: appointment.petName,
      ownerId: appointment.ownerId,
      veterinarianId: appointment.veterinarianId,
      veterinarianName: appointment.veterinarianName,
      dateTime: appointment.dateTime,
      reason: appointment.reason,
      status: status,
    );
    _addNotification(
      title: 'Appointment ${status.label}',
      body: 'Your appointment for ${appointment.petName} with ${appointment.veterinarianName} has been ${status.label.toLowerCase()}.',
      type: 'appointment',
      targetUserId: appointment.ownerId,
    );
    _addNotification(
      title: 'Appointment ${status.label}',
      body: 'Appointment for ${appointment.petName} has been marked as ${status.label.toLowerCase()}.',
      type: 'appointment',
      targetUserId: appointment.veterinarianId,
    );
    if (status == AppointmentStatus.cancelled) {
      final slotIndex = _slots.indexWhere(
        (item) => item.id == appointment.slotId,
      );
      if (slotIndex >= 0) {
        final slot = _slots[slotIndex];
        _slots[slotIndex] = AvailabilitySlot(
          id: slot.id,
          veterinarianId: slot.veterinarianId,
          start: slot.start,
          end: slot.end,
          isBooked: false,
        );
      }
    }
  }

  @override
  Stream<List<ShelterProfile>> watchShelters() => Stream.value(const [
    ShelterProfile(
      id: 'demo-shelter',
      adminId: 'demo-shelterAdmin',
      name: 'Happy Tails Shelter',
      location: 'Lahore, Pakistan',
      phone: '+92 300 0000000',
    ),
  ]);

  @override
  Future<String> saveShelter(ShelterProfile shelter) async =>
      shelter.id.isEmpty ? 'demo-shelter' : shelter.id;

  @override
  Stream<List<AdoptionListing>> watchAdoptionListings({String? shelterId}) =>
      Stream.value(const [
        AdoptionListing(
          id: 'demo-coco',
          shelterId: 'demo-shelter',
          adminId: 'demo-shelterAdmin',
          petName: 'Coco',
          species: 'Dog',
          age: 2,
          gender: 'Female',
          healthStatus: 'Vaccinated and healthy',
          status: AdoptionStatus.available,
          description: 'Gentle, social, and ready for a family.',
        ),
      ]);

  @override
  Future<String> saveAdoptionListing(AdoptionListing listing) async =>
      listing.id.isEmpty
      ? 'demo-listing-${DateTime.now().microsecondsSinceEpoch}'
      : listing.id;

  @override
  Future<void> deleteAdoptionListing(AdoptionListing listing) async {}

  @override
  Stream<List<AdoptionRequest>> watchAdoptionRequests(AppUser user) =>
      Stream.value(
        _adoptionRequests
            .where(
              (item) =>
                  item.ownerId == user.uid || item.shelterAdminId == user.uid,
            )
            .toList(),
      );

  @override
  Future<String> submitAdoptionRequest({
    required AppUser owner,
    required AdoptionListing listing,
    required String message,
  }) async {
    final alreadySubmitted = _adoptionRequests.any(
      (request) =>
          request.ownerId == owner.uid &&
          request.listingId == listing.id &&
          request.status != RequestStatus.rejected,
    );
    if (alreadySubmitted) {
      throw const CareFailure(
        'You already have an active adoption request for this pet.',
      );
    }
    final id = 'demo-request-${DateTime.now().microsecondsSinceEpoch}';
    _adoptionRequests.add(
      AdoptionRequest(
        id: id,
        listingId: listing.id,
        petName: listing.petName,
        ownerId: owner.uid,
        ownerName: owner.name,
        shelterId: listing.shelterId,
        shelterAdminId: listing.adminId,
        status: RequestStatus.pending,
        message: message,
        createdAt: DateTime.now(),
      ),
    );
    _addNotification(
      title: 'Adoption Application Sent',
      body: 'Your application to adopt ${listing.petName} has been submitted to the shelter.',
      type: 'adoption',
      targetUserId: owner.uid,
    );
    _addNotification(
      title: 'New Adoption Application',
      body: '${owner.name} submitted an application to adopt ${listing.petName}.',
      type: 'adoption',
      targetUserId: listing.adminId,
    );
    return id;
  }

   @override
  Future<void> updateAdoptionRequest({
    required AdoptionRequest request,
    required RequestStatus status,
  }) async {
    final index = _adoptionRequests.indexWhere((item) => item.id == request.id);
    if (index < 0) return;

    _adoptionRequests[index] = _requestWithStatus(request, status);

    if (status == RequestStatus.approved) {
      for (var i = 0; i < _adoptionRequests.length; i++) {
        final item = _adoptionRequests[i];
        if (item.id != request.id &&
            item.listingId == request.listingId &&
            item.status == RequestStatus.pending) {
          _adoptionRequests[i] = _requestWithStatus(
            item,
            RequestStatus.rejected,
          );
        }
      }
    }

    _addNotification(
      title: 'Adoption Application Update',
      body:
          'Your application for ${request.petName} has been ${status.label.toLowerCase()}.',
      type: 'adoption',
      targetUserId: request.ownerId,
    );
  }

  AdoptionRequest _requestWithStatus(
    AdoptionRequest request,
    RequestStatus status,
  ) =>
      AdoptionRequest(
        id: request.id,
        listingId: request.listingId,
        petName: request.petName,
        ownerId: request.ownerId,
        ownerName: request.ownerName,
        shelterId: request.shelterId,
        shelterAdminId: request.shelterAdminId,
        status: status,
        message: request.message,
        createdAt: request.createdAt,
      );
  @override
  Stream<List<SuccessStory>> watchSuccessStories({String? shelterId}) async* {
    yield _visibleStories(shelterId);
    await for (final _ in _successStoryChanges.stream) {
      yield _visibleStories(shelterId);
    }
  }

  @override
  Future<String> saveSuccessStory(SuccessStory story) async {
    final now = DateTime.now();
    final id = story.id.isEmpty
        ? 'demo-story-${now.microsecondsSinceEpoch}'
        : story.id;
    final existingIndex = _successStories.indexWhere((item) => item.id == id);
    final saved = story.copyWith(
      id: id,
      createdAt: existingIndex < 0
          ? story.createdAt ?? now
          : _successStories[existingIndex].createdAt,
      updatedAt: now,
    );
    if (existingIndex < 0) {
      _successStories.add(saved);
    } else {
      _successStories[existingIndex] = saved;
    }
    _successStoryChanges.add(null);
    return id;
  }

  @override
  Future<void> deleteSuccessStory(SuccessStory story) async {
    _successStories.removeWhere((item) => item.id == story.id);
    _successStoryChanges.add(null);
  }

  List<SuccessStory> _visibleStories(String? shelterId) {
    final stories = _successStories
        .where(
          (story) => shelterId == null
              ? story.published
              : story.shelterId == shelterId,
        )
        .toList();
    stories.sort(
      (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(1970)).compareTo(
        a.updatedAt ?? a.createdAt ?? DateTime(1970),
      ),
    );
    return stories;
  }

  @override
  Stream<List<CommunityRequest>> watchVolunteerRequests(AppUser user) =>
      _watchCommunityDemo(user, const {'volunteer', 'donation'});

  @override
  Stream<List<CommunityRequest>> watchContactMessages(AppUser user) =>
      _watchCommunityDemo(user, const {'inquiry'});

  @override
  Future<String> submitCommunityRequest({
    required AppUser user,
    required String shelterId,
    required String kind,
    required String message,
  }) async {
    final id = 'demo-community-${DateTime.now().microsecondsSinceEpoch}';
    _communityRequests.add(
      CommunityRequest(
        id: id,
        shelterId: shelterId,
        userId: user.uid,
        userName: user.name,
        kind: kind,
        message: message.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
      ),
    );
    return id;
  }

  @override
  Future<void> updateCommunityRequestStatus({
    required CommunityRequest request,
    required String status,
  }) async {
    final index = _communityRequests.indexWhere(
      (item) => item.id == request.id,
    );
    if (index < 0) return;
    _communityRequests[index] = CommunityRequest(
      id: request.id,
      shelterId: request.shelterId,
      userId: request.userId,
      userName: request.userName,
      kind: request.kind,
      message: request.message,
      status: status,
      createdAt: request.createdAt,
    );
  }

  Stream<List<CommunityRequest>> _watchCommunityDemo(
    AppUser user,
    Set<String> kinds,
  ) => Stream.value(
    _communityRequests
        .where(
          (request) =>
              kinds.contains(request.kind) &&
              (request.userId == user.uid ||
                  (user.role == UserRole.shelterAdmin &&
                      request.shelterId == 'demo-shelter')),
        )
        .toList(),
  );

  @override
  Stream<List<ProductItem>> watchProducts() => Stream.value(_products);

  @override
  Stream<Set<String>> watchWishlist(String uid) => Stream.value(_wishlist);

  @override
  Future<void> setWishlist({
    required String uid,
    required String productId,
    required bool saved,
  }) async => saved ? _wishlist.add(productId) : _wishlist.remove(productId);

  @override
  Stream<List<BlogArticle>> watchBlogs() async* {
    yield List<BlogArticle>.from(_blogs);
    await for (final _ in _blogChanges.stream) {
      yield List<BlogArticle>.from(_blogs);
    }
  }

  @override
  Future<String> saveBlogArticle(BlogArticle article) async {
    final id = article.id.isEmpty
        ? 'demo-blog-${DateTime.now().microsecondsSinceEpoch}'
        : article.id;
    final updated = article.copyWith(id: id);
    final index = _blogs.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _blogs[index] = updated;
    } else {
      _blogs.insert(0, updated);
    }
    _blogChanges.add(null);
    return id;
  }

  @override
  Future<void> deleteBlogArticle(String blogId) async {
    _blogs.removeWhere((item) => item.id == blogId);
    _blogChanges.add(null);
  }

  @override
  Stream<Set<String>> watchBookmarks(String uid) => Stream.value(_bookmarks);

  @override
  Future<void> setBookmark({
    required String uid,
    required String blogId,
    required bool saved,
  }) async => saved ? _bookmarks.add(blogId) : _bookmarks.remove(blogId);

  final List<UserNotification> _notifications = [
    UserNotification(
      id: 'welcome-notif',
      title: 'Welcome to PawfectCare',
      body: 'Keep track of your pets, vaccinations, and vet appointments all in one place!',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      type: 'general',
      resourceId: 'demo-owner',
    ),
    UserNotification(
      id: 'welcome-notif-vet',
      title: 'Welcome Dr. Maya Chen',
      body: 'You have active appointment slots and assigned pets ready.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      type: 'general',
      resourceId: 'demo-veterinarian',
    ),
  ];
  final _notificationsController = StreamController<List<UserNotification>>.broadcast();

  @override
  Stream<List<UserNotification>> watchNotifications(String uid) async* {
    List<UserNotification> getForUser(String userId) => _notifications
        .where(
          (n) =>
              n.resourceId == null ||
              n.resourceId == userId ||
              userId.contains(n.resourceId!) ||
              n.resourceId!.contains(userId) ||
              userId.startsWith('demo-') ||
              n.resourceId == 'demo-owner' ||
              n.resourceId == 'demo-veterinarian',
        )
        .toList()
        .reversed
        .toList();

    yield getForUser(uid);
    await for (final _ in _notificationsController.stream) {
      yield getForUser(uid);
    }
  }

  void _addNotification({
    required String title,
    required String body,
    required String type,
    String? targetUserId,
  }) {
    _notifications.add(
      UserNotification(
        id: 'notif-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        body: body,
        createdAt: DateTime.now(),
        type: type,
        resourceId: targetUserId,
      ),
    );
    _notificationsController.add(_notifications);
  }

  @override
  Future<void> markNotificationRead({
    required String uid,
    required String notificationId,
  }) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final old = _notifications[index];
      _notifications[index] = UserNotification(
        id: old.id,
        title: old.title,
        body: old.body,
        createdAt: old.createdAt,
        readAt: DateTime.now(),
        type: old.type,
      );
      _notificationsController.add(_notifications.reversed.toList());
    }
  }

  @override
  Future<String> submitFeedback({
    required AppUser user,
    required String type,
    required String message,
  }) async => 'demo-feedback-${DateTime.now().microsecondsSinceEpoch}';

  @override
  Future<void> updateProfile({
    required AppUser user,
    required String name,
    required String phone,
    String? photoPath,
    String? photoUrl,
  }) async {}

  @override
  Stream<Map<String, bool>> watchNotificationPreferences(String uid) =>
      Stream.value(const {
        'appointments': true,
        'vaccinations': true,
        'adoption': true,
        'blogs': true,
      });

  @override
  Future<void> updateNotificationPreferences({
    required String uid,
    required Map<String, bool> preferences,
  }) async {}
}
