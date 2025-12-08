import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import '../documents/upload_document_screen.dart';

/// Department Documents Screen - Shows all department documents
class DepartmentDocumentsScreen extends ConsumerWidget {
  const DepartmentDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final documentsAsync = ref.watch(departmentDocumentsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF92400E),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.scaffoldBackgroundColor,
        body: Column(
          children: [
            // Header
            _buildHeader(context, l10n, user),

            // Documents list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(departmentDocumentsProvider);
                },
                child: documentsAsync.when(
                  data: (documents) {
                    if (documents.isEmpty) {
                      return _buildEmptyState(l10n);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final document = documents[index];
                        return _DocumentListItem(
                          document: document,
                          onTap: () => _openDocument(context, document, ref),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.badgeDepartmentText),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          l10n.translate('error_loading'),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.invalidate(departmentDocumentsProvider),
                          child: Text(l10n.translate('retry')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UploadDocumentScreen(
                isDepartmentDocument: true,
              ),
            ),
          ),
          backgroundColor: const Color(0xFF92400E),
          icon: const Icon(Icons.upload_file, color: Colors.white),
          label: Text(
            l10n.translate('upload'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, UserModel? user) {
    return Container(
      color: const Color(0xFF92400E),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('documents'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.department?.displayName ?? l10n.translate('department'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.translate('no_documents'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('upload_first_document'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDocument(BuildContext context, DocumentModel document, WidgetRef ref) async {
    // Track download
    ref.read(documentControllerProvider.notifier).trackDownload(document.id);

    // Open document URL
    final uri = Uri.parse(document.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('cannot_open_document'))),
        );
      }
    }
  }
}

class _DocumentListItem extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;

  const _DocumentListItem({
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // File type icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getFileTypeColor(document.fileType).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  document.fileType.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getFileTypeColor(document.fileType),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Document info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        document.fileSizeFormatted,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(document.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  if (document.downloadCount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.download, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          '${document.downloadCount} downloads',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Color _getFileTypeColor(DocumentFileType type) {
    switch (type) {
      case DocumentFileType.pdf:
        return Colors.red;
      case DocumentFileType.docx:
        return Colors.blue;
      case DocumentFileType.xlsx:
        return Colors.green;
      case DocumentFileType.png:
      case DocumentFileType.jpg:
        return Colors.purple;
    }
  }
}

/// Provider for department documents
final departmentDocumentsProvider = FutureProvider<List<DocumentModel>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.department == null) {
    return <DocumentModel>[];
  }

  final repository = ref.read(documentRepositoryProvider);
  try {
    return await repository.getDocumentsByDepartment(user.department!).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <DocumentModel>[],
    );
  } catch (e) {
    return <DocumentModel>[];
  }
});
