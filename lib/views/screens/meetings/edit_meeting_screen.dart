import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';

/// Screen for editing an existing meeting
class EditMeetingScreen extends ConsumerStatefulWidget {
  final MeetingModel meeting;

  const EditMeetingScreen({super.key, required this.meeting});

  @override
  ConsumerState<EditMeetingScreen> createState() => _EditMeetingScreenState();
}

class _EditMeetingScreenState extends ConsumerState<EditMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _onlineLinkController;

  late MeetingType _selectedType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _duration;
  late bool _isOnline;
  bool _isLoading = false;

  late List<String> _agendaItems;
  final _agendaController = TextEditingController();

  // Minutes upload
  PlatformFile? _selectedMinutesFile;
  String? _minutesUrl;
  bool _isUploadingMinutes = false;
  double _uploadProgress = 0;

  // Attendance management
  late List<String> _attendeeIds;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.meeting.title);
    _descriptionController = TextEditingController(text: widget.meeting.description ?? '');
    _locationController = TextEditingController(text: widget.meeting.location ?? '');
    _onlineLinkController = TextEditingController(text: widget.meeting.onlineLink ?? '');
    _selectedType = widget.meeting.type;
    _selectedDate = widget.meeting.dateTime;
    _selectedTime = TimeOfDay.fromDateTime(widget.meeting.dateTime);
    _duration = widget.meeting.durationMinutes;
    _isOnline = widget.meeting.isOnline;
    _agendaItems = List.from(widget.meeting.agendaItems);
    _minutesUrl = widget.meeting.minutesDocumentUrl;
    _attendeeIds = List.from(widget.meeting.attendeeIds);
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
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final canEditPlenary = user != null &&
        (user.role == UserRole.bex || user.role == UserRole.superadmin);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.navy : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: context.shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.close, color: isDark ? AppColors.gold : AppColors.navy, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          );
        }),
        title: Text(
          l10n.translate('edit_meeting'),
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
            // Meeting Type (readonly display)
            Text(
              l10n.translate('meeting_type'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedType.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _selectedType.color),
              ),
              child: Row(
                children: [
                  Icon(_getTypeIcon(_selectedType), color: _selectedType.color),
                  const SizedBox(width: 12),
                  Text(
                    _selectedType.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedType.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Title
            _buildSectionTitle(l10n.translate('title')),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _titleController,
              hint: l10n.translate('meeting_title_hint'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.translate('title_required');
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Date & Time
            _buildSectionTitle(l10n.translate('date_time')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeButton(
                    icon: Icons.calendar_today_rounded,
                    label: dateFormat.format(_selectedDate),
                    onTap: _selectDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateTimeButton(
                    icon: Icons.access_time_rounded,
                    label: timeFormat.format(DateTime(2024, 1, 1, _selectedTime.hour, _selectedTime.minute)),
                    onTap: _selectTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Duration
            _buildSectionTitle(l10n.translate('duration')),
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Wrap(
                spacing: 8,
                children: [30, 45, 60, 90, 120].map((d) {
                  final isSelected = _duration == d;
                  return ChoiceChip(
                    label: Text('$d ${l10n.translate('min')}'),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _duration = d),
                    selectedColor: AppColors.gold,
                    backgroundColor: isDark ? AppColors.navy : null,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.navy
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 24),

            // Online toggle
            Builder(builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.navy : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.videocam_rounded,
                      color: _isOnline ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.translate('online_meeting'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.gold : AppColors.navy,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isOnline,
                      onChanged: (v) => setState(() => _isOnline = v),
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
              );
            }),
            const SizedBox(height: 16),

            // Location or Online Link
            if (_isOnline) ...[
              _buildSectionTitle(l10n.translate('meeting_link')),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _onlineLinkController,
                hint: 'https://meet.google.com/...',
              ),
            ] else ...[
              _buildSectionTitle(l10n.translate('location')),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _locationController,
                hint: l10n.translate('location_hint'),
              ),
            ],
            const SizedBox(height: 24),

            // Description
            _buildSectionTitle(l10n.translate('description')),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _descriptionController,
              hint: l10n.translate('description_hint'),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Agenda
            _buildSectionTitle(l10n.translate('agenda')),
            const SizedBox(height: 12),
            ..._agendaItems.asMap().entries.map((e) => _buildAgendaItem(e.key, e.value)),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _agendaController,
                    hint: l10n.translate('add_agenda_item'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addAgendaItem,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: AppColors.navy, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Meeting Minutes Section (only for completed/past meetings)
            if (!widget.meeting.isUpcoming || widget.meeting.isCompleted) ...[
              _buildSectionTitle(l10n.translate('meeting_minutes')),
              const SizedBox(height: 12),
              _buildMinutesUploadSection(l10n),
              const SizedBox(height: 24),
            ],

            // Attendance Management Section
            _buildSectionTitle(l10n.translate('attendees')),
            const SizedBox(height: 12),
            _buildAttendeesSection(l10n),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: context.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        color: isDark ? AppColors.gold : AppColors.navy,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
        filled: true,
        fillColor: isDark ? AppColors.navy : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: validator,
    );
  }

  Widget _buildDateTimeButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDark ? AppColors.gold : AppColors.navy, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: isDark ? AppColors.gold : AppColors.navy),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaItem(int index, String item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navy : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            '${index + 1}.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.gold : AppColors.navy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item,
              style: TextStyle(color: isDark ? Colors.white : AppColors.navy),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            onPressed: () => setState(() => _agendaItems.removeAt(index)),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(MeetingType type) {
    switch (type) {
      case MeetingType.countyAG:
        return Icons.account_balance_rounded;
      case MeetingType.bex:
        return Icons.groups_rounded;
      case MeetingType.department:
        return Icons.business_rounded;
      case MeetingType.school:
        return Icons.school_rounded;
    }
  }

  void _addAgendaItem() {
    if (_agendaController.text.trim().isNotEmpty) {
      setState(() {
        _agendaItems.add(_agendaController.text.trim());
        _agendaController.clear();
      });
    }
  }

  Widget _buildMinutesUploadSection(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navy : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current minutes status
          if (_minutesUrl != null && _selectedMinutesFile == null) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('minutes_uploaded'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.gold : AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.translate('tap_to_replace'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _minutesUrl = null),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // File picker / selected file display
          if (_selectedMinutesFile != null) ...[
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedMinutesFile!.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.gold : AppColors.navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatFileSize(_selectedMinutesFile!.size),
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _selectedMinutesFile = null),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            if (_isUploadingMinutes) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
              const SizedBox(height: 4),
              Text(
                '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ] else ...[
            // Upload button
            GestureDetector(
              onTap: _isUploadingMinutes ? null : _pickMinutesFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.upload_file_rounded,
                      color: Colors.grey[400],
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.translate('upload_minutes'),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendeesSection(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navy : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_attendeeIds.length} ${l10n.translate('invited')}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              TextButton.icon(
                onPressed: _showAddAttendeeDialog,
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: Text(l10n.translate('add')),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.gold,
                ),
              ),
            ],
          ),

          if (_attendeeIds.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      l10n.translate('no_attendees'),
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            // Attendees list using FutureBuilder to fetch user names
            ...List.generate(_attendeeIds.length, (index) {
              final attendeeId = _attendeeIds[index];
              return _AttendeeItem(
                userId: attendeeId,
                onRemove: () => setState(() => _attendeeIds.removeAt(index)),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _pickMinutesFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _selectedMinutesFile = result.files.first);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).translate('error_picking_file')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadMinutesFile() async {
    if (_selectedMinutesFile == null || _selectedMinutesFile!.path == null) {
      return _minutesUrl; // Return existing URL if no new file
    }

    setState(() {
      _isUploadingMinutes = true;
      _uploadProgress = 0;
    });

    try {
      final file = File(_selectedMinutesFile!.path!);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_minutes_${widget.meeting.id}.pdf';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('meetings')
          .child('minutes')
          .child(fileName);

      final uploadTask = storageRef.putFile(file);

      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred / event.totalBytes;
        });
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _isUploadingMinutes = false;
        _minutesUrl = downloadUrl;
      });

      return downloadUrl;
    } catch (e) {
      setState(() => _isUploadingMinutes = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).translate('error_uploading_file')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  void _showAddAttendeeDialog() {
    final l10n = AppLocalizations.of(context);
    final usersAsync = ref.read(allUsersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.navy : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final sheetIsDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetIsDark ? Colors.grey[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.translate('add_attendees'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: sheetIsDark ? AppColors.gold : AppColors.navy,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: usersAsync.when(
                    data: (users) {
                      // Filter out users already added
                      final availableUsers = users
                          .where((u) => !_attendeeIds.contains(u.id))
                          .toList();

                      if (availableUsers.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.translate('no_users_available'),
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: availableUsers.length,
                        itemBuilder: (context, index) {
                          final user = availableUsers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: sheetIsDark
                                  ? AppColors.gold.withValues(alpha: 0.2)
                                  : AppColors.navy.withValues(alpha: 0.1),
                              child: Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: sheetIsDark ? AppColors.gold : AppColors.navy,
                                ),
                              ),
                            ),
                            title: Text(
                              user.fullName,
                              style: TextStyle(
                                color: sheetIsDark ? Colors.white : AppColors.navy,
                              ),
                            ),
                            subtitle: Text(
                              '${user.role.displayName}${user.schoolName != null ? ' • ${user.schoolName}' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: sheetIsDark ? Colors.grey[400] : Colors.grey[500],
                              ),
                            ),
                            trailing: IconButton(
                              onPressed: () {
                                setState(() => _attendeeIds.add(user.id));
                                Navigator.pop(context);
                              },
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.green,
                                  size: 18,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Center(
                      child: Text(l10n.translate('error_loading')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Upload minutes file if selected
    String? minutesUrl = _minutesUrl;
    if (_selectedMinutesFile != null) {
      minutesUrl = await _uploadMinutesFile();
      if (minutesUrl == null && _selectedMinutesFile != null) {
        setState(() => _isLoading = false);
        return; // Upload failed
      }
    }

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final updatedMeeting = widget.meeting.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      dateTime: dateTime,
      durationMinutes: _duration,
      isOnline: _isOnline,
      location: _isOnline ? null : _locationController.text.trim(),
      onlineLink: _isOnline ? _onlineLinkController.text.trim() : null,
      agendaItems: _agendaItems,
      attendeeIds: _attendeeIds,
      minutesDocumentUrl: minutesUrl,
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(meetingControllerProvider.notifier)
        .updateMeeting(updatedMeeting);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, updatedMeeting);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('meeting_updated')),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('error_updating_meeting')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Widget to display an attendee item with remove button
class _AttendeeItem extends ConsumerWidget {
  final String userId;
  final VoidCallback onRemove;

  const _AttendeeItem({
    required this.userId,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(adminUserProvider(userId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                  child: const Icon(Icons.person, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unknown User',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.gold.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isDark
                    ? AppColors.gold.withValues(alpha: 0.2)
                    : AppColors.navy.withValues(alpha: 0.1),
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.gold : AppColors.navy,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.navy,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      user.role.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(child: Container()),
          ],
        ),
      ),
      error: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        child: Text(
          'Error loading user',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
