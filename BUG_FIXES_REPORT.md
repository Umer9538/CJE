# BUG REPORT & ADJUSTMENTS LIST - STATUS UPDATE
**Date: December 30, 2025**

---

## I. TARGETING & LOGIC

**Missing School Selection (Announcements, Initiatives, Polls etc):**
* When I select the "School" option/scope, a Dropdown Menu must appear to select the school.
* **Status:** NOT FIXED - Needs implementation.

**Document Logic:**
* Categories: Update document tags to: Regulamente, Ghiduri, Utile, Rapoarte.
* **Status:** NOT FIXED - Needs implementation.

* School Documents: When I toggle "Document Școlar", a Dropdown should appear to select school(s).
* **Status:** NOT FIXED - Needs implementation.

* Public Documents: The "Document Public" toggle should make document visible to all users.
* **Status:** NOT FIXED - Needs verification.

---

## II. BROKEN FUNCTIONALITY

**3. User Creation Failure:**
* Adding a new user manually shows red error stripe with no text.
* Google Sign-up and manual entry both fail.
* **Status:** NOT FIXED - Critical issue, needs investigation.

**4. File Uploads (System-wide):**
* Uploading documents/images is broken everywhere in the app.
* **Status:** PARTIALLY FIXED - Documents upload works now and shows in the list after upload. Attachments in Announcements can now be downloaded/opened.

**5. Notifications:**
* Push notifications are not working at all.
* **Status:** NOT FIXED - Needs implementation.

**6. Initiatives & Polls Interaction:**
* Comments: Comments feature is broken for Initiatives and Polls.
* **Status:** NOT FIXED - Needs investigation.

* Voting (Initiatives): Voting does not work. Voting screen is white (ignoring Dark Mode).
* **Status:** NOT FIXED - Needs implementation.

* Support Button: The "Support" feature on Initiatives is broken/missing.
* **Status:** NOT FIXED - Needs implementation.

* Tags: Tags on initiatives are invisible.
* **Status:** NOT FIXED - Needs fix.

* Multiple Choice: In Polls, "Multiple Votes" functionality does not work.
* **Status:** NOT FIXED - Needs implementation.

**7. County Settings:**
* The "County Settings" (Setări Județ) screen is just a blank white screen.
* **Status:** FIXED - Screen now shows properly with all translations (Select County, Contact Info, Social Media, Save button).

**8. Help & Support:**
* The button does not work.
* **Status:** NOT FIXED - Button should be removed if no functionality planned.

**9. CSV Import:**
* Please verify the "Import CSV" function works correctly.
* **Status:** NOT VERIFIED - Needs testing.

---

## III. MEETINGS (Management & UI)

**10. Attendance/Participants:**
* After a meeting is published, I need to see the participant list.
* Feature: Add participants manually after meeting is created.
* **Status:** NOT FIXED - Needs implementation.

**11. Editing UI Bug:**
* When editing a meeting in Dark Mode, input fields are white, text unreadable.
* **Status:** NOT FIXED - Needs dark mode support for meeting edit screen.

**12. Layout:**
* Meetings interface has layout issues; titles and content do not fit properly.
* **Status:** NOT FIXED - Needs UI adjustments.

---

## IV. UI & LOCALIZATION

**13. Icon Visibility & Uniformity:**
* Some icons are blue, invisible or hard to see in Dark Mode.
* All icons should be Yellow/Gold for visibility.
* **Status:** PARTIALLY FIXED - GDS screen icons and colors fixed for dark mode. Other screens may still need updates.

**14. Polls UI:**
* Titles are cutting off/overflowing.
* **Status:** NOT FIXED - Needs container fix.

**15. User Profile:**
* When viewing a user, I need to see ALL details including School and Class.
* **Status:** NOT FIXED - School and Class info missing from profile view.

**16. Translations (English vs. Romanian):**
* Start Screen and Bottom Navigation Menu are still in English when app is set to Romanian.
* **Status:** PARTIALLY FIXED - Added County Settings translations. Some screens may still need translation updates.

---

## ADDITIONAL FIXES (This Session)

**Home Button from Profile:**
* When on Profile screen and clicking Home button, nothing happened.
* **Status:** FIXED - Navigation now works correctly.

**Initiative Detail Tabs:**
* Tab labels (Overview, Impact, Comments, Management) were cut off on small screens.
* **Status:** FIXED - Tabs are now scrollable.

**Duplicate Settings:**
* Same settings appeared in both Menu and Profile screens.
* **Status:** FIXED - Settings consolidated to Menu only. Profile only shows Manage Users and Privacy & Security.

**Announcement Attachments:**
* Attachments could not be downloaded or opened.
* **Status:** FIXED - Tapping attachment now opens/downloads the file.

---

## SUMMARY

| Category | Total Issues | Fixed | Partially Fixed | Not Fixed |
|----------|-------------|-------|-----------------|-----------|
| Targeting & Logic | 4 | 0 | 0 | 4 |
| Broken Functionality | 7 | 1 | 1 | 5 |
| Meetings | 3 | 0 | 0 | 3 |
| UI & Localization | 4 | 0 | 2 | 2 |
| Additional (This Session) | 4 | 4 | 0 | 0 |
| **TOTAL** | **22** | **5** | **3** | **14** |

---

**Next Priority Items:**
1. User Creation Failure (Critical)
2. Push Notifications
3. Voting functionality
4. Meeting dark mode and participant list
5. School selection dropdown for targeting
