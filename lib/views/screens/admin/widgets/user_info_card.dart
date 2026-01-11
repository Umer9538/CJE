import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/core.dart';
import '../../../../models/models.dart';

/// Info card widget for user details
class UserInfoCard extends StatelessWidget {
  final UserModel user;

  const UserInfoCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
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
          _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
          if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
            _InfoRow(
              icon: Icons.phone_outlined,
              label: l10n.translate('phone'),
              value: user.phoneNumber!,
            ),
          if (user.schoolName != null)
            _InfoRow(
              icon: Icons.school_outlined,
              label: l10n.translate('school'),
              value: user.schoolName!,
            ),
          if (user.className != null && user.className!.isNotEmpty)
            _InfoRow(
              icon: Icons.class_outlined,
              label: l10n.translate('class'),
              value: user.className!,
            ),
          if (user.city != null)
            _InfoRow(
              icon: Icons.location_city_outlined,
              label: l10n.translate('city'),
              value: user.city!,
            ),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: l10n.translate('member_since'),
            value: dateFormat.format(user.createdAt),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppColors.gold.withValues(alpha: 0.15) : AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isDark ? AppColors.gold : AppColors.navy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
