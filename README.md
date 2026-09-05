# MyHx — Clinical History & AI Assistant

Bilingual (English / العربية) Flutter app for taking structured patient
histories, generating AI clinical analysis, and sharing reports.

Current version: **1.2.0**

## Features

- **Roles** — Student, Doctor, Developer (`lib/models/app_role.dart`).
  Students see all hospital departments, doctors pick their own from Settings,
  developers can edit the question banks and assign roles to other users.
- **Departments** — full hospital catalogue (40+ departments, grouped Medical /
  Surgical / Acute / Diagnostic / Support) with a dedicated clinical question
  set per department.
- **History modes** — department question bank, quick specialty template, or
  the full adaptive questionnaire.
- **Clinical AI** — differential diagnosis with probabilities, red flags, risk
  stratification and SOAP notes.
- **Reports** — searchable list, patient record, timeline with QR patient card,
  PDF export and sharing.
- **Offline-first** — reachability-checked offline banner and an outbox that
  syncs when the connection returns.
- **Voice dictation** for free-text answers.
- **English-only data entry** — Arabic text is blocked while typing and stored
  content is machine-translated to Arabic (with a local cache) when the app
  language is switched.
- **Themes** — light / system / dark plus six colour palettes (teal, indigo,
  emerald, rose, amber, slate), persisted between sessions.
- **Feedback effects** — motion, sound and haptics, each switchable in Settings.

## Requirements

- Flutter stable (Dart SDK `^3.29.0`)
- Firebase project (Auth + Firestore) — `google-services.json` and
  `GoogleService-Info.plist` are already wired
- Android: AGP 8.9.1, Kotlin 2.1.0, Gradle 8.12
- iOS: deployment target 17.0, CocoaPods

## Getting started

```bash
cd flutter-upgrade
flutter pub get
flutter run
```

Analyze and format before committing:

```bash
flutter analyze
dart format lib
```

### Permissions

Voice dictation requires microphone permission:

- iOS — `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription`
  in `ios/Runner/Info.plist`
- Android — `RECORD_AUDIO` in `android/app/src/main/AndroidManifest.xml`

## Project layout

```
lib/
  data/        departments, department question banks, specialty templates
  l10n/        bilingual strings (S.of(context), context.tr)
  models/      patient, doctor, question, app role
  screens/     login, dashboard, patients, history, reports, settings, admin
  services/    auth, database, clinical AI, offline, translation, roles,
               question bank, feedback, voice, PDF, analytics
  utils/       theme, palettes, colors, spacing, typography, english input
  widgets/     cards, buttons, text fields, voice input, translated text
```

## Firestore collections

| Collection | Purpose |
|---|---|
| `users/{uid}` | profile, `role`, `departments` |
| `patients` | patient records |
| `reports` | history + AI analysis per visit |
| `question_bank/{departmentId}` | developer-authored questions and hidden IDs |
