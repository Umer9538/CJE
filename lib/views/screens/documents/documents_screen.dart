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
            _selectedCategory = DocumentCategory.regulamente;
            break;
          case 2:
            _selectedCategory = DocumentCategory.ghiduri;
            break;
          case 3:
            _selectedCategory = DocumentCategory.utile;
            break;
          case 4:
            _selectedCategory = DocumentCategory.rapoarte;
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

    // Check if user is admin (can see non-public documents)
    final isAdmin = currentUser?.role == UserRole.bex ||
                    currentUser?.role == UserRole.superadmin ||
                    currentUser?.role == UserRole.schoolRep;

    // Filter documents by user's school
    // - County-level documents (schoolId == null) are visible to all
    // - School-specific documents are only visible to users of that school
    // - Admins/SchoolRep can see all documents (public and non-public)
    final documentsAsync = ref.watch(
      documentsProvider(DocumentFilter(
        category: _selectedCategory,
        schoolId: currentUser?.schoolId,
        includeCountyDocs: true, // Always show county-level documents
        publicOnly: !isAdmin, // Admins see all, others only public
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
                data: (documents) => RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(documentsProvider);
                  },
                  color: AppColors.gold,
                  child: documents.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            if (canUpload) _buildUploadCard(context, l10n),
                            _buildEmptyState(context, l10n),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: documents.length + (canUpload ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (canUpload && index == 0) {
                              return _buildUploadCard(context, l10n);
                            }
                            final docIndex = canUpload ? index - 1 : index;
                            final document = documents[docIndex];
                            return _DocumentCard(
                              document: document,
                              onTap: () => _openDocument(document),
                              onDownload: () => _downloadDocument(document),
                              onDelete: () => _deleteDocument(document),
                            );
                          },
                        ),
                ),
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
    final currentUser = ref.watch(currentUserProvider);
    final String backRoute = currentUser?.role == UserRole.bex
        ? RouteNames.bexDashboard
        : RouteNames.home;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          // Back button - navigate to home or BEX dashboard
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(backRoute);
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: context.shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(Icons.arrow_back_rounded, color: context.iconColor, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            l10n.translate('documents'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.goldColor,
            ),
          ),
          const Spacer(),
          _buildIconButton(
            context,
            icon: Icons.search_rounded,
            onTap: () {
              context.push(RouteNames.search);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: context.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: context.iconColor, size: 20),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: context.textPrimary,
        unselectedLabelColor: context.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        indicator: BoxDecoration(
          color: context.goldColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(6),
        tabs: [
          Tab(text: l10n.translate('all')),
          Tab(text: l10n.translate('regulamente')),
          Tab(text: l10n.translate('ghiduri')),
          Tab(text: l10n.translate('utile')),
          Tab(text: l10n.translate('rapoarte')),
        ],
      ),
    );
  }

  Widget _buildUploadCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: GestureDetector(
        onTap: () => _showUploadInfo(context),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gold, AppColors.gold.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.cloud_upload_rounded,
                  color: AppColors.navy,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('upload_document'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.translate('upload_document_desc'),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.navy.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.navy,
                size: 24,
              ),
            ],
          ),
        ),
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
                color: context.goldColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 48,
                color: context.goldColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.translate('no_documents'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate('no_documents_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondary,
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
            Icon(Icons.error_outline, size: 48, color: context.errorColor),
            const SizedBox(height: 16),
            Text(
              l10n.translate('error_loading'),
              style: TextStyle(color: context.textSecondary),
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
    try {
      // Try to launch the URL directly - Firebase Storage URLs work in browser
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        // Track download
        ref.read(documentControllerProvider.notifier).trackDownload(document.id);
      } else {
        // Fallback: try with inAppWebView mode
        final launchedInApp = await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
        );
        if (launchedInApp) {
          ref.read(documentControllerProvider.notifier).trackDownload(document.id);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).translate('cannot_open_file'))),
          );
        }
      }
    } catch (e) {
      // If launching fails, try opening in app web view as fallback
      try {
        final launchedInApp = await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
        );
        if (launchedInApp) {
          ref.read(documentControllerProvider.notifier).trackDownload(document.id);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).translate('cannot_open_file'))),
          );
        }
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).translate('cannot_open_file'))),
          );
        }
      }
    }
  }

  Future<void> _downloadDocument(DocumentModel document) async {
    await _openDocument(document);
  }

  void _showUploadInfo(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadDocumentScreen()),
    );
    // Refresh documents after returning from upload screen
    if (mounted) {
      ref.invalidate(documentsProvider);
    }
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
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.shadowColor,
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
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
                          AppLocalizations.of(context).translate(document.category.name),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: document.category.color,
                          ),
                        ),
                      ),
                      Text(
                        document.fileType.displayName, // File type is just PDF, DOCX, etc - no translation needed
                        style: TextStyle(fontSize: 11, color: context.textSecondary),
                      ),
                      Text(
                        document.fileSizeFormatted,
                        style: TextStyle(fontSize: 11, color: context.textSecondary),
                      ),
                      Text(
                        yearFormat.format(document.createdAt),
                        style: TextStyle(fontSize: 11, color: context.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Issuer row
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 12, color: context.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          document.uploadedByName,
                          style: TextStyle(fontSize: 11, color: context.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (document.downloadCount > 0) ...[
                        Icon(Icons.download_rounded, size: 12, color: context.textSecondary),
                        const SizedBox(width: 2),
                        Text(
                          '${document.downloadCount}',
                          style: TextStyle(fontSize: 11, color: context.textSecondary),
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
                      color: context.goldColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.download_rounded,
                      color: context.goldColor,
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
