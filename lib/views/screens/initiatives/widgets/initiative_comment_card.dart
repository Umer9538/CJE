import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
import '../../../../models/models.dart';

/// Comment card widget for initiatives
class InitiativeCommentCard extends StatelessWidget {
  final InitiativeComment comment;

  const InitiativeCommentCard({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: comment.isOfficial
            ? AppColors.gold.withValues(alpha: 0.1)
            : context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: comment.isOfficial
            ? Border.all(color: AppColors.gold.withValues(alpha: 0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, l10n, dateFormat),
          const SizedBox(height: 10),
          Text(
            comment.content,
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, DateFormat dateFormat) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: context.goldColor.withValues(alpha: 0.15),
          backgroundImage: comment.authorPhotoUrl != null
              ? NetworkImage(comment.authorPhotoUrl!)
              : null,
          child: comment.authorPhotoUrl == null
              ? Text(
                  comment.authorName.isNotEmpty
                      ? comment.authorName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 14,
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
              // Name row with official badge
              Row(
                children: [
                  Flexible(
                    child: Text(
                      comment.authorName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (comment.isOfficial) ...[
                    const SizedBox(width: 6),
                    _buildOfficialBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              // Role and school info
              if (comment.authorRole != null || comment.authorSchoolName != null)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (comment.authorRole != null)
                      _buildInfoBadge(
                        context,
                        _getRoleDisplayName(comment.authorRole!, l10n),
                        Icons.badge_outlined,
                      ),
                    if (comment.authorSchoolName != null && comment.authorSchoolName!.isNotEmpty)
                      _buildInfoBadge(
                        context,
                        comment.authorSchoolName!,
                        Icons.school_outlined,
                      ),
                  ],
                ),
              const SizedBox(height: 4),
              // Date
              Text(
                dateFormat.format(comment.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBadge(BuildContext context, String text, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use navy/gold colors for better visibility
    final badgeColor = isDark ? AppColors.gold : AppColors.navy;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: badgeColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String role, AppLocalizations l10n) {
    switch (role) {
      case 'classRep':
        return l10n.translate('class_representative');
      case 'schoolRep':
        return l10n.translate('school_representative');
      case 'department':
        return l10n.translate('department');
      case 'bex':
        return 'BEx';
      case 'superadmin':
        return 'Admin';
      default:
        return role;
    }
  }

  Widget _buildOfficialBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'OFFICIAL',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppColors.navy,
        ),
      ),
    );
  }
}
