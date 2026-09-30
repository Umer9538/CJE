import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/models.dart';

/// Service for exporting quarterly activity data to Excel
class DataExportService {
  final FirebaseFirestore _firestore;

  DataExportService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get the start and end dates of the current quarter
  static ({DateTime start, DateTime end}) getCurrentQuarterRange() {
    final now = DateTime.now();
    final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
    final start = DateTime(now.year, quarterMonth, 1);
    final end = DateTime(now.year, quarterMonth + 3, 1)
        .subtract(const Duration(seconds: 1));
    return (start: start, end: end);
  }

  /// Get quarter label (e.g. "Q1 2026")
  static String getQuarterLabel() {
    final now = DateTime.now();
    final quarter = ((now.month - 1) ~/ 3) + 1;
    return 'Q$quarter ${now.year}';
  }

  /// Fetch all content counts for the current quarter in a county
  Future<Map<String, int>> getQuarterlyContentCounts(String countyId) async {
    final range = getCurrentQuarterRange();
    final startTs = Timestamp.fromDate(range.start);
    final endTs = Timestamp.fromDate(range.end);

    final results = await Future.wait([
      _countDocuments('announcements', countyId, startTs, endTs),
      _countDocuments('meetings', countyId, startTs, endTs),
      _countDocuments('polls', countyId, startTs, endTs),
      _countDocuments('initiatives', countyId, startTs, endTs),
    ]);

    return {
      'announcements': results[0],
      'meetings': results[1],
      'polls': results[2],
      'initiatives': results[3],
    };
  }

  Future<int> _countDocuments(
    String collection,
    String countyId,
    Timestamp start,
    Timestamp end,
  ) async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      final userCounty = countyId.toLowerCase();
      return snapshot.docs.where((doc) {
        final data = doc.data();
        // County filter
        final docCounty = (data['countyId'] as String?) ?? '';
        if (docCounty.isNotEmpty) {
          final dc = docCounty.toLowerCase();
          if (!userCounty.contains(dc) && !dc.contains(userCounty)) {
            return false;
          }
        }
        // Date filter
        final createdAt = data['createdAt'];
        if (createdAt is Timestamp) {
          return createdAt.compareTo(start) >= 0 &&
              createdAt.compareTo(end) <= 0;
        }
        return false;
      }).length;
    } catch (e) {
      debugPrint('Error counting $collection: $e');
      return 0;
    }
  }

  /// Generate and share an Excel report for the current quarter
  Future<void> generateAndShareReport(String countyId) async {
    final range = getCurrentQuarterRange();
    final startTs = Timestamp.fromDate(range.start);
    final endTs = Timestamp.fromDate(range.end);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final quarterLabel = getQuarterLabel();

    final excel = Excel.createExcel();

    // Fetch all data
    final announcements =
        await _fetchFiltered('announcements', countyId, startTs, endTs);
    final meetings =
        await _fetchFiltered('meetings', countyId, startTs, endTs);
    final polls =
        await _fetchFiltered('polls', countyId, startTs, endTs);
    final initiatives =
        await _fetchFiltered('initiatives', countyId, startTs, endTs);

    // --- Summary Sheet ---
    final summarySheet = excel['Summary'];
    summarySheet.appendRow([
      TextCellValue('CJE Activity Report'),
    ]);
    summarySheet.appendRow([
      TextCellValue('Quarter: $quarterLabel'),
    ]);
    summarySheet.appendRow([
      TextCellValue(
          'Period: ${DateFormat('dd/MM/yyyy').format(range.start)} - ${DateFormat('dd/MM/yyyy').format(range.end)}'),
    ]);
    summarySheet.appendRow([
      TextCellValue('County: $countyId'),
    ]);
    summarySheet.appendRow([TextCellValue('')]);
    summarySheet.appendRow([
      TextCellValue('Category'),
      TextCellValue('Count'),
    ]);
    summarySheet.appendRow([
      TextCellValue('Announcements'),
      IntCellValue(announcements.length),
    ]);
    summarySheet.appendRow([
      TextCellValue('Meetings'),
      IntCellValue(meetings.length),
    ]);
    summarySheet.appendRow([
      TextCellValue('Polls'),
      IntCellValue(polls.length),
    ]);
    summarySheet.appendRow([
      TextCellValue('Initiatives'),
      IntCellValue(initiatives.length),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total'),
      IntCellValue(announcements.length +
          meetings.length +
          polls.length +
          initiatives.length),
    ]);

    // --- Announcements Sheet ---
    final annSheet = excel['Announcements'];
    annSheet.appendRow([
      TextCellValue('Title'),
      TextCellValue('Type'),
      TextCellValue('Author'),
      TextCellValue('School'),
      TextCellValue('Published'),
      TextCellValue('Created At'),
    ]);
    for (final doc in announcements) {
      final a = AnnouncementModel.fromFirestore(doc);
      annSheet.appendRow([
        TextCellValue(a.title),
        TextCellValue(a.type.name),
        TextCellValue(a.authorName),
        TextCellValue(a.schoolName ?? ''),
        TextCellValue(a.isPublished ? 'Yes' : 'No'),
        TextCellValue(dateFormat.format(a.createdAt)),
      ]);
    }

    // --- Meetings Sheet ---
    final meetSheet = excel['Meetings'];
    meetSheet.appendRow([
      TextCellValue('Title'),
      TextCellValue('Type'),
      TextCellValue('Date'),
      TextCellValue('Location'),
      TextCellValue('Created By'),
      TextCellValue('School'),
      TextCellValue('Completed'),
      TextCellValue('Attendees'),
    ]);
    for (final doc in meetings) {
      final m = MeetingModel.fromFirestore(doc);
      meetSheet.appendRow([
        TextCellValue(m.title),
        TextCellValue(m.type.name),
        TextCellValue(dateFormat.format(m.dateTime)),
        TextCellValue(m.isOnline ? (m.onlineLink ?? 'Online') : (m.location ?? '')),
        TextCellValue(m.createdByName),
        TextCellValue(m.schoolName ?? ''),
        TextCellValue(m.isCompleted ? 'Yes' : 'No'),
        IntCellValue(m.attendeeIds.length),
      ]);
    }

    // --- Polls Sheet ---
    final pollSheet = excel['Polls'];
    pollSheet.appendRow([
      TextCellValue('Question'),
      TextCellValue('Type'),
      TextCellValue('Created By'),
      TextCellValue('School'),
      TextCellValue('Start Date'),
      TextCellValue('End Date'),
      TextCellValue('Total Votes'),
      TextCellValue('Options'),
    ]);
    for (final doc in polls) {
      final p = PollModel.fromFirestore(doc);
      pollSheet.appendRow([
        TextCellValue(p.question),
        TextCellValue(p.type.name),
        TextCellValue(p.createdByName),
        TextCellValue(p.schoolName ?? ''),
        TextCellValue(dateFormat.format(p.startDate)),
        TextCellValue(dateFormat.format(p.endDate)),
        IntCellValue(p.totalVotes),
        TextCellValue(p.options.map((o) => '${o.text}(${o.voteCount})').join(', ')),
      ]);
    }

    // --- Initiatives Sheet ---
    final initSheet = excel['Initiatives'];
    initSheet.appendRow([
      TextCellValue('Title'),
      TextCellValue('Type'),
      TextCellValue('Status'),
      TextCellValue('Author'),
      TextCellValue('School'),
      TextCellValue('Supporters'),
      TextCellValue('Votes For'),
      TextCellValue('Votes Against'),
      TextCellValue('Votes Abstain'),
      TextCellValue('Created At'),
    ]);
    for (final doc in initiatives) {
      final i = InitiativeModel.fromFirestore(doc);
      initSheet.appendRow([
        TextCellValue(i.title),
        TextCellValue(i.type.name),
        TextCellValue(i.status.name),
        TextCellValue(i.authorName),
        TextCellValue(i.schoolName ?? ''),
        IntCellValue(i.supportCount),
        IntCellValue(i.votesFor ?? 0),
        IntCellValue(i.votesAgainst ?? 0),
        IntCellValue(i.votesAbstain ?? 0),
        TextCellValue(dateFormat.format(i.createdAt)),
      ]);
    }

    // Remove default sheet if exists
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Save file
    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Failed to generate Excel file');
    }

    final dir = await getTemporaryDirectory();
    final fileName =
        'CJE_Activity_${quarterLabel.replaceAll(' ', '_')}_${countyId.replaceAll(' ', '_')}.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    // Share file
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'CJE Activity Report - $quarterLabel',
      ),
    );
  }

  /// Fetch documents filtered by county and date range
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchFiltered(
    String collection,
    String countyId,
    Timestamp start,
    Timestamp end,
  ) async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      final userCounty = countyId.toLowerCase();
      return snapshot.docs.where((doc) {
        final data = doc.data();
        // County filter
        final docCounty = (data['countyId'] as String?) ?? '';
        if (docCounty.isNotEmpty) {
          final dc = docCounty.toLowerCase();
          if (!userCounty.contains(dc) && !dc.contains(userCounty)) {
            return false;
          }
        }
        // Date filter
        final createdAt = data['createdAt'];
        if (createdAt is Timestamp) {
          return createdAt.compareTo(start) >= 0 &&
              createdAt.compareTo(end) <= 0;
        }
        return false;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching $collection: $e');
      return [];
    }
  }
}
