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
  String? _selectedSchoolName;
  bool _isLoading = false;
  bool _obscureCityPassword = true;
  String? _errorMessage;

  // Counties list (42 Romanian counties from Parole_judete.xlsx)
  final List<String> _cities = [
    'Alba', 'Arad', 'Argeș', 'Bacău', 'Bihor', 'Bistrița-Năsăud',
    'Botoșani', 'Brașov', 'Brăila', 'București', 'Buzău', 'Caraș-Severin',
    'Călărași', 'Cluj', 'Constanța', 'Covasna', 'Dâmbovița', 'Dolj',
    'Galați', 'Giurgiu', 'Gorj', 'Harghita', 'Hunedoara', 'Ialomița',
    'Iași', 'Ilfov', 'Maramureș', 'Mehedinți', 'Mureș', 'Neamț',
    'Olt', 'Prahova', 'Satu Mare', 'Sălaj', 'Sibiu', 'Suceava',
    'Teleorman', 'Timiș', 'Tulcea', 'Vaslui', 'Vâlcea', 'Vrancea',
  ];

  // County passwords for access control (Registration codes from Parole_judete.xlsx)
  static const Map<String, String> _cityPasswords = {
    'Alba': 'AB#7291', 'Arad': 'AR#3842', 'Argeș': 'AG#9103',
    'Bacău': 'BC#5528', 'Bihor': 'BH#1937', 'Bistrița-Năsăud': 'BN#6482',
    'Botoșani': 'BT#2749', 'Brașov': 'BV#8301', 'Brăila': 'BR#4615',
    'București': 'B#9920', 'Buzău': 'BZ#3156', 'Caraș-Severin': 'CS#7043',
    'Călărași': 'CL#2819', 'Cluj': 'CJ#5392', 'Constanța': 'CT#8264',
    'Covasna': 'CV#1473', 'Dâmbovița': 'DB#6038', 'Dolj': 'DJ#9521',
    'Galați': 'GL#3740', 'Giurgiu': 'GR#5186', 'Gorj': 'GJ#2905',
    'Harghita': 'HR#7634', 'Hunedoara': 'HD#4027', 'Ialomița': 'IL#8392',
    'Iași': 'IS#1504', 'Ilfov': 'IF#6273', 'Maramureș': 'MM#9418',
    'Mehedinți': 'MH#3365', 'Mureș': 'MS#7820', 'Neamț': 'NT#2059',
    'Olt': 'OT#5941', 'Prahova': 'PH#1683', 'Satu Mare': 'SM#8407',
    'Sălaj': 'SJ#3256', 'Sibiu': 'SB#9172', 'Suceava': 'SV#4839',
    'Teleorman': 'TR#6701', 'Timiș': 'TM#2548', 'Tulcea': 'TL#5092',
    'Vaslui': 'VS#7364', 'Vâlcea': 'VL#1825', 'Vrancea': 'VN#4910',
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

    final (success, errorMessage) = await ref.read(authControllerProvider.notifier).createGoogleUserProfile(
          fullName: _fullNameController.text.trim(),
          schoolId: _selectedSchoolId!,
          schoolName: _selectedSchoolName,
          phoneNumber: _phoneController.text.trim(),
          city: _selectedCity!,
          className: _classNameController.text.trim(),
        );

    if (mounted) {
      setState(() => _isLoading = false);

      if (!success) {
        setState(() => _errorMessage = errorMessage ?? l10n.translate('error_saving_profile'));
      }
    }
  }

  Future<void> _handleCancel() async {
    final l10n = AppLocalizations.of(context);
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('cancel_registration')),
        content: Text(l10n.translate('cancel_registration_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('no')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.translate('yes_cancel')),
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
    final schoolsAsync = ref.watch(schoolsByCountyProvider(_selectedCity));
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
                if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMD),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                        const SizedBox(width: AppSizes.spacing8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: theme.colorScheme.onErrorContainer),
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
                  hint: l10n.translate('example_name'),
                  prefixIcon: const Icon(Icons.person_outline),
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.translate('field_required');
                    }
                    if (value.trim().length < 3) {
                      return l10n.translate('too_short');
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

                // City dropdown (required) - Searchable
                _buildSearchableCityField(l10n, theme),
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
                  data: (schools) {
                    // Check if selected school exists in the current schools list
                    final schoolExists = _selectedSchoolId != null &&
                        schools.any((s) => s.id == _selectedSchoolId);
                    // Reset if school doesn't exist in new list
                    if (_selectedSchoolId != null && !schoolExists) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _selectedSchoolId = null);
                        }
                      });
                    }
                    return DropdownButtonFormField<String>(
                      value: schoolExists ? _selectedSchoolId : null,
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
                          : (value) {
                              final school = schools.firstWhere(
                                (s) => s.id == value,
                                orElse: () => schools.first,
                              );
                              setState(() {
                                _selectedSchoolId = value;
                                _selectedSchoolName = school.name;
                              });
                            },
                      validator: (value) {
                        if (value == null) {
                          return l10n.translate('field_required');
                        }
                        return null;
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => Text(
                    'Eroare la încărcarea școlilor',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
                const SizedBox(height: AppSizes.spacing16),

                // Class name (required)
                AppTextField(
                  controller: _classNameController,
                  label: l10n.translate('class_name'),
                  hint: '12A',
                  prefixIcon: const Icon(Icons.class_outlined),
                  textCapitalization: TextCapitalization.characters,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.translate('field_required');
                    }
                    return null;
                  },
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

  /// Builds a searchable city selection field
  Widget _buildSearchableCityField(AppLocalizations l10n, ThemeData theme) {
    return FormField<String>(
      initialValue: _selectedCity,
      validator: (value) {
        if (_selectedCity == null) {
          return l10n.translate('city_required');
        }
        return null;
      },
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _isLoading ? null : () => _showCitySearchSheet(l10n),
              borderRadius: BorderRadius.circular(AppSizes.radiusMD),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.translate('city'),
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  suffixIcon: const Icon(Icons.search),
                  errorText: state.hasError ? state.errorText : null,
                ),
                child: Text(
                  _selectedCity ?? '${l10n.translate('select')} ${l10n.translate('city')}...',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _selectedCity != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Shows a bottom sheet with searchable city list
  void _showCitySearchSheet(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CitySearchSheet(
        cities: _cities,
        selectedCity: _selectedCity,
        l10n: l10n,
        onCitySelected: (city) {
          setState(() {
            _selectedCity = city;
            _selectedSchoolId = null; // Reset school when city changes
            _selectedSchoolName = null;
            _cityPasswordController.clear();
          });
        },
      ),
    );
  }
}
