import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import '../admin/user_detail_screen.dart';
import '../admin/admin_warnings_screen.dart';

/// BEX Members Screen - View and manage county members
class BexMembersScreen extends ConsumerStatefulWidget {
  const BexMembersScreen({super.key});

  @override
  ConsumerState<BexMembersScreen> createState() => _BexMembersScreenState();
}

class _BexMembersScreenState extends ConsumerState<BexMembersScreen> {
  String _searchQuery = '';
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(l10n.translate('members')),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminWarningsScreen()),
            ),
            icon: const Icon(Icons.warning_amber_rounded),
            tooltip: l10n.translate('warnings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Container(
            color: AppColors.navy,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.translate('search_members'),
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                // Role filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: l10n.translate('all'),
                        isSelected: _selectedRole == null,
                        onTap: () => setState(() => _selectedRole = null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: l10n.translate('school_rep'),
                        isSelected: _selectedRole == UserRole.schoolRep,
                        onTap: () => setState(() => _selectedRole = UserRole.schoolRep),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: l10n.translate('class_rep'),
                        isSelected: _selectedRole == UserRole.classRep,
                        onTap: () => setState(() => _selectedRole = UserRole.classRep),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: l10n.translate('department'),
                        isSelected: _selectedRole == UserRole.department,
                        onTap: () => setState(() => _selectedRole = UserRole.department),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: l10n.translate('student'),
                        isSelected: _selectedRole == UserRole.student,
                        onTap: () => setState(() => _selectedRole = UserRole.student),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Members list
          Expanded(
            child: usersAsync.when(
              data: (users) {
                // Apply filters
                var filteredUsers = users.where((user) {
                  // Exclude BEX and superadmin from list
                  if (user.role == UserRole.bex || user.role == UserRole.superadmin) {
                    return false;
                  }

                  // Search filter
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    if (!user.fullName.toLowerCase().contains(query) &&
                        !(user.schoolName?.toLowerCase().contains(query) ?? false) &&
                        !user.email.toLowerCase().contains(query)) {
                      return false;
                    }
                  }

                  // Role filter
                  if (_selectedRole != null && user.role != _selectedRole) {
                    return false;
                  }

                  return true;
                }).toList();

                // Sort by role priority and then name
                filteredUsers.sort((a, b) {
                  final rolePriority = {
                    UserRole.schoolRep: 0,
                    UserRole.department: 1,
                    UserRole.classRep: 2,
                    UserRole.student: 3,
                  };
                  final aPriority = rolePriority[a.role] ?? 99;
                  final bPriority = rolePriority[b.role] ?? 99;
                  if (aPriority != bPriority) {
                    return aPriority.compareTo(bPriority);
                  }
                  return a.fullName.compareTo(b.fullName);
                });

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: context.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          l10n.translate('no_users_found'),
                          style: TextStyle(fontSize: 16, color: context.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allUsersProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      return _MemberCard(
                        user: filteredUsers[index],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserDetailScreen(userId: filteredUsers[index].id),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.navy : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _MemberCard({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.15),
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getRoleColor(user.role),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.role.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getRoleColor(user.role),
                          ),
                        ),
                      ),
                      if (user.schoolName != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.schoolName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Status indicator
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _getStatusColor(user.status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superadmin:
        return Colors.red;
      case UserRole.bex:
        return Colors.purple;
      case UserRole.schoolRep:
        return Colors.blue;
      case UserRole.department:
        return Colors.teal;
      case UserRole.classRep:
        return Colors.orange;
      case UserRole.student:
        return Colors.grey;
    }
  }

  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return Colors.green;
      case UserStatus.pending:
        return Colors.orange;
      case UserStatus.suspended:
        return Colors.red;
    }
  }
}
