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

  try {
    return await repository.getDocuments(
      category: filter.category,
      publicOnly: filter.publicOnly,
      limit: filter.limit,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <DocumentModel>[],
    );
  } catch (e) {
    return <DocumentModel>[];
  }
});

/// Documents stream provider
final documentsStreamProvider = StreamProvider.family<List<DocumentModel>, DocumentFilter>((ref, filter) {
  final repository = ref.watch(documentRepositoryProvider);

  return repository.getDocumentsStream(
    category: filter.category,
    limit: filter.limit,
  );
});

/// Single document provider
final documentProvider = FutureProvider.family<DocumentModel?, String>((ref, id) async {
  final repository = ref.watch(documentRepositoryProvider);
  return repository.getDocumentById(id);
});

/// Filter model for documents
class DocumentFilter {
  final DocumentCategory? category;
  final bool publicOnly;
  final int limit;

  const DocumentFilter({
    this.category,
    this.publicOnly = true,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentFilter &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          publicOnly == other.publicOnly &&
          limit == other.limit;

  @override
  int get hashCode => category.hashCode ^ publicOnly.hashCode ^ limit.hashCode;
}

/// Document controller for CRUD operations
class DocumentController extends StateNotifier<AsyncValue<void>> {
  final DocumentRepository _repository;
  final Ref _ref;

  DocumentController(this._repository, this._ref) : super(const AsyncValue.data(null));

  /// Create new document (only bex, superadmin can upload)
  Future<String?> createDocument({
    required String title,
    String? description,
    required DocumentCategory category,
    required DocumentFileType fileType,
    required String fileUrl,
    int fileSizeBytes = 0,
    bool isPublic = true,
    List<String>? tags,
  }) async {
    state = const AsyncValue.loading();

    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return null;
    }

    // Permission check - only bex and superadmin can upload documents
    if (user.role != UserRole.bex && user.role != UserRole.superadmin) {
      state = AsyncValue.error('Permission denied', StackTrace.current);
      return null;
    }

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
      isPublic: isPublic,
      tags: tags ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await _repository.createDocument(document);

    if (id != null) {
      state = const AsyncValue.data(null);
      _ref.invalidate(documentsProvider);
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
