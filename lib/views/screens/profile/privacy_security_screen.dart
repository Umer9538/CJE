import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';

/// Privacy & Security screen for password change and account management
class PrivacySecurityScreen extends ConsumerStatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  ConsumerState<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends ConsumerState<PrivacySecurityScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isChangingPassword = false;
  bool _isDeletingAccount = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Check if user signed in with Google by checking Firebase Auth providers
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final isGoogleUser = firebaseUser?.providerData.any(
      (info) => info.providerId == 'google.com'
    ) ?? false;

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(l10n.translate('privacy_security')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Password Section
            _buildSectionTitle(context, l10n.translate('change_password')),
            const SizedBox(height: 12),
            _buildPasswordSection(context, l10n, isGoogleUser),

            const SizedBox(height: 32),

            // Account Section
            _buildSectionTitle(context, l10n.translate('account')),
            const SizedBox(height: 12),
            _buildAccountSection(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: context.textPrimary,
      ),
    );
  }

  Widget _buildPasswordSection(BuildContext context, AppLocalizations l10n, bool isGoogleUser) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isGoogleUser
          ? _buildGoogleUserMessage(context, l10n)
          : _buildPasswordForm(context, l10n),
    );
  }

  Widget _buildGoogleUserMessage(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Icon(
          Icons.g_mobiledata,
          size: 48,
          color: context.textSecondary,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.translate('google_password_message'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordForm(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Password
        _buildPasswordField(
          context: context,
          controller: _currentPasswordController,
          label: l10n.translate('current_password'),
          obscure: _obscureCurrentPassword,
          onToggle: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
        ),
        const SizedBox(height: 16),

        // New Password
        _buildPasswordField(
          context: context,
          controller: _newPasswordController,
          label: l10n.translate('new_password'),
          obscure: _obscureNewPassword,
          onToggle: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
        ),
        const SizedBox(height: 16),

        // Confirm Password
        _buildPasswordField(
          context: context,
          controller: _confirmPasswordController,
          label: l10n.translate('confirm_password'),
          obscure: _obscureConfirmPassword,
          onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
        const SizedBox(height: 24),

        // Change Password Button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isChangingPassword ? null : () => _changePassword(context, l10n),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isChangingPassword
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(l10n.translate('change_password')),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: context.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.textSecondary),
        filled: true,
        fillColor: context.scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.textSecondary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.textSecondary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.goldColor),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: context.textSecondary,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Delete Account
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.delete_forever_rounded, color: context.errorColor),
            ),
            title: Text(
              l10n.translate('delete_account'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.errorColor,
              ),
            ),
            subtitle: Text(
              l10n.translate('delete_account_subtitle'),
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: context.errorColor),
            onTap: () => _showDeleteAccountDialog(context, l10n),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(BuildContext context, AppLocalizations l10n) async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar(context, l10n.translate('fill_all_fields'), isError: true);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar(context, l10n.translate('password_min_length'), isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar(context, l10n.translate('passwords_not_match'), isError: true);
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      await ref.read(authControllerProvider.notifier).changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _showSnackBar(context, l10n.translate('password_changed_success'));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  void _showDeleteAccountDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Flexible(child: Text(l10n.translate('delete_account'))),
          ],
        ),
        content: Text(l10n.translate('delete_account_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(context, l10n);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.translate('delete')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, AppLocalizations l10n) async {
    setState(() => _isDeletingAccount = true);

    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
      // User will be signed out and redirected automatically
    } catch (e) {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
        _showSnackBar(context, e.toString(), isError: true);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
