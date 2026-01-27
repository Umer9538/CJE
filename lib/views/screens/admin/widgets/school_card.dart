import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../controllers/admin/admin_controller.dart';
import '../../../../controllers/schools/school_controller.dart';
import '../../../../core/core.dart';
import '../../../../models/models.dart';

/// School card widget for admin schools list
class SchoolCard extends ConsumerWidget {
  final SchoolModel school;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const SchoolCard({
    super.key,
    required this.school,
    required this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch the actual school representative from users collection
    final schoolRepAsync = ref.watch(schoolRepresentativeProvider(school.id));
    // Fetch actual member count from users collection
    final membersAsync = ref.watch(usersBySchoolStreamProvider(school.id));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: !school.isActive
              ? Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1)
              : null,
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
            _buildLogo(context),
            const SizedBox(width: 14),
            Expanded(child: _buildInfo(context, schoolRepAsync, membersAsync)),
            _buildTrailing(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: school.isActive
            ? (isDark ? AppColors.gold.withValues(alpha: 0.15) : AppColors.navy.withValues(alpha: 0.1))
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: school.logoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                school.logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildLogoText(context),
              ),
            )
          : _buildLogoText(context),
    );
  }

  Widget _buildLogoText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Text(
        school.shortName.isNotEmpty
            ? school.shortName.substring(0, school.shortName.length.clamp(0, 2))
            : 'S',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: school.isActive ? (isDark ? AppColors.gold : AppColors.navy) : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, AsyncValue<UserModel?> schoolRepAsync, AsyncValue<List<UserModel>> membersAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                school.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: school.isActive ? context.textPrimary : Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!school.isActive) _buildInactiveBadge(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          school.shortName,
          style: TextStyle(
            fontSize: 12,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        _buildStats(context, schoolRepAsync, membersAsync),
      ],
    );
  }

  Widget _buildInactiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Inactive',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, AsyncValue<UserModel?> schoolRepAsync, AsyncValue<List<UserModel>> membersAsync) {
    // Get the actual school rep name from the async data
    final repName = schoolRepAsync.when(
      data: (rep) => rep?.fullName,
      loading: () => null,
      error: (_, __) => null,
    );

    // Get actual member count from the async data
    final memberCount = membersAsync.when(
      data: (members) => members.length,
      loading: () => school.studentCount, // Fallback to static count while loading
      error: (_, __) => school.studentCount,
    );

    return Row(
      children: [
        Icon(Icons.people_outline, size: 14, color: context.textSecondary),
        const SizedBox(width: 4),
        Text(
          '$memberCount members',
          style: TextStyle(fontSize: 12, color: context.textSecondary),
        ),
        if (repName != null) ...[
          const SizedBox(width: 12),
          Icon(Icons.person_outline, size: 14, color: context.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              repName,
              style: TextStyle(fontSize: 12, color: context.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (onEdit != null) {
      return IconButton(
        onPressed: onEdit,
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.gold.withValues(alpha: 0.15) : AppColors.navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.edit_outlined, color: isDark ? AppColors.gold : AppColors.navy, size: 18),
        ),
      );
    }
    return Icon(Icons.chevron_right, color: context.textSecondary);
  }
}
