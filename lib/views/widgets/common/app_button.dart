import 'package:flutter/material.dart';

import '../../../core/core.dart';

/// Primary filled button
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final bool isExpanded;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.isExpanded = true,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: Size(isExpanded ? double.infinity : 0, height ?? AppSizes.buttonHeight),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSizes.spacing8),
                ],
                Text(text),
              ],
            ),
    );

    return button;
  }
}

/// Outlined button
class AppOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final bool isExpanded;
  final IconData? icon;
  final Color? foregroundColor;
  final double? height;

  const AppOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.isExpanded = true,
    this.icon,
    this.foregroundColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        minimumSize: Size(isExpanded ? double.infinity : 0, height ?? AppSizes.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  foregroundColor ?? Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSizes.spacing8),
                ],
                Text(text),
              ],
            ),
    );
  }
}

/// Text button
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final IconData? icon;
  final Color? foregroundColor;

  const AppTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isEnabled = true,
    this.icon,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: AppSizes.spacing4),
          ],
          Text(text),
        ],
      ),
    );
  }
}

/// Google sign-in button
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://www.google.com/favicon.ico',
                  height: 20,
                  width: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
                ),
                const SizedBox(width: AppSizes.spacing12),
                Text(l10n.translate('continue_with_google')),
              ],
            ),
    );
  }
}

/// Icon button with badge
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final int? badgeCount;
  final Color? iconColor;
  final double? iconSize;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.badgeCount,
    this.iconColor,
    this.iconSize,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(
      icon,
      color: iconColor,
      size: iconSize ?? 24,
    );

    if (badgeCount != null && badgeCount! > 0) {
      iconWidget = Badge(
        label: Text(badgeCount! > 99 ? '99+' : badgeCount.toString()),
        child: iconWidget,
      );
    }

    return IconButton(
      onPressed: onPressed,
      icon: iconWidget,
      tooltip: tooltip,
    );
  }
}
