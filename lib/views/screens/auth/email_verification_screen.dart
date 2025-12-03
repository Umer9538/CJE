import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../widgets/common/app_button.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  bool _isResending = false;
  bool _isChecking = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    // Start periodic check for email verification
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }

  void _startVerificationCheck() {
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkVerification();
    });
  }

  Future<void> _checkVerification() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    final isVerified = await ref.read(authControllerProvider.notifier).checkEmailVerification();

    if (mounted) {
      setState(() => _isChecking = false);

      if (isVerified) {
        _checkTimer?.cancel();
        // Reload user to update auth state
        await ref.read(authControllerProvider.notifier).reloadUser();
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0) return;

    setState(() => _isResending = true);

    final result = await ref.read(authControllerProvider.notifier).sendEmailVerification();

    if (mounted) {
      setState(() => _isResending = false);

      if (result.success) {
        // Start cooldown
        setState(() => _resendCooldown = 60);
        _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_resendCooldown > 0) {
            setState(() => _resendCooldown--);
          } else {
            timer.cancel();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de verificare trimis!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Eroare la trimitere'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLG),
          child: Column(
            children: [
              const Spacer(),

              // Email icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_unread,
                  size: 60,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSizes.spacing32),

              // Title
              Text(
                l10n.translate('verify_email'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacing16),

              // Description
              Text(
                l10n.translate('verification_email_sent'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacing8),

              // Email
              Text(
                user?.email ?? '',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacing32),

              // Checking status
              if (_isChecking)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing8),
                    Text(
                      l10n.translate('checking_verification'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),

              const Spacer(),

              // Resend button
              AppOutlinedButton(
                text: _resendCooldown > 0
                    ? '${l10n.translate('resend_in')} $_resendCooldown s'
                    : l10n.translate('resend_verification_email'),
                isLoading: _isResending,
                isEnabled: _resendCooldown == 0,
                onPressed: _resendVerificationEmail,
                icon: Icons.refresh,
              ),
              const SizedBox(height: AppSizes.spacing12),

              // Check manually button
              AppButton(
                text: l10n.translate('i_verified_my_email'),
                isLoading: _isChecking,
                onPressed: _checkVerification,
              ),
              const SizedBox(height: AppSizes.spacing16),

              // Change account / Logout
              AppTextButton(
                text: l10n.translate('use_different_account'),
                onPressed: _handleLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
