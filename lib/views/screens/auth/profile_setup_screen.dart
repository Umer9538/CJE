import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import 'register_screen.dart';

/// Screen for completing profile after Google Sign-In
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityPasswordController = TextEditingController();
  final _classNameController = TextEditingController();

  String? _selectedCity;
  String? _selectedSchoolId;
  bool _isLoading = false;
  bool _obscureCityPassword = true;
  String? _errorMessage;

  // Cities list
  final List<String> _cities = [
    'București',
    'Cluj-Napoca',
    'Timișoara',
    'Iași',
    'Constanța',
    'Craiova',
    'Brașov',
    'Galați',
    'Ploiești',
    'Oradea',
  ];

  // City passwords for access control
  static const Map<String, String> _cityPasswords = {
    'București': 'BUC2024',
    'Cluj-Napoca': 'CLJ2024',
    'Timișoara': 'TIM2024',
    'Iași': 'IAS2024',
    'Constanța': 'CTA2024',
    'Craiova': 'CRA2024',
    'Brașov': 'BV2024',
    'Galați': 'GL2024',
    'Ploiești': 'PH2024',
    'Oradea': 'BH2024',
  };

  bool _validateCityPassword() {
    if (_selectedCity == null) return false;
    final expectedPassword = _cityPasswords[_selectedCity];
    return expectedPassword != null &&
           _cityPasswordController.text.trim() == expectedPassword;
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill name from Google account
    final authService = ref.read(authServiceProvider);
    final firebaseUser = authService.currentUser;
    if (firebaseUser?.displayName != null) {
      _fullNameController.text = firebaseUser!.displayName!;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _cityPasswordController.dispose();
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

    if (!_validateCityPassword()) {
      setState(() => _errorMessage = l10n.translate('invalid_city_password'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authControllerProvider.notifier).createGoogleUserProfile(
          fullName: _fullNameController.text.trim(),
          schoolId: _selectedSchoolId!,
          phoneNumber: _phoneController.text.trim(),
          city: _selectedCity!,
          className: _classNameController.text.trim().isNotEmpty
              ? _classNameController.text.trim()
              : null,
        );

    if (mounted) {
      setState(() => _isLoading = false);

      if (!success) {
        setState(() => _errorMessage = 'Eroare la salvarea profilului. Încearcă din nou.');
      }
    }
  }

  Future<void> _handleCancel() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anulezi înregistrarea?'),
        content: const Text(
          'Dacă anulezi, vei fi deconectat și va trebui să te înregistrezi din nou.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nu'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Da, anulează'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final schoolsAsync = ref.watch(schoolsListProvider);
    final authService = ref.read(authServiceProvider);
    final firebaseUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('complete_profile')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleCancel,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Google account info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMD),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: firebaseUser?.photoURL != null
                              ? NetworkImage(firebaseUser!.photoURL!)
                              : null,
                          child: firebaseUser?.photoURL == null
                              ? Icon(
                                  Icons.person,
                                  size: 30,
                                  color: theme.colorScheme.onPrimaryContainer,
                                )
                              : null,
                        ),
                        const SizedBox(width: AppSizes.spacing16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.translate('signed_in_with_google'),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: AppSizes.spacing4),
                              Text(
                                firebaseUser?.email ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spacing24),

                // Title
                Text(
                  l10n.translate('complete_your_profile'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing8),
                Text(
                  l10n.translate('complete_profile_description'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSizes.spacing24),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMD),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: theme.colorScheme.error),
                        const SizedBox(width: AppSizes.spacing8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing16),
                ],

                // Full name
                AppTextField(
                  controller: _fullNameController,
                  label: l10n.translate('full_name'),
                  hint: 'Ion Popescu',
                  prefixIcon: const Icon(Icons.person_outline),
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.translate('field_required');
                    }
                    if (value.trim().length < 3) {
                      return 'Numele trebuie să aibă cel puțin 3 caractere';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.spacing16),

                // Phone number (required)
                AppTextField(
                  controller: _phoneController,
                  label: l10n.translate('phone_number'),
                  hint: '+40 7XX XXX XXX',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading,
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
                const SizedBox(height: AppSizes.spacing16),

                // City dropdown (required)
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: l10n.translate('city'),
                    prefixIcon: const Icon(Icons.location_city_outlined),
                  ),
                  items: _cities.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedCity = value;
                            _cityPasswordController.clear();
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return l10n.translate('city_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.spacing16),

                // City password (required)
                TextFormField(
                  controller: _cityPasswordController,
                  enabled: !_isLoading && _selectedCity != null,
                  obscureText: _obscureCityPassword,
                  decoration: InputDecoration(
                    labelText: l10n.translate('city_password'),
                    hintText: l10n.translate('city_password_hint'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCityPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() => _obscureCityPassword = !_obscureCityPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.translate('field_required');
                    }
                    return null;
                  },
                ),
                if (_selectedCity == null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.spacing8),
                    child: Text(
                      l10n.translate('city_required'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSizes.spacing16),

                // School dropdown
                schoolsAsync.when(
                  data: (schools) => DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: l10n.translate('school'),
                      prefixIcon: const Icon(Icons.school_outlined),
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
                    onChanged: _isLoading
                        ? null
                        : (value) => setState(() => _selectedSchoolId = value),
                    validator: (value) {
                      if (value == null) {
                        return l10n.translate('field_required');
                      }
                      return null;
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => Text(
                    'Eroare la încărcarea școlilor',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),

                // Class name (optional)
                AppTextField(
                  controller: _classNameController,
                  label: '${l10n.translate('class_name')} (opțional)',
                  hint: '12A',
                  prefixIcon: const Icon(Icons.class_outlined),
                  textCapitalization: TextCapitalization.characters,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: AppSizes.spacing24),

                // Info box
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMD),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSizes.spacing12),
                      Expanded(
                        child: Text(
                          l10n.translate('registration_approval_info'),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.spacing32),

                // Submit button
                AppButton(
                  text: l10n.translate('complete_registration'),
                  isLoading: _isLoading,
                  onPressed: _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
