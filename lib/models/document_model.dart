import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../core/core.dart';

/// Document model for official documents, regulations, forms
class DocumentModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DocumentCategory category;
  final DocumentFileType fileType;
  final String fileUrl;
  final int fileSizeBytes;
  final String uploadedById;
  final String uploadedByName;
  final int downloadCount;
  final bool isPublic; // Visible to all users or only council members
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentModel({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.fileType,
    required this.fileUrl,
    this.fileSizeBytes = 0,
    required this.uploadedById,
    required this.uploadedByName,
    this.downloadCount = 0,
    this.isPublic = true,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create empty document
  factory DocumentModel.empty() {
    return DocumentModel(
      id: '',
      title: '',
      category: DocumentCategory.formulare,
      fileType: DocumentFileType.pdf,
      fileUrl: '',
      uploadedById: '',
      uploadedByName: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  /// Get file size in human readable format
  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Create from Firestore document
  factory DocumentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DocumentModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      category: DocumentCategory.fromFirestore(data['category'] as String? ?? 'formulare'),
      fileType: DocumentFileType.fromFirestore(data['fileType'] as String? ?? 'pdf'),
      fileUrl: data['fileUrl'] as String? ?? '',
      fileSizeBytes: data['fileSizeBytes'] as int? ?? 0,
      uploadedById: data['uploadedById'] as String? ?? '',
      uploadedByName: data['uploadedByName'] as String? ?? '',
      downloadCount: data['downloadCount'] as int? ?? 0,
      isPublic: data['isPublic'] as bool? ?? true,
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category.toFirestore(),
      'fileType': fileType.toFirestore(),
      'fileUrl': fileUrl,
      'fileSizeBytes': fileSizeBytes,
      'uploadedById': uploadedById,
      'uploadedByName': uploadedByName,
      'downloadCount': downloadCount,
      'isPublic': isPublic,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with new values
  DocumentModel copyWith({
    String? id,
    String? title,
    String? description,
    DocumentCategory? category,
    DocumentFileType? fileType,
    String? fileUrl,
    int? fileSizeBytes,
    String? uploadedById,
    String? uploadedByName,
    int? downloadCount,
    bool? isPublic,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      fileType: fileType ?? this.fileType,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      uploadedById: uploadedById ?? this.uploadedById,
      uploadedByName: uploadedByName ?? this.uploadedByName,
      downloadCount: downloadCount ?? this.downloadCount,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        fileType,
        fileUrl,
        fileSizeBytes,
        uploadedById,
        uploadedByName,
        downloadCount,
        isPublic,
        tags,
        createdAt,
        updatedAt,
      ];
}
