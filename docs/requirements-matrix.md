# PawfectCare Requirements Matrix

This matrix maps the supplied specification to the implemented production path. “Implemented” means the Flutter workflow, repository operation, validation, and authorization rule exist and pass the applicable local checks. Live Firebase items are identified separately.

| Requirement area | Implemented behavior | Live state |
|---|---|---|
| Authentication | Register with exactly three roles, strong password/confirmation, email verification gate, login, reset, secure reauthentication password change, session restoration, and root-reset logout | Firebase Email/Password Auth enabled |
| Authorization | Active verified accounts, immutable role/identity/ownership, role routing, deny-by-default rules, private queries scoped by stored party IDs | Firestore rules deployed |
| Pet Owner: pets | Search by name/breed; create, edit, delete, view details; validated image selection/upload | CRUD live; image upload awaits Storage bucket |
| Pet Owner: health | Pet selector, medical-requirement search, type filters, vaccination/deworming/allergy routine records, due dates, read-only clinical history | Firestore live; reminders implemented in Functions; documents await Storage bucket |
| Pet Owner: appointments | Search vets by name/clinic/specialty/location, choose pet and open time, reason, book, cancel, reschedule, statuses/history | Atomic Firestore workflow live |
| Store | Food, Grooming, Toys, Health categories; image/name/description/price; search, filter, private wishlist, validated HTTPS purchase link | Four products seeded live |
| Care tips | Training, Nutrition, First Aid, Pet Care; keyword search, category filter, private bookmarks, explicit offline save/remove and offline fallback | Four guides seeded live |
| Adoption | Search/filter listings, submit private request, view owner history | Firestore live; listing images await Storage bucket |
| Veterinarian | Assigned-pet search, protected patient history, diagnosis/treatment/prescription/follow-up, report selection, availability CRUD, appointment confirm/reschedule/complete/cancel | Firestore live; report upload awaits Storage bucket |
| Shelter Admin | Create shelter profile; own listing CRUD/status; review/approve/reject requests; story draft/edit/publish/delete; manage volunteer/donation/inquiry statuses | Firestore live; images await Storage bucket |
| Notifications | Per-device token rotation/cleanup, preferences, recipient-only inbox/read state, appointment/adoption/blog triggers, hourly appointment/vaccine reminders, web service worker, iOS background entitlement | Client ready; Functions deployment awaits Blaze; APNs/VAPID remain owner credentials |
| Profile | View/edit allowed name/phone/photo, immutable role notice, password change, notification preferences, logout | Firestore/Auth live; photo awaits Storage bucket |
| Feedback/contact/maps | Suggestions, bugs, feedback; shelter inquiry; volunteer/donation forms; vet/shelter locations; Google Maps external deep links | Firestore and maps live |
| Firestore security | Owner isolation, assigned-vet grants, clinical-field restrictions, shelter isolation, atomic slot booking/release/reschedule, server-only catalogs and notifications | Deployed and emulator-tested |
| Storage security | 5 MB JPG/PNG/WebP images, 10 MB PDF/image medical files, owner/assigned-vet/shelter path authorization, deny-all fallback | Emulator-tested; deployment awaits Blaze bucket |
| Trusted backend | Notification fan-out, invalid-token cleanup, idempotent scheduled reminders, adoption/appointment/blog events | Emulator-load/lint/audit clean; deployment awaits Blaze |

## Verification evidence

- `flutter analyze`: no issues.
- `flutter test`: all unit/widget tests pass.
- Firebase Emulator Suite: 19 Firestore/Storage authorization tests pass.
- Functions: syntax check and ESLint pass; production dependency audit reports zero vulnerabilities; all trigger definitions load in the emulator.
- Firestore rules and indexes are deployed to `pawfectcare-unzela-2026`.
- Live Firestore contains four products and four care guides.

## Account-owner release actions

These cannot be completed by source code or Firebase CLI while the project is on Spark:

1. Upgrade `pawfectcare-unzela-2026` to Blaze and create the default Storage bucket.
2. Run `firebase deploy --only storage,functions`.
3. Upload the Apple APNs key/certificate for iOS push.
4. Generate a Web Push certificate and pass its public value as `FCM_WEB_VAPID_KEY` for web builds.

No fourth application role or permissive client-admin rule is introduced to work around these platform controls.
