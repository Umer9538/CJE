import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/models.dart';
import '../constants/enums.dart';
import 'content_access.dart';

/// Repository for document-related Firestore operations
class DocumentRepository {
  final FirebaseFirestore _firestore;

  DocumentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('documents');

  Future<Query<Map<String, dynamic>>> _queryForCounty(String? countyId) =>
      ContentAccess(_firestore).query(_collection, countyId: countyId);

  /// Get all documents
  /// - If schoolId is provided, returns documents from that school
  /// - If includeCountyDocs is true, also includes county-level documents (schoolId == null)
  /// - County-level documents are visible to all users in the county
  Future<List<DocumentModel>> getDocuments({
    DocumentCategory? category,
    String? schoolId,
    String? countyId,
    bool includeCountyDocs = true,
    bool publicOnly = true,
    int limit = 50,
  }) async {
    try {
      // The county condition must be part of the Firestore query so security
      // rules can prove that no document from another county is returned.
      final snapshot = await (await _queryForCounty(countyId)).get();

      List<DocumentModel> documents = snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .toList();

      if (category != null) {
        documents = documents.where((d) => d.category == category).toList();
      }

      // Filter by school
      // - County-level docs (schoolId == null) are visible if includeCountyDocs is true
      // - School-specific docs are only visible to users of that school
      if (schoolId != null) {
        documents = documents.where((d) {
          // County-level document
          if (d.schoolId == null) {
            return includeCountyDocs;
          }
          // School-specific document - only show if it's the user's school
          return d.schoolId == schoolId;
        }).toList();
      }

      // Filter public documents if needed
      if (publicOnly) {
        documents = documents.where((d) => d.isPublic).toList();
      }

      documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return documents.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting documents: $e');
      return [];
    }
  }

  /// Get documents stream
  Stream<List<DocumentModel>> getDocumentsStream({
    DocumentCategory? category,
    String? countyId,
    int limit = 50,
  }) {
    return ContentAccess(
      _firestore,
    ).snapshots(_collection, countyId: countyId).map((snapshot) {
      var documents = snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .where((d) => category == null || d.category == category)
          .toList();
      documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return documents.take(limit).toList();
    });
  }

  /// Get document by ID
  Future<DocumentModel?> getDocumentById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (doc.exists) {
        return DocumentModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting document: $e');
      return null;
    }
  }

  /// Create document
  Future<String?> createDocument(DocumentModel document) async {
    try {
      final docRef = await _collection.add(document.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating document: $e');
      return null;
    }
  }

  /// Update document
  Future<bool> updateDocument(DocumentModel document) async {
    try {
      await _collection
          .doc(document.id)
          .update(document.copyWith(updatedAt: DateTime.now()).toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error updating document: $e');
      return false;
    }
  }

  /// Delete document
  Future<bool> deleteDocument(String id) async {
    try {
      await _collection.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting document: $e');
      return false;
    }
  }

  /// Increment download count
  Future<void> incrementDownloadCount(String id) async {
    try {
      await _collection.doc(id).update({
        'downloadCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing download count: $e');
    }
  }

  /// Search documents by title
  Future<List<DocumentModel>> searchDocuments(
    String query, {
    String? countyId,
  }) async {
    try {
      final snapshot = await (await _queryForCounty(countyId)).get();
      final normalizedQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .where(
            (document) =>
                document.title.toLowerCase().contains(normalizedQuery),
          )
          .take(20)
          .toList();
    } catch (e) {
      debugPrint('Error searching documents: $e');
      return [];
    }
  }

  /// Get documents by department (filtered by tag)
  Future<List<DocumentModel>> getDocumentsByDepartment(
    DepartmentType department, {
    String? countyId,
    int limit = 50,
  }) async {
    try {
      final departmentTag = 'department:${department.name}';

      // Get all documents and filter by tag in memory
      // Firestore array-contains with orderBy requires composite index
      final snapshot = await (await _queryForCounty(countyId)).get();

      List<DocumentModel> documents = snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .where((d) => d.tags.contains(departmentTag))
          .toList();

      // Sort by createdAt descending
      documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return documents.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting documents by department: $e');
      return [];
    }
  }
}
