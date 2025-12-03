import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';

/// Screen to upload a new document
class UploadDocumentScreen extends ConsumerStatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  ConsumerState<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends ConsumerState<UploadDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();

  DocumentCategory _selectedCategory = DocumentCategory.regulamente;
  bool _isPublic = true;
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0;

  PlatformFile? _selectedFile;
  String? _uploadedFileUrl;
  final List<String> _tags = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          // Auto-fill title from file name if empty
          if (_titleController.text.isEmpty) {
            final fileName = _selectedFile!.name;
            final lastDot = fileName.lastIndexOf('.');
            _titleController.text = lastDot != -1 ? fileName.substring(0, lastDot) : fileName;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadFile() async {
    if (_selectedFile == null || _selectedFile!.path == null) return null;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final file = File(_selectedFile!.path!);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('documents')
          .child(_selectedCategory.name)
          .child(fileName);

      final uploadTask = storageRef.putFile(file);

      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred / event.totalBytes;
        });
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _isUploading = false;
        _uploadedFileUrl = downloadUrl;
      });

      return downloadUrl;
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  DocumentFileType _getFileType() {
    if (_selectedFile == null) return DocumentFileType.pdf;
    final ext = _getExtension(_selectedFile!.name).toLowerCase();
    switch (ext) {
      case '.pdf':
        return DocumentFileType.pdf;
      case '.doc':
      case '.docx':
        return DocumentFileType.docx;
      case '.xls':
      case '.xlsx':
        return DocumentFileType.xlsx;
      case '.ppt':
      case '.pptx':
        return DocumentFileType.pdf; // Use pdf as fallback for ppt
      case '.jpg':
      case '.jpeg':
        return DocumentFileType.jpg;
      case '.png':
        return DocumentFileType.png;
      default:
        return DocumentFileType.pdf;
    }
  }

  String _getExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1) return '';
    return fileName.substring(lastDot);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(l10n.translate('upload_document')),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // File picker
            Text(
              l10n.translate('select_file'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isUploading ? null : _pickFile,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFile != null
                        ? AppColors.gold
                        : Colors.grey.withValues(alpha: 0.3),
                    width: _selectedFile != null ? 2 : 1,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: _selectedFile != null
                    ? Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _getFileColor().withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getFileIcon(),
                              color: _getFileColor(),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFile!.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navy,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatFileSize(_selectedFile!.size),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _selectedFile = null),
                            icon: const Icon(Icons.close, color: Colors.grey),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.navy.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              color: Colors.grey[400],
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.translate('tap_to_select_file'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PDF, DOC, XLS, PPT, Images',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Upload progress
            if (_isUploading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_uploadProgress * 100).toStringAsFixed(0)}% uploaded',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            // Category selection
            Text(
              l10n.translate('category'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DocumentCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.gold : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.gold : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      category.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.navy : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              l10n.translate('title'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: l10n.translate('document_title_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.translate('field_required');
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              '${l10n.translate('description')} (${l10n.translate('optional')})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: l10n.translate('document_description_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Tags
            Text(
              l10n.translate('tags'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: l10n.translate('add_tag'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _addTag,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navy,
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeTag(tag),
                    backgroundColor: AppColors.navy.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),

            // Visibility toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                title: Text(l10n.translate('public_document')),
                subtitle: Text(
                  l10n.translate('public_document_desc'),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
                activeColor: AppColors.gold,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 32),

            // Upload button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || _isUploading || _selectedFile == null
                    ? null
                    : _handleUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isLoading || _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.navy,
                        ),
                      )
                    : Text(
                        l10n.translate('upload'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon() {
    if (_selectedFile == null) return Icons.description;
    final ext = _getExtension(_selectedFile!.name).toLowerCase();
    switch (ext) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.article;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart;
      case '.ppt':
      case '.pptx':
        return Icons.slideshow;
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor() {
    if (_selectedFile == null) return Colors.grey;
    final ext = _getExtension(_selectedFile!.name).toLowerCase();
    switch (ext) {
      case '.pdf':
        return Colors.red;
      case '.doc':
      case '.docx':
        return Colors.blue;
      case '.xls':
      case '.xlsx':
        return Colors.green;
      case '.ppt':
      case '.pptx':
        return Colors.orange;
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) return;

    setState(() => _isLoading = true);

    // First upload the file to Firebase Storage
    final fileUrl = await _uploadFile();
    if (fileUrl == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Then create the document record in Firestore
    final controller = ref.read(documentControllerProvider.notifier);
    final id = await controller.createDocument(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _selectedCategory,
      fileType: _getFileType(),
      fileUrl: fileUrl,
      fileSizeBytes: _selectedFile!.size,
      isPublic: _isPublic,
      tags: _tags.isEmpty ? null : _tags,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (id != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('document_uploaded')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('error_uploading_document')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
