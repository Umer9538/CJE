import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../controllers/controllers.dart';
import '../../../../core/core.dart';

/// Dialog for manually adding a new user
class AddUserDialog extends ConsumerStatefulWidget {
  const AddUserDialog({super.key});

  @override
  ConsumerState<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _classNameController = TextEditingController();

  String? _selectedCity;
  String? _selectedSchoolId;
  UserRole _selectedRole = UserRole.student;
  bool _isLoading = false;
  String? _errorMessage;

  // Track if BEX user (can only add to their own county)
  bool _isBexUser = false;
  String? _bexUserCity;

  // Cities list - should match the registration screen (42 Romanian counties)
  final List<String> _cities = [
    'Alba',
    'Arad',
    'Argeș',
    'Bacău',
    'Bihor',
    'Bistrița-Năsăud',
    'Botoșani',
    'Brașov',
    'Brăila',
    'București',
    'Buzău',
    'Caraș-Severin',
    'Călărași',
    'Cluj',
    'Constanța',
    'Covasna',
    'Dâmbovița',
    'Dolj',
    'Galați',
    'Giurgiu',
    'Gorj',
    'Harghita',
    'Hunedoara',
    'Ialomița',
    'Iași',
    'Ilfov',
    'Maramureș',
    'Mehedinți',
    'Mureș',
    'Neamț',
    'Olt',
    'Prahova',
    'Satu Mare',
    'Sălaj',
    'Sibiu',
    'Suceava',
    'Teleorman',
    'Timiș',
    'Tulcea',
    'Vaslui',
    'Vâlcea',
    'Vrancea',
  ];

  @override
  void initState() {
    super.initState();
    // Check if current user is BEX (not superadmin)
    // BEX users can only add users to their own county
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null && currentUser.role == UserRole.bex) {
        setState(() {
          _isBexUser = true;
          _bexUserCity = currentUser.city;
          _selectedCity = currentUser.city;
        });
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _classNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);

    if (_selectedCity == null) {
      setState(() => _errorMessage = l10n.translate('city_required'));
      return;
    }

    if (_selectedSchoolId == null) {
      setState(() => _errorMessage = l10n.translate('school_required'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

    // Get school name for the user record
    final schools = ref.read(allSchoolsProvider).valueOrNull ?? [];
    final school = schools.where((s) => s.id == _selectedSchoolId).firstOrNull;

    // Create user directly in Firestore (without Firebase Auth)
    // This prevents the admin from being logged out
    final userId = await ref.read(adminControllerProvider.notifier).createUserDirectly(
          email: _emailController.text.trim(),
          fullName: fullName,
          schoolId: _selectedSchoolId!,
          schoolName: school?.name,
          phoneNumber: _phoneController.text.trim(),
          city: _selectedCity!,
          role: _selectedRole,
          className: _classNameController.text.trim(),
        );

    if (mounted) {
      setState(() => _isLoading = false);

      if (userId != null) {
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.translate('user_added_successfully')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _errorMessage = l10n.translate('error_creating_user'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final schoolsAsync = ref.watch(allSchoolsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.translate('add_user'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error message
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red[700], fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // First Name & Last Name Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              enabled: !_isLoading,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: l10n.translate('first_name'),
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.translate('field_required');
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              enabled: !_isLoading,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: l10n.translate('last_name'),
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.translate('field_required');
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n.translate('email'),
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.translate('field_required');
                          }
                          if (!Validators.isValidEmail(value)) {
                            return l10n.translate('invalid_email');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone Number
                      TextFormField(
                        controller: _phoneController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: l10n.translate('phone_number'),
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.translate('phone_required');
                          }
                          final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
                          if (digitsOnly.length < 10) {
                            return l10n.translate('invalid_phone');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // City Dropdown (or read-only for BEX users)
                      if (_isBexUser && _bexUserCity != null)
                        // BEX users can only add to their own county - show read-only field
                        TextFormField(
                          initialValue: _bexUserCity,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: l10n.translate('city'),
                            prefixIcon: const Icon(Icons.location_city_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: context.cardColor,
                            helperText: l10n.translate('bex_county_restriction'),
                            helperStyle: TextStyle(
                              color: context.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        )
                      else
                        // Superadmin can select any county
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: l10n.translate('city'),
                            prefixIcon: const Icon(Icons.location_city_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _cities.map((city) {
                            return DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            );
                          }).toList(),
                          onChanged: _isLoading ? null : (value) => setState(() => _selectedCity = value),
                          validator: (value) {
                            if (value == null) {
                              return l10n.translate('city_required');
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 16),

                      // School Dropdown
                      schoolsAsync.when(
                        data: (schools) => DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: l10n.translate('school'),
                            prefixIcon: const Icon(Icons.school_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: schools.map((school) {
                            return DropdownMenuItem(
                              value: school.id,
                              child: Text(
                                school.shortName.isNotEmpty ? school.shortName : school.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _isLoading ? null : (value) => setState(() => _selectedSchoolId = value),
                          validator: (value) {
                            if (value == null) {
                              return l10n.translate('field_required');
                            }
                            return null;
                          },
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => Text(
                          'Error loading schools',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Class Name
                      TextFormField(
                        controller: _classNameController,
                        enabled: !_isLoading,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: l10n.translate('class_name'),
                          prefixIcon: const Icon(Icons.class_outlined),
                          hintText: '12A',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.translate('field_required');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Role Dropdown
                      DropdownButtonFormField<UserRole>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          labelText: l10n.translate('role'),
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: UserRole.values
                            .where((role) => role != UserRole.superadmin) // Don't allow creating superadmins
                            .map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(l10n.translate(role.translationKey)),
                          );
                        }).toList(),
                        onChanged: _isLoading ? null : (value) {
                          if (value != null) {
                            setState(() => _selectedRole = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Info about password
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.translate('user_password_info'),
                                style: TextStyle(color: Colors.blue[700], fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.navy,
                                  ),
                                )
                              : Text(
                                  l10n.translate('add_user'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
