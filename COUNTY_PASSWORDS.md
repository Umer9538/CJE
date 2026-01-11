# County Registration Passwords

This document contains the registration passwords for each county in the CJE (Student Council) app.

## Purpose
These passwords are required during user registration to verify that the user belongs to the selected county. Only authorized personnel should have access to these passwords and distribute them to eligible students.

## Security Notice
⚠️ **IMPORTANT**: This file contains sensitive information. Do not commit this file to version control or share it publicly.

## Current County Passwords

| County / City | Password | Status |
|---------------|----------|--------|
| București | BUC2024 | Active |
| Cluj-Napoca | CLJ2024 | Active |
| Timișoara | TIM2024 | Active |
| Iași | IAS2024 | Active |
| Constanța | CTA2024 | Active |
| Craiova | CRA2024 | Active |
| Brașov | BV2024 | Active |
| Galați | GL2024 | Active |
| Ploiești | PH2024 | Active |
| Oradea | BH2024 | Active |

## Missing Counties

**⚠️ ATTENTION**: The client review indicates that there should be **41 counties total**. Currently, only **10 counties** are configured in the system.

**Missing: 31 counties**

The client needs to provide:
1. Complete list of all 41 Romanian counties they want to include
2. Registration password for each county

### Suggested Counties to Add:
Based on Romanian administrative divisions, here are the remaining 31 counties that may need to be added:

1. Alba
2. Arad
3. Argeș
4. Bacău
5. Bihor
6. Bistrița-Năsăud
7. Botoșani
8. Brăila
9. Buzău
10. Caraș-Severin
11. Călărași
12. Dâmbovița
13. Dolj (Craiova is already included)
14. Giurgiu
15. Gorj
16. Harghita
17. Hunedoara
18. Ialomița
19. Ilfov
20. Maramureș
21. Mehedinți
22. Mureș
23. Neamț
24. Olt
25. Prahova (Ploiești is already included)
26. Sălaj
27. Satu Mare
28. Sibiu
29. Suceava
30. Teleorman
31. Tulcea
32. Vâlcea
33. Vaslui
34. Vrancea

**Note**: Some counties may have their capital city already listed (e.g., Craiova for Dolj, Ploiești for Prahova). The client needs to clarify whether they want county names or city names, and provide the complete list with passwords.

## How to Update

### Adding a New County

1. **In code** - Update both files:
   - `lib/views/screens/auth/register_screen.dart` (lines 113-138)
   - `lib/views/screens/auth/profile_setup_screen.dart` (lines 46-57, 32-43)

2. **Add to _cityPasswords map**:
```dart
static const Map<String, String> _cityPasswords = {
  // ... existing entries ...
  'NewCounty': 'NEW2024',  // Add new county password
};
```

3. **Add to _cities list**:
```dart
final List<String> _cities = [
  // ... existing entries ...
  'NewCounty',  // Add new county name
];
```

4. **Update this document** with the new county and password

### Password Format Convention

Current passwords follow this pattern:
- **Format**: `[3-LETTER_CODE]2024`
- **Example**: `BUC2024` for București, `CLJ2024` for Cluj-Napoca

Consider updating the year (2024) annually for security.

## Distribution Guidelines

1. **County Coordinators**: Should receive only their county's password
2. **Regional Admins**: May receive multiple county passwords for their region
3. **Super Admins**: Have access to all county passwords via this document

## Password Change Procedure

When changing a county password:
1. Update the password in both registration screens (code)
2. Update this documentation
3. Notify all county coordinators and regional admins
4. Inform all pending registrants about the password change

## Contact

For password requests or issues, contact:
- **System Administrator**: [To be provided]
- **Technical Support**: [To be provided]

---

**Last Updated**: 2025-12-16
**Document Version**: 1.0
**Maintained By**: Development Team
