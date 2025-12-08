import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../models/models.dart';

/// Header widget for user detail screen
class UserDetailHeader extends StatelessWidget {
  final UserModel user;

  const UserDetailHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navy,
            AppColors.navy.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            _buildAvatar(),
            const SizedBox(height: 12),
            _buildName(),
            const SizedBox(height: 4),
            _buildEmail(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 40,
      backgroundColor: user.role.badgeBackgroundColor,
      backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
      child: user.photoUrl == null
          ? Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: user.role.badgeTextColor,
              ),
            )
          : null,
    );
  }

  Widget _buildName() {
    return Text(
      user.fullName,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildEmail() {
    return Text(
      user.email,
      style: TextStyle(
        fontSize: 14,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }
}
