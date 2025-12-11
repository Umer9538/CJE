# CJE Platform - Complete User Guide

## Consiliul Județean al Elevilor (County Student Council Platform)

**Version:** 1.0
**Last Updated:** December 2024

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Getting Started](#2-getting-started)
3. [User Roles & Permissions](#3-user-roles--permissions)
4. [Student & Class Representative Guide](#4-student--class-representative-guide)
5. [School Representative Guide](#5-school-representative-guide)
6. [Department Staff Guide](#6-department-staff-guide)
7. [BEX (County Executive Bureau) Guide](#7-bex-county-executive-bureau-guide)
8. [Admin (Superadmin) Guide](#8-admin-superadmin-guide)
9. [Feature Reference](#9-feature-reference)
10. [Troubleshooting & FAQ](#10-troubleshooting--faq)

---

## 1. Introduction

### What is CJE Platform?

The CJE Platform is a comprehensive mobile application designed for the County Student Council (Consiliul Județean al Elevilor). It provides a centralized platform for:

- **Communication** - Announcements and notifications across schools
- **Meetings Management** - Scheduling, attendance tracking, and documentation
- **Democratic Participation** - Initiatives, voting, and polls
- **Document Management** - Centralized document repository
- **Member Management** - User administration and tracking

### Platform Highlights

- Real-time notifications for important updates
- Multi-language support (Romanian/English)
- Light and dark theme options
- Offline-capable for viewing cached content
- Secure authentication with Google Sign-In support

---

## 2. Getting Started

### 2.1 Installing the App

1. Download the CJE app from the provided link
2. Install on your Android device
3. Open the app to begin setup

### 2.2 Creating an Account

#### Option A: Email Registration
1. Tap **"Create Account"** on the welcome screen
2. Enter your details:
   - Full Name
   - Email Address
   - Password (minimum 6 characters)
3. Tap **"Register"**
4. Check your email for a verification link
5. Click the verification link to activate your account
6. Wait for admin approval (you'll receive a notification when approved)

#### Option B: Google Sign-In
1. Tap **"Continue with Google"**
2. Select your Google account
3. Complete your profile setup:
   - Confirm your name
   - Select your school
   - Select your class
4. Wait for admin approval

### 2.3 Logging In

1. Open the CJE app
2. Enter your email and password
3. Tap **"Login"**
4. If you forgot your password, tap **"Forgot Password?"** to reset it

### 2.4 Account Status

Your account can have one of these statuses:

| Status | Description |
|--------|-------------|
| **Pending** | Account created, waiting for admin approval |
| **Active** | Full access to the platform |
| **Suspended** | Account temporarily restricted by admin |

---

## 3. User Roles & Permissions

### 3.1 Role Hierarchy

The CJE Platform has 6 user roles organized in a hierarchy:

```
Level 5: Superadmin (Platform Administrator)
    ↓
Level 4: BEX (County Executive Bureau)
    ↓
Level 3: School Representative | Department Staff
    ↓
Level 2: Class Representative
    ↓
Level 1: Student (Basic User)
```

### 3.2 Role Descriptions

| Role | Description | Access Level |
|------|-------------|--------------|
| **Student** | Basic council member | View content, vote, support initiatives |
| **Class Representative** | Class-level organizer | Same as student + class coordination |
| **School Representative** | School administrator | Create school content, manage school members |
| **Department** | Department staff member | Manage department meetings and documents |
| **BEX** | County Executive Bureau | Manage county-level content and GDS groups |
| **Superadmin** | Platform administrator | Full access to all features and admin panel |

### 3.3 Permission Matrix

| Feature | Student | Class Rep | School Rep | Department | BEX | Admin |
|---------|:-------:|:---------:|:----------:|:----------:|:---:|:-----:|
| View Announcements | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Create Announcements | - | - | School | - | County | All |
| View Meetings | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Create Meetings | - | - | School | Dept | County | All |
| View Documents | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Upload Documents | - | - | School | Dept | County | All |
| Create Initiatives | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Vote on Initiatives | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Create Polls | - | - | School | - | County | All |
| Vote on Polls | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Manage Users | - | - | - | - | - | ✓ |
| Manage Schools | - | - | - | - | - | ✓ |
| Manage GDS | - | - | - | - | ✓ | ✓ |
| Issue Warnings | - | - | - | - | - | ✓ |

---

## 4. Student & Class Representative Guide

### 4.1 Home Screen

The home screen is your dashboard showing:

- **Welcome Card** - Personalized greeting with your name
- **Quick Stats** - Overview of platform activity
- **Upcoming Meetings** - Next scheduled meetings
- **Recent Activity** - Latest updates from the platform

**Pull down to refresh** the content at any time.

### 4.2 Announcements

#### Viewing Announcements
1. Tap the **"Announcements"** tab in the bottom navigation
2. Browse the list of announcements
3. Use the filter to show:
   - **All** - Both county and school announcements
   - **County** - CJE-wide announcements
   - **School** - Your school's announcements
4. Tap any announcement to read the full content

#### Announcement Details
- **Title** - Main heading
- **Summary** - Brief overview
- **Content** - Full announcement text
- **Image** - Featured image (if attached)
- **Attachments** - Downloadable files
- **Tags** - Categories for organization
- **View Count** - Number of views
- **Posted Date** - When it was published

### 4.3 Meetings

#### Viewing Meetings
1. Tap the **"Meetings"** tab
2. Toggle between:
   - **All** - All meetings
   - **Upcoming** - Future meetings only
3. Tap a meeting to view details

#### Meeting Types
| Type | Description | Color |
|------|-------------|-------|
| **County AG** | County Assembly General meetings | Purple |
| **BEX** | Executive Bureau meetings | Blue |
| **Department** | Department-specific meetings | Amber |
| **School** | School council meetings | Green |

#### Meeting Details Include:
- Date and time
- Duration
- Location (physical address or online link)
- Agenda items
- Attached documents
- Attendee list
- Meeting minutes (after completion)

#### Joining Online Meetings
1. Open the meeting details
2. Tap the **meeting link** to join
3. The link will open in your browser or meeting app

### 4.4 Initiatives

Initiatives are proposals from council members that go through a democratic process.

#### Initiative Lifecycle

```
1. DRAFT → 2. SUBMITTED → 3. REVIEW → 4. DEBATE → 5. VOTING → 6. ADOPTED/REJECTED
```

| Stage | Description | Your Actions |
|-------|-------------|--------------|
| **Draft** | Author is preparing | Edit (if you're the author) |
| **Submitted** | Waiting for review | View only |
| **Review** | Under admin review | View only |
| **Debate** | Open discussion | Comment, Support/Unsupport |
| **Voting** | Active voting period | Cast your vote |
| **Adopted** | Approved by majority | View results |
| **Rejected** | Not approved | View results and reason |

#### Creating an Initiative
1. Tap the **"Initiatives"** tab
2. Tap the **"+"** floating button
3. Fill in the form:
   - **Title** - Clear, descriptive name
   - **Description** - Detailed explanation
   - **Problem Statement** - What issue does this address?
   - **Proposed Solution** - How will it be solved?
   - **Expected Impact** - What will change?
   - **Tags** - Relevant categories
4. Tap **"Save as Draft"** or **"Submit"**

#### Supporting an Initiative
1. Open the initiative details
2. Tap **"Support"** to add your support
3. The support percentage will update
4. Tap again to remove your support

#### Voting on an Initiative
1. Open an initiative in **Voting** stage
2. Choose your vote:
   - **For** - You approve
   - **Against** - You disapprove
   - **Abstain** - No opinion
3. Tap **"Submit Vote"**
4. Your vote is recorded (cannot be changed)

### 4.5 Documents

#### Browsing Documents
1. Tap **"Documents"** from the menu
2. Browse by category:
   - **Statutul Elevului** - Student Statute
   - **Regulamente** - Regulations
   - **Metodologii** - Methodologies
   - **Formulare** - Forms

#### Downloading Documents
1. Find the document you need
2. Tap to open document details
3. Tap **"Download"** to save to your device
4. Supported formats: PDF, DOCX, XLSX, PNG, JPG

### 4.6 Polls

#### Viewing Active Polls
1. Access Polls from the menu
2. View **Active** polls (open for voting)
3. View **Ended** polls (completed)

#### Voting on a Poll
1. Open an active poll
2. Read the question carefully
3. Select your answer(s):
   - Single choice: Select one option
   - Multiple choice: Select all that apply
4. Tap **"Submit Vote"**
5. View results (if allowed before poll ends)

### 4.7 Profile & Settings

#### Viewing Your Profile
1. Tap the **"Profile"** tab
2. View your information:
   - Name and photo
   - Email address
   - Role and status
   - School and class

#### Editing Your Profile
1. Tap **"Edit Profile"**
2. Update your information:
   - Profile photo
   - Phone number
   - City
3. Tap **"Save"**

#### Changing Settings
1. Tap **"Settings"** in profile
2. Available options:
   - **Language** - Switch between Romanian and English
   - **Theme** - Choose Light or Dark mode
   - **Notifications** - Manage notification preferences

#### Logging Out
1. Go to Profile tab
2. Scroll down and tap **"Logout"**
3. Confirm your choice

### 4.8 Notifications

#### Notification Types
- **Meeting Reminders** - Upcoming meeting alerts
- **New Announcements** - When announcements are posted
- **Initiative Updates** - Status changes on initiatives
- **Poll Reminders** - Active polls requiring your vote
- **System Alerts** - Important platform notices

#### Managing Notifications
1. Tap the **bell icon** in the header
2. View all notifications
3. Tap a notification to navigate to related content
4. Notifications are marked as read automatically

---

## 5. School Representative Guide

As a School Representative, you have additional capabilities for managing school-level content.

### 5.1 Creating School Announcements

1. Go to **Announcements** tab
2. Tap the **"+"** floating button
3. Fill in the announcement:
   - **Title** - Clear heading
   - **Summary** - Brief overview (displayed in list)
   - **Content** - Full announcement text
   - **Featured Image** - Optional image
   - **Attachments** - Upload files if needed
   - **Tags** - Add relevant tags
   - **Pin** - Toggle to pin at top of list
4. Tap **"Publish"** or **"Save as Draft"**

### 5.2 Creating School Meetings

1. Go to **Meetings** tab
2. Tap the **"+"** floating button
3. Fill in meeting details:
   - **Meeting Type** - Select "School"
   - **Title** - Meeting name
   - **Date & Time** - Schedule the meeting
   - **Duration** - Expected length (30-120 minutes)
   - **Location Type**:
     - Physical: Enter address
     - Online: Enter meeting link
   - **Description** - Meeting purpose
   - **Agenda Items** - Add agenda points
   - **Documents** - Upload supporting materials
4. Tap **"Schedule Meeting"**

### 5.3 Managing Meeting Documents

1. Open a meeting you created
2. Tap **"Documents"** section
3. Tap **"Add Document"**
4. Select file from device
5. Document is uploaded and attached

### 5.4 Creating School Polls

1. Go to **Polls** section
2. Tap **"+"** to create new poll
3. Fill in poll details:
   - **Question** - What you're asking
   - **Poll Type** - Select "School"
   - **Options** - Add answer choices
   - **Settings**:
     - Anonymous voting (hide who voted for what)
     - Multiple selection (allow multiple answers)
   - **Duration** - Set start and end dates
4. Tap **"Create Poll"**

### 5.5 Uploading School Documents

1. Go to **Documents** section
2. Tap **"+"** floating button
3. Fill in document details:
   - **Title** - Document name
   - **Description** - What the document contains
   - **Category** - Select appropriate category
   - **File** - Upload from device
   - **Access** - Public or School-only
4. Tap **"Upload"**

---

## 6. Department Staff Guide

Department staff members have a specialized interface for managing department activities.

### 6.1 Department Dashboard

Your home screen shows:
- **Overview Stats** - Members count, meetings count
- **Quick Actions** - Create meeting, upload document
- **Upcoming Meetings** - Next department meetings

### 6.2 Department Navigation

The bottom navigation has 5 tabs:

| Tab | Purpose |
|-----|---------|
| **Dashboard** | Overview and quick actions |
| **Meetings** | Department meetings management |
| **Documents** | Department document library |
| **Members** | View department members |
| **More** | Settings and additional options |

### 6.3 Creating Department Meetings

1. Tap **"Meetings"** tab
2. Tap **"New Meeting"** button
3. Fill in meeting details:
   - **Title** - Meeting name
   - **Date & Time** - When it will occur
   - **Duration** - Length in minutes
   - **Location** - Physical or online
   - **Description** - Purpose of meeting
   - **Agenda** - Discussion points
   - **Documents** - Attach relevant files
4. Tap **"Schedule Meeting"**

### 6.4 Managing Department Documents

#### Uploading Documents
1. Go to **Documents** tab
2. Tap **"Upload Document"**
3. Select file and fill details
4. Tap **"Upload"**

#### Organizing Documents
- Documents are organized by category
- Add tags for better searchability
- Set access permissions as needed

### 6.5 Viewing Department Members

1. Tap **"Members"** tab
2. Browse list of department members
3. Tap a member to view their profile
4. Contact information is displayed

### 6.6 Department Settings

Access from **More** tab:
- **Language** - Change app language
- **Theme** - Switch light/dark mode
- **Logout** - Sign out of account

---

## 7. BEX (County Executive Bureau) Guide

BEX members manage county-level operations and have expanded administrative capabilities.

### 7.1 BEX Dashboard

Your dashboard provides:
- **Platform Analytics** - User statistics, activity metrics
- **Quick Stats** - Key numbers at a glance
- **Recent Activities** - Latest platform events
- **Action Items** - Tasks requiring attention

### 7.2 BEX Navigation

| Tab | Purpose |
|-----|---------|
| **Dashboard** | County overview and analytics |
| **Meetings** | County AG and BEX meetings |
| **Members** | All county council members |
| **More** | GDS, Documents, Settings |

### 7.3 Creating County Meetings

You can create two types of county meetings:

#### County AG (Assembly General)
1. Go to **Meetings** tab
2. Tap **"+"** button
3. Select **"County AG"** as meeting type
4. Fill in all details including:
   - Formal agenda items
   - Required attendance list
   - Supporting documents
5. Tap **"Schedule"**

#### BEX Meeting
1. Same process as above
2. Select **"BEX"** as meeting type
3. These are internal bureau meetings

### 7.4 Managing County Announcements

1. Go to Announcements (from More menu)
2. Tap **"+"** to create
3. Select **"County"** type
4. This announcement goes to ALL schools

### 7.5 GDS (Support Groups) Management

GDS (Grupuri de Suport) are specialized working groups.

#### Viewing GDS
1. Tap **More** → **GDS**
2. Browse list of support groups
3. Each shows: Name, Focus Area, Leader, Member Count

#### GDS Focus Areas
- Environment
- Education
- Culture
- Health
- Social Issues
- Technology
- Sports

#### Managing GDS (if enabled)
- Create new support groups
- Assign group leaders
- Add/remove members
- Set focus areas

### 7.6 Member Management

1. Go to **Members** tab
2. Search or filter members
3. View member details:
   - Contact information
   - School assignment
   - Attendance history
   - Warning records

### 7.7 Attendance Tracking

1. Open a completed meeting
2. Go to **Attendance** section
3. Mark members as:
   - **Present** - Attended the meeting
   - **Absent** - Did not attend
   - **Excused** - Absent with valid reason

---

## 8. Admin (Superadmin) Guide

Superadmins have full platform control and access to the Admin Panel.

### 8.1 Admin Dashboard

The admin dashboard shows:
- **Total Users** - Platform-wide user count
- **Active Users** - Currently active accounts
- **Schools** - Number of registered schools
- **Pending Approvals** - Users awaiting activation
- **Recent Activities** - Latest platform events
- **System Health** - Platform status indicators

### 8.2 Admin Navigation

| Tab | Purpose |
|-----|---------|
| **Dashboard** | Platform overview and analytics |
| **Users** | User management and moderation |
| **Schools** | School administration |
| **GDS** | Support groups overview |

### 8.3 User Management

#### Viewing Users
1. Go to **Users** tab
2. Search by name or email
3. Filter by:
   - School
   - Role
   - Status (Active/Pending/Suspended)

#### User Actions
For each user, you can:

| Action | Description |
|--------|-------------|
| **View Profile** | See full user details |
| **Approve** | Activate pending accounts |
| **Suspend** | Temporarily disable account |
| **Unsuspend** | Reactivate suspended account |
| **Change Role** | Modify user's role |
| **Issue Warning** | Add warning to record |
| **View Warnings** | See warning history |
| **Track Absences** | View absence records |

#### Approving New Users
1. Filter by Status: **Pending**
2. Review user information
3. Tap **"Approve"** to activate
4. User receives notification of approval

#### Suspending a User
1. Find the user in the list
2. Tap to open profile
3. Tap **"Suspend Account"**
4. Enter reason for suspension
5. User is immediately locked out
6. User sees suspension screen when trying to log in

### 8.4 Warning System

Warnings are formal records of policy violations.

#### Warning Types (by severity)
1. **Verbal Warning** - Informal notice
2. **Written Warning** - Formal documentation
3. **Suspension** - Temporary exclusion
4. **Removal** - Permanent exclusion from role

#### Issuing a Warning
1. Open user profile
2. Tap **"Issue Warning"**
3. Select warning type
4. Enter:
   - **Reason** - Brief description
   - **Details** - Full explanation
   - **Expiration** - When warning expires (for suspensions)
5. Tap **"Issue Warning"**
6. Warning is recorded in user's history

#### Resolving a Warning
1. Open user profile
2. Find the active warning
3. Tap **"Resolve"**
4. Enter resolution notes
5. Warning is marked as resolved

### 8.5 Absence Management

Track meeting attendance across the platform.

#### Recording an Absence
1. Open a meeting's attendance record
2. Find the absent member
3. Mark as **Absent** or **Excused**
4. For excused absences:
   - Enter reason
   - Attach justification document (if provided)

#### Viewing Absence History
1. Open user profile
2. Go to **Absences** section
3. View all recorded absences:
   - Meeting name
   - Date
   - Status (Excused/Unexcused)
   - Reason

### 8.6 School Management

#### Viewing Schools
1. Go to **Schools** tab
2. Browse registered schools
3. Search by name

#### School Information
Each school shows:
- School name and code
- Address and city
- School representative
- Student count
- Member list

#### School Details
1. Tap a school to open details
2. View all members from that school
3. See class distribution
4. Contact school representative

### 8.7 System Configuration

#### County Settings
1. Access from admin dashboard
2. Configure platform-wide settings
3. Manage system parameters

#### Notifications Management
1. Go to notifications section
2. Send targeted notifications:
   - Select recipients (all, by role, by school)
   - Choose notification type
   - Write message
3. Tap **"Send"**

---

## 9. Feature Reference

### 9.1 Meeting Types

| Type | Created By | Visible To | Purpose |
|------|-----------|------------|---------|
| **County AG** | BEX, Admin | All users | County assembly meetings |
| **BEX** | BEX, Admin | BEX members | Executive bureau meetings |
| **Department** | Department staff | Department members | Department coordination |
| **School** | School Rep | School members | School council meetings |

### 9.2 Document Categories

| Category | Romanian Name | Content Type |
|----------|---------------|--------------|
| Student Statute | Statutul Elevului | Student rights and rules |
| Regulations | Regulamente | Official regulations |
| Methodologies | Metodologii | Procedures and methods |
| Forms | Formulare | Official forms and templates |

### 9.3 Initiative Stages

| Stage | Who Can Act | Available Actions |
|-------|-------------|-------------------|
| Draft | Author only | Edit, Submit, Delete |
| Submitted | Admins | Move to Review |
| Review | Admins | Move to Debate, Reject |
| Debate | All users | Comment, Support |
| Voting | All users | Vote (For/Against/Abstain) |
| Adopted | View only | Final - approved |
| Rejected | View only | Final - with reason |

### 9.4 Notification Types

| Type | Trigger | Content |
|------|---------|---------|
| Meeting Reminder | Before scheduled meeting | Meeting details and time |
| New Announcement | Announcement published | Title and summary |
| Initiative Update | Status change | New status and details |
| Poll Reminder | Poll requires vote | Poll question |
| System Alert | Admin action | Alert message |

### 9.5 Supported File Types

| Extension | Type | Max Size |
|-----------|------|----------|
| .pdf | Documents | 10 MB |
| .docx | Word Documents | 10 MB |
| .xlsx | Excel Spreadsheets | 10 MB |
| .png | Images | 5 MB |
| .jpg/.jpeg | Images | 5 MB |

---

## 10. Troubleshooting & FAQ

### 10.1 Common Issues

#### "I can't log in"
- Check your email and password are correct
- Use "Forgot Password" if needed
- Ensure your account is approved (not pending)
- Check if your account is suspended

#### "I don't see the create button"
- Only certain roles can create content
- Check your role permissions in Section 3
- School Reps create school content
- BEX creates county content

#### "Meetings aren't showing"
- Pull down to refresh the list
- Check your filter settings (All vs Upcoming)
- Ensure you're viewing the correct meeting type

#### "I can't vote on an initiative"
- Voting is only available during the Voting stage
- Each user can only vote once
- Check if the voting period has ended

#### "Documents won't download"
- Check your internet connection
- Ensure you have storage space
- Try again in a few moments

#### "Notifications aren't working"
- Check notification permissions in phone settings
- Ensure notifications are enabled in app settings
- Check if Do Not Disturb is enabled

### 10.2 Frequently Asked Questions

**Q: How do I change my password?**
A: Go to Profile → Settings → Privacy & Security → Change Password

**Q: How do I change my school?**
A: Contact your admin - school changes require admin approval

**Q: Can I delete my account?**
A: Contact the platform administrator for account deletion requests

**Q: How do I become a School Representative?**
A: School Representatives are appointed by school administration and approved by the platform admin

**Q: Why is my account pending?**
A: New accounts require admin approval. You'll be notified when approved.

**Q: How long do polls stay active?**
A: Poll duration is set by the creator (School Rep, BEX, or Admin)

**Q: Can I change my vote?**
A: No, votes on initiatives and polls cannot be changed once submitted

**Q: How do I report a problem?**
A: Go to Profile → Help & Support to report issues

### 10.3 Getting Help

If you need assistance:

1. **In-App Help** - Profile → Help & Support
2. **Contact Admin** - Reach out to your School Representative or BEX member
3. **Email Support** - Contact the platform administrator

---

## Appendix A: Glossary

| Term | Definition |
|------|------------|
| **CJE** | Consiliul Județean al Elevilor (County Student Council) |
| **BEX** | Biroul Executiv (Executive Bureau) |
| **GDS** | Grupuri de Suport (Support Groups) |
| **AG** | Adunarea Generală (General Assembly) |
| **School Rep** | School Representative - school-level administrator |
| **Initiative** | A formal proposal submitted for council consideration |
| **Poll** | A voting mechanism for gathering opinions |

---

## Appendix B: Keyboard Shortcuts (Tablet/Desktop)

If using the app on a tablet or through desktop:

| Shortcut | Action |
|----------|--------|
| Pull down | Refresh content |
| Long press | Additional options menu |
| Swipe left | Quick actions (where available) |

---

## Document Information

- **Application:** CJE Platform
- **Platform:** Android (iOS coming soon)
- **Minimum Android Version:** 6.0 (API 23)
- **Languages:** Romanian, English

---

*This guide is maintained by the CJE Platform development team. For updates and corrections, please contact the platform administrator.*
