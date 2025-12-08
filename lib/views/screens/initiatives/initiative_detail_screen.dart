import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import 'tabs/tabs.dart';
import 'widgets/widgets.dart';

/// Detail screen for viewing a single initiative with tabs
class InitiativeDetailScreen extends ConsumerStatefulWidget {
  final InitiativeModel initiative;

  const InitiativeDetailScreen({super.key, required this.initiative});

  @override
  ConsumerState<InitiativeDetailScreen> createState() =>
      _InitiativeDetailScreenState();
}

class _InitiativeDetailScreenState extends ConsumerState<InitiativeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canManage = _canManage(user);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _InitiativeAppBar(
              initiative: widget.initiative,
              canManage: canManage,
              tabController: _tabController,
              onMenuAction: (action) => _handleMenuAction(action, context),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            InitiativeDescriptionTab(initiative: widget.initiative),
            InitiativeImpactTab(initiative: widget.initiative),
            InitiativeCommentsTab(initiative: widget.initiative),
          ],
        ),
      ),
    );
  }

  bool _canManage(UserModel? user) {
    return user != null &&
        (user.id == widget.initiative.authorId ||
            user.role == UserRole.bex ||
            user.role == UserRole.superadmin);
  }

  void _handleMenuAction(String action, BuildContext context) {
    final l10n = AppLocalizations.of(context);

    switch (action) {
      case 'submit':
        _submitInitiative(context);
        break;
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit functionality coming soon')),
        );
        break;
      case 'delete':
        _deleteInitiative(context, l10n);
        break;
    }
  }

  void _submitInitiative(BuildContext context) async {
    final success = await ref
        .read(initiativeControllerProvider.notifier)
        .submitInitiative(widget.initiative.id);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Initiative submitted for review'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteInitiative(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('delete_initiative')),
        content: Text(l10n.translate('delete_initiative_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(initiativeControllerProvider.notifier)
                  .deleteInitiative(widget.initiative.id);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.translate('initiative_deleted'))),
                );
              }
            },
            child: Text(
              l10n.translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitiativeAppBar extends StatelessWidget {
  final InitiativeModel initiative;
  final bool canManage;
  final TabController tabController;
  final Function(String) onMenuAction;

  const _InitiativeAppBar({
    required this.initiative,
    required this.canManage,
    required this.tabController,
    required this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.navy,
      leading: _buildBackButton(context),
      actions: canManage ? [_buildMenuButton(context, l10n)] : null,
      flexibleSpace: FlexibleSpaceBar(
        background: _InitiativeHeader(initiative: initiative),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: _buildTabBar(l10n),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
      ),
      onPressed: () => Navigator.pop(context),
    );
  }

  Widget _buildMenuButton(BuildContext context, AppLocalizations l10n) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
      ),
      onSelected: onMenuAction,
      itemBuilder: (context) => [
        if (initiative.status == InitiativeStatus.draft)
          PopupMenuItem(
            value: 'submit',
            child: Row(
              children: [
                const Icon(Icons.send_rounded, size: 20),
                const SizedBox(width: 12),
                Text(l10n.translate('submit')),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 20),
              const SizedBox(width: 12),
              Text(l10n.translate('edit')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              const SizedBox(width: 12),
              Text(l10n.translate('delete'),
                  style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      color: AppColors.navy,
      child: TabBar(
        controller: tabController,
        indicatorColor: AppColors.gold,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: l10n.translate('description')),
          Tab(text: l10n.translate('expected_impact')),
          Tab(text: l10n.translate('comments_support')),
        ],
      ),
    );
  }
}

class _InitiativeHeader extends StatelessWidget {
  final InitiativeModel initiative;

  const _InitiativeHeader({required this.initiative});

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 50, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitiativeStatusBadge(status: initiative.status),
              const SizedBox(height: 12),
              _buildTitle(),
              const SizedBox(height: 12),
              _buildAuthorInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      initiative.title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAuthorInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: Text(
            initiative.authorName.isNotEmpty
                ? initiative.authorName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                initiative.authorName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              if (initiative.schoolName != null)
                Text(
                  initiative.schoolName!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
