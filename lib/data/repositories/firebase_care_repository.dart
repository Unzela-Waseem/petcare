import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/models/app_user.dart';
import '../../domain/models/care_models.dart';
import '../../domain/models/pet.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/care_repository.dart';

class FirebaseCareRepository implements CareRepository {
  FirebaseCareRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  @override
  Stream<List<Pet>> watchOwnedPets(String ownerId) => _db
      .collection('pets')
      .where('ownerId', isEqualTo: ownerId)
      .snapshots()
      .map((snapshot) => _sortPets(snapshot.docs.map(_petFromDoc).toList()));

  @override
  Stream<List<Pet>> watchAssignedPets(String veterinarianId) => _db
      .collectionGroup('veterinarians')
      .where('veterinarianId', isEqualTo: veterinarianId)
      .where('active', isEqualTo: true)
      .snapshots()
      .asyncMap((snapshot) async {
        final petIds = snapshot.docs
            .map((doc) => doc.data()['petId'] as String?)
            .whereType<String>()
            .toSet();
        final documents = await Future.wait(
          petIds.map((petId) => _db.collection('pets').doc(petId).get()),
        );
        return _sortPets(
          documents.where((doc) => doc.exists).map(_petFromDoc).toList(),
        );
      });

  @override
  Future<String> savePet(Pet pet) => _safe(() async {
    final reference = pet.id.isEmpty
        ? _db.collection('pets').doc()
        : _db.collection('pets').doc(pet.id);
    final existing = pet.id.isEmpty ? null : await reference.get();
    final data = <String, Object?>{
      'ownerId': pet.ownerId,
      'name': pet.name.trim(),
      'species': pet.species.trim(),
      'breed': pet.breed.trim(),
      'age': pet.age,
      'gender': pet.gender,
      'description': pet.description.trim(),
      'photoPath': pet.photoPath,
      'photoUrl': pet.photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (existing == null || !existing.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await reference.set(data, SetOptions(merge: true));
    return reference.id;
  });

  @override
  Future<void> deletePet(Pet pet) =>
      _safe(() => _db.collection('pets').doc(pet.id).delete());

  @override
  Stream<List<HealthRecord>> watchHealthRecords(String petId) => _db
      .collection('petHealthRecords')
      .where('petId', isEqualTo: petId)
      .snapshots()
      .map((snapshot) {
        final records = snapshot.docs.map(_healthFromDoc).toList();
        records.sort((a, b) => b.date.compareTo(a.date));
        return records;
      });

  @override
  Future<String> saveHealthRecord({
    required AppUser actor,
    required HealthRecord record,
  }) => _safe(() async {
    final reference = record.id.isEmpty
        ? _db.collection('petHealthRecords').doc()
        : _db.collection('petHealthRecords').doc(record.id);
    final existing = record.id.isEmpty ? null : await reference.get();
    final isVet = actor.role == UserRole.veterinarian;
    final data = <String, Object?>{
      'petId': record.petId,
      'createdBy': actor.uid,
      'veterinarianId': isVet ? actor.uid : record.veterinarianId,
      'type': record.type.value,
      'title': record.title.trim(),
      'diagnosis': isVet ? record.diagnosis.trim() : '',
      'treatment': isVet ? record.treatment.trim() : '',
      'prescription': isVet ? record.prescription.trim() : '',
      'notes': record.notes.trim(),
      'date': Timestamp.fromDate(record.date),
      'dueDate': _timestamp(record.dueDate),
      'followUpDate': isVet ? _timestamp(record.followUpDate) : null,
      'reportPaths': isVet ? record.reportPaths : <String>[],
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (existing == null || !existing.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await reference.set(data, SetOptions(merge: true));
    if (record.dueDate != null) {
      await _sendNotification(
        recipientId: actor.uid,
        title: '${record.type.label} Reminder Set',
        body: 'Reminder set for ${record.title} (Due: ${record.dueDate!.day}/${record.dueDate!.month}/${record.dueDate!.year}).',
        type: 'vaccination',
      );
    }
    return reference.id;
  });

  @override
  Future<void> deleteHealthRecord({
    required AppUser actor,
    required HealthRecord record,
  }) => _safe(() => _db.collection('petHealthRecords').doc(record.id).delete());

  @override
  Stream<List<VeterinarianProfile>> watchVeterinarians() => _db
      .collection('publicProfiles')
      .where('role', isEqualTo: UserRole.veterinarian.value)
      .snapshots()
      .map((snapshot) {
        final vets = snapshot.docs.map((doc) {
          final data = doc.data();
          return VeterinarianProfile(
            uid: doc.id,
            name: data['name'] as String? ?? 'Veterinarian',
            clinicName: data['clinicName'] as String? ?? '',
            specialty: data['specialty'] as String? ?? '',
            location: data['location'] as String? ?? '',
            photoUrl: data['photoUrl'] as String?,
          );
        }).toList();
        vets.sort((a, b) => a.name.compareTo(b.name));
        return vets;
      });

  @override
  Stream<List<AvailabilitySlot>> watchAvailability({String? veterinarianId}) {
    Query<Map<String, dynamic>> query = _db.collection('vetAvailability');
    if (veterinarianId != null) {
      query = query.where('veterinarianId', isEqualTo: veterinarianId);
    }
    return query.snapshots().map((snapshot) {
      final slots = snapshot.docs.map(_slotFromDoc).toList();
      slots.sort((a, b) => a.start.compareTo(b.start));
      return slots;
    });
  }

  @override
  Future<String> createAvailability({
    required String veterinarianId,
    required DateTime start,
    required DateTime end,
  }) => _safe(() async {
    if (!end.isAfter(start)) {
      throw const CareFailure('End time must be after the start time.');
    }
    final possibleOverlaps = await _db
        .collection('vetAvailability')
        .where('veterinarianId', isEqualTo: veterinarianId)
        .where('start', isLessThan: Timestamp.fromDate(end))
        .get();
    final overlaps = possibleOverlaps.docs.any(
      (document) => _date(document.data()['end']).isAfter(start),
    );
    if (overlaps) {
      throw const CareFailure('This availability overlaps an existing slot.');
    }
    final id = '${veterinarianId}_${start.toUtc().millisecondsSinceEpoch}';
    await _db.collection('vetAvailability').doc(id).set({
      'veterinarianId': veterinarianId,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'isBooked': false,
      'bookingOwnerId': null,
      'appointmentId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return id;
  });

  @override
  Future<void> deleteAvailability(AvailabilitySlot slot) =>
      _safe(() => _db.collection('vetAvailability').doc(slot.id).delete());

  @override
  Stream<List<CareAppointment>> watchAppointments(AppUser user) {
    Query<Map<String, dynamic>> query = _db.collection('appointments');
    query = user.role == UserRole.veterinarian
        ? query.where('veterinarianId', isEqualTo: user.uid)
        : query.where('ownerId', isEqualTo: user.uid);
    return query.snapshots().map((snapshot) {
      final appointments = snapshot.docs.map(_appointmentFromDoc).toList();
      appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return appointments;
    });
  }

  @override
  Future<String> bookAppointment({
    required AppUser owner,
    required Pet pet,
    required VeterinarianProfile veterinarian,
    required AvailabilitySlot slot,
    required String reason,
  }) => _safe(() async {
    if (owner.role != UserRole.petOwner || pet.ownerId != owner.uid) {
      throw const CareFailure('Only the pet owner can book this visit.');
    }
    final slotRef = _db.collection('vetAvailability').doc(slot.id);
    final appointmentRef = _db.collection('appointments').doc();
    final accessRef = _db
        .collection('petAccess')
        .doc(pet.id)
        .collection('veterinarians')
        .doc(veterinarian.uid);
    await _db.runTransaction((transaction) async {
      final currentSlot = await transaction.get(slotRef);
      final currentAccess = await transaction.get(accessRef);
      final data = currentSlot.data();
      if (data == null || data['isBooked'] == true) {
        throw const CareFailure('That appointment time is no longer open.');
      }
      transaction.update(slotRef, {
        'isBooked': true,
        'bookingOwnerId': owner.uid,
        'appointmentId': appointmentRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(appointmentRef, {
        'slotId': slot.id,
        'petId': pet.id,
        'petName': pet.name,
        'ownerId': owner.uid,
        'ownerName': owner.name,
        'veterinarianId': veterinarian.uid,
        'veterinarianName': veterinarian.name,
        'dateTime': Timestamp.fromDate(slot.start),
        'reason': reason.trim(),
        'status': AppointmentStatus.pending.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final accessData = <String, Object?>{
        'petId': pet.id,
        'veterinarianId': veterinarian.uid,
        'appointmentId': appointmentRef.id,
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!currentAccess.exists) {
        accessData['createdAt'] = FieldValue.serverTimestamp();
      }
      transaction.set(accessRef, accessData, SetOptions(merge: true));
    });
    await _sendNotification(
      recipientId: owner.uid,
      title: 'Appointment Booked',
      body: 'Your appointment for ${pet.name} with ${veterinarian.name} is booked.',
      type: 'appointment',
    );
    await _sendNotification(
      recipientId: veterinarian.uid,
      title: 'New Appointment Booking',
      body: '${owner.name} booked an appointment for ${pet.name} on ${slot.start.day}/${slot.start.month} at ${slot.start.hour}:${slot.start.minute.toString().padLeft(2, '0')}.',
      type: 'appointment',
    );
    return appointmentRef.id;
  });

  @override
  Future<String> rescheduleAppointment({
    required AppUser actor,
    required CareAppointment appointment,
    required AvailabilitySlot newSlot,
  }) => _safe(() async {
    final isOwner = actor.role == UserRole.petOwner;
    final isVeterinarian = actor.role == UserRole.veterinarian;
    if ((!isOwner && !isVeterinarian) ||
        (isOwner && appointment.ownerId != actor.uid) ||
        (isVeterinarian && appointment.veterinarianId != actor.uid) ||
        newSlot.veterinarianId != appointment.veterinarianId) {
      throw const CareFailure('You cannot reschedule this appointment.');
    }
    final newSlotRef = _db.collection('vetAvailability').doc(newSlot.id);
    final oldAppointmentRef = _db
        .collection('appointments')
        .doc(appointment.id);
    final oldSlotRef = _db
        .collection('vetAvailability')
        .doc(appointment.slotId);
    final newAppointmentRef = _db.collection('appointments').doc();
    final accessRef = _db
        .collection('petAccess')
        .doc(appointment.petId)
        .collection('veterinarians')
        .doc(appointment.veterinarianId);
    await _db.runTransaction((transaction) async {
      final currentAppointment = await transaction.get(oldAppointmentRef);
      final currentOldSlot = await transaction.get(oldSlotRef);
      final currentSlot = await transaction.get(newSlotRef);
      final currentAccess = isOwner ? await transaction.get(accessRef) : null;
      final appointmentData = currentAppointment.data();
      final slotData = currentSlot.data();
      if (appointmentData == null || slotData == null) {
        throw const CareFailure(
          'The appointment or selected time no longer exists.',
        );
      }
      if (appointmentData['status'] == AppointmentStatus.cancelled.value ||
          appointmentData['status'] == AppointmentStatus.completed.value) {
        throw const CareFailure('A closed appointment cannot be rescheduled.');
      }
      if (slotData['isBooked'] == true) {
        throw const CareFailure('That appointment time is no longer open.');
      }
      if (slotData['veterinarianId'] != appointment.veterinarianId) {
        throw const CareFailure('Choose a slot from the same veterinarian.');
      }
      transaction.update(oldAppointmentRef, {
        'status': AppointmentStatus.cancelled.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (currentOldSlot.data()?['appointmentId'] == appointment.id) {
        transaction.update(oldSlotRef, {
          'isBooked': false,
          'bookingOwnerId': null,
          'appointmentId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      transaction.update(newSlotRef, {
        'isBooked': true,
        'bookingOwnerId': appointment.ownerId,
        'appointmentId': newAppointmentRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(newAppointmentRef, {
        'slotId': newSlot.id,
        'rescheduledFrom': appointment.id,
        'petId': appointment.petId,
        'petName': appointment.petName,
        'ownerId': appointment.ownerId,
        'ownerName': appointmentData['ownerName'] as String? ?? '',
        'veterinarianId': appointment.veterinarianId,
        'veterinarianName': appointment.veterinarianName,
        'dateTime': Timestamp.fromDate(newSlot.start),
        'reason': appointment.reason,
        'status': AppointmentStatus.pending.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (isOwner) {
        final accessData = <String, Object?>{
          'petId': appointment.petId,
          'veterinarianId': appointment.veterinarianId,
          'appointmentId': newAppointmentRef.id,
          'active': true,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (currentAccess == null || !currentAccess.exists) {
          accessData['createdAt'] = FieldValue.serverTimestamp();
        }
        transaction.set(accessRef, accessData, SetOptions(merge: true));
      }
    });
    return newAppointmentRef.id;
  });

  @override
  Future<void> updateAppointmentStatus({
    required CareAppointment appointment,
    required AppointmentStatus status,
  }) => _safe(() async {
    final appointmentRef = _db.collection('appointments').doc(appointment.id);
    if (status != AppointmentStatus.cancelled) {
      await appointmentRef.update({
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    final slotRef = _db.collection('vetAvailability').doc(appointment.slotId);
    await _db.runTransaction((transaction) async {
      final currentAppointment = await transaction.get(appointmentRef);
      final currentSlot = await transaction.get(slotRef);
      if (!currentAppointment.exists) {
        throw const CareFailure('The appointment no longer exists.');
      }
      transaction.update(appointmentRef, {
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (currentSlot.data()?['appointmentId'] == appointment.id) {
        transaction.update(slotRef, {
          'isBooked': false,
          'bookingOwnerId': null,
          'appointmentId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  });

  @override
  Stream<List<ShelterProfile>> watchShelters() =>
      _db.collection('shelters').snapshots().map((snapshot) {
        final shelters = snapshot.docs.map(_shelterFromDoc).toList();
        shelters.sort((a, b) => a.name.compareTo(b.name));
        return shelters;
      });

  @override
  Future<String> saveShelter(ShelterProfile shelter) => _safe(() async {
    final reference = shelter.id.isEmpty
        ? _db.collection('shelters').doc()
        : _db.collection('shelters').doc(shelter.id);
    await reference.set({
      'adminId': shelter.adminId,
      'name': shelter.name.trim(),
      'location': shelter.location.trim(),
      'phone': shelter.phone.trim(),
      'description': shelter.description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (shelter.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return reference.id;
  });

  @override
  Stream<List<AdoptionListing>> watchAdoptionListings({String? shelterId}) {
    Query<Map<String, dynamic>> query = _db.collection('adoptionListings');
    if (shelterId != null) {
      query = query.where('shelterId', isEqualTo: shelterId);
    }
    return query.snapshots().map((snapshot) {
      final listings = snapshot.docs.map(_listingFromDoc).toList();
      listings.sort((a, b) => a.petName.compareTo(b.petName));
      return listings;
    });
  }

  @override
  Future<String> saveAdoptionListing(AdoptionListing listing) =>
      _safe(() async {
        final reference = listing.id.isEmpty
            ? _db.collection('adoptionListings').doc()
            : _db.collection('adoptionListings').doc(listing.id);
        await reference.set({
          'shelterId': listing.shelterId,
          'adminId': listing.adminId,
          'petName': listing.petName.trim(),
          'species': listing.species.trim(),
          'age': listing.age,
          'gender': listing.gender,
          'healthStatus': listing.healthStatus.trim(),
          'description': listing.description.trim(),
          'photoPath': listing.photoPath,
          'photoUrl': listing.photoUrl,
          'status': listing.status.value,
          'updatedAt': FieldValue.serverTimestamp(),
          if (listing.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return reference.id;
      });

  @override
  Future<void> deleteAdoptionListing(AdoptionListing listing) =>
      _safe(() => _db.collection('adoptionListings').doc(listing.id).delete());

  @override
  Stream<List<AdoptionRequest>> watchAdoptionRequests(AppUser user) {
    Query<Map<String, dynamic>> query = _db.collection('adoptionRequests');
    query = user.role == UserRole.shelterAdmin
        ? query.where('shelterAdminId', isEqualTo: user.uid)
        : query.where('ownerId', isEqualTo: user.uid);
    return query.snapshots().map((snapshot) {
      final requests = snapshot.docs.map(_requestFromDoc).toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  @override
  Future<String> submitAdoptionRequest({
    required AppUser owner,
    required AdoptionListing listing,
    required String message,
  }) => _safe(() async {
    final requests = _db.collection('adoptionRequests');
    final ownerRequests = await requests
        .where('ownerId', isEqualTo: owner.uid)
        .get();
    final alreadySubmitted = ownerRequests.docs.any((document) {
      final data = document.data();
      final status = RequestStatus.parse(data['status'] as String?);
      return data['listingId'] == listing.id &&
          status != RequestStatus.rejected;
    });
    if (alreadySubmitted) {
      throw const CareFailure(
        'You already have an active adoption request for this pet.',
      );
    }

    final reference = requests.doc();
    await reference.set({
      'listingId': listing.id,
      'petName': listing.petName,
      'ownerId': owner.uid,
      'ownerName': owner.name,
      'shelterId': listing.shelterId,
      'shelterAdminId': listing.adminId,
      'message': message.trim(),
      'status': RequestStatus.pending.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  });

  @override
  Future<void> updateAdoptionRequest({
    required AdoptionRequest request,
    required RequestStatus status,
  }) => _safe(() async {
    final requests = _db.collection('adoptionRequests');
    final requestReference = requests.doc(request.id);
    if (status != RequestStatus.approved) {
      await requestReference.update({
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final actorId = _auth.currentUser?.uid;
    if (actorId == null) {
      throw const CareFailure('Sign in again to update this request.');
    }
    final listingReference = _db
        .collection('adoptionListings')
        .doc(request.listingId);
    final listingSnapshot = await listingReference.get();
    final listingData = listingSnapshot.data();
    final photoPath = listingData?['photoPath'];
    final photoUrl = listingData?['photoUrl'];
    if (photoPath is! String ||
        photoPath.trim().isEmpty ||
        photoUrl is! String ||
        photoUrl.trim().isEmpty) {
      throw const CareFailure(
        'Add a pet photo to the listing before approving this adoption.',
      );
    }
    final relatedSnapshot = await requests
        .where('shelterAdminId', isEqualTo: actorId)
        .get();
    final batch = _db.batch();
    batch.update(requestReference, {
      'status': RequestStatus.approved.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    for (final document in relatedSnapshot.docs) {
      final data = document.data();
      if (document.id != request.id &&
          data['listingId'] == request.listingId &&
          RequestStatus.parse(data['status'] as String?) ==
              RequestStatus.pending) {
        batch.update(document.reference, {
          'status': RequestStatus.rejected.value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    batch.update(listingReference, {
      'status': AdoptionStatus.adopted.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  });

  @override
  Stream<List<SuccessStory>> watchSuccessStories({String? shelterId}) {
    Query<Map<String, dynamic>> query = _db.collection('successStories');
    if (shelterId != null) {
      query = query.where(
        'adminId',
        isEqualTo: _auth.currentUser?.uid ?? 'signed-out',
      );
    } else {
      query = query.where('published', isEqualTo: true);
    }
    return query.snapshots().map((snapshot) {
      final stories = snapshot.docs
          .map(_storyFromDoc)
          .where((story) => shelterId == null || story.shelterId == shelterId)
          .toList();
      stories.sort(
        (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(1970)).compareTo(
          a.updatedAt ?? a.createdAt ?? DateTime(1970),
        ),
      );
      return stories;
    });
  }

  @override
  Future<String> saveSuccessStory(SuccessStory story) => _safe(() async {
    final reference = story.id.isEmpty
        ? _db.collection('successStories').doc()
        : _db.collection('successStories').doc(story.id);
    await reference.set({
      'shelterId': story.shelterId,
      'adminId': story.adminId,
      'title': story.title.trim(),
      'story': story.story.trim(),
      'published': story.published,
      'photoPath': story.photoPath,
      'photoUrl': story.photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
      if (story.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return reference.id;
  });

  @override
  Future<void> deleteSuccessStory(SuccessStory story) =>
      _safe(() => _db.collection('successStories').doc(story.id).delete());

  @override
  Stream<List<CommunityRequest>> watchVolunteerRequests(AppUser user) =>
      _watchCommunity('volunteerRequests', user);

  @override
  Stream<List<CommunityRequest>> watchContactMessages(AppUser user) =>
      _watchCommunity('contactMessages', user);

  Stream<List<CommunityRequest>> _watchCommunity(
    String collection,
    AppUser user,
  ) {
    Query<Map<String, dynamic>> query = _db.collection(collection);
    query = user.role == UserRole.shelterAdmin
        ? query.where('shelterAdminId', isEqualTo: user.uid)
        : query.where('userId', isEqualTo: user.uid);
    return query.snapshots().map((snapshot) {
      final requests = snapshot.docs.map((doc) {
        final data = doc.data();
        return CommunityRequest(
          id: doc.id,
          shelterId: data['shelterId'] as String? ?? '',
          userId: data['userId'] as String? ?? '',
          userName: data['userName'] as String? ?? 'PawfectCare user',
          kind: data['kind'] as String? ?? collection,
          message: data['message'] as String? ?? '',
          status: data['status'] as String? ?? 'pending',
          createdAt: _date(data['createdAt']),
        );
      }).toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  @override
  Future<String> submitCommunityRequest({
    required AppUser user,
    required String shelterId,
    required String kind,
    required String message,
  }) => _safe(() async {
    final isVolunteer = kind == 'volunteer' || kind == 'donation';
    final collection = isVolunteer ? 'volunteerRequests' : 'contactMessages';
    final shelter = await _db.collection('shelters').doc(shelterId).get();
    final adminId = shelter.data()?['adminId'] as String?;
    if (adminId == null) throw const CareFailure('Shelter was not found.');
    final reference = _db.collection(collection).doc();
    await reference.set({
      'shelterId': shelterId,
      'shelterAdminId': adminId,
      'userId': user.uid,
      'userName': user.name,
      'kind': kind,
      'message': message.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  });

  @override
  Future<void> updateCommunityRequestStatus({
    required CommunityRequest request,
    required String status,
  }) => _safe(() {
    final collection = request.kind == 'volunteer' || request.kind == 'donation'
        ? 'volunteerRequests'
        : 'contactMessages';
    return _db.collection(collection).doc(request.id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });

  @override
  Stream<List<ProductItem>> watchProducts() => _db
      .collection('products')
      .where('active', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        final products = snapshot.docs.map((doc) {
          final data = doc.data();
          return ProductItem(
            id: doc.id,
            name: data['name'] as String? ?? '',
            description: data['description'] as String? ?? '',
            price: (data['price'] as num?)?.toDouble() ?? 0,
            category: data['category'] as String? ?? 'Other',
            purchaseUrl: data['purchaseUrl'] as String? ?? '',
            imageUrl: data['imageUrl'] as String?,
          );
        }).toList();
        products.sort((a, b) => a.name.compareTo(b.name));
        return products;
      });

  @override
  Stream<Set<String>> watchWishlist(String uid) => _db
      .collection('wishlists')
      .doc(uid)
      .collection('items')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());

  @override
  Future<void> setWishlist({
    required String uid,
    required String productId,
    required bool saved,
  }) => _safe(() {
    final reference = _db
        .collection('wishlists')
        .doc(uid)
        .collection('items')
        .doc(productId);
    return saved
        ? reference.set({
            'productId': productId,
            'createdAt': FieldValue.serverTimestamp(),
          })
        : reference.delete();
  });

  @override
  Stream<List<BlogArticle>> watchBlogs() => _db
      .collection('blogs')
      .where('published', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        final articles = snapshot.docs.map((doc) {
          final data = doc.data();
          final rawTags = data['tags'];
          final tags = rawTags is List
              ? rawTags.map((item) => item.toString()).toList()
              : const <String>[];
          return BlogArticle(
            id: doc.id,
            title: data['title'] as String? ?? '',
            category: data['category'] as String? ?? 'Pet Care',
            summary: data['summary'] as String? ?? '',
            content: data['content'] as String? ?? '',
            publishedAt: _date(data['publishedAt']),
            imageUrl: data['imageUrl'] as String?,
            authorId: data['authorId'] as String?,
            authorName: data['authorName'] as String?,
            tags: tags,
            published: data['published'] as bool? ?? true,
          );
        }).toList();
        articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        return articles;
      });

  @override
  Future<String> saveBlogArticle(BlogArticle article) => _safe(() async {
    final reference = article.id.isEmpty
        ? _db.collection('blogs').doc()
        : _db.collection('blogs').doc(article.id);
    await reference.set({
      'title': article.title,
      'category': article.category,
      'summary': article.summary,
      'content': article.content,
      'publishedAt': Timestamp.fromDate(article.publishedAt),
      'imageUrl': article.imageUrl,
      'authorId': article.authorId,
      'authorName': article.authorName,
      'tags': article.tags,
      'published': article.published,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return reference.id;
  });

  @override
  Future<void> deleteBlogArticle(String blogId) => _safe(() async {
    await _db.collection('blogs').doc(blogId).delete();
  });

  @override
  Stream<Set<String>> watchBookmarks(String uid) => _db
      .collection('bookmarks')
      .doc(uid)
      .collection('items')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());

  @override
  Future<void> setBookmark({
    required String uid,
    required String blogId,
    required bool saved,
  }) => _safe(() {
    final reference = _db
        .collection('bookmarks')
        .doc(uid)
        .collection('items')
        .doc(blogId);
    return saved
        ? reference.set({
            'blogId': blogId,
            'createdAt': FieldValue.serverTimestamp(),
          })
        : reference.delete();
  });

  @override
  Stream<List<UserNotification>> watchNotifications(String uid) => _db
      .collection('notifications')
      .doc(uid)
      .collection('items')
      .snapshots()
      .map((snapshot) {
        final notifications = snapshot.docs.map((doc) {
          final data = doc.data();
          return UserNotification(
            id: doc.id,
            title: data['title'] as String? ?? 'PawfectCare update',
            body: data['body'] as String? ?? '',
            type: data['type'] as String? ?? 'general',
            createdAt: _date(data['createdAt']),
            readAt: _nullableDate(data['readAt']),
            resourceId: data['resourceId'] as String?,
          );
        }).toList();
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return notifications;
      });

  @override
  Future<void> markNotificationRead({
    required String uid,
    required String notificationId,
  }) => _safe(
    () => _db
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .doc(notificationId)
        .update({'readAt': FieldValue.serverTimestamp()}),
  );

  @override
  Future<String> submitFeedback({
    required AppUser user,
    required String type,
    required String message,
  }) => _safe(() async {
    final reference = _db.collection('feedback').doc();
    await reference.set({
      'userId': user.uid,
      'type': type,
      'message': message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  });

  @override
  Future<void> updateProfile({
    required AppUser user,
    required String name,
    required String phone,
    String? photoPath,
    String? photoUrl,
  }) => _safe(() async {
    final batch = _db.batch();
    final userRef = _db.collection('users').doc(user.uid);
    batch.update(userRef, {
      'name': name.trim(),
      'phone': phone.trim(),
      'photoPath': photoPath,
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final publicRef = _db.collection('publicProfiles').doc(user.uid);
    batch.set(publicRef, {
      'uid': user.uid,
      'name': name.trim(),
      'role': user.role.value,
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
    await _auth.currentUser?.updateDisplayName(name.trim());
  });

  @override
  Stream<Map<String, bool>> watchNotificationPreferences(String uid) =>
      _db.collection('users').doc(uid).snapshots().map((snapshot) {
        final raw = snapshot.data()?['notificationPreferences'];
        if (raw is! Map<String, dynamic>) {
          return const {
            'appointments': true,
            'vaccinations': true,
            'adoption': true,
            'blogs': true,
          };
        }
        return raw.map((key, value) => MapEntry(key, value == true));
      });

  @override
  Future<void> updateNotificationPreferences({
    required String uid,
    required Map<String, bool> preferences,
  }) => _safe(
    () => _db.collection('users').doc(uid).update({
      'notificationPreferences': preferences,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  List<Pet> _sortPets(List<Pet> pets) {
    pets.sort((a, b) => a.name.compareTo(b.name));
    return pets;
  }

  Pet _petFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Pet(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      name: data['name'] as String? ?? 'Pet',
      species: data['species'] as String? ?? '',
      breed: data['breed'] as String? ?? '',
      age: (data['age'] as num?)?.toInt() ?? 0,
      gender: data['gender'] as String? ?? '',
      photoPath: data['photoPath'] as String?,
      photoUrl: data['photoUrl'] as String?,
      description: data['description'] as String? ?? '',
    );
  }

  HealthRecord _healthFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return HealthRecord(
      id: doc.id,
      petId: data['petId'] as String? ?? '',
      veterinarianId: data['veterinarianId'] as String?,
      type: HealthRecordType.parse(data['type'] as String?),
      title: data['title'] as String? ?? 'Health record',
      diagnosis: data['diagnosis'] as String? ?? '',
      treatment: data['treatment'] as String? ?? '',
      prescription: data['prescription'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      date: _date(data['date']),
      dueDate: _nullableDate(data['dueDate']),
      followUpDate: _nullableDate(data['followUpDate']),
      reportPaths: List<String>.from(
        data['reportPaths'] as List<dynamic>? ?? const [],
      ),
    );
  }

  AvailabilitySlot _slotFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AvailabilitySlot(
      id: doc.id,
      veterinarianId: data['veterinarianId'] as String? ?? '',
      start: _date(data['start']),
      end: _date(data['end']),
      isBooked: data['isBooked'] as bool? ?? false,
      bookingOwnerId: data['bookingOwnerId'] as String?,
    );
  }

  CareAppointment _appointmentFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return CareAppointment(
      id: doc.id,
      slotId: data['slotId'] as String? ?? doc.id,
      petId: data['petId'] as String? ?? '',
      petName: data['petName'] as String? ?? 'Pet',
      ownerId: data['ownerId'] as String? ?? '',
      veterinarianId: data['veterinarianId'] as String? ?? '',
      veterinarianName: data['veterinarianName'] as String? ?? 'Veterinarian',
      dateTime: _date(data['dateTime']),
      reason: data['reason'] as String? ?? '',
      status: AppointmentStatus.parse(data['status'] as String?),
    );
  }

  ShelterProfile _shelterFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ShelterProfile(
      id: doc.id,
      adminId: data['adminId'] as String? ?? '',
      name: data['name'] as String? ?? 'Shelter',
      location: data['location'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      description: data['description'] as String? ?? '',
    );
  }

  AdoptionListing _listingFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AdoptionListing(
      id: doc.id,
      shelterId: data['shelterId'] as String? ?? '',
      adminId: data['adminId'] as String? ?? '',
      petName: data['petName'] as String? ?? 'Pet',
      species: data['species'] as String? ?? '',
      age: (data['age'] as num?)?.toInt() ?? 0,
      gender: data['gender'] as String? ?? '',
      healthStatus: data['healthStatus'] as String? ?? '',
      status: AdoptionStatus.parse(data['status'] as String?),
      description: data['description'] as String? ?? '',
      photoPath: data['photoPath'] as String?,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  AdoptionRequest _requestFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AdoptionRequest(
      id: doc.id,
      listingId: data['listingId'] as String? ?? '',
      petName: data['petName'] as String? ?? 'Pet',
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? 'Applicant',
      shelterId: data['shelterId'] as String? ?? '',
      shelterAdminId: data['shelterAdminId'] as String? ?? '',
      status: RequestStatus.parse(data['status'] as String?),
      message: data['message'] as String? ?? '',
      createdAt: _date(data['createdAt']),
    );
  }

  SuccessStory _storyFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return SuccessStory(
      id: doc.id,
      shelterId: data['shelterId'] as String? ?? '',
      adminId: data['adminId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      story: data['story'] as String? ?? '',
      published: data['published'] as bool? ?? false,
      photoPath: data['photoPath'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: _nullableDate(data['createdAt']),
      updatedAt: _nullableDate(data['updatedAt']),
    );
  }

  DateTime _date(Object? value) => switch (value) {
    Timestamp timestamp => timestamp.toDate(),
    DateTime date => date,
    _ => DateTime.fromMillisecondsSinceEpoch(0),
  };

  DateTime? _nullableDate(Object? value) => switch (value) {
    Timestamp timestamp => timestamp.toDate(),
    DateTime date => date,
    _ => null,
  };

  Timestamp? _timestamp(DateTime? value) =>
      value == null ? null : Timestamp.fromDate(value);

  Future<T> _safe<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on CareFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw CareFailure(_safeMessage(error));
    }
  }

  String _safeMessage(FirebaseException error) => switch (error.code) {
    'permission-denied' =>
      'Your account is not allowed to perform that action.',
    'unavailable' => 'The service is temporarily unavailable.',
    'not-found' => 'The requested information no longer exists.',
    'already-exists' => 'That record already exists.',
    _ => 'The request could not be completed securely.',
  };

  Future<void> _sendNotification({
    required String recipientId,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      final docRef = _db
          .collection('notifications')
          .doc(recipientId)
          .collection('items')
          .doc();
      await docRef.set({
        'title': title,
        'body': body,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'readAt': null,
      });
    } on Object {
      // Background notifications failure should not break primary operation
    }
  }
}
