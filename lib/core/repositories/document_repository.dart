import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/models.dart';
import '../constants/enums.dart';

/// Repository for document-related Firestore operations
class DocumentRepository {
  final FirebaseFirestore _firestore;

  DocumentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('documents');

  /// Get all documents
  Future<List<DocumentModel>> getDocuments({
    DocumentCategory? category,
    bool publicOnly = true,
    int limit = 50,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection
          .orderBy('createdAt', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.toFirestore());
      }

      final snapshot = await query.limit(limit).get();

      List<DocumentModel> documents = snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .toList();

      // Filter public documents if needed
      if (publicOnly) {
        documents = documents.where((d) => d.isPublic).toList();
      }

      return documents;
    } catch (e) {
      debugPrint('Error getting documents: $e');
      return [];
    }
  }

  /// Get documents stream
  Stream<List<DocumentModel>> getDocumentsStream({
    DocumentCategory? category,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _collection
        .orderBy('createdAt', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category.toFirestore());
    }

    return query.limit(limit).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => DocumentModel.fromFirestore(doc)).toList());
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
      await _collection.doc(document.id).update(
        document.copyWith(updatedAt: DateTime.now()).toFirestore(),
      );
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
  Future<List<DocumentModel>> searchDocuments(String query) async {
    try {
      // Simple search - in production, use Algolia or similar
      final snapshot = await _collection
          .orderBy('title')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error searching documents: $e');
      return [];
    }
  }
}
