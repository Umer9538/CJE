import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import 'create_initiative_screen.dart';
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
    // Always show 3 tabs - Comments tab visible to all, but only BEx can post
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
    final l10n = AppLocalizations.of(context);

    // Watch the initiative provider for real-time updates (e.g., after voting)
    final initiativeAsync = ref.watch(initiativeProvider(widget.initiative.id));

    // Use fresh data from provider, fallback to widget.initiative for initial render
    final initiative = initiativeAsync.valueOrNull ?? widget.initiative;

    final canManage = _canManage(user, initiative);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header section
          _InitiativeHeader(
            initiative: initiative,
            canManage: canManage,
            onMenuAction: (action) => _handleMenuAction(action, context),
          ),
          // Tab bar
          Container(
            color: AppColors.navy,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.gold,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: [
                Tab(text: l10n.translate('description')),
                Tab(text: l10n.translate('expected_impact')),
                Tab(text: l10n.translate('comments_support')),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                InitiativeDescriptionTab(initiative: initiative),
                InitiativeImpactTab(initiative: initiative),
                InitiativeCommentsTab(initiative: initiative),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canManage(UserModel? user, InitiativeModel initiative) {
    return user != null &&
        (user.id == initiative.authorId ||
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
        _editInitiative(context);
        break;
      case 'delete':
        _deleteInitiative(context, l10n);
        break;
    }
  }

  void _editInitiative(BuildContext context) async {
    // Get fresh initiative data for editing
    final initiativeAsync = ref.read(initiativeProvider(widget.initiative.id));
    final initiative = initiativeAsync.valueOrNull ?? widget.initiative;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateInitiativeScreen(initiative: initiative),
      ),
    );

    // If edit was successful, pop back to refresh the list
    if (result == true && context.mounted) {
      Navigator.pop(context);
    }
  }

  void _submitInitiative(BuildContext context) async {
    final success = await ref
        .read(initiativeControllerProvider.notifier)
        .submitInitiative(widget.initiative.id);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('initiative_submitted_for_review')),
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

class _InitiativeHeader extends StatelessWidget {
  final InitiativeModel initiative;
  final bool canManage;
  final Function(String) onMenuAction;

  const _InitiativeHeader({
    required this.initiative,
    required this.canManage,
    required this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  _buildBackButton(context),
                  const Spacer(),
                  if (canManage) _buildMenuButton(context, l10n),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
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
          ],
        ),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (initiative.schoolName != null)
                Text(
                  initiative.schoolName!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
