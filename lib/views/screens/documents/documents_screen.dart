import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';

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
    final user = ref.watch(currentUserProvider);
    final documentsAsync = ref.watch(
      documentsProvider(DocumentFilter(category: _selectedCategory)),
    );

    // Only bex and superadmin can upload documents
    final canUpload = user != null &&
        (user.role == UserRole.bex || user.role == UserRole.superadmin);

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
          ? FloatingActionButton.extended(
              onPressed: () => _showUploadInfo(context),
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navy,
              icon: const Icon(Icons.upload_rounded),
              label: Text(l10n.translate('upload')),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
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
        );
      },
    );
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
    // TODO: Implement file upload with Firebase Storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document upload coming soon')),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const _DocumentCard({
    required this.document,
    required this.onTap,
    required this.onDownload,
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
                  Row(
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
                      const SizedBox(width: 8),
                      Text(
                        document.fileType.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        document.fileSizeFormatted,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  if (document.downloadCount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.download_rounded,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${document.downloadCount} downloads',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Download button
            IconButton(
              onPressed: onDownload,
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.download_rounded,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
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
