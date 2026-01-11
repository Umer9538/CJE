import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';

/// Screen for creating or editing an initiative
class CreateInitiativeScreen extends ConsumerStatefulWidget {
  /// Pass an existing initiative to edit, or null to create new
  final InitiativeModel? initiative;

  const CreateInitiativeScreen({super.key, this.initiative});

  @override
  ConsumerState<CreateInitiativeScreen> createState() =>
      _CreateInitiativeScreenState();
}

class _CreateInitiativeScreenState
    extends ConsumerState<CreateInitiativeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _problemController = TextEditingController();
  final _solutionController = TextEditingController();
  final _impactController = TextEditingController();
  final _tagController = TextEditingController();

  final List<String> _tags = [];
  bool _isLoading = false;

  // Initiative type (school or county level)
  InitiativeType _selectedType = InitiativeType.school;

  // School selection for BEX/Superadmin
  String? _selectedSchoolId;
  String? _selectedSchoolName;

  bool get _isEditing => widget.initiative != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if editing
    if (_isEditing) {
      final initiative = widget.initiative!;
      _titleController.text = initiative.title;
      _descriptionController.text = initiative.description;
      _problemController.text = initiative.problem ?? '';
      _solutionController.text = initiative.solution ?? '';
      _impactController.text = initiative.impact ?? '';
      _tags.addAll(initiative.tags);
      _selectedType = initiative.type;
      _selectedSchoolId = initiative.schoolId;
      _selectedSchoolName = initiative.schoolName;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _problemController.dispose();
    _solutionController.dispose();
    _impactController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
          _isEditing
              ? l10n.translate('edit_initiative')
              : l10n.translate('create_initiative'),
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isEditing ? Icons.edit_rounded : Icons.lightbulb_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing
                          ? l10n.translate('edit_initiative_info')
                          : 'Share your ideas to improve student life. Your initiative can make a difference!',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Initiative type selector
            _buildTypeSelector(context, l10n),

            // School selection for BEX/Superadmin (only for school-level initiatives)
            if (_selectedType == InitiativeType.school)
              _buildSchoolDropdown(context, l10n),

            // Title
            _buildLabel(context, l10n.translate('initiative_title'), required: true),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              style: TextStyle(color: context.textPrimary),
              decoration: _buildInputDecoration(
                context,
                l10n.translate('initiative_title_hint'),
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

            // Description
            _buildLabel(context, l10n.translate('initiative_description'), required: true),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              style: TextStyle(color: context.textPrimary),
              decoration: _buildInputDecoration(
                context,
                l10n.translate('initiative_description_hint'),
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

            // Problem
            _buildLabel(context, l10n.translate('problem')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _problemController,
              maxLines: 3,
              style: TextStyle(color: context.textPrimary),
              decoration: _buildInputDecoration(
                context,
                l10n.translate('problem_hint'),
              ),
            ),
            const SizedBox(height: 24),

            // Solution
            _buildLabel(context, l10n.translate('solution')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _solutionController,
              maxLines: 3,
              style: TextStyle(color: context.textPrimary),
              decoration: _buildInputDecoration(
                context,
                l10n.translate('solution_hint'),
              ),
            ),
            const SizedBox(height: 24),

            // Impact
            _buildLabel(context, l10n.translate('impact')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _impactController,
              maxLines: 3,
              style: TextStyle(color: context.textPrimary),
              decoration: _buildInputDecoration(
                context,
                l10n.translate('impact_hint'),
              ),
            ),
            const SizedBox(height: 24),

            // Tags
            _buildLabel(context, 'Tags'),
            const SizedBox(height: 12),
            _buildTagsSection(context),
            const SizedBox(height: 32),

            // Submit/Update button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _handleSubmit(true),
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
                        _isEditing
                            ? l10n.translate('update_initiative')
                            : l10n.translate('submit_initiative'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Save as draft (only for new initiatives or draft status)
            if (!_isEditing || widget.initiative?.status == InitiativeStatus.draft)
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => _handleSubmit(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textPrimary,
                    side: BorderSide(color: context.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.translate('save_as_draft'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  /// Build school dropdown for BEX/Superadmin users
  Widget _buildSchoolDropdown(BuildContext context, AppLocalizations l10n) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    // Only show for BEX and Superadmin
    if (user.role != UserRole.bex && user.role != UserRole.superadmin) {
      return const SizedBox.shrink();
    }

    final schoolsAsync = ref.watch(activeSchoolsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, l10n.translate('select_school'), required: true),
        const SizedBox(height: 12),
        schoolsAsync.when(
          data: (schools) {
            if (schools.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: isDark ? Border.all(color: Colors.grey[700]!) : null,
                ),
                child: Text(
                  l10n.translate('no_schools_available'),
                  style: TextStyle(color: context.textSecondary),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: isDark ? Border.all(color: Colors.grey[700]!) : null,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedSchoolId,
                  hint: Text(
                    l10n.translate('select_school'),
                    style: TextStyle(color: context.textSecondary),
                  ),
                  dropdownColor: context.cardColor,
                  style: TextStyle(color: context.textPrimary),
                  icon: Icon(Icons.arrow_drop_down, color: context.textSecondary),
                  items: schools.map((school) {
                    return DropdownMenuItem<String>(
                      value: school.id,
                      child: Text(
                        school.name,
                        style: TextStyle(color: context.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      final selectedSchool = schools.firstWhere((s) => s.id == value);
                      setState(() {
                        _selectedSchoolId = value;
                        _selectedSchoolName = selectedSchool.name;
                      });
                    }
                  },
                ),
              ),
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: isDark ? Border.all(color: Colors.grey[700]!) : null,
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: isDark ? Border.all(color: Colors.grey[700]!) : null,
            ),
            child: Text(
              l10n.translate('error_loading_schools'),
              style: TextStyle(color: context.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Build initiative type selector (School or County level)
  Widget _buildTypeSelector(BuildContext context, AppLocalizations l10n) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    // Only BEX and Superadmin can create county-level initiatives
    final canCreateCountyInitiative =
        user.role == UserRole.bex || user.role == UserRole.superadmin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, l10n.translate('initiative_type')),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(
                context: context,
                title: l10n.translate('school'),
                icon: Icons.school_rounded,
                isSelected: _selectedType == InitiativeType.school,
                onTap: () {
                  setState(() => _selectedType = InitiativeType.school);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeOption(
                context: context,
                title: l10n.translate('county'),
                icon: Icons.account_balance_rounded,
                isSelected: _selectedType == InitiativeType.county,
                isEnabled: canCreateCountyInitiative,
                onTap: canCreateCountyInitiative
                    ? () {
                        setState(() {
                          _selectedType = InitiativeType.county;
                          // Clear school selection for county-level initiatives
                          _selectedSchoolId = null;
                          _selectedSchoolName = null;
                        });
                      }
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Build a single type option button
  Widget _buildTypeOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    bool isEnabled = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.15)
              : context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.gold : context.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Opacity(
          opacity: isEnabled ? 1 : 0.5,
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.gold : context.textSecondary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? context.textPrimary : context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textSecondary),
      filled: true,
      fillColor: context.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: isDark ? BorderSide(color: Colors.grey[700]!) : BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: isDark ? BorderSide(color: Colors.grey[700]!) : BorderSide.none,
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
    );
  }

  Widget _buildTagsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.grey[700]!) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Existing tags
          if (_tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.gold.withValues(alpha: 0.15) : AppColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tag,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _tags.remove(tag)),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Add tag input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Add a tag...',
                    hintStyle: TextStyle(color: context.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              IconButton(
                onPressed: _addTag,
                icon: const Icon(Icons.add_circle_outline, color: AppColors.gold),
              ),
            ],
          ),

          // Suggested tags
          const SizedBox(height: 12),
          Text(
            'Suggested:',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Education',
              'Environment',
              'Health',
              'Technology',
              'Culture',
              'Sports',
            ].where((tag) => !_tags.contains(tag)).map((tag) {
              return GestureDetector(
                onTap: () => setState(() => _tags.add(tag)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+ $tag',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  Future<void> _handleSubmit(bool submitImmediately) async {
    // Only validate if submitting immediately
    if (submitImmediately && !_formKey.currentState!.validate()) return;

    // For drafts, at least title is required
    if (!submitImmediately && _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('title_required')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate school selection for BEX/Superadmin when school type is selected
    final user = ref.read(currentUserProvider);
    if (user != null &&
        _selectedType == InitiativeType.school &&
        (user.role == UserRole.bex || user.role == UserRole.superadmin) &&
        _selectedSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('please_select_school')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final controller = ref.read(initiativeControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);
    bool success = false;

    if (_isEditing) {
      // Update existing initiative
      final updatedInitiative = widget.initiative!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        problem: _problemController.text.trim().isEmpty
            ? null
            : _problemController.text.trim(),
        solution: _solutionController.text.trim().isEmpty
            ? null
            : _solutionController.text.trim(),
        impact: _impactController.text.trim().isEmpty
            ? null
            : _impactController.text.trim(),
        type: _selectedType,
        schoolId: _selectedType == InitiativeType.school ? _selectedSchoolId : null,
        schoolName: _selectedType == InitiativeType.school ? _selectedSchoolName : null,
        tags: _tags.isEmpty ? [] : _tags,
        status: submitImmediately && widget.initiative!.status == InitiativeStatus.draft
            ? InitiativeStatus.submitted
            : widget.initiative!.status,
        updatedAt: DateTime.now(),
        submittedAt: submitImmediately && widget.initiative!.status == InitiativeStatus.draft
            ? DateTime.now()
            : widget.initiative!.submittedAt,
      );

      success = await controller.updateInitiative(updatedInitiative);

      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.pop(context, true); // Return true to indicate successful update
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('initiative_updated')),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('error_updating_initiative')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Create new initiative
      final id = await controller.createInitiative(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        problem: _problemController.text.trim().isEmpty
            ? null
            : _problemController.text.trim(),
        solution: _solutionController.text.trim().isEmpty
            ? null
            : _solutionController.text.trim(),
        impact: _impactController.text.trim().isEmpty
            ? null
            : _impactController.text.trim(),
        tags: _tags.isEmpty ? null : _tags,
        submitImmediately: submitImmediately,
        type: _selectedType,
        schoolId: _selectedType == InitiativeType.school ? _selectedSchoolId : null,
        schoolName: _selectedType == InitiativeType.school ? _selectedSchoolName : null,
      );

      setState(() => _isLoading = false);

      if (id != null && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              submitImmediately
                  ? l10n.translate('initiative_submitted')
                  : l10n.translate('draft_saved'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('error_creating_initiative')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
