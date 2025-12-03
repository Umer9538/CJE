import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../widgets/common/app_button.dart';

class SuspendedAccountScreen extends ConsumerWidget {
  const SuspendedAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

              // Suspended icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block,
                  size: 60,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: AppSizes.spacing32),

              // Title
              Text(
                l10n.translate('account_suspended'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacing16),

              // Description
              Text(
                l10n.translate('account_suspended_description'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacing32),

              // User info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMD),
                  child: Column(
                    children: [
                      // Avatar with overlay
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            backgroundImage: user?.photoUrl != null
                                ? NetworkImage(user!.photoUrl!)
                                : null,
                            child: user?.photoUrl == null
                                ? Text(
                                    user?.fullName.isNotEmpty == true
                                        ? user!.fullName[0].toUpperCase()
                                        : '?',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: theme.colorScheme.onError,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spacing12),

                      // Name
                      Text(
                        user?.fullName ?? '',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing4),

                      // Email
                      Text(
                        user?.email ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),

                      // Status badge
                      const SizedBox(height: AppSizes.spacing12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingMD,
                          vertical: AppSizes.paddingSM,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.block,
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: AppSizes.spacing4),
                            Text(
                              l10n.translate('status_suspended'),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Contact info
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMD),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.support_agent,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: AppSizes.spacing12),
                    Expanded(
                      child: Text(
                        l10n.translate('contact_admin_for_help'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.spacing24),

              // Refresh button
              AppOutlinedButton(
                text: l10n.translate('check_status'),
                icon: Icons.refresh,
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).reloadUser();
                },
              ),
              const SizedBox(height: AppSizes.spacing12),

              // Logout button
              AppButton(
                text: l10n.translate('logout'),
                backgroundColor: theme.colorScheme.error,
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
