import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart' show GoRouterHelper;

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(_emailController.text.trim());

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _emailSent = true;
        } else {
          _errorMessage = result.errorMessage;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('forgot_password')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLG),
          child: _emailSent ? _buildSuccessContent(theme, l10n) : _buildFormContent(theme, l10n),
        ),
      ),
    );
  }

  Widget _buildFormContent(ThemeData theme, AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Icon(
            Icons.lock_reset,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSizes.spacing24),

          // Title
          Text(
            l10n.translate('reset_password'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spacing8),
          Text(
            l10n.translate('reset_password_instructions'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spacing32),

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

          // Email field
          EmailTextField(
            controller: _emailController,
            enabled: !_isLoading,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSendResetEmail(),
          ),
          const SizedBox(height: AppSizes.spacing24),

          // Send button
          AppButton(
            text: l10n.translate('send_reset_link'),
            isLoading: _isLoading,
            onPressed: _handleSendResetEmail,
          ),
          const SizedBox(height: AppSizes.spacing16),

          // Back to login
          AppTextButton(
            text: l10n.translate('back_to_login'),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSizes.spacing32),

        // Success icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read,
            size: 50,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSizes.spacing24),

        // Title
        Text(
          l10n.translate('email_sent'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacing8),
        Text(
          l10n.translate('check_email_for_reset_link'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacing8),
        Text(
          _emailController.text,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.spacing32),

        // Back to login button
        AppButton(
          text: l10n.translate('back_to_login'),
          onPressed: () => context.pop(),
        ),
        const SizedBox(height: AppSizes.spacing16),

        // Resend button
        AppTextButton(
          text: l10n.translate('resend_email'),
          onPressed: () {
            setState(() => _emailSent = false);
          },
        ),
      ],
    );
  }
}
