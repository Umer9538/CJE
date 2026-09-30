import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../routes/route_names.dart';
import '../profile/legal_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  int _titleTapCount = 0;

  // SharedPreferences keys for remember me (email only — never store passwords)
  static const String _keyRememberMe = 'remember_me';
  static const String _keySavedEmail = 'saved_email';

  static const String _keyTermsAccepted = 'terms_accepted';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTermsAccepted());
  }

  Future<void> _checkTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_keyTermsAccepted) ?? false;
    if (!accepted && mounted) {
      _showTermsDialog();
    }
  }

  void _showTermsDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('terms_agreement_title')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.translate('terms_agreement_body'),
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsOfServiceScreen(),
                    ),
                  ).then((_) => _showTermsDialog());
                },
                child: Text(
                  l10n.translate('view_full_terms'),
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Exit the app if user declines
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: Text(
              l10n.translate('decline'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navy,
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(_keyTermsAccepted, true);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.translate('accept_terms')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// Load saved email if remember me was checked
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_keyRememberMe) ?? false;

      // Clean up any previously stored password (security fix)
      await prefs.remove('saved_password');

      if (rememberMe) {
        final savedEmail = prefs.getString(_keySavedEmail) ?? '';

        setState(() {
          _rememberMe = true;
          _emailController.text = savedEmail;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  /// Save email to SharedPreferences (never store passwords)
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_rememberMe) {
        await prefs.setBool(_keyRememberMe, true);
        await prefs.setString(_keySavedEmail, _emailController.text.trim());
      } else {
        // Clear saved credentials if remember me is unchecked
        await _clearCredentials();
      }
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  /// Clear saved credentials from SharedPreferences
  Future<void> _clearCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRememberMe);
      await prefs.remove(_keySavedEmail);
      await prefs.remove('saved_password');
    } catch (e) {
      debugPrint('Error clearing credentials: $e');
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(authControllerProvider.notifier).signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        // Save credentials if remember me is checked
        await _saveCredentials();
      } else {
        setState(() => _errorMessage = _getLocalizedAuthError(result.errorCode));
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
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

  Future<void> _handleAppleLogin() async {
    setState(() {
      _isAppleLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(authControllerProvider.notifier).signInWithApple();

    if (mounted) {
      setState(() => _isAppleLoading = false);

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

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            maxWidth: 480,
            padding: EdgeInsets.all(context.responsive.value(mobile: 24.0, tablet: 32.0, desktop: 48.0)),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Title with wave emoji - tap 5 times for admin setup
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
                      '${l10n.translate('welcome_back')} 👋',
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
                    l10n.translate('login_subtitle'),
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

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

                  // Email Label
                  Text(
                    l10n.translate('email_address'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    enabled: !_isLoading && !_isGoogleLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: context.textPrimary),
                    onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                    decoration: _inputDecoration(context, l10n.translate('email_hint')),
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
                  const SizedBox(height: 20),

                  // Password Label
                  Text(
                    l10n.translate('password'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    enabled: !_isLoading && !_isGoogleLoading,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(color: context.textPrimary),
                    onFieldSubmitted: (_) => _handleEmailLogin(),
                    decoration: _inputDecoration(context, l10n.translate('password_hint')).copyWith(
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
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Remember me & Forgot password row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Remember me
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() => _rememberMe = value ?? false);
                                // Clear credentials immediately if unchecked
                                if (!_rememberMe) {
                                  _clearCredentials();
                                }
                              },
                              shape: const CircleBorder(),
                              side: BorderSide(color: context.textSecondary),
                              activeColor: AppColors.gold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remember me',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      // Forgot password
                      GestureDetector(
                        onTap: () => context.push(RouteNames.forgotPassword),
                        child: Text(
                          'Forgot Password ?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading || _isGoogleLoading ? null : _handleEmailLogin,
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
                          : const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account ? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push(RouteNames.register),
                        child: Text(
                          'Sign Up',
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
                          'OR',
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

                  // Google Sign In Button
                  _SocialButton(
                    icon: 'G',
                    iconColor: Colors.red,
                    label: l10n.translate('continue_with_google'),
                    isLoading: _isGoogleLoading,
                    onPressed: _isLoading || _isAppleLoading ? null : _handleGoogleLogin,
                  ),
                  const SizedBox(height: 12),

                  // Apple Sign In Button
                  _SocialButton(
                    icon: '',
                    iconColor: Colors.white,
                    label: 'Continue with Apple',
                    isLoading: _isAppleLoading,
                    onPressed: _isLoading || _isGoogleLoading ? null : _handleAppleLogin,
                    isApple: true,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
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
  final bool isApple;

  const _SocialButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isApple = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isApple ? Colors.black : AppColors.navy,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isApple)
                    const Icon(Icons.apple, color: Colors.white, size: 24)
                  else
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          icon,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
