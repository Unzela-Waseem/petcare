# PawfectCare Architecture and Security Blueprint

This document is the implementation contract for PawfectCare. The product has exactly three roles: `petOwner`, `veterinarian`, and `shelterAdmin`. A role is assigned during registration, persisted in the private user profile, and can never be changed by a client.

## 1. Architecture

PawfectCare uses feature-first clean architecture with explicit trust boundaries.

```text
presentation  ->  application/controllers  ->  domain/repositories
                                                   |
                                                   v
data/repositories  ->  Firebase services  ->  Auth / Firestore / Storage / FCM
```

- **Presentation** renders immutable view state and sends user intent to controllers. Widgets never call Firebase directly.
- **Application** owns authentication state, role routing, validation, and use-case coordination.
- **Domain** contains roles, entities, repository contracts, and authorization-neutral business rules.
- **Data** maps domain contracts to Firebase or deterministic demo implementations.
- **Firebase services and rules** form the security boundary. UI visibility is convenience only; all authorization is repeated server-side by Security Rules or trusted server code.
- **Demo mode** contains non-sensitive seed data so the UI can run without project credentials. Production mode is enabled with `--dart-define=USE_FIREBASE=true` after native Firebase configuration files are installed.

### Folder structure

```text
lib/
  main.dart
  app/
    pawfect_care_app.dart
  core/
    config/app_environment.dart
    theme/app_theme.dart
    widgets/
  domain/
    models/
    repositories/
  data/
    repositories/
    services/
  presentation/
    controllers/
    screens/
      auth/
      onboarding/
      owner/
      veterinarian/
      shelter/
      pets/
      shared/
assets/images/
firebase/
  firestore.rules
  storage.rules
  firestore.indexes.json
test/
rules-tests/
```

Dependencies point inward: data knows domain contracts, presentation knows controllers and domain models, while domain does not import Flutter or Firebase.

## 2. Authentication and session flow

```text
Launch
  -> initialize Firebase / demo services
  -> observe authentication token
  -> signed out: onboarding -> login or registration
  -> registered: send verification email -> verification gate
  -> verified: fetch private /users/{uid}
  -> reject disabled/missing/unknown-role profile
  -> create role-scoped session
  -> rebuild the root navigator with the matching dashboard
```

Login performs authentication, email verification, private-profile lookup, account-status validation, and strict role parsing. Unknown roles fail closed. Logout signs out Firebase, deletes secure session hints, clears sensitive in-memory state, and rebuilds the root `MaterialApp` so back navigation cannot reveal protected screens. Firebase remains the source of truth; secure storage contains no password or authorization grant.

Password requirements are at least 12 characters with uppercase, lowercase, number, and symbol. Passwords are handled only by Firebase Authentication and are never written to Firestore, logs, analytics, or local storage.

## 3. Database schema

Server timestamps are used for every `createdAt` and `updatedAt`. IDs shown below are Firestore document IDs.

| Collection | Required fields | Ownership / notes |
|---|---|---|
| `users/{uid}` | `uid`, `name`, `email`, `phone`, `role`, `accountStatus`, `photoUrl`, `createdAt`, `updatedAt` | Private self profile. `role`, `uid`, `email`, and `accountStatus` are immutable to clients. |
| `publicProfiles/{uid}` | `uid`, `displayName`, `role`, `photoUrl`, `specialty`, `location` | Sanitized directory record, normally maintained by trusted backend. |
| `pets/{petId}` | `ownerId`, `name`, `species`, `breed`, `age`, `gender`, `photoPath`, timestamps | Owner-only mutation. Vet reads require server-managed access grant. |
| `petAccess/{petId}/veterinarians/{vetId}` | `petId`, `veterinarianId`, `appointmentId`, `active`, timestamps | Written only by trusted appointment automation; used by rules. |
| `petHealthRecords/{recordId}` | `petId`, `veterinarianId`, `diagnosis`, `treatment`, `prescription`, `date`, timestamps | Assigned vet creates; owner and assigned vet read; shelter is denied. |
| `appointments/{appointmentId}` | `petId`, `ownerId`, `veterinarianId`, `dateTime`, `reason`, `status`, timestamps | Owner creates for own pet. Party-specific status transitions are validated. |
| `vetAvailability/{slotId}` | `veterinarianId`, `startAt`, `endAt`, `isBooked` | Vet owns slots; booking is finalized transactionally by trusted backend to prevent double booking. |
| `shelters/{shelterId}` | `adminId`, `name`, `location`, `contact`, timestamps | Only its shelter admin mutates private shelter data. |
| `adoptionListings/{listingId}` | `shelterId`, `adminId`, pet fields, `healthStatus`, `status`, `photoPath`, timestamps | Authenticated users read published listings; owning shelter admin mutates. |
| `adoptionRequests/{requestId}` | `listingId`, `petId`, `ownerId`, `shelterId`, `status`, `message`, timestamps | Owner creates/reads own; target shelter admin reads and changes status. |
| `successStories/{storyId}` | `shelterId`, `adminId`, `title`, `body`, `imagePath`, `published`, timestamps | Published stories are readable; owning shelter admin mutates. |
| `volunteerRequests/{requestId}` | `userId`, `shelterId`, contact fields, `status`, timestamps | Submitter and target shelter admin only. |
| `contactMessages/{messageId}` | `userId`, `shelterId`, `subject`, `message`, `status`, timestamps | Submitter and target shelter admin only. |
| `products/{productId}` | `name`, `description`, `price`, `category`, `imageUrl`, `externalUrl`, `active` | Authenticated read; trusted backend writes. |
| `wishlists/{uid}/items/{productId}` | `productId`, `createdAt` | User-private. |
| `blogs/{blogId}` | `title`, `body`, `category`, `imageUrl`, `published`, timestamps | Authenticated read for published content; trusted backend writes. |
| `bookmarks/{uid}/items/{blogId}` | `blogId`, `offlineSnapshot`, `createdAt` | User-private. |
| `notifications/{uid}/items/{notificationId}` | `type`, `title`, `body`, `route`, `readAt`, `createdAt` | Trusted backend creates; recipient reads and marks read. |
| `feedback/{feedbackId}` | `userId`, `type`, `message`, `createdAt` | User creates and reads own; no cross-user access. |

Storage paths are document-linked, never public URLs: `users/{uid}/avatar/*`, `pets/{petId}/images/*`, `shelters/{shelterId}/images/*`, and `medical/{petId}/{recordId}/*`.

## 4. Authorization matrix

Legend: `own` means only a resource whose stored owner field equals `request.auth.uid`; `assigned` means an active `petAccess` grant exists; `server` means Admin SDK / trusted automation only.

| Resource / action | Pet Owner | Veterinarian | Shelter Admin |
|---|---|---|---|
| Private user profile | Read/update allowed fields on self | Same | Same |
| Change role/account status | Denied | Denied | Denied |
| Pet profile | CRUD own | Read assigned | Denied |
| Health record | Read for own pet | Create/read/update assigned record | Denied |
| Appointment | Create/read/cancel/reschedule own | Read/confirm/reschedule/complete assigned | Denied |
| Vet availability | Read | CRUD own | Denied |
| Product/blog | Read, bookmark/wishlist own | Read, bookmark own | Read, bookmark own |
| Adoption listing | Read published | Read published | CRUD own shelter listing |
| Adoption request | Create/read own | Denied | Read/update own shelter request |
| Success story | Read published | Read published | CRUD/publish own shelter story |
| Volunteer/contact | Create/read own | Create/read own | Read/update own shelter submissions |
| Notifications | Read/mark-read own | Same | Same |
| Feedback | Create/read own | Same | Same |

Every denied cell remains denied even if a client forges `uid`, `role`, `ownerId`, `adminId`, or navigation state.

## 5. Firestore and Storage security strategy

1. Require `request.auth != null` before all private operations.
2. Obtain role from `/users/{request.auth.uid}`, never from request payload.
3. Bind ownership to stored resource fields and prevent those fields from changing.
4. Use deterministic `petAccess` grants created by trusted appointment automation for veterinarian access.
5. Validate required keys, enums, field types, timestamps, transition-specific changed keys, and query-compatible ownership constraints.
6. Keep medical reports in protected Storage paths and validate MIME type and size. No download path is public.
7. Keep catalog/blog/notification administration server-only because there is no fourth administrator role.
8. Deny unmatched documents and paths by default.
9. Use App Check, least-privilege service accounts, audit logging, FCM token rotation, and Firebase Emulator Suite rule tests before production release.
10. Queries must include the same owner/party constraints required by rules; rules are not filters.

## 6. Screen inventory

### Public and authentication

- Splash / secure session restoration
- Three-page onboarding
- Login
- Registration with exactly three roles
- Email verification gate
- Forgot/reset password

### Pet Owner

- Owner home, My Pets, pet detail/editor
- Health timeline and due-date reminders
- Veterinarian search, appointment booking/history
- Pet store, search/filter, wishlist, external checkout confirmation
- Care tips, search/filter, bookmark/offline view
- Adoption discovery, listing detail, request/history
- Notifications, feedback, contact/locations, profile/security

### Veterinarian

- Today dashboard, assigned patients, patient history
- Appointment calendar and availability
- Medical record editor, prescription/follow-up, protected report upload
- Notifications, feedback, contact, profile/security

### Shelter Admin

- Shelter dashboard
- Listing manager/editor
- Adoption request review
- Success story manager/editor
- Volunteer requests and contact messages
- Notifications, feedback, contact, profile/security

## 7. Feature implementation contracts

| Feature | Purpose and UI | Data changes | Authentication / authorization | Core tests |
|---|---|---|---|---|
| Authentication | Register, verify, login, reset, logout | `users`, server-built `publicProfiles` | Verified, active user; strict role parser; root reset on logout | weak password rejected; unverified/disabled/unknown role denied; back after logout stays public |
| Pets | Owner pet grid and editor | `pets`, protected image path | owner CRUD only; assigned vet read only | cross-owner read/update/delete denied; vet without grant denied |
| Health | Timeline, record detail, reminders | `petHealthRecords`, medical Storage | owner read own; assigned vet writes attributable records | owner diagnosis write denied; unrelated vet and shelter denied |
| Appointments | Search, book, calendar, reschedule | `appointments`, `vetAvailability`, access grant via server | only appointment parties; field-level state transitions | forged owner/vet denied; double booking rejected; invalid transition denied |
| Store | Catalog, filters, wishlist | `products`, `wishlists` | auth read; wishlist private; catalog server-write | other wishlist denied; client product mutation denied |
| Care tips | Feed, filters, saved/offline reader | `blogs`, `bookmarks` | published auth read; bookmark private; publishing server-only | draft hidden; cross-user bookmark denied |
| Adoption | Discovery, request, request review | `adoptionListings`, `adoptionRequests` | owner submits own; owning shelter admin decides | foreign admin denied; owner cannot approve; immutable parties enforced |
| Shelter content | Listings and success-story editor | listings, `successStories`, shelter images | shelter admin limited to own `shelterId` | other shelter mutation denied; non-admin creation denied |
| Volunteer/contact | Forms and shelter inbox | `volunteerRequests`, `contactMessages` | submitter and target shelter only | other user/shelter denied; immutable user/shelter IDs |
| Notifications | Inbox and deep-link prompt | per-user notifications, FCM token service | recipient-only read; trusted sender; recipient mark-read only | cross-user read denied; client create denied |
| Profile | Safe edits, photo, password change | `users`, avatar Storage, Firebase Auth | self only; role/status immutable | role escalation and cross-user edits denied |
| Feedback | Suggestion/bug/feedback form | `feedback` | authenticated creator and owner-only read | forged user ID and cross-user read denied |

## 8. Release gates

- `dart format`, `flutter analyze`, and Flutter unit/widget tests pass.
- Firestore and Storage emulator authorization tests pass.
- Android and iOS Firebase configuration files are installed outside source control where appropriate.
- Firebase App Check is enforced after observing valid production traffic.
- Crash/analytics payloads contain no diagnoses, prescriptions, phone numbers, or message bodies.
- Accessibility checks cover text scaling, contrast, focus order, semantic labels, and 48 dp touch targets.
- A privacy review confirms data retention/deletion and medical-document access policies.
