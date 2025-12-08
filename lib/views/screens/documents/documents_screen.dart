import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import '../../../routes/route_names.dart';
import 'upload_document_screen.dart';

/// Main documents list screen
/// Students can VIEW documents but CANNOT upload
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DocumentCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedCategory = null; // All
            break;
          case 1:
            _selectedCategory = DocumentCategory.statutElevului;
            break;
          case 2:
            _selectedCategory = DocumentCategory.regulamente;
            break;
          case 3:
            _selectedCategory = DocumentCategory.metodologii;
            break;
          case 4:
            _selectedCategory = DocumentCategory.formulare;
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentUser = ref.watch(currentUserProvider);

    // Filter documents by user's school
    // - County-level documents (schoolId == null) are visible to all
    // - School-specific documents are only visible to users of that school
    final documentsAsync = ref.watch(
      documentsProvider(DocumentFilter(
        category: _selectedCategory,
        schoolId: currentUser?.schoolId,
        includeCountyDocs: true, // Always show county-level documents
      )),
    );

    // SchoolRep can upload school documents, BEX/Superadmin can upload any
    final canUpload = ref.watch(canUploadDocumentsProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, l10n),

            // Tabs
            _buildTabs(context, l10n),

            // Content
            Expanded(
              child: documentsAsync.when(
                data: (documents) => documents.isEmpty
                    ? _buildEmptyState(context, l10n)
                    : _buildDocumentsList(documents),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (error, _) => _buildErrorState(context, l10n, error),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: canUpload
          ? Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: FloatingActionButton.extended(
                heroTag: 'fab_documents',
                onPressed: () => _showUploadInfo(context),
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navy,
                icon: const Icon(Icons.upload_rounded),
                label: Text(l10n.translate('upload')),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          // Back button - navigate to home
          GestureDetector(
            onTap: () => context.go(RouteNames.home),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.navy, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            l10n.translate('documents'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const Spacer(),
          _buildIconButton(
            icon: Icons.search_rounded,
            onTap: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.navy, size: 20),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppColors.navy,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        indicator: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(6),
        tabs: [
          Tab(text: l10n.translate('all')),
          Tab(text: l10n.translate('statut')),
          Tab(text: l10n.translate('regulations')),
          Tab(text: l10n.translate('methodologies')),
          Tab(text: l10n.translate('forms')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.translate('no_documents'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate('no_documents_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations l10n, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              l10n.translate('error_loading'),
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(documentsProvider),
              child: Text(l10n.translate('retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsList(List<DocumentModel> documents) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return _DocumentCard(
          document: document,
          onTap: () => _openDocument(document),
          onDownload: () => _downloadDocument(document),
          onDelete: () => _deleteDocument(document),
        );
      },
    );
  }

  Future<void> _deleteDocument(DocumentModel document) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('delete_document')),
        content: Text(l10n.translate('delete_document_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(documentControllerProvider.notifier)
          .deleteDocument(document.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? l10n.translate('document_deleted')
                : l10n.translate('error_deleting_document')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openDocument(DocumentModel document) async {
    final uri = Uri.parse(document.fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // Track download
      ref.read(documentControllerProvider.notifier).trackDownload(document.id);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('cannot_open_file'))),
        );
      }
    }
  }

  Future<void> _downloadDocument(DocumentModel document) async {
    await _openDocument(document);
  }

  void _showUploadInfo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadDocumentScreen()),
    );
  }
}

class _DocumentCard extends ConsumerWidget {
  final DocumentModel document;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.document,
    required this.onTap,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final canDelete = user != null &&
        (user.role == UserRole.bex || user.role == UserRole.superadmin);
    final yearFormat = DateFormat('yyyy');

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
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // File type icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: document.category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getFileIcon(document.fileType),
                color: document.category.color,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

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
                  // Category, Type, Size, Year row
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: document.category.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          document.category.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: document.category.color,
                          ),
                        ),
                      ),
                      Text(
                        document.fileType.displayName,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      Text(
                        document.fileSizeFormatted,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      Text(
                        yearFormat.format(document.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Issuer row
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          document.uploadedByName,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (document.downloadCount > 0) ...[
                        Icon(Icons.download_rounded, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 2),
                        Text(
                          '${document.downloadCount}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Actions column
            Column(
              children: [
                // Download button
                IconButton(
                  onPressed: onDownload,
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      color: AppColors.gold,
                      size: 18,
                    ),
                  ),
                ),
                // Delete button (only for BEX/admin)
                if (canDelete)
                  IconButton(
                    onPressed: onDelete,
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(DocumentFileType type) {
    switch (type) {
      case DocumentFileType.pdf:
        return Icons.picture_as_pdf_rounded;
      case DocumentFileType.docx:
        return Icons.description_rounded;
      case DocumentFileType.xlsx:
        return Icons.table_chart_rounded;
      case DocumentFileType.png:
      case DocumentFileType.jpg:
        return Icons.image_rounded;
    }
  }
}
