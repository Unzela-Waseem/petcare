# PawfectCare Submission Guide

This file contains the public project identifiers and the exact steps needed to
run and evaluate PawfectCare. It deliberately does **not** contain personal
passwords, private keys, access tokens, service-account JSON, signing keys, or
Cloudinary API secrets.

## Project links

| Item | Value |
| --- | --- |
| Project name | PawfectCare |
| Flutter package | `pawfect_care` |
| Version | `1.0.0+1` |
| GitHub repository | <https://github.com/Unzela-Waseem/petcare.git> |
| Submission branch | `feat/pawfectcare-foundation` |
| Live web application | <https://pawfectcare-unzela-2026.web.app/> |
| Firebase Console | <https://console.firebase.google.com/project/pawfectcare-unzela-2026/overview> |

## Public Firebase configuration

These values identify the Firebase client apps; they are not administrator
credentials and do not bypass Firebase Authentication or security rules.

| Item | Value |
| --- | --- |
| Firebase project ID | `pawfectcare-unzela-2026` |
| Google/Firebase project number | `292981245129` |
| Authentication domain | `pawfectcare-unzela-2026.firebaseapp.com` |
| Storage bucket name | `pawfectcare-unzela-2026.firebasestorage.app` |
| Firestore location | `asia-south1` (Mumbai) |
| Android application ID | `com.pawfectcare.app.pawfect_care` |
| Android Firebase app ID | `1:292981245129:android:33e70096950e9ce627f918` |
| iOS bundle ID | `com.pawfectcare.app.pawfectCare` |
| iOS Firebase app ID | `1:292981245129:ios:c4866871522ccbd927f918` |
| Web Firebase app ID | `1:292981245129:web:5ccef1aafe8f53d927f918` |
| Enabled sign-in provider | Email/Password |

The complete generated client configuration is already included in
`lib/firebase_options.dart` and `android/app/google-services.json`. No manual
Firebase credential is needed for a normal clone and run.

## Public Cloudinary configuration

Cloudinary provides the Spark-plan-compatible image-upload fallback.

| Item | Value |
| --- | --- |
| Cloud name | `dc1w5stzg` |
| Unsigned upload preset | `pawfactcare_unsigned` |
| Accepted files | JPG, JPEG, PNG, and WebP images up to 5 MB |

The Cloudinary API secret is not required by the Flutter client and must never
be committed. The unsigned preset is restricted to generated unique public IDs
with overwrite disabled.

## Evaluator access for all three roles

### Recommended: deterministic demo mode

Demo mode requires no email or password, never changes production data, and
provides separate entry buttons for all required roles:

1. Pet Owner
2. Veterinarian
3. Shelter Admin

Run it with:

```bash
flutter pub get
flutter run -d chrome --dart-define=USE_FIREBASE=false
```

On the login screen, select the required role's demo button. This is the safest
way to submit repeatable evaluator access without publishing real passwords.

### Live Firebase mode

The checked-in default uses the connected Firebase project:

```bash
flutter pub get
flutter run -d chrome
```

Use **Register** to create a live account, choose exactly one role, and verify
the email before entering protected screens. Firebase Authentication does not
allow the same exact email address to represent three separate accounts. A
single Gmail inbox can receive mail for three aliases such as:

- `youraddress+owner@gmail.com`
- `youraddress+vet@gmail.com`
- `youraddress+shelter@gmail.com`

Choose separate strong test passwords and share them with the evaluator through
a private submission field, not through this public repository. Do not reuse a
personal email password.

## Clone and run

### Windows PowerShell

```powershell
git clone --branch feat/pawfectcare-foundation --single-branch https://github.com/Unzela-Waseem/petcare.git PawfectCare
cd PawfectCare
flutter clean
flutter pub get
flutter run -d chrome
```

### Linux/Kubuntu

```bash
git clone --branch feat/pawfectcare-foundation --single-branch https://github.com/Unzela-Waseem/petcare.git PawfectCare
cd PawfectCare
flutter clean
flutter pub get
flutter run -d chrome
```

## Optional build-time values

The repository already contains safe public defaults. The equivalent explicit
command is:

```bash
flutter run -d chrome \
  --dart-define=USE_FIREBASE=true \
  --dart-define=CLOUDINARY_CLOUD_NAME=dc1w5stzg \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=pawfactcare_unsigned \
  --dart-define=PUBLIC_WEB_BASE_URL=https://pawfectcare-unzela-2026.web.app/
```

The following values are disabled by default because they require additional
production infrastructure:

| Build value | Default | Purpose |
| --- | --- | --- |
| `USE_FIREBASE_STORAGE` | `false` | Use private Firebase Storage instead of the hybrid media fallback |
| `USE_FIREBASE_PUSH` | `false` | Enable trusted-backend FCM token registration and remote push |
| `FCM_WEB_VAPID_KEY` | empty | Public Web Push certificate key |
| `PUBLIC_WEB_BASE_URL` | PawfectCare Firebase Hosting URL | Stable public base URL encoded into printable pet QR tags |

## Current Firebase status

- Firebase Authentication, Firestore, Hosting, rules, indexes, and connected
  Flutter client configuration are live.
- Profile, pet, adoption, and success-story images use Cloudinary on the current
  no-card Spark configuration.
- Private medical attachments remain on the mobile device until private
  Firebase Storage is provisioned.
- All roles receive authorization-scoped in-app appointment, adoption, health,
  and blog updates.
- Android/iOS appointment and medical reminders are scheduled locally.
- Pet owners and shelter admins can generate, preview, copy, regenerate,
  disable, and share/download secure QR pet identities. Normal phone-camera
  scans open only the explicitly public safety profile without requiring login.
- Automatic remote FCM delivery while the app is fully closed requires a
  trusted deployed sender. The checked-in Cloud Functions implement that sender,
  but production Functions deployment requires the Firebase Blaze plan.

See `docs/requirements-matrix.md` for requirement-by-requirement evidence and
`docs/architecture.md` for the security and database design.

## Credentials that must not be submitted publicly

Never place any of the following in GitHub, a Flutter build, screenshots, or
this file:

- Firebase/Google account password
- Firebase service-account private key or JSON file
- Firebase CLI token or Google OAuth token
- GitHub password or personal access token
- Cloudinary API secret
- Android release-keystore password or private signing key
- APNs private key or FCM server authorization credentials

If an examiner requires Firebase Console access, add their Google account as a
restricted project member. Never share the project owner's password.
