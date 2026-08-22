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
});
