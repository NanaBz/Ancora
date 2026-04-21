# Ancora — Backend Architecture Reference

> Single source of truth for the Firebase backend design of **Ancora** (a.k.a. MediTrack), a Flutter medication reminder & adherence app built for a university mobile-computing module.
>
> **Audience:** you, future-you, and any collaborator wiring the backend. This document is a *specification*, not a tutorial — it tells you what to build and why, with rule/code snippets you can lift directly.

---

## 1. Overview

| Item | Value |
|---|---|
| Product | Ancora — medication reminder, tracker, and caregiver oversight |
| Frontend | Flutter (already built, UI-only, no backend wiring yet) |
| Backend | Firebase — Auth, Firestore, Cloud Functions (one), FCM |
| Billing tier | **Spark (free)** |
| Target scale | Academic demo, ≤ ~50 users |
| User roles | `patient`, `caregiver` (separate login flows already exist in the UI) |

### What changed from the spec docx

The submitted docx proposed React Native + Node.js + MongoDB + FCM. We've swapped to **Flutter + Firebase**. Two extras not in the docx but required here:

1. Each user gets a **unique 4-digit `displayId`** (e.g. `5953`) on account creation.
2. Internally every user has a Firebase Auth UID used for all secure references.
3. Caregivers add a patient by entering that 4-digit `displayId`.

### Design principles for this project

- **Do the simplest thing that works on Spark.** Spark forbids scheduled / pub-sub Cloud Functions; it allows Auth, Firestore, and Storage triggers. Any design that needs cron goes to v2 or an external GitHub-Actions cron.
- **Push logic to the client where it's safe.** Small user base → we can run transactions from the client for displayId generation and caregiver linking, with security rules as the trust boundary.
- **Every write is idempotent.** Dose logs use deterministic IDs so retries/offline replay can't duplicate.
- **No premature abstractions.** No repository layer wrappers, no sync engines, no DTO classes — call Firebase directly from screens initially; refactor only if it hurts.

---

## 2. User roles & auth model

- **One Firebase Auth project**, one email/password credential per user (optionally Google later).
- Role is stored at `users/{uid}.role` ∈ `{'patient', 'caregiver'}`.
- At sign-up, the chosen flow (`/signup` vs `/caregiver-signup`) decides the role and writes it. Security rules enforce that role cannot change on update.
- After sign-in, `main.dart` listens to `FirebaseAuth.authStateChanges()`, loads `users/{uid}`, and routes on `role`:
  - `patient` → `/home`
  - `caregiver` → `/caregiver-home`
- **No custom claims** in v1. Rules read the role via `get(/databases/$(database)/documents/users/$(request.auth.uid))` where necessary. (Custom claims would reduce per-rule reads at scale; unnecessary at ≤50 users.)

### Why not separate "patients" and "caregivers" collections?

One collection + a `role` field keeps uniqueness on `email` trivial, makes the `displayId` index uniform, and avoids duplicating profile fields. The caregiver's *patient list* lives as a subcollection on the caregiver doc; the patient's *caregiver list* mirrors on the patient. See §8.

---

## 3. The 4-digit `displayId` design

### Requirements

- Unique across the whole app (not per-role).
- 4 digits `0000`–`9999` (10 000 slots).
- Visible in the patient's UI so the caregiver can be told it out-of-band.
- Reverse-lookup: caregiver enters `5953` → backend resolves to a Firebase Auth UID → both sides create a link doc.

### Why a dedicated index collection (`displayIdIndex`) beats a `where` query

A `where('displayId', '==', x)` query requires `list` permission on `users`, which you cannot scope per-document — so you'd be granting every signed-in user the right to enumerate every user's profile. A **reverse-index collection with the displayId as the document ID** lets us grant only `get` (point reads), not `list`, and *the document ID itself is the uniqueness constraint*. Uniqueness then becomes atomic inside a single `runTransaction`.

```
displayIdIndex/{displayId}  →  { uid }
```

### Generation algorithm (client-side transaction)

Runs once, immediately after `createUserWithEmailAndPassword` succeeds:

```dart
Future<String> claimDisplayId(String uid, FirebaseFirestore db) async {
  for (var attempt = 0; attempt < 5; attempt++) {
    final id = (1000 + Random.secure().nextInt(9000)).toString(); // 1000-9999
    final idxRef  = db.collection('displayIdIndex').doc(id);
    final userRef = db.collection('users').doc(uid);
    try {
      await db.runTransaction((tx) async {
        final snap = await tx.get(idxRef);
        if (snap.exists) throw _CollisionException();
        tx.set(idxRef, {'uid': uid});
        tx.set(userRef, {'displayId': id}, SetOptions(merge: true));
      });
      return id;
    } on _CollisionException {
      continue;
    }
  }
  throw Exception('Could not allocate displayId after 5 tries');
}
class _CollisionException implements Exception {}
```

Collision probability with 50 users in a 10 000-slot space is ~0.25%; 5 retries is overkill but free.

### Why 4 digits is acceptable for an academic project

A determined attacker could script 10 000 `get`s to enumerate the index and discover existing displayIds. Mitigations, cheapest first:

- Enable **App Check** with Play Integrity / DeviceCheck — kills scripted clients.
- Rate-limit in the callable flow (N/A here — we're client-side).
- Bump to 6 digits in v2 if the threat model tightens.

For a graded demo, App Check + 4 digits is sufficient. Document this trade-off in your report.

---

## 4. Firestore data model

All fields are camelCase. Timestamps are `Timestamp` unless stated. Dates-without-time are `Timestamp` stored at local midnight; intake times are `HH:mm` strings interpreted in `users/{uid}.tzIana`.

### `users/{uid}`

```json
{
  "role": "patient",            // 'patient' | 'caregiver'
  "displayId": "5953",          // 4-digit, unique, immutable
  "fullName": "John Davies Jr",
  "email": "john@example.com",
  "phone": "+233596719305",
  "photoURL": null,             // optional
  "age": null,                  // optional, shown on profile
  "tzIana": "Africa/Accra",     // never store intake times as UTC
  "createdAt": <Timestamp>
}
```

Notes:
- `role` and `displayId` are write-once (enforced by rules).
- Populated by the signup transaction in §3.

### `users/{uid}/medications/{medId}`  (patients only)

```json
{
  "name": "Paracetamol",
  "dosage": 500,
  "unit": "mg",                 // 'mg' | 'ml' | 'g'
  "medType": "Tablet",          // Tablet | Capsule | Syrup | Injection | Drops | Cream | Inhaler
  "frequency": "Twice Daily",   // matches UI ChoiceChips
  "intakeTimes": ["08:00", "20:00"],
  "startDate": <Timestamp>,     // local midnight
  "endDate":   <Timestamp>,     // local midnight, inclusive
  "createdAt": <Timestamp>
}
```

### `users/{patientUid}/doseLogs/{logId}`

**Only written on actual events** — either `taken` (patient confirms) or `missed` (on-device background sweep writes it after the grace window). No pre-materialised `pending` docs.

Deterministic id: `logId = "{medId}_{yyyymmdd}_{hhmm}"`. Re-trying a write is a no-op.

```json
{
  "medId":       "abc123",
  "scheduledAt": <Timestamp>,   // the exact slot this log is for
  "status":      "taken",       // 'taken' | 'missed'
  "takenAt":     <Timestamp>,   // present iff status=='taken'
  "proofPath":   null           // v2: 'doseProofs/{uid}/{medId}/{logId}.jpg'
}
```

Adherence % and the monthly calendar on `history_page.dart` / `caregiver_clients_page.dart` are **derived client-side** from this subcollection + the medication start/end windows. No stored aggregate doc — cheap enough for ≤50 users and avoids recompute triggers.

### `users/{patientUid}/caregivers/{caregiverUid}`  (existence doc)

```json
{ "linkedAt": <Timestamp> }
```

### `users/{caregiverUid}/patients/{patientUid}`  (mirror, denormalised for list UI)

```json
{
  "linkedAt":  <Timestamp>,
  "fullName":  "John Davies Jr",
  "displayId": "5953",
  "photoURL":  null,
  "age":       22
}
```

Both link docs are written together in one batched write; unlink deletes both together. See §8.

### `users/{uid}/fcmTokens/{tokenId}`

One doc per device. `tokenId` = the FCM token string itself (collision-free).

```json
{ "platform": "android", "updatedAt": <Timestamp> }
```

Write on `onTokenRefresh` and on app start; delete on sign-out. *Never* store a single token on the user doc — multi-device users overwrite each other.

### `displayIdIndex/{displayId}`

```json
{ "uid": "firebase-auth-uid" }
```

`get` permitted to any authed user; `list` and `write` always denied from the client. The only creator path is the signup transaction, which rules allow iff `request.resource.data.uid == request.auth.uid`.

---

## 5. Security rules

Paste into `firestore.rules`. Inline comments explain intent.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // --- helpers ---
    function signedIn()   { return request.auth != null; }
    function me()         { return request.auth.uid; }
    function isOwner(uid) { return signedIn() && me() == uid; }
    function roleOf(uid)  {
      return get(/databases/$(database)/documents/users/$(uid)).data.role;
    }
    function isCaregiverOf(patientUid) {
      // exists() is cheaper than get() for boolean checks
      return exists(/databases/$(database)/documents/users/$(patientUid)/caregivers/$(me()));
    }

    // --- users ---
    match /users/{uid} {
      allow read:   if signedIn();                 // profile reads needed for caregiver list denorm
      allow create: if isOwner(uid)
                    && request.resource.data.role in ['patient','caregiver'];
      allow update: if isOwner(uid)
                    && request.resource.data.role == resource.data.role
                    && request.resource.data.displayId == resource.data.displayId;
      allow delete: if false;                       // never from client

      // medications — patient-only owner write, linked caregiver read
      match /medications/{medId} {
        allow read:  if isOwner(uid) || isCaregiverOf(uid);
        allow write: if isOwner(uid) && roleOf(uid) == 'patient';
      }

      // doseLogs — patient-only owner write, linked caregiver read
      match /doseLogs/{logId} {
        allow read:   if isOwner(uid) || isCaregiverOf(uid);
        allow create: if isOwner(uid) && roleOf(uid) == 'patient'
                      && request.resource.data.status in ['taken','missed'];
        allow update: if isOwner(uid)
                      && request.resource.data.status == resource.data.status; // status immutable post-hoc
        allow delete: if false;
      }

      // caregivers subcollection (existence doc on patient side)
      match /caregivers/{caregiverUid} {
        // patient sees their own caregivers; caregiver sees their own presence
        allow read:   if isOwner(uid) || me() == caregiverUid;
        // Either side can create the link (batched with the mirror write); both can delete
        allow create: if signedIn() && (me() == caregiverUid || isOwner(uid));
        allow delete: if signedIn() && (me() == caregiverUid || isOwner(uid));
        allow update: if false;
      }

      // patients subcollection (mirror on caregiver side)
      match /patients/{patientUid} {
        allow read:   if isOwner(uid);
        allow create: if isOwner(uid) && roleOf(uid) == 'caregiver';
        allow delete: if isOwner(uid) || me() == patientUid;
        allow update: if false;
      }

      // fcm tokens — owner only
      match /fcmTokens/{tokenId} {
        allow read, write: if isOwner(uid);
      }
    }

    // --- displayIdIndex --- point reads only; writes only by the new owner
    match /displayIdIndex/{displayId} {
      allow get:    if signedIn();
      allow list:   if false;
      allow create: if signedIn() && request.resource.data.uid == me();
      allow update, delete: if false;
    }
  }
}
```

**Test these rules with the Firebase emulator before deploying** — rule mistakes silently break offline writes on reconnect (see §9).

---

## 6. Cloud Functions

v1 ships **exactly one** function. Everything else is client-side.

### `onDoseLogCreate` — notify caregivers on missed doses

**Trigger:** Firestore `onCreate` at `users/{patientUid}/doseLogs/{logId}`.

Firestore triggers work on Spark. Scheduled / pub-sub / Cloud Tasks triggers do **not**.

**Logic:**
1. If `snap.data().status !== 'missed'`, return.
2. Read `users/{patientUid}/caregivers` (list of caregiver UIDs).
3. For each caregiver, read `users/{caregiverUid}/fcmTokens`.
4. Call `messaging.sendEachForMulticast` with a payload like `{ title: "Missed dose", body: "{patientName} missed {medName} at {time}" }`.
5. On `NotRegistered` / `InvalidRegistration` responses, delete the stale token doc.

**Folder layout** (created later at `functions/`):

```
functions/
├── package.json
├── tsconfig.json
└── src/
    └── index.ts        // exports onDoseLogCreate
```

Node 20 runtime, `firebase-functions` v5+, `firebase-admin` v12+.

### What we'd add on Blaze (for your writeup)

- `sweepMissedDoses` scheduled every 15 min as a belt-and-braces backup to the on-device missed-dose sweep.
- `pruneOldDoseLogs` monthly.
- Callable `linkPatient` if you ever want to add server-side abuse rate-limiting.

None of these are v1. Tagged **Blaze-only**.

---

## 7. Reminders & scheduling

All dose scheduling happens **on the device**. The server never needs to know "now is 8 AM for Yaw."

### Libraries (add to `pubspec.yaml`)

- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`
- `flutter_local_notifications` — schedule exact alarms
- `workmanager` — periodic background task for missed-dose sweep
- `timezone` — IANA zone math (use `flutter_native_timezone` to read the device zone once, store on `users/{uid}.tzIana`)

### Scheduling model

For each active medication doc (patient's own subscription):
1. Derive the full set of `(scheduledAt)` slots from `startDate..endDate` × `intakeTimes`, interpreted in the user's `tzIana`.
2. Cancel the app's previously-scheduled notifications for this `medId` and reschedule the next ~48 h of slots via `flutter_local_notifications.zonedSchedule`. (iOS caps pending local notifications at 64 per app — rolling window is safer.)
3. Every time the medications stream updates, re-run step 2.

### Dose-taken flow

When the user confirms intake:
- Compute `logId = "{medId}_{yyyymmdd}_{hhmm}"`.
- Write `doseLogs/{logId}` with `status:'taken'`, `takenAt: serverTimestamp()`.

### Missed-dose sweep (on-device, WorkManager periodic every 30 min)

- Iterate today's and yesterday's slots for all active meds.
- For each slot where `now > scheduledAt + graceMinutes` and `doseLogs/{logId}` does not exist, create it with `status:'missed'`.
- Idempotent by construction (deterministic id + rule `status in ['taken','missed']`).
- Creating the `missed` doc triggers `onDoseLogCreate` which fans out the caregiver FCM.

### Android permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>     <!-- Android 12+ -->
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>          <!-- Android 13+ (auto-granted) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>       <!-- Android 13+ runtime -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>   <!-- re-schedule after reboot -->
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

On Android 14+, `SCHEDULE_EXACT_ALARM` requires the user to grant it in Settings. UX: on first run, if `canScheduleExactAlarms()` is false, deep-link to the settings screen with an explanation.

---

## 8. Caregiver linking flow

### Step-by-step (client-side, rule-enforced)

1. Caregiver taps "Add user" → opens `caregiver_add_user_page.dart`, enters the 4-digit `displayId`.
2. Client: `final idx = await db.collection('displayIdIndex').doc(code).get();`
3. If `!idx.exists` → show "No user with this ID." Done.
4. If exists, read `patientUid = idx.data()!['uid']`.
5. Fetch `users/{patientUid}` to get `fullName`, `photoURL`, etc. for the denormalised mirror.
6. Batched write:
   ```dart
   final batch = db.batch();
   batch.set(
     db.doc('users/$patientUid/caregivers/${me.uid}'),
     {'linkedAt': FieldValue.serverTimestamp()},
   );
   batch.set(
     db.doc('users/${me.uid}/patients/$patientUid'),
     {
       'linkedAt':  FieldValue.serverTimestamp(),
       'fullName':  patient['fullName'],
       'displayId': patient['displayId'],
       'photoURL':  patient['photoURL'],
       'age':       patient['age'],
     },
   );
   await batch.commit();
   ```
7. Rules allow step 6 because:
   - `users/{patientUid}/caregivers/{cgUid}` create: `me() == caregiverUid` ✓
   - `users/{cgUid}/patients/{patientUid}` create: `isOwner(cgUid) && roleOf(cgUid) == 'caregiver'` ✓

### Unlinking

Either side deletes *both* docs in one batch. Rules permit this for both sides. A dangling single side = silent permission leak; always batch.

### Frontend adjustment

Today's `caregiver_add_user_page.dart` has a "Code" field with hint `eg. xxxx:xxx`. Change the hint to `eg. 5953` and add a 4-digit length validator. The two name fields on that screen are redundant once we look up by displayId — consider removing them, or using them only to confirm the match ("Is this John Davies Jr?").

---

## 9. Offline behaviour

Firestore's default SDK persistence is enabled on mobile. Reads/writes succeed offline; writes queue and flush on reconnect.

### Caveats you must test

- **Writes that violate security rules fail *silently* on reconnect.** The only symptom is the write never appearing server-side. Test every write path in airplane mode → reconnect before demo day.
- **`serverTimestamp()` is `null` locally** until the write flushes. Any UI sorting by it must tolerate `null`.
- **Transactions require connectivity.** The displayId-generation transaction won't run offline; users must be online for signup. Acceptable.
- **Dose taken while offline** still writes the `doseLogs/{logId}` locally; the `onDoseLogCreate` trigger fires later when it syncs (not when the user tapped). Caregiver "missed dose" notifications for offline patients will be **delayed** until the patient's device syncs. Document this limitation.

---

## 10. Client integration checklist

Per screen, the minimum backend wiring to make the existing UI functional. File paths are relative to `lib/`.

| Screen | Reads | Writes | Status |
|---|---|---|---|
| `main.dart` | `authStateChanges()`, `users/{uid}` for role routing | — | ✅ Done. `HomePage` fetches its own name internally — no prop drilling. |
| `screens/signup_page.dart` | — | `createUserWithEmailAndPassword` → `claimDisplayId` transaction → `users/{uid}` with `role:'patient'` | ✅ Done. |
| `screens/login_page.dart` | `signInWithEmailAndPassword` | — | ✅ Done. Role-validated; rejects caregiver credentials. |
| `screens/caregiver_signup_page.dart` | — | same as patient but `role:'caregiver'` | ✅ Done. |
| `screens/caregiver_login_page.dart` | same as patient login | — | ✅ Done. Rejects patient credentials. |
| `screens/add_medication_page.dart` | — | `users/{uid}/medications.add(...)` | ✅ Done. Start/end dates blocked to today+. Custom frequency supports free add/remove of time slots. Schedules local notifications on save. |
| `screens/home_page.dart` | `users/{uid}` (name) + `medications` stream + `doseLogs` stream | `doseLogs/{logId}` on "Taken" tap | ✅ Done. Shows time on each card. Upcoming section (next 2 days). Overdue triggers at exact scheduledAt. |
| `screens/history_page.dart` | `doseLogs` stream | — | ✅ Done. 7-day average, streak (includes today), month calendar. |
| `screens/more_page.dart` | `users/{uid}` | `users/{uid}` on "Save Changes" | ✅ Done. Real displayId in code circles. Sign Out clears FCM token. |
| `screens/caregiver_home_page.dart` | `users/{me.uid}/patients` + per-patient `doseLogs` (7 days) | — | ✅ Done. Adherence stat cards, tap → clients page with patientUid. |
| `screens/caregiver_clients_page.dart` | patient profile + `doseLogs` (month) | — | ✅ Done. Shows patient list (name only, no code) when opened without patientUid arg; shows detail view when arg present. |
| `screens/caregiver_add_user_page.dart` | `displayIdIndex/{code}`, `users/{patientUid}` | batched link writes (§8) | ✅ Done. 4-digit validated, confirm dialog, batched write. |
| `screens/caregiver_more_page.dart` | `users/{me.uid}` | `users/{me.uid}` | ✅ Done. Real profile, Save Changes wired, Sign Out clears FCM token. |

### Web-specific setup (Chrome)

`web/firebase-messaging-sw.js` must exist so Flutter's dev server can serve it as JavaScript. Without it the browser returns a 404 HTML page, FCM throws `failed-service-worker-registration`, and the app shows a white screen. The file initialises the Firebase app with the web config and registers a background message handler.

---

## 11. Setup steps (run once, for the follow-up session)

```bash
# 1. Install tooling
npm i -g firebase-tools
dart pub global activate flutterfire_cli

# 2. Log in, create project on console.firebase.google.com, then:
firebase login
flutterfire configure        # writes lib/firebase_options.dart + updates google-services.json / GoogleService-Info.plist

# 3. Init Firebase in this repo (at project root)
firebase init firestore functions
# - Firestore rules file: firestore.rules
# - Firestore indexes file: firestore.indexes.json
# - Functions language: TypeScript
# - ESLint: yes, don't install deps yet (we'll npm i manually)

# 4. Flutter deps
flutter pub add firebase_core firebase_auth cloud_firestore firebase_messaging \
                flutter_local_notifications workmanager timezone \
                flutter_native_timezone
```

**Android:** add permissions per §7, ensure `minSdkVersion >= 23`, and add the `google-services` plugin block (FlutterFire does this).

**iOS:** enable Push Notifications capability + Background Modes (Remote notifications) in Xcode. Upload an APNs auth key to Firebase Console → Project Settings → Cloud Messaging.

### Local iteration with the emulator

```bash
firebase emulators:start --only auth,firestore,functions
```

Point the Flutter app at the emulator by adding, before `runApp`:

```dart
if (kDebugMode) {
  FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
}
```

This is non-negotiable for testing security rules. Deploy only after emulator tests pass.

---

## 12. Academic-project best practices

- **Enable App Check** in the console with debug tokens locally — prevents scraping of `displayIdIndex` during your public demo.
- **Budget alerts:** even on Spark, set a billing alert at $1 so you're told the moment you slip onto Blaze.
- **Seed data script:** keep `scripts/seed.ts` that populates the emulator with 2–3 patients + 1 caregiver + a week of dose logs, so demos and examiners see a realistic dashboard in one command.
- **One branch per feature.** `feat/auth`, `feat/meds`, `feat/caregiver-link`, `feat/reminders`, `feat/cloud-fn`. Merge with squash — your examiner will likely read the PR list.
- **Secrets:** you have none in v1 (no API keys outside Firebase's auto-configured ones). Do **not** commit `google-services.json` / `GoogleService-Info.plist` to a public repo; add to `.gitignore` before the first push. For academic submission keep a private branch with the config files intact.
- **Firestore read budgets:** the home screen streams `medications` + today's `doseLogs`. Make sure you `.limit(...)` the history queries to the visible month.
- **Testing:**
  - Rules: `firebase emulators:exec --only firestore 'npm test'` using the `@firebase/rules-unit-testing` package.
  - Widget tests with `fake_cloud_firestore` for screen-level logic.
  - Manual: one full end-to-end in airplane mode → reconnect before submission.
- **Document the architecture in your report** using the diagrams you can generate from this file. Mermaid works in GitHub previews if you want to copy snippets.

---

## 13. Risks & gotchas

| # | Risk | Mitigation |
|---|---|---|
| 1 | **Timezone drift** in intake times | Store `HH:mm` + `tzIana`; never UTC. Use `timezone` + `flutter_native_timezone`. |
| 2 | **Silent offline-write failures** when rules reject | Emulator rule tests + manual airplane-mode test pass. |
| 3 | **displayId shoulder-surfing** | App Check on; document in report; 6-digit bump in v2. |
| 4 | **Android 14 exact-alarm UX** | On first run, if `canScheduleExactAlarms()==false`, show rationale + deep-link to Settings. |
| 5 | **Unlink desync** (one mirror doc left behind → ghost access) | Always batch both docs together; code-review anywhere you delete a link. |
| 6 | **FCM stale tokens** | `onDoseLogCreate` deletes tokens that return `NotRegistered`. |
| 7 | **iOS 64-notification cap** | Schedule a rolling 48 h window, not the entire treatment course. |
| 8 | **Public repo + `google-services.json`** | `.gitignore` before first push. |
| 9 | **Spark quota overshoot** mid-demo | Billing alert at $1; seed data is light; no scheduled functions. |
| 10 | **Dose log id collisions across meds at the same minute** | Id includes `medId` prefix — already namespaced. |

---

## 14. v2 roadmap (not shipping in v1)

- **Photo verification of dose intake.** Firebase Storage path `doseProofs/{patientUid}/{medId}/{logId}.jpg`; Storage rules mirror doseLog read rules; enforce `request.resource.size < 2 * 1024 * 1024` and `contentType.matches('image/.*')`; client-side compression to ~800 px / 70 % JPEG using `flutter_image_compress`.
- **Server-side missed-dose sweep** (Blaze only) — scheduled function every 15 min as a belt-and-braces backup to on-device.
- **Caregiver live stream** of patient intake events via a top-level `caregiverEvents` collection or a FCM data-only message.
- **Biometric unlock** (`local_auth`).
- **Medication photo recognition / OCR** per the docx's "Future Enhancements" section.
- **Wearable companion** (Wear OS / watchOS) — receives the same FCM alerts.
- **Export adherence PDF** for caregivers (`printing` package).
- **Multi-language** — the docx target audience (Ghana) has English + Twi; `intl` + ARB files.

---

## Appendix A — minimal file map this doc expects you to create

```
Ancora/
├── BACKEND.md                       # this file
├── firebase.json
├── firestore.rules                  # §5 rules
├── firestore.indexes.json
├── functions/
│   ├── package.json
│   ├── tsconfig.json
│   └── src/
│       └── index.ts                 # onDoseLogCreate only
├── android/app/src/main/AndroidManifest.xml   # permissions per §7
├── lib/
│   ├── main.dart                    # Firebase.initializeApp + role routing
│   ├── firebase_options.dart        # generated by flutterfire configure
│   └── screens/                     # existing — wire per §10
└── scripts/
    └── seed.ts                      # optional, for demos
```

## Appendix B — glossary

- **displayId** — user-facing 4-digit unique number (e.g. `5953`). Used for caregiver linking. Never used in security-sensitive reads.
- **uid** — Firebase Auth UID. Used for every secure reference.
- **doseLog** — a record that an intake slot was either confirmed taken or detected as missed.
- **link doc** — existence document that records a caregiver↔patient relationship. Mirrored on both sides.
- **slot** — a `(medication, scheduledAt)` pair produced by expanding `startDate..endDate × intakeTimes`.
