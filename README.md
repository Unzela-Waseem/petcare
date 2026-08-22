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
- Strict Firestore and Storage rules with deny-by-default behavior
- Trusted Cloud Functions for appointment, vaccine, adoption, and blog notifications
- Firestore composite indexes and seeded production store/care-tip content
- Flutter unit/widget tests and 19 Firestore/Storage Emulator authorization tests
- A deterministic demo mode that never touches production data

The complete architecture and security contract live in [`docs/architecture.md`](docs/architecture.md). The specification-by-specification completion evidence and remaining account-owner release actions are in [`docs/requirements-matrix.md`](docs/requirements-matrix.md).

## Run the design demo

Demo mode is the default and requires no Firebase project:

```bash
flutter pub get
flutter run
```

On the login screen, use the Pet Owner, Veterinarian, or Shelter Admin demo button to inspect that role. The sample email/password fields also open the Pet Owner dashboard.

## Connected production Firebase

The repository is connected to Firebase project `pawfectcare-unzela-2026`:

- Android, iOS, and Web apps are registered through FlutterFire.
- Email/Password Authentication is enabled and requires a password.
- The default Standard Firestore database is in `asia-south1` (Mumbai) with deletion protection enabled.
- Firestore rules and composite indexes are deployed.
- Four store products and four published care guides are live in Firestore.
- Cloud Messaging, Firebase Installations, and Cloud Storage APIs are enabled.
- The generated Firebase client configuration is checked in. These client identifiers are not server credentials; authorization remains enforced by Firebase Authentication and the checked-in rules.

Cloud Storage and Cloud Functions require the Blaze plan for projects created under the current Firebase policy. The complete Storage rules and notification Functions are checked in and pass local emulator/lint/security verification, but Firebase rejected their live deployment while this project remains on Spark. After linking a billing account, provision the default Storage bucket and deploy both:

```bash
firebase deploy --only storage,functions
```

Configure APNs separately before testing push notifications on iOS. For Web Push, pass the Firebase Web Push certificate's public VAPID key as a build-time value.

Run the app against Firebase:

```bash
flutter run --dart-define=USE_FIREBASE=true
```

For Web Push:

```bash
flutter run -d chrome \
  --dart-define=USE_FIREBASE=true \
  --dart-define=FCM_WEB_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
```

Demo builds continue to work without Firebase configuration.

Catalog/blog publishing, role/account administration, and notification fan-out remain trusted-backend-only. Appointment booking and veterinarian grants are committed atomically and verified with `getAfter()` rules, so a client cannot grant access without a valid appointment or book one slot twice.

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
