# Ancora — Medication Adherence App

Ancora is a Flutter application that helps patients manage their medication schedules and keeps caregivers informed of adherence in real time. Built with Firebase as the backend.

---

## Features

### For Patients
- **Medication schedule** — today's doses displayed as colour-coded cards (blue = upcoming, amber = due soon, green = taken, red = overdue/missed)
- **Take button** — log a dose with one tap; shows a confirmation dialog if taken more than 60 minutes early
- **Upcoming view** — next 48 hours of scheduled doses shown below today's schedule
- **Progress tracker** — circular indicator showing today's completion percentage
- **History** — month calendar (green = taken, red = missed), 7-day adherence average, and current streak
- **Add medication** — name, dosage, unit, type, frequency, intake times, start/end dates, with scheduled local notifications on Android
- **Profile** — view and edit name and phone number, see your unique 4-digit patient code

### For Caregivers
- **Dashboard** — linked patients shown with on-track / needs-attention status cards based on 7-day adherence
- **Patient detail** — full month calendar and adherence percentage for any linked patient
- **Link patient** — enter a patient's 4-digit code to link their account
- **Push notifications** — receive an FCM alert when a patient misses a dose or takes one unusually early *(requires Blaze plan deployment)*
- **Profile** — view and edit caregiver profile, sign out

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Local notifications | flutter_local_notifications |
| Background tasks | WorkManager (Android) |
| Server logic | Firebase Cloud Functions (TypeScript) |
| Target platforms | Android, Web (Chrome) |

---

## Project Structure

```
lib/
  main.dart                  # App entry, Firebase init, AuthWrapper
  firebase_options.dart      # Generated Firebase config (not in repo — see setup)
  services/
    auth_service.dart        # Sign up, sign in, sign out, displayId claim
    notification_service.dart # FCM, local notifications, WorkManager init
    _workmanager_io.dart     # Android background sweep (mobile only)
    _workmanager_web.dart    # Web no-op stubs
  screens/
    ...                      # All patient and caregiver screens
functions/
  src/index.ts               # Cloud Function: notify caregivers on missed/early dose
firestore.rules              # Firestore security rules
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm install -g firebase-tools`)
- A connected Android device or Chrome browser

### 1. Clone the repository

```bash
git clone <repo-url>
cd Ancora
```

### 2. Add Firebase config files

These files contain API keys and are not committed to the repository. Get them from the project owner.

| File | Where to place it |
|---|---|
| `google-services.json` | `android/app/google-services.json` |
| `firebase_options.dart` | `lib/firebase_options.dart` |
| `firebase-messaging-sw.js` | `web/firebase-messaging-sw.js` (copy `web/firebase-messaging-sw.js.example` and fill in your Firebase web config) |

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run the app

**Android (connected device or emulator):**
```bash
flutter run
```

**Chrome (web):**
```bash
flutter run -d chrome
```

---

## Data Model

See [BACKEND.md](BACKEND.md) for the full Firestore data model and architecture notes.

---

## Known Limitations

- Notification scheduling covers the next 48 hours only; re-scheduling on medication edits is not yet implemented
- Cloud Function deployment requires the Firebase project to be on the Blaze (pay-as-you-go) plan
- Background WorkManager sweep may not fire in a fresh isolate if the app has not been opened recently
