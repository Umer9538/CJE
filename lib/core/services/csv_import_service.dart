import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

import '../../models/models.dart';
import '../constants/enums.dart';

/// Result of CSV import operation
class CSVImportResult {
  final List<UserModel> successfulUsers;
  final List<CSVImportError> errors;
  final int totalRows;

  CSVImportResult({
    required this.successfulUsers,
    required this.errors,
    required this.totalRows,
  });

  int get successCount => successfulUsers.length;
  int get errorCount => errors.length;
  bool get hasErrors => errors.isNotEmpty;
  bool get hasSuccess => successfulUsers.isNotEmpty;
}

/// Error during CSV import
class CSVImportError {
  final int rowNumber;
  final String message;
  final Map<String, String>? rowData;

  CSVImportError({
    required this.rowNumber,
    required this.message,
    this.rowData,
  });

  @override
  String toString() => 'Row $rowNumber: $message';
}

/// Service for importing users from CSV files
class CSVImportService {
  /// Expected CSV headers (case-insensitive)
  static const List<String> requiredHeaders = ['email', 'fullname', 'city'];
  static const List<String> optionalHeaders = [
    'phonenumber',
    'role',
    'schoolid',
    'schoolname',
    'classname',
    'department',
  ];

  /// Parse CSV content and return user models
  ///
  /// CSV format:
  /// email,fullName,phoneNumber,city,role,schoolId,schoolName,className,department
  /// john@example.com,John Doe,0712345678,Cluj,student,school123,High School #1,12A,
  ///
  /// Role values: student, classRep, schoolRep, department.
  /// Leadership roles (bex and superadmin) are assigned separately by an
  /// authorised administrator and cannot be created through bulk import.
  /// Department values: secondaryEducation, iptcv, vulnerableGroups, specialEducation, volunteering, prCommunications
  CSVImportResult parseCSV(String csvContent) {
    final List<UserModel> successfulUsers = [];
    final List<CSVImportError> errors = [];

    try {
      final lines = const LineSplitter().convert(csvContent.trim());

      if (lines.isEmpty) {
        errors.add(CSVImportError(rowNumber: 0, message: 'CSV file is empty'));
        return CSVImportResult(
          successfulUsers: successfulUsers,
          errors: errors,
          totalRows: 0,
        );
      }

      // Parse headers
      final headers = _parseCSVLine(
        lines[0],
      ).map((h) => h.toLowerCase().trim()).toList();

      // Validate required headers
      for (final required in requiredHeaders) {
        if (!headers.contains(required)) {
          errors.add(
            CSVImportError(
              rowNumber: 1,
              message: 'Missing required header: $required',
            ),
          );
        }
      }

      if (errors.isNotEmpty) {
        return CSVImportResult(
          successfulUsers: successfulUsers,
          errors: errors,
          totalRows: lines.length - 1,
        );
      }

      // Create header index map
      final headerIndex = <String, int>{};
      for (var i = 0; i < headers.length; i++) {
        headerIndex[headers[i]] = i;
      }

      // Parse data rows
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        try {
          final values = _parseCSVLine(line);
          final rowData = <String, String>{};

          // Map values to headers
          for (var j = 0; j < values.length && j < headers.length; j++) {
            rowData[headers[j]] = values[j].trim();
          }

          // Validate and create user
          final user = _createUserFromRow(rowData, i + 1, errors);
          if (user != null) {
            successfulUsers.add(user);
          }
        } catch (e) {
          errors.add(
            CSVImportError(
              rowNumber: i + 1,
              message: 'Failed to parse row: $e',
            ),
          );
        }
      }

      return CSVImportResult(
        successfulUsers: successfulUsers,
        errors: errors,
        totalRows: lines.length - 1,
      );
    } catch (e) {
      debugPrint('CSV parsing error: $e');
      errors.add(
        CSVImportError(rowNumber: 0, message: 'Failed to parse CSV: $e'),
      );
      return CSVImportResult(
        successfulUsers: successfulUsers,
        errors: errors,
        totalRows: 0,
      );
    }
  }

  /// Parse a single CSV line, handling quoted values
  List<String> _parseCSVLine(String line) {
    final List<String> result = [];
    final buffer = StringBuffer();
    var inQuotes = false;
    var i = 0;

    while (i < line.length) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          buffer.write('"');
          i++;
        } else {
          // Toggle quotes
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }

      i++;
    }

    result.add(buffer.toString());
    return result;
  }

  /// Create a UserModel from parsed row data
  UserModel? _createUserFromRow(
    Map<String, String> rowData,
    int rowNumber,
    List<CSVImportError> errors,
  ) {
    // Get required fields
    final email = rowData['email']?.trim() ?? '';
    final fullName = rowData['fullname']?.trim() ?? '';

    // Validate required fields
    if (email.isEmpty) {
      errors.add(
        CSVImportError(
          rowNumber: rowNumber,
          message: 'Email is required',
          rowData: rowData,
        ),
      );
      return null;
    }

    if (!_isValidEmail(email)) {
      errors.add(
        CSVImportError(
          rowNumber: rowNumber,
          message: 'Invalid email format: $email',
          rowData: rowData,
        ),
      );
      return null;
    }

    if (fullName.isEmpty) {
      errors.add(
        CSVImportError(
          rowNumber: rowNumber,
          message: 'Full name is required',
          rowData: rowData,
        ),
      );
      return null;
    }

    // Parse optional fields
    final phoneNumber = rowData['phonenumber']?.trim();

    // Validate county: must match the fixed list exactly. No guessing, no
    // auto-correction -- a wrong value here silently partitions the user out
    // of their county for every rule that compares city/countyId.
    final city = rowData['city']?.trim();
    if (city == null || city.isEmpty) {
      errors.add(
        CSVImportError(
          rowNumber: rowNumber,
          message: 'County is required',
          rowData: rowData,
        ),
      );
      return null;
    }
    if (!romanianCounties.contains(city)) {
      errors.add(
        CSVImportError(
          rowNumber: rowNumber,
          message:
              'Invalid county: "$city". '
              'Accepted values (exact match, case-sensitive): '
              '${romanianCounties.join(', ')}',
          rowData: rowData,
        ),
      );
      return null;
    }

    final schoolId = rowData['schoolid']?.trim();
    final schoolName = rowData['schoolname']?.trim();
    final className = rowData['classname']?.trim();

    // Parse role
    UserRole role = UserRole.student;
    final roleStr = rowData['role']?.trim().toLowerCase();
    if (roleStr != null && roleStr.isNotEmpty) {
      final parsedRole = _parseRole(roleStr);
      if (parsedRole == null) {
        errors.add(
          CSVImportError(
            rowNumber: rowNumber,
            message:
                'Invalid role: $roleStr. Valid values: student, classRep, schoolRep, department, bex',
            rowData: rowData,
          ),
        );
        return null;
      }
      // Keep the client validation aligned with the server-side allowlist.
      // BEX and superadmin privileges must never be granted through a CSV.
      if (parsedRole == UserRole.bex || parsedRole == UserRole.superadmin) {
        errors.add(
          CSVImportError(
            rowNumber: rowNumber,
            message:
                'Cannot import BEX or superadmin users. Assign leadership roles separately from the admin panel.',
            rowData: rowData,
          ),
        );
        return null;
      }
      role = parsedRole;
    }

    // Parse department (only for department role)
    DepartmentType? department;
    final departmentStr = rowData['department']?.trim().toLowerCase();
    if (departmentStr != null && departmentStr.isNotEmpty) {
      department = _parseDepartment(departmentStr);
      if (department == null) {
        errors.add(
          CSVImportError(
            rowNumber: rowNumber,
            message:
                'Invalid department: $departmentStr. Valid values: secondaryEducation, iptcv, vulnerableGroups, specialEducation, volunteering, prCommunications',
            rowData: rowData,
          ),
        );
        return null;
      }
    }

    // Create user model
    final now = DateTime.now();
    return UserModel(
      id: '', // Will be assigned by Firestore
      email: email,
      fullName: fullName,
      phoneNumber: phoneNumber?.isNotEmpty == true ? phoneNumber : null,
      city: city,
      role: role,
      status: UserStatus.pending, // New imports are pending approval
      schoolId: schoolId?.isNotEmpty == true ? schoolId : null,
      schoolName: schoolName?.isNotEmpty == true ? schoolName : null,
      className: className?.isNotEmpty == true ? className : null,
      department: department,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Parse role string to UserRole enum
  UserRole? _parseRole(String roleStr) {
    final normalized = roleStr
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '');
    switch (normalized) {
      case 'student':
        return UserRole.student;
      case 'classrep':
      case 'classlead':
      case 'classchief':
        return UserRole.classRep;
      case 'schoolrep':
      case 'schoollead':
      case 'schoolchief':
        return UserRole.schoolRep;
      case 'department':
      case 'dept':
        return UserRole.department;
      case 'bex':
        return UserRole.bex;
      case 'superadmin':
      case 'admin':
        return UserRole.superadmin;
      default:
        return null;
    }
  }

  /// Parse department string to DepartmentType enum
  DepartmentType? _parseDepartment(String departmentStr) {
    final normalized = departmentStr
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '');
    switch (normalized) {
      case 'secondaryeducation':
      case 'gimnazial':
      case 'secondary':
        return DepartmentType.secondaryEducation;
      case 'iptcv':
        return DepartmentType.iptcv;
      case 'vulnerablegroups':
      case 'vulnerable':
      case 'minorities':
        return DepartmentType.vulnerableGroups;
      case 'specialeducation':
      case 'special':
        return DepartmentType.specialEducation;
      case 'volunteering':
      case 'voluntariat':
        return DepartmentType.volunteering;
      case 'prcommunications':
      case 'pr':
      case 'communications':
        return DepartmentType.prCommunications;
      default:
        return null;
    }
  }

  /// Parse Excel file content and return user models
  ///
  /// Supports both .xls and .xlsx formats
  /// First row must contain headers (same as CSV format)
  CSVImportResult parseExcel(Uint8List bytes) {
    final List<UserModel> successfulUsers = [];
    final List<CSVImportError> errors = [];

    try {
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        errors.add(
          CSVImportError(rowNumber: 0, message: 'Excel file has no sheets'),
        );
        return CSVImportResult(
          successfulUsers: successfulUsers,
          errors: errors,
          totalRows: 0,
        );
      }

      // Get first sheet
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      if (sheet.rows.isEmpty) {
        errors.add(
          CSVImportError(rowNumber: 0, message: 'Excel sheet is empty'),
        );
        return CSVImportResult(
          successfulUsers: successfulUsers,
          errors: errors,
          totalRows: 0,
        );
      }

      // Parse headers from first row
      final headerRow = sheet.rows[0];
      final headers = headerRow
          .map((cell) => cell?.value?.toString().toLowerCase().trim() ?? '')
          .toList();

      // Validate required headers
      for (final required in requiredHeaders) {
        if (!headers.contains(required)) {
          errors.add(
            CSVImportError(
              rowNumber: 1,
              message: 'Missing required header: $required',
            ),
          );
        }
      }

      if (errors.isNotEmpty) {
        return CSVImportResult(
          successfulUsers: successfulUsers,
          errors: errors,
          totalRows: sheet.rows.length - 1,
        );
      }

      // Create header index map
      final headerIndex = <String, int>{};
      for (var i = 0; i < headers.length; i++) {
        if (headers[i].isNotEmpty) {
          headerIndex[headers[i]] = i;
        }
      }

      // Parse data rows (skip header row)
      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        // Skip empty rows
        if (row.every(
          (cell) =>
              cell?.value == null || cell!.value.toString().trim().isEmpty,
        )) {
          continue;
        }

        try {
          final rowData = <String, String>{};

          // Map values to headers
          for (var j = 0; j < row.length && j < headers.length; j++) {
            final cellValue = row[j]?.value?.toString().trim() ?? '';
            if (headers[j].isNotEmpty) {
              rowData[headers[j]] = cellValue;
            }
          }

          // Validate and create user
          final user = _createUserFromRow(rowData, i + 1, errors);
          if (user != null) {
            successfulUsers.add(user);
          }
        } catch (e) {
          errors.add(
            CSVImportError(
              rowNumber: i + 1,
              message: 'Failed to parse row: $e',
            ),
          );
        }
      }

      return CSVImportResult(
        successfulUsers: successfulUsers,
        errors: errors,
        totalRows: sheet.rows.length - 1,
      );
    } catch (e) {
      debugPrint('Excel parsing error: $e');
      errors.add(
        CSVImportError(rowNumber: 0, message: 'Failed to parse Excel file: $e'),
      );
      return CSVImportResult(
        successfulUsers: successfulUsers,
        errors: errors,
        totalRows: 0,
      );
    }
  }

  /// Parse file based on extension (CSV or Excel)
  Future<CSVImportResult> parseFile(String filePath) async {
    final file = File(filePath);
    final extension = filePath.toLowerCase().split('.').last;

    if (extension == 'csv') {
      final content = await file.readAsString();
      return parseCSV(content);
    } else if (extension == 'xls' || extension == 'xlsx') {
      final bytes = await file.readAsBytes();
      return parseExcel(bytes);
    } else {
      return CSVImportResult(
        successfulUsers: [],
        errors: [
          CSVImportError(
            rowNumber: 0,
            message:
                'Unsupported file format: .$extension. Please use .csv, .xls, or .xlsx',
          ),
        ],
        totalRows: 0,
      );
    }
  }

  /// Generate a sample CSV template
  static String generateTemplate() {
    const headers =
        'email,fullName,phoneNumber,city,role,schoolId,schoolName,className,department';
    const example1 =
        'student1@school.ro,Ion Popescu,,Cluj,student,school1,Colegiul National Example,12A,';
    const example2 =
        'rep@school.ro,Maria Ionescu,,Cluj,classRep,school1,Colegiul National Example,11B,';
    const example3 =
        'dept@school.ro,Alexandru Marin,,Cluj,department,school1,Colegiul National Example,10C,prCommunications';

    return '$headers\n$example1\n$example2\n$example3';
  }

  /// Get template description for display
  static String getTemplateDescription() {
    return '''
Supported formats: CSV, XLS, XLSX

Required columns:
- email: User's email address
- fullName: User's full name
- city: Romanian county name (for example: Cluj, Sibiu, București)

Optional columns:
- phoneNumber: Phone number
- role: student, classRep, schoolRep, department (default: student)
- schoolId: School document ID
- schoolName: School name (display)
- className: Class name (e.g., 12A, 11B)
- department: secondaryEducation, iptcv, vulnerableGroups, specialEducation, volunteering, prCommunications (only for department role)

Notes:
- First row must contain headers
- Imported users will have 'pending' status
- At first sign-in, every imported user must personally acknowledge the Privacy Policy and declare the required age band before approval
- Email addresses must be unique
- Use UTF-8 encoding for CSV files
''';
  }
}
