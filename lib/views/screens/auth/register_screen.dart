import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import '../../../routes/route_names.dart';

/// Provider to fetch schools list
final schoolsListProvider = FutureProvider<List<SchoolModel>>((ref) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();

    final schools = snapshot.docs.map((doc) => SchoolModel.fromFirestore(doc)).toList();

    // If no schools in database, return sample schools for development
    if (schools.isEmpty) {
      return _getSampleSchools();
    }

    return schools;
  } catch (e) {
    // Return sample schools if Firebase fails (for development)
    return _getSampleSchools();
  }
});

/// Sample schools for development/testing
List<SchoolModel> _getSampleSchools() {
  return [
    SchoolModel(
      id: 'school_1',
      name: 'Colegiul Național "Emil Racoviță"',
      shortName: 'CNER',
      city: 'Iași',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SchoolModel(
      id: 'school_2',
      name: 'Colegiul Național',
      shortName: 'CN',
      city: 'Iași',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SchoolModel(
      id: 'school_3',
      name: 'Liceul Teoretic "Dimitrie Cantemir"',
      shortName: 'LTDC',
      city: 'Iași',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SchoolModel(
      id: 'school_4',
      name: 'Colegiul Național "Costache Negruzzi"',
      shortName: 'CNCN',
      city: 'Iași',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SchoolModel(
      id: 'school_5',
      name: 'Colegiul Național "Mihail Sadoveanu"',
      shortName: 'CNMS',
      city: 'Iași',
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

  // City passwords for access control (in production, these would be stored securely on the server)
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityPasswordController.dispose();
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
        );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Please wait for approval.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _errorMessage = result.errorMessage);
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
        setState(() => _errorMessage = result.errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final schoolsAsync = ref.watch(schoolsListProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
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
                            content: Text('${5 - _titleTapCount} more taps for admin setup'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: Text(
                      l10n.translate('create_account'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
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
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.translate('first_name'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
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

                  // City Dropdown (Required)
                  Text(
                    l10n.translate('city'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: _inputDecoration('${l10n.translate('select')} ${l10n.translate('city')}...'),
                    items: _cities.map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      );
                    }).toList(),
                    onChanged: _isLoading || _isGoogleLoading
                        ? null
                        : (value) {
                            setState(() {
                              _selectedCity = value;
                              _cityPasswordController.clear(); // Clear password when city changes
                            });
                          },
                    validator: (value) {
                      if (value == null) {
                        return l10n.translate('city_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // City Password (Required - provided by admin)
                  Text(
                    l10n.translate('city_password'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cityPasswordController,
                    enabled: !_isLoading && !_isGoogleLoading && _selectedCity != null,
                    obscureText: _obscureCityPassword,
                    decoration: _inputDecoration(l10n.translate('city_password_hint')).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCityPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey[500],
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  schoolsAsync.when(
                    data: (schools) => DropdownButtonFormField<String>(
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
                      'Error loading schools',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  Text(
                    l10n.translate('password'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_isLoading && !_isGoogleLoading,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration('${l10n.translate('password')}...').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey[500],
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    enabled: !_isLoading && !_isGoogleLoading,
                    obscureText: _obscureConfirmPassword,
                    decoration: _inputDecoration('${l10n.translate('confirm_password')}...').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey[500],
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
                          color: Colors.grey[600],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          l10n.translate('login'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // OR Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.translate('or').toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Social Sign Up Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          icon: 'G',
                          iconColor: Colors.red,
                          label: 'Google',
                          isLoading: _isGoogleLoading,
                          onPressed: _isLoading ? null : _handleGoogleSignUp,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SocialButton(
                          icon: 'in',
                          iconColor: const Color(0xFF0077B5),
                          label: 'LinkedIn',
                          isOutlined: true,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('LinkedIn sign in coming soon')),
                            );
                          },
                        ),
                      ),
                    ],
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red[400]!),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
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
