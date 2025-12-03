import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/models.dart';
import '../constants/enums.dart';

/// Repository for meeting-related Firestore operations
class MeetingRepository {
  final FirebaseFirestore _firestore;

  MeetingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('meetings');

  CollectionReference<Map<String, dynamic>> get _attendanceCollection =>
      _firestore.collection('meeting_attendance');

  /// Get all meetings
  Future<List<MeetingModel>> getMeetings({
    MeetingType? type,
    String? schoolId,
    DepartmentType? department,
    bool upcomingOnly = false,
    int limit = 20,
  }) async {
    try {
      // Simple query without orderBy to avoid index requirement
      final snapshot = await _collection.get();

      final now = DateTime.now();
      List<MeetingModel> meetings = snapshot.docs
          .map((doc) => MeetingModel.fromFirestore(doc))
          .where((m) {
            if (type != null && m.type != type) return false;
            if (schoolId != null && m.type == MeetingType.school && m.schoolId != schoolId) return false;
            if (department != null && m.department != department) return false;
            if (upcomingOnly && m.dateTime.isBefore(now)) return false;
            return true;
          })
          .toList();

      // Sort in memory
      if (upcomingOnly) {
        meetings.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      } else {
        meetings.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      }

      return meetings.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting meetings: $e');
      return [];
    }
  }

  /// Get meetings stream
  Stream<List<MeetingModel>> getMeetingsStream({
    MeetingType? type,
    String? schoolId,
    bool upcomingOnly = false,
    int limit = 20,
  }) {
    // Simple stream without composite queries
    return _collection.snapshots().map((snapshot) {
      final now = DateTime.now();
      List<MeetingModel> meetings = snapshot.docs
          .map((doc) => MeetingModel.fromFirestore(doc))
          .where((m) {
            if (type != null && m.type != type) return false;
            if (schoolId != null && m.type == MeetingType.school && m.schoolId != schoolId) return false;
            if (upcomingOnly && m.dateTime.isBefore(now)) return false;
            return true;
          })
          .toList();

      // Sort in memory
      if (upcomingOnly) {
        meetings.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      } else {
        meetings.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      }

      return meetings.take(limit).toList();
    });
  }

  /// Get meeting by ID
  Future<MeetingModel?> getMeetingById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (doc.exists) {
        return MeetingModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting meeting: $e');
      return null;
    }
  }

  /// Create meeting
  Future<String?> createMeeting(MeetingModel meeting) async {
    try {
      final docRef = await _collection.add(meeting.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating meeting: $e');
      return null;
    }
  }

  /// Update meeting
  Future<bool> updateMeeting(MeetingModel meeting) async {
    try {
      await _collection.doc(meeting.id).update(
        meeting.copyWith(updatedAt: DateTime.now()).toFirestore(),
      );
      return true;
    } catch (e) {
      debugPrint('Error updating meeting: $e');
      return false;
    }
  }

  /// Delete meeting
  Future<bool> deleteMeeting(String id) async {
    try {
      await _collection.doc(id).delete();
      // Also delete attendance records
      final attendanceQuery = await _attendanceCollection
          .where('meetingId', isEqualTo: id)
          .get();
      for (var doc in attendanceQuery.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting meeting: $e');
      return false;
    }
  }

  /// Mark meeting as completed
  Future<bool> completeMeeting(String id) async {
    try {
      await _collection.doc(id).update({
        'isCompleted': true,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error completing meeting: $e');
      return false;
    }
  }

  /// Get upcoming meetings for home screen
  Future<List<MeetingModel>> getUpcomingMeetings({
    String? schoolId,
    int limit = 5,
  }) async {
    try {
      // Simple query without orderBy to avoid index requirement
      final snapshot = await _collection.get();

      final now = DateTime.now();
      List<MeetingModel> meetings = snapshot.docs
          .map((doc) => MeetingModel.fromFirestore(doc))
          .where((m) => m.dateTime.isAfter(now)) // Filter upcoming
          .toList();

      // Filter by school if needed (for school-specific meetings)
      if (schoolId != null) {
        meetings = meetings.where((m) =>
            m.type != MeetingType.school || m.schoolId == schoolId).toList();
      }

      // Sort by dateTime ascending (soonest first)
      meetings.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      return meetings.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting upcoming meetings: $e');
      return [];
    }
  }

  /// Get next meeting
  Future<MeetingModel?> getNextMeeting({String? schoolId}) async {
    final meetings = await getUpcomingMeetings(schoolId: schoolId, limit: 1);
    return meetings.isNotEmpty ? meetings.first : null;
  }

  /// Record attendance
  Future<bool> recordAttendance(MeetingAttendance attendance) async {
    try {
      await _attendanceCollection.doc(attendance.id).set(attendance.toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error recording attendance: $e');
      return false;
    }
  }

  /// Get attendance for a meeting
  Future<List<MeetingAttendance>> getMeetingAttendance(String meetingId) async {
    try {
      final snapshot = await _attendanceCollection
          .where('meetingId', isEqualTo: meetingId)
          .get();
      return snapshot.docs
          .map((doc) => MeetingAttendance.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting attendance: $e');
      return [];
    }
  }

  /// Update attendance status
  Future<bool> updateAttendanceStatus(
    String attendanceId,
    AttendanceStatus status,
  ) async {
    try {
      await _attendanceCollection.doc(attendanceId).update({
        'status': status.toFirestore(),
        'checkInTime': status == AttendanceStatus.present ? Timestamp.now() : null,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating attendance: $e');
      return false;
    }
  }

  /// Get meetings for a specific date
  Future<List<MeetingModel>> getMeetingsByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get all meetings and filter in memory to avoid composite index requirement
      final snapshot = await _collection.get();

      final meetings = snapshot.docs
          .map((doc) => MeetingModel.fromFirestore(doc))
          .where((m) =>
              m.dateTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
              m.dateTime.isBefore(endOfDay))
          .toList();

      // Sort by dateTime
      meetings.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      return meetings;
    } catch (e) {
      debugPrint('Error getting meetings by date: $e');
      return [];
    }
  }
}
