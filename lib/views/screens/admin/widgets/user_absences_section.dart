import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../controllers/admin/admin_controller.dart';
import '../../../../core/core.dart';
import '../../../../models/models.dart';

/// Absences section widget for user details
class UserAbsencesSection extends ConsumerWidget {
  final UserModel user;

  const UserAbsencesSection({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref, l10n),
          if (user.absences.isEmpty)
            _buildEmpty(context, l10n)
          else
            _buildAbsencesList(context, ref, dateFormat, l10n),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.event_busy_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              '${user.absenceCount} ${l10n.translate('total')}',
              style: TextStyle(fontSize: 14, color: context.textSecondary),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () => _showAddAbsenceDialog(context, ref, l10n),
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.translate('add')),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: Text(
          l10n.translate('no_absences'),
          style: TextStyle(color: context.textSecondary),
        ),
      ),
    );
  }

  Widget _buildAbsencesList(
    BuildContext context,
    WidgetRef ref,
    DateFormat dateFormat,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        const SizedBox(height: 12),
        const Divider(),
        ...user.absences.map((a) => _AbsenceTile(
              user: user,
              absence: a,
              dateFormat: dateFormat,
            )),
      ],
    );
  }

  Future<void> _showAddAbsenceDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final meetingTitleController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.translate('add_absence')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: meetingTitleController,
                decoration: InputDecoration(
                  labelText: l10n.translate('meeting_title'),
                  hintText: l10n.translate('meeting_title_hint'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 12),
                      Text(DateFormat('MMMM d, yyyy').format(selectedDate)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {
                'title': meetingTitleController.text,
                'date': selectedDate,
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.translate('add_absence')),
            ),
          ],
        ),
      ),
    );

    if (result != null && (result['title'] as String).trim().isNotEmpty) {
      final success = await ref.read(adminControllerProvider.notifier).addAbsence(
        user.id,
        'manual_${DateTime.now().millisecondsSinceEpoch}',
        (result['title'] as String).trim(),
        result['date'] as DateTime,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? l10n.translate('absence_added')
                : l10n.translate('error_adding_absence')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

class _AbsenceTile extends ConsumerWidget {
  final UserModel user;
  final UserAbsence absence;
  final DateFormat dateFormat;

  const _AbsenceTile({
    required this.user,
    required this.absence,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: absence.isExcused ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _buildContent(context, l10n)),
          _buildTrailing(context, ref, l10n),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                absence.meetingTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
              ),
            ),
            if (absence.isExcused) _buildExcusedBadge(l10n),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${l10n.translate('meeting_date')}: ${dateFormat.format(absence.meetingDate)}',
          style: TextStyle(fontSize: 11, color: context.textSecondary),
        ),
        if (absence.reason != null && absence.reason!.isNotEmpty)
          Text(
            '${l10n.translate('reason')}: ${absence.reason}',
            style: TextStyle(fontSize: 11, color: context.textSecondary),
          ),
      ],
    );
  }

  Widget _buildExcusedBadge(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        l10n.translate('excused'),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    if (!absence.isExcused) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 18),
        onSelected: (value) {
          if (value == 'excuse') {
            _showExcuseDialog(context, ref, l10n);
          } else if (value == 'remove') {
            _removeAbsence(context, ref, l10n);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'excuse',
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                const SizedBox(width: 8),
                Text(l10n.translate('excuse')),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'remove',
            child: Row(
              children: [
                const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                const SizedBox(width: 8),
                Text(l10n.translate('remove')),
              ],
            ),
          ),
        ],
      );
    }
    return IconButton(
      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
      onPressed: () => _removeAbsence(context, ref, l10n),
    );
  }

  Future<void> _showExcuseDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('excuse_absence')),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: l10n.translate('reason'),
            hintText: l10n.translate('excuse_reason_hint'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.translate('excuse')),
          ),
        ],
      ),
    );

    if (result != null) {
      final success = await ref
          .read(adminControllerProvider.notifier)
          .excuseAbsence(user.id, absence.id, result.trim());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? l10n.translate('absence_excused')
                : l10n.translate('error_excusing_absence')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeAbsence(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('confirm_remove_absence')),
        content: Text(l10n.translate('remove_absence_message')),
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
            child: Text(l10n.translate('remove')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(adminControllerProvider.notifier)
          .removeAbsence(user.id, absence.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? l10n.translate('absence_removed')
                : l10n.translate('error_removing_absence')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
