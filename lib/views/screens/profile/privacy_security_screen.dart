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
      backgroundColor: const Color(0xFFF5F7FA),
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
            _buildSectionTitle(l10n.translate('change_password')),
            const SizedBox(height: 12),
            _buildPasswordSection(context, l10n, isGoogleUser),

            const SizedBox(height: 32),

            // Account Section
            _buildSectionTitle(l10n.translate('account')),
            const SizedBox(height: 12),
            _buildAccountSection(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.navy,
      ),
    );
  }

  Widget _buildPasswordSection(BuildContext context, AppLocalizations l10n, bool isGoogleUser) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isGoogleUser
          ? _buildGoogleUserMessage(l10n)
          : _buildPasswordForm(context, l10n),
    );
  }

  Widget _buildGoogleUserMessage(AppLocalizations l10n) {
    return Column(
      children: [
        Icon(
          Icons.g_mobiledata,
          size: 48,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.translate('google_password_message'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[600],
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
          controller: _currentPasswordController,
          label: l10n.translate('current_password'),
          obscure: _obscureCurrentPassword,
          onToggle: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
        ),
        const SizedBox(height: 16),

        // New Password
        _buildPasswordField(
          controller: _newPasswordController,
          label: l10n.translate('new_password'),
          obscure: _obscureNewPassword,
          onToggle: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
        ),
        const SizedBox(height: 16),

        // Confirm Password
        _buildPasswordField(
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
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.red),
            ),
            title: Text(
              l10n.translate('delete_account'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            subtitle: Text(
              l10n.translate('delete_account_subtitle'),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
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
