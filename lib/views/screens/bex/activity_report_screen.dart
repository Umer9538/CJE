import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';

/// Provider for the DataExportService instance
final _dataExportServiceProvider = Provider<DataExportService>((ref) {
  return DataExportService();
});

/// Provider for quarterly content counts
final quarterlyReportDataProvider =
    FutureProvider.family<Map<String, int>, String>((ref, countyId) async {
  final service = ref.read(_dataExportServiceProvider);
  return service.getQuarterlyContentCounts(countyId);
});

/// BEx Activity Report Screen — download quarterly activity data
class ActivityReportScreen extends ConsumerStatefulWidget {
  const ActivityReportScreen({super.key});

  @override
  ConsumerState<ActivityReportScreen> createState() =>
      _ActivityReportScreenState();
}

class _ActivityReportScreenState extends ConsumerState<ActivityReportScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final countyId = ref.watch(effectiveCountyProvider) ?? '';
    final quarterLabel = DataExportService.getQuarterLabel();
    final range = DataExportService.getCurrentQuarterRange();
    final dateFormat = DateFormat('dd/MM/yyyy');

    final countsAsync = countyId.isNotEmpty
        ? ref.watch(quarterlyReportDataProvider(countyId))
        : const AsyncValue<Map<String, int>>.data({});

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(l10n.translate('activity_report')),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quarter info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navy, Color(0xFF1A3A5C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quarterLabel,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${dateFormat.format(range.start)} - ${dateFormat.format(range.end)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                if (countyId.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      countyId,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Content counts
          Text(
            l10n.translate('quarterly_summary'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          countsAsync.when(
            data: (counts) {
              if (countyId.isEmpty) {
                return _buildEmptyState(l10n.translate('no_county_selected'));
              }
              final total = (counts['announcements'] ?? 0) +
                  (counts['meetings'] ?? 0) +
                  (counts['polls'] ?? 0) +
                  (counts['initiatives'] ?? 0);
              if (total == 0) {
                return _buildEmptyState(l10n.translate('no_data_for_period'));
              }
              return Column(
                children: [
                  Row(
                    children: [
                      _CountCard(
                        icon: Icons.campaign_rounded,
                        label: l10n.translate('announcements'),
                        count: counts['announcements'] ?? 0,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _CountCard(
                        icon: Icons.groups_rounded,
                        label: l10n.translate('meetings'),
                        count: counts['meetings'] ?? 0,
                        color: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _CountCard(
                        icon: Icons.poll_rounded,
                        label: l10n.translate('polls'),
                        count: counts['polls'] ?? 0,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _CountCard(
                        icon: Icons.lightbulb_rounded,
                        label: l10n.translate('initiatives'),
                        count: counts['initiatives'] ?? 0,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Download button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : () => _exportReport(countyId),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(
                        _isExporting
                            ? l10n.translate('generating_report')
                            : l10n.translate('download_excel_report'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => _buildEmptyState(e.toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
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
      child: Column(
        children: [
          Icon(Icons.inbox_rounded,
              size: 48, color: context.textSecondary),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReport(String countyId) async {
    if (countyId.isEmpty) return;

    setState(() => _isExporting = true);

    try {
      final service = ref.read(_dataExportServiceProvider);
      await service.generateAndShareReport(countyId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).translate('report_downloaded')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}

class _CountCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _CountCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
