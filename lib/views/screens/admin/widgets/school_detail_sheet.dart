import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../controllers/schools/school_controller.dart';
import '../../../../controllers/admin/admin_controller.dart';
import '../../../../core/core.dart';
import '../../../../models/models.dart';
import 'school_members_sheet.dart';

/// Detail sheet for viewing school information
class SchoolDetailSheet extends ConsumerWidget {
  final SchoolModel school;

  const SchoolDetailSheet({super.key, required this.school});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canManage = ref.watch(canManageSchoolsProvider);
    final usersAsync = ref.watch(usersByRoleProvider(UserRole.schoolRep));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          controller: scrollController,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildInfoSection(l10n),
            const SizedBox(height: 24),
            _SchoolRepSection(
              school: school,
              canManage: canManage,
              usersAsync: usersAsync,
            ),
            const SizedBox(height: 24),
            _SchoolMembersSection(school: school),
            if (canManage) ...[
              const SizedBox(height: 32),
              _ActionButtons(school: school),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              school.shortName.isNotEmpty
                  ? school.shortName.substring(0, school.shortName.length.clamp(0, 2))
                  : 'S',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                school.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                school.shortName,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(AppLocalizations l10n) {
    return Column(
      children: [
        _InfoRow(
          icon: Icons.people_outlined,
          label: l10n.translate('students'),
          value: '${school.studentCount}',
        ),
        if (school.city != null)
          _InfoRow(
            icon: Icons.location_city_outlined,
            label: l10n.translate('city'),
            value: school.city!,
          ),
        if (school.address != null)
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: l10n.translate('address'),
            value: school.address!,
          ),
        _InfoRow(
          icon: Icons.circle,
          label: l10n.translate('status'),
          value: school.isActive ? l10n.translate('active') : l10n.translate('inactive'),
          valueColor: school.isActive ? Colors.green : Colors.red,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.navy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SchoolRepSection extends ConsumerWidget {
  final SchoolModel school;
  final bool canManage;
  final AsyncValue<List<UserModel>> usersAsync;

  const _SchoolRepSection({
    required this.school,
    required this.canManage,
    required this.usersAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('school_representative'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 12),
        if (school.schoolRepName != null)
          _buildRepCard(context, ref, l10n)
        else
          _buildNoRepCard(context, ref, l10n),
      ],
    );
  }

  Widget _buildRepCard(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.navy,
            child: Text(
              school.schoolRepName![0].toUpperCase(),
              style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              school.schoolRepName!,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ),
          if (canManage)
            TextButton(
              onPressed: () => _showChangeRepDialog(context, ref),
              child: Text(l10n.translate('change')),
            ),
        ],
      ),
    );
  }

  Widget _buildNoRepCard(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.person_add_outlined, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.translate('no_representative'),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
          if (canManage)
            TextButton(
              onPressed: () => _showChangeRepDialog(context, ref),
              child: Text(l10n.translate('assign')),
            ),
        ],
      ),
    );
  }

  void _showChangeRepDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('select_representative')),
        content: SizedBox(
          width: double.maxFinite,
          child: usersAsync.when(
            data: (users) => ListView.builder(
              shrinkWrap: true,
              itemCount: users.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_off)),
                    title: Text(l10n.translate('none')),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ref.read(schoolControllerProvider.notifier)
                          .assignSchoolRep(school.id, null, null);
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                }
                final user = users[index - 1];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.navy.withValues(alpha: 0.1),
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(user.fullName),
                  subtitle: Text(user.email),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(schoolControllerProvider.notifier)
                        .assignSchoolRep(school.id, user.id, user.fullName);
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(l10n.translate('error_loading')),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('cancel')),
          ),
        ],
      ),
    );
  }
}

class _SchoolMembersSection extends ConsumerWidget {
  final SchoolModel school;

  const _SchoolMembersSection({required this.school});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final membersAsync = ref.watch(usersBySchoolProvider(school.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.translate('school_members'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showMembersSheet(context, ref),
              icon: const Icon(Icons.people_outline, size: 18),
              label: Text(l10n.translate('view_all')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMembersPreview(membersAsync, l10n),
      ],
    );
  }

  Widget _buildMembersPreview(AsyncValue<List<UserModel>> membersAsync, AppLocalizations l10n) {
    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.people_outline, color: Colors.grey[500]),
                const SizedBox(width: 12),
                Text(
                  l10n.translate('no_members'),
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final previewMembers = members.take(3).toList();
        final remainingCount = members.length - 3;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ...previewMembers.map((m) => _MemberPreviewRow(member: m)),
              if (remainingCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+$remainingCount more members',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Text(l10n.translate('error_loading'), style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  void _showMembersSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SchoolMembersSheet(school: school),
    );
  }
}

class _MemberPreviewRow extends StatelessWidget {
  final UserModel member;

  const _MemberPreviewRow({required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: member.role.badgeBackgroundColor,
            child: Text(
              member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: member.role.badgeTextColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  member.role.displayName,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: member.status.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              member.status.displayName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: member.status.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  final SchoolModel school;

  const _ActionButtons({required this.school});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _toggleActive(context, ref),
            icon: Icon(school.isActive ? Icons.block : Icons.check_circle_outline),
            label: Text(school.isActive
                ? l10n.translate('deactivate')
                : l10n.translate('activate')),
            style: OutlinedButton.styleFrom(
              foregroundColor: school.isActive ? Colors.orange : Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _deleteSchool(context, ref),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.translate('delete')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final success = await ref
        .read(schoolControllerProvider.notifier)
        .toggleSchoolActive(school.id, !school.isActive);

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? l10n.translate('school_updated')
              : l10n.translate('error_updating_school')),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSchool(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('confirm_delete')),
        content: Text(l10n.translate('delete_school_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(schoolControllerProvider.notifier)
          .deleteSchool(school.id);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? l10n.translate('school_deleted')
                : l10n.translate('error_deleting_school')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
