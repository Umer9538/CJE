import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../core/services/content_moderation_service.dart';
import '../announcements/announcement_detail_screen.dart';
import '../initiatives/initiative_detail_screen.dart';

class ModerationReportsScreen extends ConsumerWidget {
  const ModerationReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    if (user == null || !user.isActive || !user.isBEXOrHigher) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.translate('access_denied'))),
      );
    }
    Query<Map<String, dynamic>> reports = FirebaseFirestore.instance.collection(
      'reports',
    );
    final county = ref.watch(effectiveCountyProvider);
    if (user.role != UserRole.superadmin || county != null) {
      reports = reports.where('countyId', isEqualTo: county ?? user.city);
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('moderation_reports'))),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: reports
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(l10n.translate('error')));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Icon(Icons.check_circle_outline, size: 48),
            );
          }
          return ListView(
            children: snapshot.data!.docs.map((document) {
              final report = document.data();
              final pending = report['status'] == 'pending';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['reason'] as String? ?? '',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${report['type']} · ${report['countyId']} · ${report['status']}',
                      ),
                      TextButton(
                        onPressed: () async {
                          try {
                            if (report['type'] == 'initiative' ||
                                report['type'] == 'initiative_comment') {
                              String? initiativeId =
                                  report['contentId'] as String?;
                              if (report['type'] == 'initiative_comment') {
                                final comment = await FirebaseFirestore.instance
                                    .collection('initiative_comments')
                                    .doc(initiativeId)
                                    .get();
                                initiativeId =
                                    comment.data()?['initiativeId'] as String?;
                              }
                              if (initiativeId == null) return;
                              final initiative = await InitiativeRepository()
                                  .getInitiativeById(initiativeId);
                              if (context.mounted && initiative != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => InitiativeDetailScreen(
                                      initiative: initiative,
                                    ),
                                  ),
                                );
                              }
                              return;
                            }
                            final content = await AnnouncementRepository()
                                .getAnnouncementById(
                                  report['contentId'] as String,
                                );
                            if (context.mounted && content != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => AnnouncementDetailScreen(
                                    announcement: content,
                                  ),
                                ),
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.translate('error')),
                                ),
                              );
                            }
                          }
                        },
                        child: Text(l10n.translate('view')),
                      ),
                      if (pending)
                        Wrap(
                          children: [
                            TextButton(
                              onPressed: () => _resolve(
                                context,
                                document.id,
                                user.id,
                                false,
                              ),
                              child: Text(l10n.translate('mark_reviewed')),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _resolve(context, document.id, user.id, true),
                              child: Text(l10n.translate('dismiss_report')),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _resolve(
    BuildContext context,
    String id,
    String moderatorId,
    bool dismissed,
  ) async {
    try {
      await ContentModerationService().resolveReport(
        id,
        moderatorId,
        dismissed: dismissed,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('report_failed'),
            ),
          ),
        );
      }
    }
  }
}
