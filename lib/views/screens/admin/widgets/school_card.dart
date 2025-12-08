import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../models/models.dart';

/// School card widget for admin schools list
class SchoolCard extends StatelessWidget {
  final SchoolModel school;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const SchoolCard({
    super.key,
    required this.school,
    required this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: !school.isActive
              ? Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildLogo(),
            const SizedBox(width: 14),
            Expanded(child: _buildInfo()),
            _buildTrailing(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: school.isActive
            ? AppColors.navy.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: school.logoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                school.logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildLogoText(),
              ),
            )
          : _buildLogoText(),
    );
  }

  Widget _buildLogoText() {
    return Center(
      child: Text(
        school.shortName.isNotEmpty
            ? school.shortName.substring(0, school.shortName.length.clamp(0, 2))
            : 'S',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: school.isActive ? AppColors.navy : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                school.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: school.isActive ? AppColors.navy : Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!school.isActive) _buildInactiveBadge(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          school.shortName,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        _buildStats(),
      ],
    );
  }

  Widget _buildInactiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Inactive',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Icon(Icons.people_outline, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Text(
          '${school.studentCount} students',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        if (school.schoolRepName != null) ...[
          const SizedBox(width: 12),
          Icon(Icons.person_outline, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              school.schoolRepName!,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrailing() {
    if (onEdit != null) {
      return IconButton(
        onPressed: onEdit,
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.edit_outlined, color: AppColors.navy, size: 18),
        ),
      );
    }
    return Icon(Icons.chevron_right, color: Colors.grey[400]);
  }
}
