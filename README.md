# PawfectCare

PawfectCare is a secure Flutter pet-care platform for exactly three roles:

- Pet Owner
- Veterinarian
- Shelter Admin

The UI follows a warm editorial pet-care system: cream canvases, peach feature photography, orange actions, black paw controls, rounded white surfaces, and soft pastel information cards. The original cat-and-dog cutout in `assets/images/pawfect_pet_family_cutout.png` was generated specifically for this project.

## What is implemented

- Responsive onboarding modeled on the supplied visual reference
- Secure login, registration, password reset, email-verification gate, session restoration, and logout stack reset
- Registration restricted to the three specified roles
- Role-specific dashboards, navigation, tools, copy, and privacy messaging
- Firebase-backed pet CRUD, protected health timelines, due dates, and clinical documents
- Veterinarian directory search, atomic booking/cancellation/rescheduling, availability management, and appointment history
- Product search/filter/wishlist/external HTTPS links, plus care-tip search/filter/bookmark/offline reading
- Adoption listings/requests, shelter profiles, success stories, volunteer/donation requests, and shelter inquiries
- Profile editing/photo, recent-login password changes, notification preferences, feedback, and Google Maps links
- Firebase Authentication and private profile adapter
- Firebase Cloud Messaging permission, token rotation, per-device storage, and logout cleanup
- No-card fallback: ordinary images sync through a restricted Cloudinary unsigned preset, private medical reports remain on-device, and appointment/vaccine/follow-up reminders use local notifications
- Strict Firestore and Storage rules with deny-by-default behavior
- Trusted Cloud Functions for appointment, vaccine, adoption, and blog notifications
- Firestore composite indexes and seeded production store/care-tip content
- Flutter unit/widget tests and 20 Firestore/Storage Emulator authorization tests
- A deterministic demo mode that never touches production data

The complete architecture and security contract live in [`docs/architecture.md`](docs/architecture.md). The specification-by-specification completion evidence and remaining account-owner release actions are in [`docs/requirements-matrix.md`](docs/requirements-matrix.md).

## Run the app

The checked-in app defaults to the connected Firebase project and the restricted
Cloudinary image preset, so a normal run matches the testing APK and the live
website:

```bash
flutter pub get
flutter run
```

To intentionally open the isolated design/demo data instead, run:

```bash
flutter run --dart-define=USE_FIREBASE=false
```

In demo mode, use the Pet Owner, Veterinarian, or Shelter Admin demo button on
the login screen to inspect that role.

### Fresh setup on Windows

Open PowerShell in the extracted/cloned folder that contains `pubspec.yaml`,
then run:

```powershell
flutter clean
flutter pub get
flutter run -d chrome
```

When cloning from GitHub, make sure to use the current application branch:

```powershell
git clone --branch feat/pawfectcare-foundation --single-branch https://github.com/Unzela-Waseem/petcare.git PawfectCare
cd PawfectCare
flutter clean
flutter pub get
flutter run -d chrome
```

## Connected production Firebase

The repository is connected to Firebase project `pawfectcare-unzela-2026`:

- Android, iOS, and Web apps are registered through FlutterFire.
- Email/Password Authentication is enabled and requires a password.
- The default Standard Firestore database is in `asia-south1` (Mumbai) with deletion protection enabled.
- Firestore rules and composite indexes are deployed.
- Twenty store products and sixteen published care guides are live in Firestore, evenly covering every required category.
- The restricted `pawfactcare_unsigned` Cloudinary preset is configured and has passed an end-to-end web profile-image upload.
- Cloud Messaging, Firebase Installations, and Cloud Storage APIs are enabled.
- The generated Firebase client configuration is checked in. These client identifiers are not server credentials; authorization remains enforced by Firebase Authentication and the checked-in rules.

Cloud Storage and Cloud Functions require the Blaze plan for this project. The complete Storage rules and notification Functions are checked in and pass local emulator/lint/security verification, but Firebase rejected their live deployment while this project remains on Spark.

The Firebase-connected app supports a no-card hybrid fallback. Pet, profile, adoption-listing, and success-story images can sync through Cloudinary, while confidential medical reports remain in private application storage on Android/iOS. Appointment, vaccination, deworming, and clinical follow-up reminders are scheduled on-device. Firestore records continue to sync, but medical files do not sync to another device and server-originated adoption/blog notifications still require Functions.

The values below are now safe public defaults in the Flutter client. They can
still be overridden explicitly for another Firebase/Cloudinary environment:

```bash
flutter run -d chrome \
  --dart-define=USE_FIREBASE=true \
  --dart-define=CLOUDINARY_CLOUD_NAME=dc1w5stzg \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=pawfactcare_unsigned
```

The preset must allow only JPG/JPEG/PNG/WebP images up to 5 MB, disallow caller-provided public IDs, generate unique IDs, and disable overwrite. An unsigned client cannot securely delete an older remote asset after its short-lived deletion window; deleting or replacing an image removes the Firestore reference immediately, while periodic asset cleanup is performed from Cloudinary Media Library until a trusted signed backend is available. API secrets must never be added to this repository or any Flutter build.

After linking a billing account, provision the default Storage bucket and deploy both:

```bash
firebase deploy --only storage,functions
```

Then opt into the paid cloud paths explicitly:

```bash
flutter run \
  --dart-define=USE_FIREBASE=true \
  --dart-define=USE_FIREBASE_STORAGE=true \
  --dart-define=USE_FIREBASE_PUSH=true
```

Configure APNs separately before testing push notifications on iOS. For Web Push, pass the Firebase Web Push certificate's public VAPID key as a build-time value.

Run the app against Firebase with device-only media:

```bash
flutter run --dart-define=USE_FIREBASE=true
```

That command uses Firebase Auth/Firestore with the free on-device media and reminder fallback; no billing account is required.

For Web Push:

```bash
flutter run -d chrome \
  --dart-define=USE_FIREBASE=true \
  --dart-define=FCM_WEB_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
```

Demo builds remain available with `--dart-define=USE_FIREBASE=false`.

Catalog/blog publishing, role/account administration, and notification fan-out remain trusted-backend-only. Appointment booking and veterinarian grants are committed atomically and verified with `getAfter()` rules, so a client cannot grant access without a valid appointment or book one slot twice.

Appointment documents use unique immutable IDs rather than slot IDs. Cancelling releases the slot without overwriting its history, so the same open time can be booked again as a new pending appointment.

## Verification

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
npm install
PATH=/path/to/jdk/bin:$PATH npm run test:rules
npm --prefix functions install
npm --prefix functions run check
npm --prefix functions run lint
```

The rules suites verify registration consistency, signed-out denial, pet ownership isolation, routine-versus-clinical health fields, veterinarian assignment boundaries, atomic booking/rescheduling/cancellation, role escalation denial, catalog/notification server ownership, MIME/size restrictions, private medical files, and shelter isolation.

## Security notes

- Passwords are handled only by Firebase Authentication.
- Secure storage contains onboarding/session hints, never passwords or permission grants.
- Unknown roles and inactive profiles fail closed.
- The client never decides authorization; Firestore and Storage rules verify identity, role, ownership, and explicit access grants.
- Medical uploads accept only PDF or supported image MIME types up to 10 MB and are never public.
- User roles, account status, ownership fields, and appointment parties are immutable to ordinary client edits.
- Product/blog publishing, notification creation, and veterinarian access grants are trusted-backend-only.
