# CJE Platform — User Manual
## Consiliul Județean al Elevilor — Vocea Elevilor
### Digital Platform for County Student Councils

---

## Table of Contents

1. [About the App](#1-about-the-app)
2. [Getting Started](#2-getting-started)
   - 2.1 [Registration](#21-registration)
   - 2.2 [Login](#22-login)
   - 2.3 [Profile Setup (Google Sign-In)](#23-profile-setup-google-sign-in)
   - 2.4 [Account Approval](#24-account-approval)
3. [User Roles & Permissions](#3-user-roles--permissions)
4. [Home Screen](#4-home-screen)
5. [Announcements](#5-announcements)
   - 5.1 [Viewing Announcements](#51-viewing-announcements)
   - 5.2 [Creating Announcements](#52-creating-announcements)
6. [Initiatives (Ideas)](#6-initiatives-ideas)
   - 6.1 [Browsing Initiatives](#61-browsing-initiatives)
   - 6.2 [Proposing an Initiative](#62-proposing-an-initiative)
   - 6.3 [Initiative Lifecycle](#63-initiative-lifecycle)
   - 6.4 [Supporting & Voting](#64-supporting--voting)
   - 6.5 [Comments & Discussion](#65-comments--discussion)
7. [Meetings](#7-meetings)
   - 7.1 [Viewing Meetings](#71-viewing-meetings)
   - 7.2 [Creating Meetings](#72-creating-meetings)
   - 7.3 [Meeting Attendance](#73-meeting-attendance)
8. [Documents](#8-documents)
   - 8.1 [Browsing Documents](#81-browsing-documents)
   - 8.2 [Uploading Documents](#82-uploading-documents)
9. [Polls](#9-polls)
   - 9.1 [Viewing & Voting on Polls](#91-viewing--voting-on-polls)
   - 9.2 [Creating Polls](#92-creating-polls)
10. [GDS (Support Groups)](#10-gds-support-groups)
11. [Calendar](#11-calendar)
12. [Notifications](#12-notifications)
13. [Warnings & Absences](#13-warnings--absences)
14. [Menu & Settings](#14-menu--settings)
    - 14.1 [Profile](#141-profile)
    - 14.2 [Dark Mode](#142-dark-mode)
    - 14.3 [Language](#143-language)
    - 14.4 [Notification Preferences](#144-notification-preferences)
15. [Administration (BEX & Superadmin)](#15-administration-bex--superadmin)
    - 15.1 [User Management](#151-user-management)
    - 15.2 [School Management](#152-school-management)
    - 15.3 [GDS Management](#153-gds-management)
    - 15.4 [Analytics](#154-analytics)
    - 15.5 [County Settings](#155-county-settings)
    - 15.6 [Activity Report](#156-activity-report)
    - 15.7 [CSV User Import](#157-csv-user-import)
16. [Departments](#16-departments)
17. [Troubleshooting & FAQ](#17-troubleshooting--faq)

---

## 1. About the App

The **CJE Platform** (Consiliul Județean al Elevilor) is a digital platform designed for County Student Councils in Romania. It enables student council members to:

- Communicate through **announcements**
- Propose and vote on **initiatives**
- Schedule and track **meetings** with attendance
- Share **documents** (regulations, guides, reports)
- Conduct **polls** and surveys
- Manage **support groups** (GDS)
- Track **warnings** and **absences**

The app supports **Romanian** and **English** languages, **dark mode**, and **push notifications**.

---

## 2. Getting Started

### 2.1 Registration

1. Open the app and tap **Register** on the login screen.
2. Fill in the required fields:
   - **Full Name**
   - **Email Address**
   - **Password** (minimum 6 characters)
   - **County** — select your county
   - **Role** — select your role (Student, Class Rep, School Rep, etc.)
   - **School** — select your school from the list
   - **Class** — enter your class (e.g., "12A")
   - **Department** — if your role is Department, select the specific department
3. Tap **Register**.
4. If email verification is required, check your email and follow the verification link.
5. After verification, your account will be in **Pending Approval** status until an administrator approves it.

### 2.2 Login

1. Enter your **email** and **password**.
2. Tap **Login**.
3. Alternatively, tap **Sign in with Google** to use your Google account.
4. If you forgot your password, tap **Forgot Password** and enter your email to receive a reset link.

### 2.3 Profile Setup (Google Sign-In)

If you sign in with Google for the first time, you will be taken to a **Profile Setup** screen to complete your profile:
- Select your **county**
- Select your **school**
- Enter your **class name**
- Select your **role** and **department** (if applicable)

### 2.4 Account Approval

After registration, your account enters **Pending Approval** status. You will see a waiting screen with a message that your account is under review. A BEX member or Superadmin will review and approve your account. Once approved, you will have full access to the app.

If your account is **suspended**, you will see a suspension notice and will not be able to access the app until the suspension is lifted.

---

## 3. User Roles & Permissions

The app has a hierarchical role system with 6 levels:

| Role | Level | Description |
|------|-------|-------------|
| **Student** (Elev) | 1 | Regular student. Can view content, vote on polls, support initiatives. |
| **Class Rep** (Reprezentant de clasă) | 2 | Class representative. Can create initiatives and participate in class-level activities. |
| **School Rep** (Reprezentant de școală) | 3 | School representative. Can manage school-level content, upload documents, create school meetings and announcements. |
| **Department** (Departament) | 4 | Department head. Can create announcements, meetings, and polls within their department scope. Assigned to one of 6 departments. |
| **BEX** (Biroul Executiv) | 5 | County Executive Bureau member. Full administrative access — can manage users, schools, GDS, and all content. |
| **Superadmin** | 6 | System administrator. All permissions, including managing other admins. |

### Permission Summary

| Feature | Student | Class Rep | School Rep | Department | BEX | Superadmin |
|---------|---------|-----------|------------|------------|-----|------------|
| View announcements | Yes | Yes | Yes | Yes | Yes | Yes |
| Create announcements | — | — | School only | Yes | Yes | Yes |
| View meetings | Yes | Yes | Yes | Yes | Yes | Yes |
| Create meetings | — | — | School | Department | All types | All types |
| Create initiatives | Yes | Yes | Yes | — | — | — |
| Approve initiatives | — | — | School only | — | All | All |
| Upload documents | — | — | School | Department | All | All |
| Create polls | — | — | School | Yes | Yes | Yes |
| Vote on polls | Yes | Yes | Yes | Yes | Yes | Yes |
| View GDS | Yes | Yes | Yes | Yes | Yes | Yes |
| Manage GDS | — | — | — | — | Yes | Yes |
| Manage users | — | — | — | — | Yes | Yes |
| Manage schools | — | — | — | — | Yes | Yes |
| View analytics | — | — | — | — | Yes | Yes |
| County settings | — | — | — | — | Yes | Yes |

---

## 4. Home Screen

The home screen is your dashboard, showing a personalized overview:

- **Welcome Card** — Displays your name, school, role, and a personalized greeting.
- **Quick Stats** — Shows your activity numbers: votes cast, initiatives proposed, meetings attended.
- **Upcoming Events** — Lists upcoming meetings, active polls, and recent announcements with colored indicators:
  - Meetings shown with their type color
  - Active polls
  - Recent announcements
- **Reprimands Status** — If you have any active warnings or unexcused absences, a summary card appears here.
- **Activity Feed** — A chronological feed of recent activity across the platform (new announcements, polls created, initiatives submitted, etc.).

Tap the **bell icon** in the header to access your notifications. Tap your **avatar** to go to your profile.

---

## 5. Announcements

### 5.1 Viewing Announcements

The Announcements screen is accessible from the bottom navigation bar. It displays announcements organized in tabs:

- **All** — All announcements you have access to
- **County** (Comunicat CJE) — County-level announcements
- **School** (Comunicat Școală) — School-specific announcements
- **Drafts** — Your unpublished drafts (visible only to creators)

Each announcement card shows:
- Title and preview text
- Author name and photo
- Publication date
- Pinned indicator (if pinned)
- View count

Tap an announcement to read the full content, view attached images, and see details.

### 5.2 Creating Announcements

*Available to: School Rep, Department, BEX, Superadmin*

1. On the Announcements screen, tap the **+** (floating action button).
2. Fill in the fields:
   - **Title** — The announcement headline
   - **Content** — The full announcement body
   - **Summary** — Optional short preview text
   - **Type** — County or School announcement
   - **Image** — Optional featured image
   - **Tags** — Optional tags for categorization
   - **Minimum Visibility Role** — Set which roles can see this announcement
3. Tap **Save as Draft** to save without publishing, or **Publish** to make it immediately visible and send notifications to all eligible users.

Bilingual support: If translation is configured, your content can be automatically translated to the other language (Romanian ↔ English).

---

## 6. Initiatives (Ideas)

The Initiatives section is the democratic heart of the platform, allowing students to propose ideas and have them go through a formal review and voting process.

### 6.1 Browsing Initiatives

Access from the bottom navigation bar (labeled "Ideas" / "Inițiative"). Initiatives are organized in tabs:

- **All** — All initiatives
- **Draft** — Your personal drafts
- **Submitted** — Submitted and awaiting review
- **Review** — Under official review
- **Debate** — Open for community discussion
- **Voting** — Currently being voted on
- **Adopted** / **Rejected** — Final decisions

You can filter by:
- **My Initiatives** — Only your own proposals
- **School** — Filter by school
- **Type** — School-level or county-level initiatives

### 6.2 Proposing an Initiative

*Available to: Student, Class Rep, School Rep*

1. Tap the **+** button on the Initiatives screen.
2. Fill in:
   - **Title** — A clear, concise title for your idea
   - **Description** — Detailed description of your proposal
   - **Problem** — What problem does this solve?
   - **Solution** — Your proposed solution
   - **Impact** — What impact do you expect?
   - **Type** — School or County initiative
   - **Tags** — Categorization tags
3. Tap **Save as Draft** to save for later, or **Submit** to send it for review.

### 6.3 Initiative Lifecycle

Each initiative goes through these stages:

```
Draft → Submitted → Review → Debate → Voting → Adopted or Rejected
```

1. **Draft** — Private to the author. Can be edited freely.
2. **Submitted** — Sent for review by administrators. The author can no longer edit.
3. **Review** — Being evaluated by School Rep (school initiatives) or BEX (county initiatives).
4. **Debate** — Open for community discussion. Members can comment.
5. **Voting** — Eligible members can cast their vote (For / Against / Abstain).
6. **Adopted** — The initiative was approved and will be implemented.
7. **Rejected** — The initiative was not approved. A rejection reason is provided.

Status changes are made by administrators (School Rep for school initiatives, BEX/Superadmin for all).

### 6.4 Supporting & Voting

- **Support** — Tap the heart/support button on any submitted initiative to show your support. An initiative needs a minimum number of supporters (default: 10) to move forward.
- **Vote** — When an initiative reaches the Voting stage, eligible members can vote:
  - **For** — Support adoption
  - **Against** — Oppose adoption
  - **Abstain** — Neutral

The voting results (For / Against / Abstain counts and percentages) are visible to all.

### 6.5 Comments & Discussion

During the Debate stage, all members can comment on an initiative:
- Add your thoughts and feedback
- Official comments from administrators are highlighted
- Comments show the author's name, school, and role

---

## 7. Meetings

### 7.1 Viewing Meetings

Access from the bottom navigation bar. Meetings are organized in tabs:

- **All** — All meetings you can see
- **County AG** (Adunare Generală) — County-level general assemblies
- **BEX** — BEX coordination meetings
- **Department** — Department-specific meetings
- **School** — School-level meetings

Each meeting card shows:
- Title and date/time
- Meeting type (color-coded)
- Location or online link
- Number of attendees
- Whether it's upcoming, in progress, or completed

Tap a meeting to see:
- Full description and agenda items
- Attendee list
- Online meeting link (if applicable)
- Attached documents
- Attendance records (after the meeting)

### 7.2 Creating Meetings

*Available to: Department (department meetings), School Rep (school meetings), BEX/Superadmin (all types)*

1. Tap the **+** button on the Meetings screen.
2. Fill in:
   - **Title** — Meeting name
   - **Description** — Meeting purpose and details
   - **Type** — County AG, BEX, Department, or School
   - **Date & Time** — When the meeting takes place
   - **Duration** — Expected duration (default: 60 minutes)
   - **Location** — Physical location
   - **Online** — Toggle for online meetings; provide a Zoom/Meet link
   - **Agenda Items** — Add the meeting agenda
   - **Minimum Visibility Role** — Set who can see this meeting
   - **Department** — For department meetings, select the department
3. Tap **Create** to save and notify attendees.

### 7.3 Meeting Attendance

*Managed by: Meeting creator, BEX, Superadmin*

After a meeting, administrators can record attendance:
- **Present** — The member attended
- **Absent** — The member did not attend (unexcused)
- **Excused** — The member was absent with a valid reason

Unexcused absences are automatically recorded in the member's profile and can contribute to warnings.

---

## 8. Documents

### 8.1 Browsing Documents

Access from the **Menu** screen → **Documents**. Documents are organized in tabs by category:

- **All** — All documents
- **Regulamente** (Regulations) — Official rules and regulations
- **Ghiduri** (Guides) — How-to guides and manuals
- **Utile** (Useful) — Useful resources and templates
- **Rapoarte** (Reports) — Official reports
- **Altele** (Other) — Documents that don't fit other categories

Each document shows:
- Title and description
- Category (color-coded)
- File type icon (PDF, DOCX, XLSX, PNG, JPG)
- File size
- Upload date and uploader name
- Download count

Tap a document to view its details. You can download documents to your device.

### 8.2 Uploading Documents

*Available to: School Rep (school documents), Department, BEX, Superadmin*

1. On the Documents screen, tap the **Upload** button.
2. Fill in:
   - **Title** — Document name
   - **Description** — Optional description
   - **Category** — Select from Regulamente, Ghiduri, Utile, Rapoarte, or Altele
   - **File** — Select a file from your device (PDF, DOCX, XLSX, PNG, JPG)
   - **School** — For school-specific documents, select the school
   - **Public** — Toggle whether the document is publicly accessible or restricted by role
   - **Minimum Role** — If not public, set the minimum role required to view
3. Tap **Upload** to save the document.

---

## 9. Polls

### 9.1 Viewing & Voting on Polls

Access from the **Menu** screen → **Polls**. Polls are organized in tabs:

- **All** — All polls
- **County** (Sondaj Județ) — County-wide polls
- **School** (Sondaj Școală) — School-specific polls

Each poll card shows:
- Question text
- Number of votes
- Status (Active or Ended)
- End date/deadline

To vote on a poll:
1. Tap the poll to open it.
2. Read the question and description.
3. Select your choice(s) from the available options.
4. Tap **Vote** to submit.

After voting (or when a poll ends), you can see the results:
- Vote count and percentage for each option
- Total number of votes
- Whether the poll was anonymous

**Note:** You can only vote once on each poll (unless the poll allows multiple votes).

### 9.2 Creating Polls

*Available to: Department, BEX, Superadmin*

1. On the Polls screen, tap the **+** button.
2. Fill in:
   - **Question** — The poll question
   - **Description** — Optional additional context
   - **Type** — County or School poll
   - **Options** — Add 2 or more answer options
   - **End Date** — When the poll closes
   - **Anonymous** — Toggle anonymous voting (default: on)
   - **Allow Multiple Votes** — Toggle whether users can select multiple options
   - **Minimum Visibility Role** — Set who can see and vote
3. Tap **Create** to publish the poll and notify eligible users.

---

## 10. GDS (Support Groups)

GDS (Grupuri de Suport / Support Groups) are thematic working groups within the student council.

All authenticated users can view active support groups from the **Menu** screen → **GDS**. Each group card displays:
- Group name and focus area
- Number of members
- Leader name
- Active/Inactive status

Tap a group to see full details:
- Description
- Member list with roles
- Leader (highlighted)
- Creation date
- Status

**Note:** Only BEX and Superadmin can create, edit, and manage GDS groups. Other users have read-only access to active groups.

---

## 11. Calendar

Access from the **Menu** screen → **Calendar**.

The Calendar provides a monthly view of all events:
- **Meetings** — Shown with their type color
- **Polls** — Active polls with their end dates
- **Announcements** — Scheduled or pinned announcements

Tap a date to see all events on that day. Tap an event to navigate to its detail screen.

---

## 12. Notifications

Access by tapping the **bell icon** on the home screen, or from the **Menu**.

The Notifications screen shows all your notifications, including:
- **New Announcement** — When a new announcement is published
- **Meeting Reminder** — Upcoming meeting reminders
- **Initiative Update** — When an initiative you're following changes status
- **Poll Reminder** — When a new poll is available
- **Warning Issued** — When you receive a warning
- **Absence Recorded** — When an absence is recorded for you
- **System Alert** — System-wide notifications

Each notification shows:
- Title and body text
- Timestamp
- Read/unread indicator

You can:
- Tap a notification to navigate to the related content
- Mark individual notifications as read
- Mark all as read
- Delete notifications

**Push Notifications:** The app sends push notifications to your device for important events. You can toggle push notifications on/off in Settings.

---

## 13. Warnings & Absences

Access from the **Menu** screen → **My Warnings & Absences**.

This screen shows your personal record:

### Warnings

Warnings are disciplinary notices issued by administrators. There are 4 types by severity:
1. **Verbal** (Avertisment verbal) — Least severe
2. **Written** (Avertisment scris) — Formal written warning
3. **Suspension** (Suspendare) — Temporary suspension with an expiration date
4. **Removal** (Excludere) — Most severe

Each warning shows:
- Type and severity
- Reason
- Who issued it and when
- Resolution status (if resolved)

### Absences

Absences are recorded when you miss a meeting. Types:
- **Excused** — You had a valid reason and it was accepted
- **Unexcused** — No valid reason provided

Each absence shows:
- Meeting name and date
- Type (excused/unexcused)
- Reason (if provided)
- Who recorded it

**Note:** Warnings and absences also appear on your home screen in the Reprimands Status card if you have any active records.

---

## 14. Menu & Settings

The **Menu** screen (last tab in bottom navigation) provides access to additional features and settings.

### 14.1 Profile

Tap your profile card at the top of the Menu to view and edit your profile:
- **Full Name**
- **Photo** — Upload or change your profile picture
- **School and Class** — Update your school assignment
- **Phone Number** — Optional contact number
- View your role and account status

### 14.2 Dark Mode

Toggle dark mode on/off from the Settings section in the Menu. The app supports:
- **Light Mode** — White/light gray background with dark text
- **Dark Mode** — Dark blue-gray background with light text and gold accents

### 14.3 Language

Switch between **Romanian** and **English**:
1. In the Menu, tap **Language**.
2. Select your preferred language from the bottom sheet.
3. The app interface will update immediately.

Your language preference is also used for push notification content — notifications will be sent in your preferred language.

### 14.4 Notification Preferences

Toggle push notifications on/off from the Settings section in the Menu. When enabled, you'll receive push notifications for:
- New announcements
- Meeting reminders
- New polls
- Initiative updates
- Warnings and absences

---

## 15. Administration (BEX & Superadmin)

The Administration section is available only to BEX members and Superadmin users. It appears as a separate section in the Menu screen.

### 15.1 User Management

Access from Menu → **Users** (in the Administration section).

Features:
- **View all users** — Browse, search, and filter the user list
- **Filter by role** — Show only users with a specific role
- **Search** — Find users by name or email
- **Approve pending users** — Review and approve new registrations
- **Change user role** — Promote or demote users (BEX cannot be changed by other BEX, only by Superadmin)
- **Suspend/reactivate accounts** — Temporarily disable user access
- **Issue warnings** — Add warnings to a user's record
- **Record absences** — Add meeting absences
- **Create users directly** — Create new user accounts without requiring them to register

Tap any user to see their full profile, including:
- Personal information
- Role and status
- Warning history
- Absence history
- Actions (approve, suspend, change role, issue warning)

### 15.2 School Management

Access from Menu → **Schools** (in the Administration section).

Features:
- **View all schools** in the county
- **Add new schools** — Create school entries with name, short name, and address
- **Edit school information** — Update school details
- **Assign school representatives** — Designate a School Rep for each school
- **Toggle active/inactive** — Deactivate schools no longer in use
- **View student count** — See how many registered students each school has

### 15.3 GDS Management

*For BEX/Superadmin only — management features within the GDS screen*

When accessing GDS as a BEX/Superadmin user:
- **Create new groups** — Tap the + button to create a support group
  - Set group name, description, focus area
  - Select a leader from registered users
- **Edit groups** — Tap the edit icon on any group card
- **Add/remove members** — Manage group membership from the detail sheet
- **Change leaders** — Reassign group leadership
- **Activate/deactivate** — Toggle group active status
- **Delete groups** — Permanently remove a group
- **Show/hide inactive groups** — Toggle visibility of inactive groups with the eye icon in the app bar

### 15.4 Analytics

Access from Menu → **Analytics** (in the Administration section).

View county-level statistics and insights about platform activity:
- Total users, active users
- Content creation statistics
- Activity trends

### 15.5 County Settings

Access from Menu → **County Settings** (in the Administration section).

Configure county contact information:
- **Facebook** page URL
- **Instagram** profile URL
- **Website** URL
- **Email** address
- **Phone** number

This information is used for the Help & Support section and may be displayed across the app.

### 15.6 Activity Report

Access from Menu → **Activity Report** (in the Administration section).

Generate and download quarterly activity reports:
- View the current quarter's statistics
- See content counts (announcements, meetings, initiatives, polls, documents)
- Export data for official reporting

### 15.7 CSV User Import

Within User Management, administrators can bulk-import users using a CSV file.

**CSV Format:**
```
email, fullName, phoneNumber, city, role, schoolId, schoolName, className, department
john@example.com, John Doe, 0712345678, Cluj, student, school123, High School #1, 12A,
jane@example.com, Jane Smith, , Cluj, classRep, school123, High School #1, 11B,
```

**Required columns:** email, fullName
**Optional columns:** phoneNumber, city, role, schoolId, schoolName, className, department

The import will:
- Validate all rows before importing
- Skip duplicate emails
- Report errors with row numbers
- Create user accounts in bulk

---

## 16. Departments

The CJE has 6 organizational departments:

1. **Department for Secondary Education** (Dept. Învățământ Gimnazial)
2. **Department for IPTCV** (Dept. IPTCV) — Vocational Education
3. **Department for Vulnerable Groups** (Dept. Grupuri Vulnerabile) — Vulnerable groups & minorities
4. **Department for Special Education** (Dept. Învățământ Special)
5. **Department for Volunteering** (Dept. Voluntariat) — Volunteering & non-formal education
6. **Department for PR & Communications** (Dept. PR & Comunicare)

Users with the **Department** role are assigned to one of these departments. They can:
- Create department-level meetings
- Create announcements
- Manage department documents
- Create polls
- View department members

---

## 17. Troubleshooting & FAQ

### I registered but can't access the app
Your account is likely in **Pending Approval** status. Wait for a BEX member or Superadmin to approve your account. You'll receive a notification when approved.

### I'm not receiving push notifications
1. Check that notifications are enabled in the app (Menu → Settings → Notifications toggle).
2. Check your device's notification settings — make sure the CJE app is allowed to send notifications.
3. Make sure you're logged in — notifications are sent to your device's FCM token, which is registered on login.

### I can't create announcements/meetings/polls
Only certain roles have creation permissions. Check the [Roles & Permissions table](#3-user-roles--permissions) to see if your role allows this action.

### I can't see certain content
Some content has a **minimum visibility role** set by the creator. If your role level is below the minimum, the content won't appear in your feed.

### I can't vote on an initiative
Initiative voting may require a minimum role level (e.g., Class Rep or higher). Check if you meet the requirements.

### My account was suspended
Contact your county's BEX administration to inquire about the suspension. The suspension notice screen will display relevant information.

### How do I change my password?
Go to Profile → Edit Profile → Change Password. You'll need to enter your current password first.

### How do I change my school?
Go to Profile → Edit Profile → update your school selection. Note: this may require admin approval depending on your county's settings.

### How do I switch between Romanian and English?
Go to Menu → Settings → Language → select your preferred language. The change takes effect immediately.

### How do I enable dark mode?
Go to Menu → Settings → Dark Mode toggle. The app theme will switch instantly.

---

*CJE Platform v1.0 — Consiliul Județean al Elevilor*
*Vocea Elevilor — The Voice of Students*
