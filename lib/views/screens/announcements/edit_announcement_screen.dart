import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';

/// Screen for editing an existing announcement
class EditAnnouncementScreen extends ConsumerStatefulWidget {
  final AnnouncementModel announcement;

  const EditAnnouncementScreen({super.key, required this.announcement});

  @override
  ConsumerState<EditAnnouncementScreen> createState() =>
      _EditAnnouncementScreenState();
}

class _EditAnnouncementScreenState
    extends ConsumerState<EditAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  late AnnouncementType _selectedType;
  late bool _isPinned;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement.title);
    _contentController = TextEditingController(text: widget.announcement.content);
    _selectedType = widget.announcement.type;
    _isPinned = widget.announcement.isPinned;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);

    final canCreateCounty = user != null &&
        (user.role == UserRole.bex || user.role == UserRole.superadmin);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: context.shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.close, color: context.iconColor, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.translate('edit_announcement'),
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isLoading ? null : _handleSave,
              child: Text(
                l10n.translate('save'),
                style: TextStyle(
                  color: _isLoading ? Colors.grey : AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Type selector
            Text(
              l10n.translate('announcement_type'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TypeCard(
                    title: l10n.translate('school'),
                    icon: Icons.school_rounded,
                    isSelected: _selectedType == AnnouncementType.school,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                    onTap: () =>
                        setState(() => _selectedType = AnnouncementType.school),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeCard(
                    title: 'CJE',
                    icon: Icons.account_balance_rounded,
                    isSelected: _selectedType == AnnouncementType.county,
                    isDisabled: !canCreateCounty,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                    onTap: canCreateCounty
                        ? () => setState(
                            () => _selectedType = AnnouncementType.county)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Title field
            Text(
              l10n.translate('title'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.translate('announcement_title_hint'),
                hintStyle: TextStyle(color: context.textSecondary),
                filled: true,
                fillColor: context.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.gold, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.translate('title_required');
                }
                if (value.trim().length < 5) {
                  return l10n.translate('title_too_short');
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Content field
            Text(
              l10n.translate('content'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              maxLines: 8,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.translate('announcement_content_hint'),
                hintStyle: TextStyle(color: context.textSecondary),
                filled: true,
                fillColor: context.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.gold, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.translate('content_required');
                }
                if (value.trim().length < 20) {
                  return l10n.translate('content_too_short');
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Pin toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isPinned
                          ? AppColors.gold.withValues(alpha: 0.15)
                          : context.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.push_pin_rounded,
                      color: _isPinned ? AppColors.gold : context.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('pin_announcement'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.translate('pin_announcement_desc'),
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isPinned,
                    onChanged: (value) => setState(() => _isPinned = value),
                    activeTrackColor: AppColors.gold.withValues(alpha: 0.5),
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.gold;
                      }
                      return null;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.navy,
                        ),
                      )
                    : Text(
                        l10n.translate('save_changes'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = ref.read(currentUserProvider);
    final updatedAnnouncement = widget.announcement.copyWith(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      type: _selectedType,
      isPinned: _isPinned,
      schoolId: _selectedType == AnnouncementType.school ? user?.schoolId : null,
      schoolName: _selectedType == AnnouncementType.school ? user?.schoolName : null,
      updatedAt: DateTime.now(),
    );

    final controller = ref.read(announcementControllerProvider.notifier);
    final success = await controller.updateAnnouncement(updatedAnnouncement);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, updatedAnnouncement);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('announcement_updated')),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('error_updating_announcement')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Type selection card widget
class _TypeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final bool isDark;
  final VoidCallback? onTap;

  const _TypeCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    this.isDisabled = false,
    this.isDark = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.15)
              : context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.gold
                : isDisabled
                    ? (isDark ? Colors.grey.shade700 : Colors.grey.shade200)
                    : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isDisabled
                  ? (isDark ? Colors.grey.shade600 : Colors.grey.shade300)
                  : isSelected
                      ? AppColors.gold
                      : (isDark ? AppColors.gold : AppColors.navy),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDisabled
                    ? (isDark ? Colors.grey.shade600 : Colors.grey.shade400)
                    : isSelected
                        ? AppColors.gold
                        : context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
