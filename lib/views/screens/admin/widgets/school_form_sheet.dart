import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../controllers/schools/school_controller.dart';
import '../../../../core/core.dart';
import '../../../../models/models.dart';

/// Form sheet for creating or editing a school
class SchoolFormSheet extends ConsumerStatefulWidget {
  final SchoolModel? school;

  const SchoolFormSheet({super.key, this.school});

  @override
  ConsumerState<SchoolFormSheet> createState() => _SchoolFormSheetState();
}

class _SchoolFormSheetState extends ConsumerState<SchoolFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _shortNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  bool _isLoading = false;

  bool get isEditing => widget.school != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.school?.name);
    _shortNameController = TextEditingController(text: widget.school?.shortName);
    _addressController = TextEditingController(text: widget.school?.address);
    _cityController = TextEditingController(text: widget.school?.city);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24,
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
                isEditing ? l10n.translate('edit_school') : l10n.translate('add_school'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 24),
              _buildNameField(l10n),
              const SizedBox(height: 16),
              _buildShortNameField(l10n),
              const SizedBox(height: 16),
              _buildCityField(l10n),
              const SizedBox(height: 16),
              _buildAddressField(l10n),
              const SizedBox(height: 24),
              _buildSubmitButton(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField(AppLocalizations l10n) {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: l10n.translate('school_name'),
        hintText: 'e.g., Colegiul National Mircea cel Batran',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.translate('field_required');
        }
        return null;
      },
    );
  }

  Widget _buildShortNameField(AppLocalizations l10n) {
    return TextFormField(
      controller: _shortNameController,
      decoration: InputDecoration(
        labelText: l10n.translate('short_name'),
        hintText: 'e.g., CNMB',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.translate('field_required');
        }
        return null;
      },
    );
  }

  Widget _buildCityField(AppLocalizations l10n) {
    return TextFormField(
      controller: _cityController,
      decoration: InputDecoration(
        labelText: l10n.translate('city'),
        hintText: 'e.g., Constanta',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildAddressField(AppLocalizations l10n) {
    return TextFormField(
      controller: _addressController,
      decoration: InputDecoration(
        labelText: l10n.translate('address'),
        hintText: 'e.g., Str. Mihai Viteazu Nr. 10',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      maxLines: 2,
    );
  }

  Widget _buildSubmitButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navy,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                isEditing ? l10n.translate('save') : l10n.translate('create'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final controller = ref.read(schoolControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);
    bool success;

    if (isEditing) {
      final updatedSchool = widget.school!.copyWith(
        name: _nameController.text.trim(),
        shortName: _shortNameController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      );
      success = await controller.updateSchool(updatedSchool);
    } else {
      final id = await controller.createSchool(
        name: _nameController.text.trim(),
        shortName: _shortNameController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      );
      success = id != null;
    }

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (isEditing ? l10n.translate('school_updated') : l10n.translate('school_created'))
              : l10n.translate('error_saving_school')),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
