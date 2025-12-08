import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/schools/school_controller.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import 'widgets/widgets.dart';

/// Admin screen to manage schools
class AdminSchoolsScreen extends ConsumerStatefulWidget {
  const AdminSchoolsScreen({super.key});

  @override
  ConsumerState<AdminSchoolsScreen> createState() => _AdminSchoolsScreenState();
}

class _AdminSchoolsScreenState extends ConsumerState<AdminSchoolsScreen> {
  final _searchController = TextEditingController();
  bool _showInactive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canManage = ref.watch(canManageSchoolsProvider);
    final schoolsAsync = ref.watch(allSchoolsProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: _buildAppBar(l10n),
      body: Column(
        children: [
          _buildSearchBar(l10n),
          Expanded(
            child: schoolsAsync.when(
              data: (schools) => _buildSchoolsList(schools, canManage, l10n),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
              error: (_, __) => _buildErrorState(l10n),
            ),
          ),
        ],
      ),
      floatingActionButton: canManage ? _buildFab(l10n) : null,
    );
  }

  AppBar _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: Text(l10n.translate('manage_schools')),
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
          tooltip: _showInactive ? 'Hide inactive' : 'Show inactive',
          onPressed: () => setState(() => _showInactive = !_showInactive),
        ),
      ],
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: l10n.translate('search_schools'),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.6)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSchoolsList(List<SchoolModel> schools, bool canManage, AppLocalizations l10n) {
    var filteredSchools = schools;

    // Filter by active status
    if (!_showInactive) {
      filteredSchools = filteredSchools.where((s) => s.isActive).toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filteredSchools = filteredSchools.where((s) =>
          s.name.toLowerCase().contains(query) ||
          s.shortName.toLowerCase().contains(query)).toList();
    }

    if (filteredSchools.isEmpty) {
      return _buildEmptyState(l10n);
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(allSchoolsProvider),
      color: AppColors.gold,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredSchools.length,
        itemBuilder: (context, index) {
          final school = filteredSchools[index];
          return SchoolCard(
            school: school,
            onTap: () => _showSchoolDetail(school),
            onEdit: canManage ? () => _showEditSchool(school) : null,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.school_outlined, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('no_schools'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(l10n.translate('error_loading')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(allSchoolsProvider),
            child: Text(l10n.translate('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(AppLocalizations l10n) {
    return FloatingActionButton.extended(
      heroTag: 'fab_admin_schools',
      onPressed: _showCreateSchool,
      backgroundColor: AppColors.gold,
      foregroundColor: AppColors.navy,
      icon: const Icon(Icons.add_rounded),
      label: Text(l10n.translate('add_school')),
    );
  }

  void _showSchoolDetail(SchoolModel school) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SchoolDetailSheet(school: school),
    );
  }

  void _showCreateSchool() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const SchoolFormSheet(),
    );
  }

  void _showEditSchool(SchoolModel school) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SchoolFormSheet(school: school),
    );
  }
}
