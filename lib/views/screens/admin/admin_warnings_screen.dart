import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';

/// Admin screen for managing warnings and absences
class AdminWarningsScreen extends ConsumerStatefulWidget {
  const AdminWarningsScreen({super.key});

  @override
  ConsumerState<AdminWarningsScreen> createState() => _AdminWarningsScreenState();
}

class _AdminWarningsScreenState extends ConsumerState<AdminWarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canManage = ref.watch(canManageWarningsProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.translate('warnings_absences'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: l10n.translate('warnings')),
            Tab(text: l10n.translate('absences')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WarningsTab(canManage: canManage),
          _AbsencesTab(canManage: canManage),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showIssueWarningDialog(context),
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navy,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.translate('issue_warning')),
            )
          : null,
    );
  }

  void _showIssueWarningDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _IssueWarningSheet(),
    );
  }
}

class _WarningsTab extends ConsumerWidget {
  final bool canManage;

  const _WarningsTab({required this.canManage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final warningsAsync = ref.watch(
      warningsProvider(WarningFilter(countyId: user?.city)),
    );

    return warningsAsync.when(
      data: (warnings) {
        if (warnings.isEmpty) {
          return _buildEmptyState(context, l10n, Icons.warning_amber_rounded, 'no_warnings');
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(warningsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: warnings.length,
            itemBuilder: (context, index) {
              return _WarningCard(
                warning: warnings[index],
                canManage: canManage,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, _) => Center(child: Text(l10n.translate('error_loading'))),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n, IconData icon, String key) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: context.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            l10n.translate(key),
            style: TextStyle(fontSize: 16, color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AbsencesTab extends ConsumerWidget {
  final bool canManage;

  const _AbsencesTab({required this.canManage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final absencesAsync = ref.watch(
      absencesProvider(AbsenceFilter(countyId: user?.city)),
    );

    return absencesAsync.when(
      data: (absences) {
        if (absences.isEmpty) {
          return _buildEmptyState(context, l10n, Icons.event_busy_rounded, 'no_absences');
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(absencesProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: absences.length,
            itemBuilder: (context, index) {
              return _AbsenceCard(
                absence: absences[index],
                canManage: canManage,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, _) => Center(child: Text(l10n.translate('error_loading'))),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n, IconData icon, String key) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: context.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            l10n.translate(key),
            style: TextStyle(fontSize: 16, color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends ConsumerWidget {
  final WarningModel warning;
  final bool canManage;

  const _WarningCard({required this.warning, required this.canManage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: warning.isActive ? _getTypeColor(warning.type) : context.borderColor,
          width: 1,
        ),
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getTypeColor(warning.type).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(
                  _getTypeIcon(warning.type),
                  color: _getTypeColor(warning.type),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warning.type.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getTypeColor(warning.type),
                        ),
                      ),
                      Text(
                        dateFormat.format(warning.issuedAt),
                        style: TextStyle(fontSize: 12, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!warning.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.textSecondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.translate('inactive'),
                      style: TextStyle(fontSize: 11, color: context.textSecondary),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: context.textPrimary.withValues(alpha: 0.1),
                      child: Text(
                        warning.userName.isNotEmpty ? warning.userName[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            warning.userName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                          if (warning.userSchoolName != null)
                            Text(
                              warning.userSchoolName!,
                              style: TextStyle(fontSize: 12, color: context.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Reason
                Text(
                  warning.reason,
                  style: TextStyle(fontSize: 14, color: context.textPrimary),
                ),

                if (warning.details != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    warning.details!,
                    style: TextStyle(fontSize: 13, color: context.textSecondary),
                  ),
                ],

                const SizedBox(height: 12),

                // Footer
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: context.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n.translate('issued_by')}: ${warning.issuedByName}',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                    const Spacer(),
                    if (canManage && warning.isActive)
                      TextButton(
                        onPressed: () => _deactivateWarning(context, ref),
                        child: Text(
                          l10n.translate('deactivate'),
                          style: const TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(WarningType type) {
    switch (type) {
      case WarningType.verbal:
        return Colors.orange;
      case WarningType.written:
        return Colors.deepOrange;
      case WarningType.suspension:
        return Colors.red;
      case WarningType.removal:
        return Colors.red[900]!;
    }
  }

  IconData _getTypeIcon(WarningType type) {
    switch (type) {
      case WarningType.verbal:
        return Icons.record_voice_over_outlined;
      case WarningType.written:
        return Icons.edit_document;
      case WarningType.suspension:
        return Icons.pause_circle_outline;
      case WarningType.removal:
        return Icons.remove_circle_outline;
    }
  }

  void _deactivateWarning(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('deactivate_warning')),
        content: Text(l10n.translate('deactivate_warning_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.translate('deactivate')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(warningControllerProvider.notifier)
          .deactivateWarning(warning.id, warning.userId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? l10n.translate('warning_deactivated')
                : l10n.translate('error_deactivating_warning')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

class _AbsenceCard extends ConsumerWidget {
  final AbsenceModel absence;
  final bool canManage;

  const _AbsenceCard({required this.absence, required this.canManage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final isExcused = absence.type == AbsenceType.excused;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with meeting info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.gold.withValues(alpha: 0.15) : AppColors.navy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.event_busy_rounded, color: isDark ? AppColors.gold : AppColors.navy, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        absence.meetingTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dateFormat.format(absence.meetingDate),
                        style: TextStyle(fontSize: 12, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExcused
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    absence.type.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isExcused ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: context.textSecondary.withValues(alpha: 0.2),
                  child: Text(
                    absence.userName.isNotEmpty ? absence.userName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        absence.userName,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textPrimary),
                      ),
                      if (absence.userSchoolName != null)
                        Text(
                          absence.userSchoolName!,
                          style: TextStyle(fontSize: 11, color: context.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            if (absence.reason != null) ...[
              const SizedBox(height: 8),
              Text(
                absence.reason!,
                style: TextStyle(fontSize: 13, color: context.textSecondary),
              ),
            ],

            // Actions
            if (canManage && !isExcused) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _markAsExcused(context, ref),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(l10n.translate('mark_excused')),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _markAsExcused(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final success = await ref
        .read(warningControllerProvider.notifier)
        .updateAbsenceType(absence.id, AbsenceType.excused, absence.userId, absence.meetingId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? l10n.translate('absence_updated')
              : l10n.translate('error_updating_absence')),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

class _IssueWarningSheet extends ConsumerStatefulWidget {
  const _IssueWarningSheet();

  @override
  ConsumerState<_IssueWarningSheet> createState() => _IssueWarningSheetState();
}

class _IssueWarningSheetState extends ConsumerState<_IssueWarningSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _detailsController = TextEditingController();

  UserModel? _selectedUser;
  WarningType _selectedType = WarningType.verbal;
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final usersAsync = ref.watch(allUsersProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                l10n.translate('issue_warning'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // User selector
              Text(
                l10n.translate('select_user'),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
              ),
              const SizedBox(height: 8),
              usersAsync.when(
                data: (users) => DropdownButtonFormField<UserModel>(
                  initialValue: _selectedUser,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                  ),
                  hint: Text(l10n.translate('select_user')),
                  items: users.map((user) => DropdownMenuItem(
                    value: user,
                    child: Text(user.fullName),
                  )).toList(),
                  onChanged: (user) => setState(() => _selectedUser = user),
                  validator: (value) => value == null ? l10n.translate('field_required') : null,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Text(l10n.translate('error_loading')),
              ),
              const SizedBox(height: 16),

              // Warning type
              Text(
                l10n.translate('warning_type'),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: WarningType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return ChoiceChip(
                    label: Text(type.displayName),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedType = type),
                    selectedColor: AppColors.gold,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.navy : context.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Reason
              Text(
                l10n.translate('reason'),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  hintText: l10n.translate('reason_hint'),
                  filled: true,
                  fillColor: context.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                ),
                maxLines: 2,
                validator: (value) =>
                    value == null || value.isEmpty ? l10n.translate('field_required') : null,
              ),
              const SizedBox(height: 16),

              // Details (optional)
              Text(
                l10n.translate('details_optional'),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _detailsController,
                decoration: InputDecoration(
                  hintText: l10n.translate('details_hint'),
                  filled: true,
                  fillColor: context.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitWarning,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
                        )
                      : Text(
                          l10n.translate('issue_warning'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitWarning() async {
    if (!_formKey.currentState!.validate() || _selectedUser == null) return;

    setState(() => _isLoading = true);

    final success = await ref.read(warningControllerProvider.notifier).issueWarning(
      userId: _selectedUser!.id,
      userName: _selectedUser!.fullName,
      userSchoolId: _selectedUser!.schoolId,
      userSchoolName: _selectedUser!.schoolName,
      type: _selectedType,
      reason: _reasonController.text.trim(),
      details: _detailsController.text.trim().isEmpty ? null : _detailsController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? l10n.translate('warning_issued')
              : l10n.translate('error_issuing_warning')),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
