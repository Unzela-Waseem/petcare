const fs = require('node:fs');
const path = require('node:path');
const { after, before, beforeEach, describe, it } = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const projectId = 'pawfectcare-rules-test';
let testEnv;

function authenticated(uid) {
  return testEnv.authenticatedContext(uid, {
    email: `${uid}@test.pawfectcare.app`,
    email_verified: true,
  }).firestore();
}

function appointmentData({
  slotId,
  ownerId = 'owner-a',
  rescheduledFrom,
} = {}) {
  const value = {
    slotId,
    petId: 'luna',
    petName: 'Luna',
    ownerId,
    ownerName: 'owner-a',
    veterinarianId: 'vet-a',
    veterinarianName: 'vet-a',
    dateTime: new Date('2030-01-10T10:00:00.000Z'),
    reason: 'Annual checkup',
    status: 'pending',
    createdAt: new Date(),
    updatedAt: new Date(),
  };
  if (rescheduledFrom) value.rescheduledFrom = rescheduledFrom;
  return value;
}

async function seedData() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const users = {
      'owner-a': 'petOwner',
      'owner-b': 'petOwner',
      'vet-a': 'veterinarian',
      'vet-b': 'veterinarian',
      'shelter-a': 'shelterAdmin',
      'shelter-b': 'shelterAdmin',
    };
    for (const [uid, role] of Object.entries(users)) {
      await db.doc(`users/${uid}`).set({
        uid,
        name: uid,
        email: `${uid}@test.pawfectcare.app`,
        phone: '+1 555 0100',
        role,
        accountStatus: 'active',
        photoUrl: null,
      });
      await db.doc(`publicProfiles/${uid}`).set({
        uid,
        name: uid,
        role,
        photoUrl: null,
        clinicName: role === 'veterinarian' ? `${uid} Clinic` : '',
        specialty: role === 'veterinarian' ? 'General Care' : '',
        location: 'Lahore',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    }
    await db.doc('pets/luna').set({
      ownerId: 'owner-a',
      name: 'Luna',
      species: 'dog',
      breed: 'Husky',
      age: 3,
      gender: 'female',
    });
    await db.doc('petAccess/luna/veterinarians/vet-a').set({
      petId: 'luna',
      veterinarianId: 'vet-a',
      appointmentId: 'appointment-1',
      active: true,
    });
    await db.doc('petHealthRecords/record-1').set({
      petId: 'luna',
      veterinarianId: 'vet-a',
      diagnosis: 'Healthy',
      treatment: 'Routine care',
      prescription: '',
      date: new Date(),
    });
    await db.doc('shelters/shelter-one').set({
      adminId: 'shelter-a',
      name: 'Happy Tails',
      location: 'Central',
    });
    await db.doc('shelters/shelter-two').set({
      adminId: 'shelter-b',
      name: 'Second Chance',
      location: 'North',
    });
    await db.doc('adoptionListings/coco').set({
      shelterId: 'shelter-one',
      adminId: 'shelter-a',
      name: 'Coco',
      status: 'available',
    });
    await db.doc('vetAvailability/slot-open').set({
      veterinarianId: 'vet-a',
      start: new Date('2030-01-10T10:00:00.000Z'),
      end: new Date('2030-01-10T10:30:00.000Z'),
      isBooked: false,
      bookingOwnerId: null,
      appointmentId: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    await db.doc('vetAvailability/slot-reschedule').set({
      veterinarianId: 'vet-a',
      start: new Date('2030-01-11T10:00:00.000Z'),
      end: new Date('2030-01-11T10:30:00.000Z'),
      isBooked: false,
      bookingOwnerId: null,
      appointmentId: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    await db.doc('vetAvailability/slot-old').set({
      veterinarianId: 'vet-a',
      start: new Date('2030-01-09T10:00:00.000Z'),
      end: new Date('2030-01-09T10:30:00.000Z'),
      isBooked: true,
      bookingOwnerId: 'owner-a',
      appointmentId: 'appointment-old',
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    await db.doc('appointments/appointment-old').set({
      ...appointmentData({ slotId: 'slot-old' }),
      dateTime: new Date('2030-01-09T10:00:00.000Z'),
      status: 'confirmed',
    });
    await db.doc('products/food-one').set({
      name: 'Healthy Food',
      category: 'Food',
      active: true,
    });
    await db.doc('notifications/owner-a/items/notice-one').set({
      title: 'Reminder',
      body: 'Your visit is tomorrow.',
      type: 'appointment',
      readAt: null,
      createdAt: new Date(),
    });
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, '..', 'firebase', 'firestore.rules'),
        'utf8',
      ),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await seedData();
});

after(async () => {
  await testEnv.cleanup();
});

describe('PawfectCare Firestore authorization', () => {
  it('creates a pending user and matching public role atomically', async () => {
    const db = testEnv.authenticatedContext('new-owner', {
      email: 'new-owner@test.pawfectcare.app',
      email_verified: false,
    }).firestore();
    const batch = db.batch();
    batch.set(db.doc('users/new-owner'), {
      uid: 'new-owner',
      name: 'New Owner',
      email: 'new-owner@test.pawfectcare.app',
      phone: '+1 555 0111',
      role: 'petOwner',
      accountStatus: 'pendingEmailVerification',
      photoUrl: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    batch.set(db.doc('publicProfiles/new-owner'), {
      uid: 'new-owner',
      name: 'New Owner',
      role: 'petOwner',
      photoUrl: null,
      clinicName: '',
      specialty: '',
      location: '',
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    await assertSucceeds(batch.commit());
  });

  it('denies signed-out access to private pet data', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(db.doc('pets/luna').get());
  });

  it('allows only the owning pet owner to read a pet', async () => {
    await assertSucceeds(authenticated('owner-a').doc('pets/luna').get());
    await assertFails(authenticated('owner-b').doc('pets/luna').get());
  });

  it('limits a veterinarian to explicitly assigned pets', async () => {
    await assertSucceeds(
      authenticated('vet-a').doc('petHealthRecords/record-1').get(),
    );
    await assertFails(
      authenticated('vet-b').doc('petHealthRecords/record-1').get(),
    );
  });

  it('denies shelter admins access to medical records', async () => {
    await assertFails(
      authenticated('shelter-a').doc('petHealthRecords/record-1').get(),
    );
  });

  it('prevents a user from escalating their role', async () => {
    await assertFails(
      authenticated('owner-a').doc('users/owner-a').update({
        role: 'shelterAdmin',
      }),
    );
  });

  it('limits shelter listing changes to the owning shelter admin', async () => {
    await assertSucceeds(
      authenticated('shelter-a').doc('adoptionListings/coco').update({
        status: 'pending',
      }),
    );
    await assertFails(
      authenticated('shelter-b').doc('adoptionListings/coco').update({
        status: 'adopted',
      }),
    );
  });

  it('lets owners add routine health records but blocks clinical fields', async () => {
    const base = {
      petId: 'luna',
      createdBy: 'owner-a',
      veterinarianId: null,
      type: 'vaccination',
      title: 'Rabies vaccine',
      diagnosis: '',
      treatment: '',
      prescription: '',
      notes: 'Completed',
      date: new Date(),
      dueDate: new Date('2030-01-01T00:00:00.000Z'),
      followUpDate: null,
      reportPaths: [],
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    await assertSucceeds(
      authenticated('owner-a').doc('petHealthRecords/owner-routine').set(base),
    );
    await assertFails(
      authenticated('owner-a').doc('petHealthRecords/owner-clinical').set({
        ...base,
        diagnosis: 'Owner supplied diagnosis',
      }),
    );
  });

  it('allows clinical records only from an assigned veterinarian', async () => {
    const record = {
      petId: 'luna',
      createdBy: 'vet-a',
      veterinarianId: 'vet-a',
      type: 'medical',
      title: 'Clinical exam',
      diagnosis: 'Healthy',
      treatment: 'Observation',
      prescription: '',
      notes: '',
      date: new Date(),
      dueDate: null,
      followUpDate: null,
      reportPaths: [],
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    await assertSucceeds(
      authenticated('vet-a').doc('petHealthRecords/vet-record').set(record),
    );
    await assertFails(
      authenticated('vet-b').doc('petHealthRecords/rogue-record').set({
        ...record,
        createdBy: 'vet-b',
        veterinarianId: 'vet-b',
      }),
    );
  });

  it('prevents public profile role tampering', async () => {
    await assertFails(
      authenticated('owner-a').doc('publicProfiles/owner-a').update({
        role: 'veterinarian',
      }),
    );
  });

  it('books a slot only through one atomic owner batch', async () => {
    const db = authenticated('owner-a');
    const batch = db.batch();
    batch.update(db.doc('vetAvailability/slot-open'), {
      isBooked: true,
      bookingOwnerId: 'owner-a',
      appointmentId: 'slot-open',
      updatedAt: new Date(),
    });
    batch.set(
      db.doc('appointments/slot-open'),
      appointmentData({ slotId: 'slot-open' }),
    );
    batch.update(db.doc('petAccess/luna/veterinarians/vet-a'), {
      appointmentId: 'slot-open',
      active: true,
      updatedAt: new Date(),
    });
    await assertSucceeds(batch.commit());

    const dbB = authenticated('owner-b');
    const second = dbB.batch();
    second.update(dbB.doc('vetAvailability/slot-open'), {
      isBooked: true,
      bookingOwnerId: 'owner-b',
      appointmentId: 'slot-open',
      updatedAt: new Date(),
    });
    await assertFails(second.commit());
  });

  it('blocks direct appointment and arbitrary veterinarian grant writes', async () => {
    await assertFails(
      authenticated('owner-a')
        .doc('appointments/direct')
        .set(appointmentData({ slotId: 'direct' })),
    );
    await assertFails(
      authenticated('owner-a').doc('petAccess/luna/veterinarians/vet-b').set({
        petId: 'luna',
        veterinarianId: 'vet-b',
        appointmentId: 'made-up',
        active: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  it('allows a veterinarian to atomically reschedule only their appointment', async () => {
    const db = authenticated('vet-a');
    const batch = db.batch();
    batch.update(db.doc('appointments/appointment-old'), {
      status: 'cancelled',
      updatedAt: new Date(),
    });
    batch.update(db.doc('vetAvailability/slot-old'), {
      isBooked: false,
      bookingOwnerId: null,
      appointmentId: null,
      updatedAt: new Date(),
    });
    batch.update(db.doc('vetAvailability/slot-reschedule'), {
      isBooked: true,
      bookingOwnerId: 'owner-a',
      appointmentId: 'slot-reschedule',
      updatedAt: new Date(),
    });
    batch.set(
      db.doc('appointments/slot-reschedule'),
      {
        ...appointmentData({
          slotId: 'slot-reschedule',
          rescheduledFrom: 'appointment-old',
        }),
        dateTime: new Date('2030-01-11T10:00:00.000Z'),
      },
    );
    await assertSucceeds(batch.commit());
  });

  it('lets the owner cancel and atomically release the booked slot', async () => {
    const db = authenticated('owner-a');
    const batch = db.batch();
    batch.update(db.doc('appointments/appointment-old'), {
      status: 'cancelled',
      updatedAt: new Date(),
    });
    batch.update(db.doc('vetAvailability/slot-old'), {
      isBooked: false,
      bookingOwnerId: null,
      appointmentId: null,
      updatedAt: new Date(),
    });
    await assertSucceeds(batch.commit());
  });

  it('keeps catalog writes and notification creation server-only', async () => {
    await assertSucceeds(
      authenticated('owner-a').doc('products/food-one').get(),
    );
    await assertFails(
      authenticated('owner-a').doc('products/food-one').update({
        name: 'Compromised',
      }),
    );
    await assertSucceeds(
      authenticated('owner-a')
        .doc('notifications/owner-a/items/notice-one')
        .get(),
    );
    await assertFails(
      authenticated('owner-a')
        .doc('notifications/owner-a/items/fake')
        .set({ title: 'Fake' }),
    );
    await assertFails(
      authenticated('owner-b')
        .doc('notifications/owner-a/items/notice-one')
        .get(),
    );
  });
});
