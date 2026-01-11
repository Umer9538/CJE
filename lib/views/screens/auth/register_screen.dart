import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import '../../../routes/route_names.dart';

/// Provider to fetch schools list filtered by county - REAL-TIME UPDATES
/// Uses real-time snapshots() stream to automatically update when schools are added
/// Firestore rules allow public read on schools collection for registration
final schoolsByCountyProvider = StreamProvider.family<List<SchoolModel>, String?>((ref, county) {
  if (county == null || county.isEmpty) {
    return Stream.value([]);
  }

  debugPrint('schoolsByCountyProvider: Setting up REAL-TIME stream for county: $county');
  final countyLower = county.toLowerCase().trim();

  // Use snapshots() for real-time updates - schools collection allows public read
  return FirebaseFirestore.instance
      .collection('schools')
      .snapshots()
      .map((snapshot) {
        debugPrint('schoolsByCountyProvider: Received snapshot with ${snapshot.docs.length} docs');

        final allSchools = snapshot.docs
            .map((doc) {
              try {
                return SchoolModel.fromFirestore(doc);
              } catch (e) {
                debugPrint('Error parsing school doc ${doc.id}: $e');
                return null;
              }
            })
            .whereType<SchoolModel>()
            .toList();

        // Filter by city (case-insensitive, trimmed) and active status
        final schools = allSchools
            .where((school) => school.isActive)
            .where((school) {
              final schoolCity = school.city?.toLowerCase().trim();
              if (schoolCity == null) return false;
              return schoolCity == countyLower ||
                     schoolCity.contains(countyLower) ||
                     countyLower.contains(schoolCity);
            })
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        debugPrint('schoolsByCountyProvider: Found ${schools.length} schools matching "$county"');

        if (schools.isNotEmpty) {
          return schools;
        } else {
          debugPrint('schoolsByCountyProvider: No schools found, using sample schools');
          return _getSampleSchools(county);
        }
      })
      .handleError((e) {
        debugPrint('schoolsByCountyProvider: Stream error: $e');
        return _getSampleSchools(county);
      });
});

/// Sample schools for development/testing - filtered by county
List<SchoolModel> _getSampleSchools(String county) {
  // Return sample schools for the selected county
  // These are only shown when database has no schools for this county
  final countyAbbr = county.length >= 2 ? county.substring(0, 2).toUpperCase() : county.toUpperCase();
  return [
    SchoolModel(
      id: '${county.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_')}_school_1',
      name: 'Colegiul Național "$county"',
      shortName: 'CN$countyAbbr',
      city: county,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SchoolModel(
      id: '${county.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_')}_school_2',
      name: 'Liceul Teoretic "$county"',
      shortName: 'LT$countyAbbr',
      city: county,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityPasswordController = TextEditingController();
  final _classNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedCity;
  String? _selectedSchoolId;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureCityPassword = true;
  String? _errorMessage;
  int _titleTapCount = 0;

  // County passwords for access control (Registration codes from Parole_judete.xlsx)
  // IMPORTANT: Must match passwords in profile_setup_screen.dart
  static const Map<String, String> _cityPasswords = {
    'Alba': 'AB#7291',
    'Arad': 'AR#3842',
    'Argeș': 'AG#9103',
    'Bacău': 'BC#5528',
    'Bihor': 'BH#1937',
    'Bistrița-Năsăud': 'BN#6482',
    'Botoșani': 'BT#2749',
    'Brașov': 'BV#8301',
    'Brăila': 'BR#4615',
    'București': 'B#9920',
    'Buzău': 'BZ#3156',
    'Caraș-Severin': 'CS#7043',
    'Călărași': 'CL#2819',
    'Cluj': 'CJ#5392',
    'Constanța': 'CT#8264',
    'Covasna': 'CV#1473',
    'Dâmbovița': 'DB#6038',
    'Dolj': 'DJ#9521',
    'Galați': 'GL#3740',
    'Giurgiu': 'GR#5186',
    'Gorj': 'GJ#2905',
    'Harghita': 'HR#7634',
    'Hunedoara': 'HD#4027',
    'Ialomița': 'IL#8392',
    'Iași': 'IS#1504',
    'Ilfov': 'IF#6273',
    'Maramureș': 'MM#9418',
    'Mehedinți': 'MH#3365',
    'Mureș': 'MS#7820',
    'Neamț': 'NT#2059',
    'Olt': 'OT#5941',
    'Prahova': 'PH#1683',
    'Satu Mare': 'SM#8407',
    'Sălaj': 'SJ#3256',
    'Sibiu': 'SB#9172',
    'Suceava': 'SV#4839',
    'Teleorman': 'TR#6701',
    'Timiș': 'TM#2548',
    'Tulcea': 'TL#5092',
    'Vaslui': 'VS#7364',
    'Vâlcea': 'VL#1825',
    'Vrancea': 'VN#4910',
  };

  // Counties list (all 42 Romanian counties with proper diacritics)
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
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityPasswordController.dispose();
    _classNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateCityPassword() {
    if (_selectedCity == null) return false;
    final expectedPassword = _cityPasswords[_selectedCity];
    return expectedPassword != null &&
           _cityPasswordController.text.trim() == expectedPassword;
  }

  Future<void> _handleRegister() async {
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

    final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

    final result = await ref.read(authControllerProvider.notifier).createAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: fullName,
          schoolId: _selectedSchoolId!,
          phoneNumber: _phoneController.text.trim(),
          city: _selectedCity!,
          className: _classNameController.text.trim(),
        );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate('account_created_wait_approval')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _errorMessage = _getLocalizedAuthError(result.errorCode));
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(authControllerProvider.notifier).signInWithGoogle();

    if (mounted) {
      setState(() => _isGoogleLoading = false);

      if (!result.success) {
        setState(() => _errorMessage = _getLocalizedAuthError(result.errorCode));
      }
    }
  }

  /// Get localized error message based on error code
  String _getLocalizedAuthError(String? errorCode) {
    final l10n = AppLocalizations.of(context);
    final key = 'auth_error_${errorCode?.replaceAll('-', '_') ?? 'default'}';
    final translation = l10n.translate(key);
    // If translation returns the key itself, use the default error message
    if (translation == key) {
      return l10n.translate('auth_error_default');
    }
    return translation;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final schoolsAsync = ref.watch(schoolsByCountyProvider(_selectedCity));

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Title - tap 5 times for admin setup
                  GestureDetector(
                    onTap: () {
                      _titleTapCount++;
                      if (_titleTapCount >= 5) {
                        _titleTapCount = 0;
                        context.push(RouteNames.adminSetup);
                      } else if (_titleTapCount >= 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.translate('admin_setup_taps').replaceAll('{count}', '${5 - _titleTapCount}')),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: Text(
                      l10n.translate('create_account'),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    l10n.translate('join_student_council'),
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 13),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.translate('first_name'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _firstNameController,
                              enabled: !_isLoading && !_isGoogleLoading,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDecoration('${l10n.translate('first_name')}...'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.translate('field_required');
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.translate('last_name'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _lastNameController,
                              enabled: !_isLoading && !_isGoogleLoading,
                              textCapitalization: TextCapitalization.words,
                              decoration: _inputDecoration('${l10n.translate('last_name')}...'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.translate('field_required');
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Email
                  Text(
                    l10n.translate('email'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    enabled: !_isLoading && !_isGoogleLoading,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('${l10n.translate('email')}...'),
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

                  // Phone Number (Required)
                  Text(
                    l10n.translate('phone_number'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    enabled: !_isLoading && !_isGoogleLoading,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('+40 7XX XXX XXX'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.translate('phone_required');
                      }
                      // Basic phone validation - at least 10 digits
                      final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (digitsOnly.length < 10) {
                        return l10n.translate('invalid_phone');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // City Dropdown (Required) - Searchable
                  Text(
                    l10n.translate('city'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSearchableCityField(l10n),
                  const SizedBox(height: 16),

                  // City Password (Required - provided by admin)
                  Text(
                    l10n.translate('city_password'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cityPasswordController,
                    enabled: !_isLoading && !_isGoogleLoading && _selectedCity != null,
                    obscureText: _obscureCityPassword,
                    style: TextStyle(color: context.textPrimary),
                    decoration: _inputDecoration(
                      l10n.translate('city_password_hint'),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCityPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: context.textSecondary,
                          size: 20,
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
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.translate('city_required'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // School Dropdown
                  Text(
                    l10n.translate('school'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedCity == null)
                    // Show disabled dropdown when no city is selected
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration(l10n.translate('select_city_first')),
                      items: const [],
                      onChanged: null,
                    )
                  else
                    schoolsAsync.when(
                      data: (schools) => DropdownButtonFormField<String>(
                        value: _selectedSchoolId,
                        decoration: _inputDecoration('${l10n.translate('select')} ${l10n.translate('school')}...'),
                        items: schools.map((school) {
                          return DropdownMenuItem(
                            value: school.id,
                            child: Text(
                              school.shortName.isNotEmpty ? school.shortName : school.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _isLoading || _isGoogleLoading
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
                        l10n.translate('error_loading'),
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Class Name (Required)
                  Text(
                    l10n.translate('class_name'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _classNameController,
                    enabled: !_isLoading && !_isGoogleLoading,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _inputDecoration('12A'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.translate('field_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  Text(
                    l10n.translate('password'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_isLoading && !_isGoogleLoading,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: context.textPrimary),
                    decoration: _inputDecoration(
                      '${l10n.translate('password')}...',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: context.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.translate('field_required');
                      }
                      if (value.length < 6) {
                        return l10n.translate('password_too_short');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  Text(
                    l10n.translate('confirm_password'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    enabled: !_isLoading && !_isGoogleLoading,
                    obscureText: _obscureConfirmPassword,
                    style: TextStyle(color: context.textPrimary),
                    decoration: _inputDecoration(
                      '${l10n.translate('confirm_password')}...',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: context.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.translate('field_required');
                      }
                      if (value != _passwordController.text) {
                        return l10n.translate('passwords_do_not_match');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Create Account Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading || _isGoogleLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navy,
                        disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                              l10n.translate('create_account'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Already have account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${l10n.translate('already_have_account')} ',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          l10n.translate('login'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // OR Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: context.borderColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.translate('or').toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: context.borderColor)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Google Sign Up Button
                  _SocialButton(
                    icon: 'G',
                    iconColor: Colors.red,
                    label: 'Continue with Google',
                    isLoading: _isGoogleLoading,
                    onPressed: _isLoading ? null : _handleGoogleSignUp,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a searchable city selection field
  Widget _buildSearchableCityField(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = _isLoading || _isGoogleLoading;

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
              onTap: isDisabled ? null : () => _showCitySearchSheet(l10n),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.hasError ? context.errorColor : context.borderColor,
                    width: state.hasError ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedCity ?? '${l10n.translate('select')} ${l10n.translate('city')}...',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedCity != null
                              ? context.textPrimary
                              : context.textSecondary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.search,
                      color: context.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: context.errorColor,
                    fontSize: 12,
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
            _cityPasswordController.clear(); // Clear password when city changes
          });
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: context.textSecondary,
        fontSize: 14,
      ),
      filled: true,
      fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
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
        borderSide: BorderSide(color: context.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.errorColor, width: 1.5),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;

  const _SocialButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _buildContent(),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _buildContent(isLight: true),
            ),
    );
  }

  Widget _buildContent({bool isLight = false}) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: isLight ? AppColors.white : AppColors.navy,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isLight ? AppColors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              icon,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isLight ? AppColors.white : AppColors.navy,
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet widget for searching and selecting a city
/// Public so it can be reused in profile_setup_screen
class CitySearchSheet extends StatefulWidget {
  final List<String> cities;
  final String? selectedCity;
  final AppLocalizations l10n;
  final ValueChanged<String> onCitySelected;

  const CitySearchSheet({
    super.key,
    required this.cities,
    required this.selectedCity,
    required this.l10n,
    required this.onCitySelected,
  });

  @override
  State<CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<CitySearchSheet> {
  late TextEditingController _searchController;
  late List<String> _filteredCities;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredCities = widget.cities;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCities = widget.cities;
      } else {
        final queryLower = query.toLowerCase();
        _filteredCities = widget.cities
            .where((city) => city.toLowerCase().contains(queryLower))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${widget.l10n.translate('select')} ${widget.l10n.translate('city')}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: '${widget.l10n.translate('search')}...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[500]),
                        onPressed: () {
                          _searchController.clear();
                          _filterCities('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: _filterCities,
            ),
          ),

          const SizedBox(height: 8),

          // City list
          Expanded(
            child: _filteredCities.isEmpty
                ? Center(
                    child: Text(
                      widget.l10n.translate('no_results'),
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _filteredCities.length,
                    itemBuilder: (context, index) {
                      final city = _filteredCities[index];
                      final isSelected = city == widget.selectedCity;

                      return ListTile(
                        title: Text(
                          city,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: AppColors.gold)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tileColor: isSelected
                            ? AppColors.gold.withValues(alpha: 0.1)
                            : null,
                        onTap: () {
                          widget.onCitySelected(city);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
