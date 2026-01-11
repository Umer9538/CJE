import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/models.dart';

/// Repository for county settings Firestore operations
/// Settings are stored in a single document per county
class CountySettingsRepository {
  final FirebaseFirestore _firestore;

  // Use a fixed document ID for the county settings
  static const String _settingsDocId = 'county_settings';

  CountySettingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Document reference for settings
  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _firestore.collection('settings').doc(_settingsDocId);

  /// Get county settings
  Future<CountySettingsModel> getSettings() async {
    try {
      final doc = await _settingsDoc.get();
      if (doc.exists) {
        return CountySettingsModel.fromFirestore(doc);
      }
      // Return defaults if no settings exist
      return CountySettingsModel.defaults();
    } catch (e) {
      debugPrint('Error getting county settings: $e');
      return CountySettingsModel.defaults();
    }
  }

  /// Get settings stream for real-time updates
  Stream<CountySettingsModel> getSettingsStream() {
    return _settingsDoc.snapshots().map((doc) {
      if (doc.exists) {
        return CountySettingsModel.fromFirestore(doc);
      }
      return CountySettingsModel.defaults();
    });
  }

  /// Update county settings
  Future<bool> updateSettings(CountySettingsModel settings) async {
    try {
      await _settingsDoc.set(
        settings.copyWith(updatedAt: DateTime.now()).toFirestore(),
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      debugPrint('Error updating county settings: $e');
      return false;
    }
  }

  /// Update specific fields
  Future<bool> updateSettingsFields(Map<String, dynamic> fields) async {
    try {
      fields['updatedAt'] = Timestamp.now();
      await _settingsDoc.set(fields, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Error updating county settings fields: $e');
      return false;
    }
  }

  /// Initialize settings with defaults if they don't exist
  Future<bool> initializeSettingsIfNeeded() async {
    try {
      final doc = await _settingsDoc.get();
      if (!doc.exists) {
        final defaults = CountySettingsModel.defaults();
        await _settingsDoc.set(defaults.toFirestore());
        debugPrint('County settings initialized with defaults');
      }
      return true;
    } catch (e) {
      debugPrint('Error initializing county settings: $e');
      return false;
    }
  }
}
