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
- Pet profile/detail and health-reminder experience
- Appointment, clinical history, availability, store, care-tip, adoption, shelter, volunteer, contact, notification, saved-item, messaging, and profile surfaces
- Firebase Authentication and private profile adapter
- Firebase Cloud Messaging permission, token rotation, per-device storage, and logout cleanup
- Strict Firestore and Storage rules with deny-by-default behavior
- Firestore composite indexes
- Flutter unit/widget tests and Firestore Emulator authorization tests
- A deterministic demo mode that never touches production data

The complete architecture, schema, role matrix, screen inventory, per-feature security contract, and release gates live in [`docs/architecture.md`](docs/architecture.md).

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
- Cloud Messaging, Firebase Installations, and Cloud Storage APIs are enabled.
- The generated Firebase client configuration is checked in. These client identifiers are not server credentials; authorization remains enforced by Firebase Authentication and the checked-in rules.

Cloud Storage for Firebase requires the Blaze plan for projects created under the current Firebase policy. After linking a billing account, provision the default bucket in the Firebase Console and deploy the checked-in Storage rules:

```bash
firebase deploy --only storage
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

Production catalog publishing, role/account administration, veterinarian access grants, double-booking prevention, and notification fan-out are intentionally server-only operations. Implement those with trusted Cloud Functions or another Admin SDK service; never grant a fourth client role broad write access.

## Verification

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
npm install
PATH=/path/to/jdk/bin:$PATH npm run test:rules
```

The rules suite verifies signed-out denial, pet ownership isolation, veterinarian assignment boundaries, shelter denial from medical data, prevention of role escalation, and shelter ownership boundaries.

## Security notes

- Passwords are handled only by Firebase Authentication.
- Secure storage contains onboarding/session hints, never passwords or permission grants.
- Unknown roles and inactive profiles fail closed.
- The client never decides authorization; Firestore and Storage rules verify identity, role, ownership, and explicit access grants.
- Medical uploads accept only PDF or supported image MIME types up to 10 MB and are never public.
- User roles, account status, ownership fields, and appointment parties are immutable to ordinary client edits.
- Product/blog publishing, notification creation, and veterinarian access grants are trusted-backend-only.
