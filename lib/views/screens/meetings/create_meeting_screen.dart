import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';

/// Screen for creating a new meeting
class CreateMeetingScreen extends ConsumerStatefulWidget {
  final MeetingType? preselectedType;

  const CreateMeetingScreen({
    super.key,
    this.preselectedType,
  });

  @override
  ConsumerState<CreateMeetingScreen> createState() =>
      _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends ConsumerState<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _onlineLinkController = TextEditingController();

  late MeetingType _selectedType;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  int _duration = 60;
  bool _isOnline = false;
  bool _isLoading = false;

  // School and department selection for targeting
  String? _selectedSchoolId;
  String? _selectedSchoolName;
  DepartmentType? _selectedDepartment;

  final List<String> _agendaItems = [];
  final _agendaController = TextEditingController();

  // Documents
  final List<PlatformFile> _pendingFiles = [];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.preselectedType ?? MeetingType.school;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _onlineLinkController.dispose();
    _agendaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);

    // Check which types user can create
    final canCreatePlenary = user != null &&
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
          l10n.translate('create_meeting'),
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
          padding: const EdgeInsets.all(24),
          children: [
            // Meeting Type
            Text(
              l10n.translate('meeting_type'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TypeChip(
                  label: l10n.translate('school'),
                  icon: Icons.school_rounded,
                  isSelected: _selectedType == MeetingType.school,
                  onTap: () => setState(() => _selectedType = MeetingType.school),
                ),
                _TypeChip(
                  label: l10n.translate('department'),
                  icon: Icons.groups_rounded,
                  isSelected: _selectedType == MeetingType.department,
                  onTap: () => setState(() => _selectedType = MeetingType.department),
                ),
                _TypeChip(
                  label: l10n.translate('meeting_type_county_ag'),
                  icon: Icons.account_balance_rounded,
                  isSelected: _selectedType == MeetingType.countyAG,
                  isDisabled: !canCreatePlenary,
                  onTap: canCreatePlenary
                      ? () => setState(() => _selectedType = MeetingType.countyAG)
                      : null,
                ),
                _TypeChip(
                  label: l10n.translate('meeting_type_bex'),
                  icon: Icons.admin_panel_settings_rounded,
                  isSelected: _selectedType == MeetingType.bex,
                  isDisabled: !canCreatePlenary,
                  onTap: canCreatePlenary
                      ? () => setState(() => _selectedType = MeetingType.bex)
                      : null,
                ),
              ],
            ),

            // School Dropdown (when School type is selected)
            if (_selectedType == MeetingType.school) ...[
              const SizedBox(height: 16),
              _buildSchoolSelector(l10n),
            ],

            // Department Dropdown (when Department type is selected)
            if (_selectedType == MeetingType.department) ...[
              const SizedBox(height: 16),
              _buildDepartmentSelector(l10n),
            ],

            const SizedBox(height: 24),

            // Title
            Text(
              l10n.translate('meeting_title'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: _buildInputDecoration(
                l10n.translate('meeting_title_hint'),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.translate('title_required');
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Date & Time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('date'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDateSelector(context, l10n),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('time'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTimeSelector(context, l10n),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Duration
            Text(
              l10n.translate('duration'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildDurationSelector(),
            const SizedBox(height: 24),

            // Online toggle
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
                      color: _isOnline
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.videocam_rounded,
                      color: _isOnline ? Colors.green : Colors.grey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('online'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.translate('this_is_online_meeting'),
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isOnline,
                    onChanged: (value) => setState(() => _isOnline = value),
                    activeTrackColor: Colors.green.withValues(alpha: 0.5),
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.green;
                      }
                      return null;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Location or Online Link
            if (_isOnline) ...[
              Text(
                l10n.translate('meeting_link'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _onlineLinkController,
                decoration: _buildInputDecoration(
                  'https://meet.google.com/...',
                ),
                keyboardType: TextInputType.url,
              ),
            ] else ...[
              Text(
                l10n.translate('meeting_location'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: _buildInputDecoration(
                  l10n.translate('location_hint'),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Description
            Text(
              l10n.translate('meeting_description'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _buildInputDecoration(
                l10n.translate('meeting_description_hint'),
              ),
            ),
            const SizedBox(height: 24),

            // Agenda
            Row(
              children: [
                Text(
                  l10n.translate('agenda'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_agendaItems.length} items',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAgendaSection(l10n),
            const SizedBox(height: 24),

            // Documents Section
            Row(
              children: [
                Text(
                  l10n.translate('documents'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_pendingFiles.length} ${l10n.translate('files')}',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDocumentsSection(l10n),
            const SizedBox(height: 32),

            // Create button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.textPrimary,
                        ),
                      )
                    : Text(
                        l10n.translate('schedule_meeting'),
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

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textSecondary),
      filled: true,
      fillColor: context.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.borderColor),
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

  Widget _buildDateSelector(BuildContext context, AppLocalizations l10n) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.gold,
                  onPrimary: AppColors.navy,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: context.textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(
              dateFormat.format(_selectedDate),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(BuildContext context, AppLocalizations l10n) {
    final timeFormat = DateFormat('h:mm a');
    final dateTime = DateTime(
      2024, 1, 1,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    return GestureDetector(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.gold,
                  onPrimary: AppColors.navy,
                ),
              ),
              child: child!,
            );
          },
        );
        if (time != null) {
          setState(() => _selectedTime = time);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule_rounded, color: context.textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(
              timeFormat.format(dateTime),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    final durations = [30, 45, 60, 90, 120];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: durations.map((d) {
        final isSelected = _duration == d;
        return GestureDetector(
          onTap: () => setState(() => _duration = d),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.gold : context.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$d min',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.navy : context.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSchoolSelector(AppLocalizations l10n) {
    final schoolsAsync = ref.watch(allSchoolsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('select_school'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        schoolsAsync.when(
          data: (schools) {
            if (schools.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  l10n.translate('no_schools_available'),
                  style: TextStyle(color: context.textSecondary),
                ),
              );
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSchoolId,
                  hint: Text(
                    l10n.translate('select_school'),
                    style: TextStyle(color: context.textSecondary),
                  ),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: context.iconColor),
                  dropdownColor: context.cardColor,
                  style: TextStyle(
                    fontSize: 15,
                    color: context.textPrimary,
                  ),
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
                      final school = schools.firstWhere((s) => s.id == value);
                      setState(() {
                        _selectedSchoolId = school.id;
                        _selectedSchoolName = school.name;
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
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              l10n.translate('error_loading_schools'),
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentSelector(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('select_department'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<DepartmentType>(
              value: _selectedDepartment,
              hint: Text(
                l10n.translate('select_department'),
                style: TextStyle(color: context.textSecondary),
              ),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: context.iconColor),
              dropdownColor: context.cardColor,
              style: TextStyle(
                fontSize: 15,
                color: context.textPrimary,
              ),
              items: DepartmentType.values.map((dept) {
                return DropdownMenuItem<DepartmentType>(
                  value: dept,
                  child: Text(
                    dept.displayName,
                    style: TextStyle(color: context.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDepartment = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgendaSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Existing items
          ..._agendaItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: context.textSecondary),
                    onPressed: () {
                      setState(() => _agendaItems.removeAt(index));
                    },
                  ),
                ],
              ),
            );
          }),

          // Add new item
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _agendaController,
                  decoration: InputDecoration(
                    hintText: l10n.translate('agenda_item_hint'),
                    hintStyle: TextStyle(color: context.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _addAgendaItem(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.gold),
                onPressed: _addAgendaItem,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addAgendaItem() {
    final text = _agendaController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _agendaItems.add(text);
        _agendaController.clear();
      });
    }
  }

  Widget _buildDocumentsSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Existing files
          ..._pendingFiles.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getFileColor(file.extension).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getFileIcon(file.extension),
                      color: _getFileColor(file.extension),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatFileSize(file.size),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: context.textSecondary),
                    onPressed: () {
                      setState(() => _pendingFiles.removeAt(index));
                    },
                  ),
                ],
              ),
            );
          }),

          // Add file button
          GestureDetector(
            onTap: _pickFiles,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.borderColor,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: AppColors.gold,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.translate('add_document'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pendingFiles.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).translate('error_picking_files')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<MeetingDocument>> _uploadDocuments() async {
    final List<MeetingDocument> uploadedDocs = [];
    final uuid = const Uuid();

    for (final file in _pendingFiles) {
      if (file.path == null) continue;

      try {
        final fileObj = File(file.path!);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('meetings')
            .child('documents')
            .child(fileName);

        final uploadTask = await storageRef.putFile(fileObj);
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        uploadedDocs.add(MeetingDocument(
          id: uuid.v4(),
          name: file.name,
          url: downloadUrl,
          fileType: file.extension,
          uploadedAt: DateTime.now(),
        ));
      } catch (e) {
        debugPrint('Error uploading document: $e');
      }
    }

    return uploadedDocs;
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileColor(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Upload documents first if any
    List<MeetingDocument> uploadedDocuments = [];
    if (_pendingFiles.isNotEmpty) {
      uploadedDocuments = await _uploadDocuments();
    }

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final controller = ref.read(meetingControllerProvider.notifier);
    final id = await controller.createMeeting(
      title: _titleController.text.trim(),
      type: _selectedType,
      dateTime: dateTime,
      description: _descriptionController.text.trim(),
      durationMinutes: _duration,
      location: _isOnline ? null : _locationController.text.trim(),
      isOnline: _isOnline,
      onlineLink: _isOnline ? _onlineLinkController.text.trim() : null,
      schoolId: _selectedSchoolId,
      schoolName: _selectedSchoolName,
      department: _selectedDepartment,
      agendaItems: _agendaItems.isEmpty ? null : _agendaItems,
      documents: uploadedDocuments.isEmpty ? null : uploadedDocuments,
    );

    setState(() => _isLoading = false);

    if (id != null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('meeting_created')),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('error_creating_meeting')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Type selection chip
class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.gold
                : isDisabled
                    ? context.borderColor.withValues(alpha: 0.5)
                    : context.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDisabled
                  ? context.textSecondary.withValues(alpha: 0.5)
                  : isSelected
                      ? AppColors.navy
                      : context.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDisabled
                    ? context.textSecondary.withValues(alpha: 0.5)
                    : isSelected
                        ? AppColors.navy
                        : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
