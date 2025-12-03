import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../widgets/common/app_button.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

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

              // Pending icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_top,
                  size: 60,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(height: AppSizes.spacing32),

              // Title
              Text(
                l10n.translate('account_pending'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacing16),

              // Description
              Text(
                l10n.translate('account_pending_description'),
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
                      // Avatar
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: user?.photoUrl != null
                            ? NetworkImage(user!.photoUrl!)
                            : null,
                        child: user?.photoUrl == null
                            ? Text(
                                user?.fullName.isNotEmpty == true
                                    ? user!.fullName[0].toUpperCase()
                                    : '?',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              )
                            : null,
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
                      const SizedBox(height: AppSizes.spacing8),

                      // School
                      if (user?.schoolName != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSizes.spacing4),
                            Text(
                              user!.schoolName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),

                      // Status badge
                      const SizedBox(height: AppSizes.spacing12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingMD,
                          vertical: AppSizes.paddingSM,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pending,
                              size: 16,
                              color: theme.colorScheme.tertiary,
                            ),
                            const SizedBox(width: AppSizes.spacing4),
                            Text(
                              l10n.translate('status_pending'),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.tertiary,
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

              // Info box
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMD),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSizes.spacing12),
                    Expanded(
                      child: Text(
                        l10n.translate('pending_approval_info'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
              AppTextButton(
                text: l10n.translate('logout'),
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
