import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';

/// Screen for sending county-wide notifications (BEX/Admin only)
class SendNotificationScreen extends ConsumerStatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  ConsumerState<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends ConsumerState<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  NotificationType _selectedType = NotificationType.systemAlert;
  final Set<UserRole> _selectedRoles = {};
  bool _sendToAllRoles = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canSend = ref.watch(canSendCountyNotificationsProvider);

    if (!canSend) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.translate('send_notification')),
        ),
        body: Center(
          child: Text(l10n.translate('permission_denied')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(l10n.translate('send_notification')),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          children: [
            // Header info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.translate('county_notification_info'),
                      style: TextStyle(
                        color: Colors.amber[800],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notification Type
            _buildSectionTitle(l10n.translate('notification_type')),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: NotificationType.values.map((type) {
                final isSelected = _selectedType == type;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? _getTypeColor(type) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? _getTypeColor(type) : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTypeIcon(type),
                          size: 18,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getTypeLabel(type, l10n),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Title
            _buildSectionTitle(l10n.translate('title')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: l10n.translate('notification_title_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.translate('field_required');
                }
                if (value.trim().length < 5) {
                  return l10n.translate('too_short');
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Body/Message
            _buildSectionTitle(l10n.translate('message')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: l10n.translate('notification_body_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.translate('field_required');
                }
                if (value.trim().length < 10) {
                  return l10n.translate('too_short');
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Target audience
            _buildSectionTitle(l10n.translate('target_audience')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // All roles toggle
                  SwitchListTile(
                    title: Text(l10n.translate('all_users')),
                    subtitle: Text(
                      l10n.translate('send_to_all_users'),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    value: _sendToAllRoles,
                    onChanged: (value) {
                      setState(() {
                        _sendToAllRoles = value;
                        if (value) {
                          _selectedRoles.clear();
                        }
                      });
                    },
                    activeTrackColor: AppColors.gold.withValues(alpha: 0.5),
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.gold;
                      }
                      return null;
                    }),
                    contentPadding: EdgeInsets.zero,
                  ),

                  if (!_sendToAllRoles) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      l10n.translate('select_roles'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        UserRole.student,
                        UserRole.classRep,
                        UserRole.schoolRep,
                        UserRole.department,
                        UserRole.bex,
                      ].map((role) {
                        final isSelected = _selectedRoles.contains(role);
                        return FilterChip(
                          label: Text(role.displayName),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedRoles.add(role);
                              } else {
                                _selectedRoles.remove(role);
                              }
                            });
                          },
                          selectedColor: AppColors.gold,
                          checkmarkColor: AppColors.navy,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Send button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleSend,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.navy,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isLoading
                      ? l10n.translate('sending')
                      : l10n.translate('send_notification'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.meetingReminder:
        return Icons.event_rounded;
      case NotificationType.newAnnouncement:
        return Icons.campaign_rounded;
      case NotificationType.initiativeUpdate:
        return Icons.lightbulb_rounded;
      case NotificationType.pollReminder:
        return Icons.poll_rounded;
      case NotificationType.systemAlert:
        return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.meetingReminder:
        return Colors.indigo;
      case NotificationType.newAnnouncement:
        return Colors.purple;
      case NotificationType.initiativeUpdate:
        return Colors.amber;
      case NotificationType.pollReminder:
        return Colors.orange;
      case NotificationType.systemAlert:
        return Colors.blue;
    }
  }

  String _getTypeLabel(NotificationType type, AppLocalizations l10n) {
    switch (type) {
      case NotificationType.meetingReminder:
        return l10n.translate('meeting');
      case NotificationType.newAnnouncement:
        return l10n.translate('announcement');
      case NotificationType.initiativeUpdate:
        return l10n.translate('initiative');
      case NotificationType.pollReminder:
        return l10n.translate('poll');
      case NotificationType.systemAlert:
        return l10n.translate('general');
    }
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_sendToAllRoles && _selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('select_at_least_one_role')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirm before sending
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('confirm_send')),
        content: Text(AppLocalizations.of(context).translate('send_notification_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navy,
            ),
            child: Text(AppLocalizations.of(context).translate('send')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final success = await ref.read(notificationControllerProvider.notifier).sendCountyWideNotification(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          type: _selectedType,
          targetRoles: _sendToAllRoles ? null : _selectedRoles.toList(),
        );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('notification_sent')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('error_sending_notification')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
