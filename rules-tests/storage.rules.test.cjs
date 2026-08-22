const fs = require('node:fs');
const path = require('node:path');
const {after, before, describe, it} = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

// Cross-service Storage rules are evaluated in the Firebase CLI project
// namespace, so the emulator test must use that same local namespace.
const projectId = 'pawfectcare-unzela-2026';
let testEnv;

function authenticated(uid) {
  return testEnv.authenticatedContext(uid, {
    email: `${uid}@test.pawfectcare.app`,
    email_verified: true,
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
    storage: {
      rules: fs.readFileSync(
        path.join(__dirname, '..', 'firebase', 'storage.rules'),
        'utf8',
      ),
    },
  });
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
        role,
        accountStatus: 'active',
      });
    }
    await db.doc('pets/luna').set({ownerId: 'owner-a'});
    await db.doc('petAccess/luna/veterinarians/vet-a').set({
      petId: 'luna',
      veterinarianId: 'vet-a',
      active: true,
    });
    await db.doc('petAccess/luna/veterinarians/vet-b').set({
      petId: 'luna',
      veterinarianId: 'vet-b',
      active: false,
    });
    await db.doc('shelters/happy-tails').set({adminId: 'shelter-a'});
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('PawfectCare Storage authorization', () => {
  it('allows only the pet owner to upload a valid pet image', async () => {
    const owner = authenticated('owner-a').storage();
    await assertSucceeds(
      owner.ref('pets/luna/images/photo.png').putString('image', 'raw', {
        contentType: 'image/png',
      }),
    );
    await assertFails(
      authenticated('owner-b')
        .storage()
        .ref('pets/luna/images/other.png')
        .putString('image', 'raw', {contentType: 'image/png'}),
    );
  });

  it('rejects unsupported image content types', async () => {
    await assertFails(
      authenticated('owner-a')
        .storage()
        .ref('pets/luna/images/payload.svg')
        .putString('<svg/>', 'raw', {contentType: 'image/svg+xml'}),
    );
  });

  it('restricts medical files to assigned vets and the pet owner', async () => {
    const assigned = authenticated('vet-a').storage();
    const report = assigned.ref('medical/luna/record-one/report.pdf');
    await assertSucceeds(
      report.putString('protected report', 'raw', {
        contentType: 'application/pdf',
      }),
    );
    await assertSucceeds(
      authenticated('owner-a')
        .storage()
        .ref('medical/luna/record-one/report.pdf')
        .getDownloadURL(),
    );
    await assertFails(
      authenticated('vet-b')
        .storage()
        .ref('medical/luna/record-two/report.pdf')
        .putString('unauthorized', 'raw', {contentType: 'application/pdf'}),
    );
    await assertFails(
      authenticated('owner-b')
        .storage()
        .ref('medical/luna/record-one/report.pdf')
        .getDownloadURL(),
    );
  });

  it('isolates shelter image management by shelter ownership', async () => {
    await assertSucceeds(
      authenticated('shelter-a')
        .storage()
        .ref('shelters/happy-tails/images/story.webp')
        .putString('image', 'raw', {contentType: 'image/webp'}),
    );
    await assertFails(
      authenticated('shelter-b')
        .storage()
        .ref('shelters/happy-tails/images/other.webp')
        .putString('image', 'raw', {contentType: 'image/webp'}),
    );
  });
});
