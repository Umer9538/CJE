import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import 'edit_announcement_screen.dart';

/// Detail screen for viewing a single announcement
class AnnouncementDetailScreen extends ConsumerStatefulWidget {
  final AnnouncementModel announcement;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcement,
  });

  @override
  ConsumerState<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends ConsumerState<AnnouncementDetailScreen> {
  bool _viewTracked = false;

  @override
  void initState() {
    super.initState();
    // Track view count when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(announcementControllerProvider.notifier).trackView(widget.announcement.id);
      if (mounted) {
        setState(() {
          _viewTracked = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');
    final isCounty = widget.announcement.type == AnnouncementType.county;

    // Check if user can edit/delete
    final canEdit = user != null &&
        (user.id == widget.announcement.authorId ||
            user.role == UserRole.bex ||
            user.role == UserRole.superadmin);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with image
          SliverAppBar(
            expandedHeight: widget.announcement.imageUrl != null ? 300 : 120,
            pinned: true,
            backgroundColor: AppColors.navy,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (canEdit)
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _handleEdit(context);
                    } else if (value == 'delete') {
                      _handleDelete(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 20),
                          const SizedBox(width: 12),
                          Text(l10n.translate('edit')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          const SizedBox(width: 12),
                          Text(
                            l10n.translate('delete'),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: widget.announcement.imageUrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.announcement.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.navy,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 64,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.4),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: AppColors.navy,
                      child: const Center(
                        child: Icon(
                          Icons.campaign_rounded,
                          size: 64,
                          color: Colors.white24,
                        ),
                      ),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: BoxDecoration(
                  color: context.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge and pinned indicator
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isCounty
                                    ? context.goldColor.withValues(alpha: 0.15)
                                    : context.textSecondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isCounty ? 'CJE' : widget.announcement.schoolName ?? 'School',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isCounty ? context.goldColor : context.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (widget.announcement.isPinned) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.push_pin_rounded,
                                    size: 14,
                                    color: Colors.orange[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.translate('pinned'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title (with translation support)
                      Text(
                        widget.announcement.getTitle(Localizations.localeOf(context).languageCode),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Author and date info
                      Container(
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
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: context.goldColor.withValues(alpha: 0.1),
                              backgroundImage: widget.announcement.authorPhotoUrl != null
                                  ? NetworkImage(widget.announcement.authorPhotoUrl!)
                                  : null,
                              child: widget.announcement.authorPhotoUrl == null
                                  ? Text(
                                      widget.announcement.authorName.isNotEmpty
                                          ? widget.announcement.authorName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: context.goldColor,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.announcement.authorName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dateFormat.format(
                                      widget.announcement.publishedAt ?? widget.announcement.createdAt,
                                    ),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                  color: context.textSecondary,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.announcement.viewCount + (_viewTracked ? 1 : 0)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Content (with translation support)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
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
                        child: Text(
                          widget.announcement.getContent(Localizations.localeOf(context).languageCode),
                          style: TextStyle(
                            fontSize: 16,
                            color: context.textPrimary,
                            height: 1.7,
                          ),
                        ),
                      ),

                      // Attachments if any
                      if (widget.announcement.attachmentUrls.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          l10n.translate('attachments'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...widget.announcement.attachmentUrls.map(
                          (url) => _buildAttachmentItem(context, url),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(BuildContext context, String url) {
    // Decode URL-encoded filename
    final rawFileName = url.split('/').last.split('?').first;
    final fileName = Uri.decodeComponent(rawFileName);

    return GestureDetector(
      onTap: () => _openAttachment(context, url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.textSecondary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.goldColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.attach_file_rounded,
                color: context.goldColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.download_rounded,
              color: context.goldColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachment(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri.parse(url);

    try {
      // Try to launch the URL directly - Firebase Storage URLs work in browser
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback: try with inAppWebView mode
        final launchedInApp = await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
        );
        if (!launchedInApp && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.translate('cannot_open_file')),
              backgroundColor: Colors.red,
            ),
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
        if (!launchedInApp && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.translate('cannot_open_file')),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e2) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.translate('error_opening_file')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditAnnouncementScreen(announcement: widget.announcement),
      ),
    );
  }

  void _handleDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('delete_announcement')),
        content: Text(l10n.translate('delete_announcement_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final controller = ref.read(announcementControllerProvider.notifier);
              final success = await controller.deleteAnnouncement(widget.announcement.id);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.translate('announcement_deleted'))),
                );
              }
            },
            child: Text(
              l10n.translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
