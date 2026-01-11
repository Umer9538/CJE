import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/repositories/document_repository.dart';
import '../../core/constants/enums.dart';
import '../../models/models.dart';
import '../auth/auth_controller.dart';

/// Document repository provider
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository();
});

/// Documents list provider
final documentsProvider = FutureProvider.family<List<DocumentModel>, DocumentFilter>((ref, filter) async {
  final repository = ref.watch(documentRepositoryProvider);
  final user = ref.read(currentUserProvider);
  final userId = user?.id;
  final userRole = user?.role;
  final userSchoolId = user?.schoolId;

  try {
    // For BEX/Superadmin, don't filter by school - they see everything
    final effectiveSchoolId = (userRole == UserRole.bex || userRole == UserRole.superadmin)
        ? null
        : filter.schoolId;

    final documents = await repository.getDocuments(
      category: filter.category,
      schoolId: effectiveSchoolId,
      includeCountyDocs: filter.includeCountyDocs,
      publicOnly: filter.publicOnly,
      limit: filter.limit,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <DocumentModel>[],
    );

    // Filter documents based on visibility rules
    return documents.where((doc) {
      // Always show documents created by the current user
      if (userId != null && doc.uploadedById == userId) {
        return doc.canBeViewedBy(userRole);
      }

      // BEX and Superadmin see ALL documents
      if (userRole == UserRole.bex || userRole == UserRole.superadmin) {
        return doc.canBeViewedBy(userRole);
      }

      // School filtering for other users
      if (userSchoolId != null && doc.schoolId != null && doc.schoolId != userSchoolId) {
        return false;
      }

      return doc.canBeViewedBy(userRole);
    }).toList();
  } catch (e) {
    return <DocumentModel>[];
  }
});

/// Documents stream provider
final documentsStreamProvider = StreamProvider.family<List<DocumentModel>, DocumentFilter>((ref, filter) {
  final repository = ref.watch(documentRepositoryProvider);
  final user = ref.read(currentUserProvider);
  final userSchoolId = user?.schoolId;
  final userId = user?.id;
  final userRole = user?.role;

  return repository.getDocumentsStream(
    category: filter.category,
    limit: filter.limit,
  ).map((documents) => documents.where((doc) {
    // Always show documents created by the current user
    if (userId != null && doc.uploadedById == userId) {
      return doc.canBeViewedBy(userRole);
    }

    // BEX and Superadmin see ALL documents (county-level and school-specific)
    if (userRole == UserRole.bex || userRole == UserRole.superadmin) {
      return doc.canBeViewedBy(userRole);
    }

    // School filtering for other users:
    // - County-level documents (doc.schoolId == null) are visible to all
    // - School-specific documents are only visible to users from that school
    if (userSchoolId != null && doc.schoolId != null && doc.schoolId != userSchoolId) {
      return false;
    }

    // Role filtering for non-public documents
    return doc.canBeViewedBy(userRole);
  }).toList());
});

/// Single document provider
final documentProvider = FutureProvider.family<DocumentModel?, String>((ref, id) async {
  final repository = ref.watch(documentRepositoryProvider);
  return repository.getDocumentById(id);
});

/// Filter model for documents
class DocumentFilter {
  final DocumentCategory? category;
  final String? schoolId; // Filter by school (null = county-level documents)
  final bool includeCountyDocs; // Whether to include county-level documents
  final bool publicOnly;
  final int limit;

  const DocumentFilter({
    this.category,
    this.schoolId,
    this.includeCountyDocs = true,
    this.publicOnly = true,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentFilter &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          schoolId == other.schoolId &&
          includeCountyDocs == other.includeCountyDocs &&
          publicOnly == other.publicOnly &&
          limit == other.limit;

  @override
  int get hashCode =>
      category.hashCode ^
      schoolId.hashCode ^
      includeCountyDocs.hashCode ^
      publicOnly.hashCode ^
      limit.hashCode;
}

/// Document controller for CRUD operations
class DocumentController extends StateNotifier<AsyncValue<void>> {
  final DocumentRepository _repository;
  final Ref _ref;

  DocumentController(this._repository, this._ref) : super(const AsyncValue.data(null));

  /// Create new document
  /// - BEX and Superadmin can upload any document (county-level)
  /// - SchoolRep can upload school-level documents only
  /// - Department can upload department-level documents only
  /// - schoolId/schoolName: Optional overrides for BEX/Superadmin to upload documents for specific schools
  Future<String?> createDocument({
    required String title,
    String? description,
    required DocumentCategory category,
    required DocumentFileType fileType,
    required String fileUrl,
    int fileSizeBytes = 0,
    bool isPublic = true,
    UserRole? minimumRole,
    bool isSchoolDocument = false,
    bool isDepartmentDocument = false,
    List<String>? tags,
    String? schoolId,
    String? schoolName,
  }) async {
    state = const AsyncValue.loading();

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return null;
    }

    // Permission check
    // - BEX and Superadmin can upload any document
    // - SchoolRep can only upload school-level documents
    // - Department can only upload department-level documents
    if (user.role == UserRole.schoolRep) {
      if (!isSchoolDocument) {
        state = AsyncValue.error('School representatives can only upload school documents', StackTrace.current);
        return null;
      }
    } else if (user.role == UserRole.department) {
      if (!isDepartmentDocument) {
        state = AsyncValue.error('Department members can only upload department documents', StackTrace.current);
        return null;
      }
    } else if (user.role != UserRole.bex && user.role != UserRole.superadmin) {
      state = AsyncValue.error('Permission denied', StackTrace.current);
      return null;
    }

    // Determine school ID and name for school documents
    // - If schoolId is provided (BEX/Superadmin selected specific school), use it
    // - Otherwise, use the current user's school
    final effectiveSchoolId = isSchoolDocument
        ? (schoolId ?? user.schoolId)
        : null;
    final effectiveSchoolName = isSchoolDocument
        ? (schoolName ?? user.schoolName)
        : null;

    final document = DocumentModel(
      id: '',
      title: title,
      description: description,
      category: category,
      fileType: fileType,
      fileUrl: fileUrl,
      fileSizeBytes: fileSizeBytes,
      uploadedById: user.id,
      uploadedByName: user.fullName,
      schoolId: effectiveSchoolId,
      schoolName: effectiveSchoolName,
      isPublic: isPublic,
      minimumRole: isPublic ? null : minimumRole,
      tags: isDepartmentDocument ? [...(tags ?? []), 'department:${user.department?.name ?? 'unknown'}'] : tags ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await _repository.createDocument(document);

    if (id != null) {
      state = const AsyncValue.data(null);
      // Invalidate all document-related providers to force refresh
      _ref.invalidate(documentsProvider);
      _ref.invalidate(documentsStreamProvider);
    } else {
      state = AsyncValue.error('Failed to create document', StackTrace.current);
    }

    return id;
  }

  /// Update document
  Future<bool> updateDocument(DocumentModel document) async {
    state = const AsyncValue.loading();

    final success = await _repository.updateDocument(document);

    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(documentsProvider);
      _ref.invalidate(documentProvider(document.id));
    } else {
      state = AsyncValue.error('Failed to update document', StackTrace.current);
    }

    return success;
  }

  /// Delete document
  Future<bool> deleteDocument(String id) async {
    state = const AsyncValue.loading();

    final success = await _repository.deleteDocument(id);

    if (success) {
      state = const AsyncValue.data(null);
      _ref.invalidate(documentsProvider);
    } else {
      state = AsyncValue.error('Failed to delete document', StackTrace.current);
    }

    return success;
  }

  /// Track download
  Future<void> trackDownload(String id) async {
    await _repository.incrementDownloadCount(id);
  }
}

/// Document controller provider
final documentControllerProvider =
    StateNotifierProvider<DocumentController, AsyncValue<void>>((ref) {
  return DocumentController(
    ref.watch(documentRepositoryProvider),
    ref,
  );
});

/// Check if current user can upload documents
/// SchoolRep can upload school documents, Department can upload department documents
/// BEX/Superadmin can upload any
final canUploadDocumentsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.schoolRep ||
         user.role == UserRole.department ||
         user.role == UserRole.bex ||
         user.role == UserRole.superadmin;
});

/// Check if current user can upload county-level documents (not school-specific)
final canUploadCountyDocumentsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.bex || user.role == UserRole.superadmin;
});

/// Check if current user can upload department-level documents
final canUploadDepartmentDocumentsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.department ||
         user.role == UserRole.bex ||
         user.role == UserRole.superadmin;
});
