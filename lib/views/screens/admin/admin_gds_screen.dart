import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/gds/gds_controller.dart';
import '../../../controllers/admin/admin_controller.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';

/// Admin screen to manage GDS (Support Groups)
class AdminGDSScreen extends ConsumerStatefulWidget {
  const AdminGDSScreen({super.key});

  @override
  ConsumerState<AdminGDSScreen> createState() => _AdminGDSScreenState();
}

class _AdminGDSScreenState extends ConsumerState<AdminGDSScreen> {
  final _searchController = TextEditingController();
  bool _showInactive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canManage = ref.watch(canManageGDSProvider);
    final gdsAsync = ref.watch(allGDSProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(l10n.translate('manage_gds')),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            tooltip: _showInactive ? 'Hide inactive' : 'Show inactive',
            onPressed: () => setState(() => _showInactive = !_showInactive),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.navy,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l10n.translate('search_gds'),
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.6)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // GDS list
          Expanded(
            child: gdsAsync.when(
              data: (gdsList) {
                var filteredList = gdsList;

                // Filter by active status
                if (!_showInactive) {
                  filteredList = filteredList.where((g) => g.isActive).toList();
                }

                // Filter by search
                if (_searchController.text.isNotEmpty) {
                  final query = _searchController.text.toLowerCase();
                  filteredList = filteredList.where((g) =>
                      g.name.toLowerCase().contains(query) ||
                      (g.focus?.toLowerCase().contains(query) ?? false)).toList();
                }

                if (filteredList.isEmpty) {
                  return _buildEmptyState(context, l10n);
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(allGDSProvider),
                  color: AppColors.gold,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final gds = filteredList[index];
                      return _GDSCard(
                        gds: gds,
                        onTap: () => _showGDSDetail(context, gds),
                        onEdit: canManage ? () => _showEditGDS(context, gds) : null,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
              error: (error, _) => _buildErrorState(context, l10n),
            ),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateGDS(context),
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navy,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.translate('add_gds')),
            )
          : null,
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_outlined,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('no_gds'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate('no_gds_message'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(l10n.translate('error_loading')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(allGDSProvider),
            child: Text(l10n.translate('retry')),
          ),
        ],
      ),
    );
  }

  void _showGDSDetail(BuildContext context, GDSModel gds) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _GDSDetailSheet(gds: gds),
    );
  }

  void _showCreateGDS(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _GDSFormSheet(),
    );
  }

  void _showEditGDS(BuildContext context, GDSModel gds) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _GDSFormSheet(gds: gds),
    );
  }
}

class _GDSCard extends StatelessWidget {
  final GDSModel gds;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _GDSCard({
    required this.gds,
    required this.onTap,
    this.onEdit,
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
          border: !gds.isActive
              ? Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1)
              : null,
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
            // GDS icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: gds.isActive
                    ? AppColors.gold.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  Icons.groups_rounded,
                  size: 28,
                  color: gds.isActive ? AppColors.navy : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // GDS info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          gds.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: gds.isActive ? AppColors.navy : Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!gds.isActive)
                        Container(
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
                        ),
                    ],
                  ),
                  if (gds.focus != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      gds.focus!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        '${gds.memberCount} members',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.person_outline, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          gds.leaderName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Edit button
            if (onEdit != null)
              IconButton(
                onPressed: onEdit,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.navy,
                    size: 18,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}

class _GDSDetailSheet extends ConsumerWidget {
  final GDSModel gds;

  const _GDSDetailSheet({required this.gds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canManage = ref.watch(canManageGDSProvider);
    final dateFormat = DateFormat('MMM d, yyyy');

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          controller: scrollController,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.groups_rounded,
                      size: 32,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gds.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                      if (gds.focus != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          gds.focus!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description
            if (gds.description != null && gds.description!.isNotEmpty) ...[
              Text(
                l10n.translate('description'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                gds.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Info rows
            _buildInfoRow(Icons.people_outlined, l10n.translate('members'), '${gds.memberCount}'),
            _buildInfoRow(Icons.person_outlined, l10n.translate('leader'), gds.leaderName),
            _buildInfoRow(Icons.calendar_today_outlined, l10n.translate('created'), dateFormat.format(gds.createdAt)),
            _buildInfoRow(
              Icons.circle,
              l10n.translate('status'),
              gds.isActive ? l10n.translate('active') : l10n.translate('inactive'),
              valueColor: gds.isActive ? Colors.green : Colors.red,
            ),

            const SizedBox(height: 24),

            // Members section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('members'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                if (canManage)
                  TextButton.icon(
                    onPressed: () => _showAddMemberDialog(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.translate('add')),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (gds.members.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    l10n.translate('no_members'),
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              ...gds.members.map((member) => _buildMemberTile(context, ref, member, canManage)),

            if (canManage) ...[
              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _toggleActive(context, ref),
                      icon: Icon(gds.isActive ? Icons.block : Icons.check_circle_outline),
                      label: Text(gds.isActive
                          ? l10n.translate('deactivate')
                          : l10n.translate('activate')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: gds.isActive ? Colors.orange : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteGDS(context, ref),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.translate('delete')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
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
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
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

  Widget _buildMemberTile(BuildContext context, WidgetRef ref, GDSMember member, bool canManage) {
    final l10n = AppLocalizations.of(context);
    final isLeader = member.id == gds.leaderId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLeader ? AppColors.gold.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: isLeader ? Border.all(color: AppColors.gold.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isLeader ? AppColors.navy : AppColors.navy.withValues(alpha: 0.1),
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: isLeader ? Colors.white : AppColors.navy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    if (isLeader) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.translate('leader'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (member.role != null && member.role!.isNotEmpty && !isLeader)
                  Text(
                    member.role!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          if (canManage && !isLeader)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
              onPressed: () => _removeMember(context, ref, member),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddMemberDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final usersAsync = ref.read(allUsersProvider);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('add_member')),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: usersAsync.when(
            data: (users) {
              // Filter out users already in the group
              final availableUsers = users.where((u) => !gds.memberIds.contains(u.id)).toList();

              if (availableUsers.isEmpty) {
                return Center(
                  child: Text(l10n.translate('no_users_available')),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: availableUsers.length,
                itemBuilder: (context, index) {
                  final user = availableUsers[index];
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
                      Navigator.pop(context);
                      final success = await ref.read(gdsControllerProvider.notifier)
                          .addMember(gds.id, user.id, user.fullName);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? l10n.translate('member_added')
                                : l10n.translate('error_adding_member')),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                        if (success) Navigator.pop(context);
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(child: Text(l10n.translate('error_loading'))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(BuildContext context, WidgetRef ref, GDSMember member) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('confirm_remove_member')),
        content: Text('${l10n.translate('remove_member_message')} ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.translate('remove')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(gdsControllerProvider.notifier)
          .removeMember(gds.id, member.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? l10n.translate('member_removed')
                : l10n.translate('error_removing_member')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) Navigator.pop(context);
      }
    }
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final success = await ref.read(gdsControllerProvider.notifier)
        .toggleGDSActive(gds.id, !gds.isActive);

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? l10n.translate('gds_updated')
              : l10n.translate('error_updating_gds')),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteGDS(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('confirm_delete')),
        content: Text(l10n.translate('delete_gds_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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
      final success = await ref.read(gdsControllerProvider.notifier)
          .deleteGDS(gds.id);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? l10n.translate('gds_deleted')
                : l10n.translate('error_deleting_gds')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

class _GDSFormSheet extends ConsumerStatefulWidget {
  final GDSModel? gds;

  const _GDSFormSheet({this.gds});

  @override
  ConsumerState<_GDSFormSheet> createState() => _GDSFormSheetState();
}

class _GDSFormSheetState extends ConsumerState<_GDSFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _focusController;
  String? _selectedLeaderId;
  String? _selectedLeaderName;
  bool _isLoading = false;

  bool get isEditing => widget.gds != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gds?.name);
    _descriptionController = TextEditingController(text: widget.gds?.description);
    _focusController = TextEditingController(text: widget.gds?.focus);
    _selectedLeaderId = widget.gds?.leaderId;
    _selectedLeaderName = widget.gds?.leaderName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final usersAsync = ref.watch(allUsersProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? l10n.translate('edit_gds') : l10n.translate('create_gds'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.translate('gds_name'),
                  hintText: 'e.g., Environment Team',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.translate('field_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Focus field
              TextFormField(
                controller: _focusController,
                decoration: InputDecoration(
                  labelText: l10n.translate('focus_area'),
                  hintText: 'e.g., Environment, Education, Culture',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.translate('description'),
                  hintText: l10n.translate('gds_description_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Leader selection
              Text(
                l10n.translate('select_leader'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              usersAsync.when(
                data: (users) => DropdownButtonFormField<String>(
                  value: _selectedLeaderId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  hint: Text(l10n.translate('select_leader')),
                  items: users.map((user) => DropdownMenuItem(
                    value: user.id,
                    child: Text(user.fullName),
                  )).toList(),
                  onChanged: (value) {
                    final user = users.firstWhere((u) => u.id == value);
                    setState(() {
                      _selectedLeaderId = value;
                      _selectedLeaderName = user.fullName;
                    });
                  },
                  validator: (value) {
                    if (!isEditing && (value == null || value.isEmpty)) {
                      return l10n.translate('field_required');
                    }
                    return null;
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Text(l10n.translate('error_loading')),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          isEditing ? l10n.translate('save') : l10n.translate('create'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final controller = ref.read(gdsControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);
    bool success;

    if (isEditing) {
      final updatedGDS = widget.gds!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        focus: _focusController.text.trim().isEmpty ? null : _focusController.text.trim(),
        leaderId: _selectedLeaderId ?? widget.gds!.leaderId,
        leaderName: _selectedLeaderName ?? widget.gds!.leaderName,
      );
      success = await controller.updateGDS(updatedGDS);
    } else {
      final id = await controller.createGDS(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        focus: _focusController.text.trim().isEmpty ? null : _focusController.text.trim(),
        leaderId: _selectedLeaderId!,
        leaderName: _selectedLeaderName!,
      );
      success = id != null;
    }

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (isEditing ? l10n.translate('gds_updated') : l10n.translate('gds_created'))
              : l10n.translate('error_saving_gds')),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
