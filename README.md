# CJE Platform

A mobile application for County Student Council (Consiliul Județean al Elevilor) management built with Flutter and Firebase.

## Overview

CJE Platform is a comprehensive student council management app that enables communication, collaboration, and organization for student representatives across schools in a county.

## Features

### Authentication
- Email + Password login
- Google Sign-In
- Profile setup with school selection
- Email verification
- Account approval workflow

### User Roles
- **Student** - Basic access to view content and vote
- **Class Representative** - Can draft initiatives
- **School Representative** - Manage school-level content
- **Department** - Manage department meetings and documents (PR, Volunteering, School Inclusion)
- **BEX (County Executive Board)** - Full administrative access
- **Superadmin** - System administrator (single instance)

### Core Modules

#### Announcements
- School and county-level announcements
- Filter by type (All/CJE/School)
- Attachments support
- Create/Edit/Delete (role-based)

#### Meetings
- Four meeting types: County AG, BEX, Department, School
- Agenda management
- Document attachments
- Participant tracking
- Meeting minutes upload
- Attendance management

#### Initiatives
- Create and submit initiatives
- Approval workflow (Proposed → In Debate → Adopted/Rejected)
- Comments and voting system
- Expected impact tracking

#### Documents
- Categories: Statut Elevului, Regulamente, Metodologii, Formulare
- Upload/Download functionality
- Tags and folder organization
- Role-based access control

#### Polls
- School and county-level polls
- Multiple choice voting
- Anonymous voting option
- Results visualization

### Administration
- User management (approve/suspend accounts)
- Role assignment
- Schools management
- GDS (Support Groups) management
- Warnings and absences tracking
- CSV user import
- Analytics dashboard

### Global Features
- Push notifications (FCM)
- Monthly calendar view
- Global search (title + tags)
- Multi-language support (English/Romanian)
- Dark/Light theme

## Tech Stack

- **Framework:** Flutter 3.9+
- **State Management:** Riverpod
- **Backend:** Firebase (Auth, Firestore, Storage, Messaging)
- **Navigation:** GoRouter
- **Localization:** Custom implementation with Romanian/English

## Project Structure

```
lib/
├── controllers/       # Riverpod providers and state management
├── core/
│   ├── constants/     # App constants and enums
│   ├── l10n/          # Localization
│   ├── repositories/  # Firebase data access
│   ├── services/      # Business logic services
│   ├── theme/         # App theming
│   └── utils/         # Utility functions
├── models/            # Data models
├── routes/            # Navigation configuration
└── views/
    ├── screens/       # App screens
    └── widgets/       # Reusable widgets
```

## Getting Started

### Prerequisites
- Flutter SDK 3.9+
- Firebase project configured
- Android Studio / VS Code

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd cje
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Firebase
- Add `google-services.json` (Android)
- Add `GoogleService-Info.plist` (iOS)
- Update `firebase_options.dart`

4. Run the app
```bash
flutter run
```

## Build

### Android APK
```bash
flutter build apk --release
```

### iOS (TestFlight)
```bash
flutter build ios --release
```

## Configuration

### Environment
- Minimum Android SDK: 21
- Minimum iOS: 12.0
- Target SDK: Latest stable

### Firebase Collections
- `users` - User profiles
- `schools` - School information
- `announcements` - Announcements
- `meetings` - Meetings
- `initiatives` - Initiatives
- `polls` - Polls
- `documents` - Documents metadata
- `notifications` - In-app notifications
- `gds` - Support groups
- `warnings` - User warnings
- `activities` - Activity feed

## License

This project is proprietary software for CJE (County Student Council).
