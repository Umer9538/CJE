import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../controllers/admin/admin_controller.dart';
import '../../../../controllers/auth/auth_controller.dart';
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
  String? _selectedCity;
  bool _isLoading = false;

  bool get isEditing => widget.school != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.school?.name);
    _shortNameController = TextEditingController(text: widget.school?.shortName);
    _addressController = TextEditingController(text: widget.school?.address);
    // Pre-select city: use school's city if editing, otherwise initialize later in didChangeDependencies
    // Only set if the city exists in the romanianCounties list
    final schoolCity = widget.school?.city;
    if (schoolCity != null && romanianCounties.contains(schoolCity)) {
      _selectedCity = schoolCity;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-select the BEX user's city if not editing and no city selected yet
    if (!isEditing && _selectedCity == null) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser?.city != null && currentUser!.city!.isNotEmpty) {
        // Only set if the city exists in the romanianCounties list
        if (romanianCounties.contains(currentUser.city)) {
          _selectedCity = currentUser.city;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _addressController.dispose();
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
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.goldColor,
                ),
              ),
              const SizedBox(height: 24),
              _buildNameField(l10n),
              const SizedBox(height: 16),
              _buildShortNameField(l10n),
              const SizedBox(height: 16),
              // Always show city field - pre-selected for BEX users from their profile
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

  InputDecoration _inputDecoration(BuildContext context, String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: context.textSecondary),
      hintStyle: TextStyle(color: context.textSecondary.withValues(alpha: 0.6)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.goldColor, width: 2),
      ),
    );
  }

  Widget _buildNameField(AppLocalizations l10n) {
    return TextFormField(
      controller: _nameController,
      style: TextStyle(color: context.textPrimary),
      decoration: _inputDecoration(
        context,
        l10n.translate('school_name'),
        'e.g., Colegiul National Mircea cel Batran',
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
      style: TextStyle(color: context.textPrimary),
      decoration: _inputDecoration(
        context,
        l10n.translate('short_name'),
        'e.g., CNMB',
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
    return DropdownButtonFormField<String>(
      value: _selectedCity,
      style: TextStyle(color: context.textPrimary),
      dropdownColor: context.cardColor,
      decoration: _inputDecoration(
        context,
        l10n.translate('county'),
        '${l10n.translate('select')} ${l10n.translate('county')}...',
      ),
      items: romanianCounties.map((county) {
        return DropdownMenuItem(
          value: county,
          child: Text(county, style: TextStyle(color: context.textPrimary)),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCity = value),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.translate('field_required');
        }
        return null;
      },
    );
  }

  Widget _buildAddressField(AppLocalizations l10n) {
    return TextFormField(
      controller: _addressController,
      style: TextStyle(color: context.textPrimary),
      decoration: _inputDecoration(
        context,
        l10n.translate('address'),
        'e.g., Str. Mihai Viteazu Nr. 10',
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

    final controller = ref.read(schoolControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final currentUser = ref.read(currentUserProvider);

    // Always use the selected city from the dropdown (pre-selected for BEX users)
    final cityValue = _selectedCity;

    // Validate city is set
    if (cityValue == null || cityValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('city_required')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint('SchoolFormSheet: Creating school with city: "$cityValue" (length: ${cityValue.length})');
    debugPrint('SchoolFormSheet: User city from profile: "${currentUser?.city}" | Selected city: "$cityValue"');

    setState(() => _isLoading = true);

    bool success;

    if (isEditing) {
      final updatedSchool = widget.school!.copyWith(
        name: _nameController.text.trim(),
        shortName: _shortNameController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: cityValue,
      );
      debugPrint('SchoolFormSheet: Updating school ${widget.school!.id} with city: "$cityValue"');
      success = await controller.updateSchool(updatedSchool);
    } else {
      final id = await controller.createSchool(
        name: _nameController.text.trim(),
        shortName: _shortNameController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: cityValue,
      );
      success = id != null;
      debugPrint('SchoolFormSheet: School created with id: $id, city: "$cityValue", success: $success');
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
