import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/custom_app_bar.dart';
import '../components/error_display.dart';
import '../models/event.dart';
import '../models/generated_plan.dart';
import '../providers/event_provider.dart';
import '../providers/generated_plan_provider.dart';
import '../services/event_ai_service.dart';
import '../theme/theme.dart';
import '../utils/loading_dialog_helper.dart';
import '../utils/snackbar_helper.dart';

class GeneratedPlanDetailScreen extends StatefulWidget {
  const GeneratedPlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  State<GeneratedPlanDetailScreen> createState() =>
      _GeneratedPlanDetailScreenState();
}

class _GeneratedPlanDetailScreenState extends State<GeneratedPlanDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GeneratedPlanProvider>().loadPlan(widget.planId);
    });
  }

  DateTime? _parseDt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  List<dynamic> _itinerary(GeneratedPlan p) {
    final it = p.output['itinerary'];
    return it is List ? it : const [];
  }

  Future<void> _saveAsEvents(GeneratedPlan plan) async {
    final itinerary = _itinerary(plan);
    if (itinerary.isEmpty) return;
    final provider = context.read<EventProvider>();

    int created = 0;
    for (final raw in itinerary) {
      if (raw is! Map) continue;
      final m = raw.cast<String, dynamic>();
      final e = Event(
        title: (m['title'] ?? 'Planned Event').toString(),
        description: (m['notes'] ?? '').toString(),
        startAt: _parseDt(m['startAt']),
        endAt: _parseDt(m['endAt']),
        venueName: m['venueName']?.toString(),
        address: m['address']?.toString(),
        categories:
            (m['categories'] is List)
                ? (m['categories'] as List)
                    .map((x) => x.toString())
                    .where((s) => s.trim().isNotEmpty)
                    .toList()
                : const [],
        sourcePlatform: 'ai_planner',
      );

      final saved = await provider.createEvent(e, context);
      if (saved != null) created++;
    }

    if (!mounted) return;
    if (created > 0) {
      SnackBarHelper.showSuccess(context, 'Saved $created events');
      Navigator.pushNamed(context, '/myEvents');
    } else {
      SnackBarHelper.showError(context, 'No events were saved');
    }
  }

  Future<void> _regenerate(GeneratedPlan plan) async {
    final input = plan.input;
    try {
      LoadingDialogHelper.show(context, message: 'Regenerating…');
      final resp = await EventAiService.planItinerary(
        vibe:
            (input['vibe'] as String?)?.trim().isEmpty == true
                ? null
                : input['vibe'] as String?,
        budget:
            (input['budget'] as String?)?.trim().isEmpty == true
                ? null
                : input['budget'] as String?,
        location:
            (input['location'] as String?)?.trim().isEmpty == true
                ? null
                : input['location'] as String?,
        dates:
            (input['dates'] as String?)?.trim().isEmpty == true
                ? null
                : input['dates'] as String?,
        constraints:
            (input['constraints'] as String?)?.trim().isEmpty == true
                ? null
                : input['constraints'] as String?,
      );
      if (!mounted) return;
      LoadingDialogHelper.dismiss(context);

      if (resp.success && resp.data != null) {
        final saved = await context.read<GeneratedPlanProvider>().savePlan(
          input: Map<String, dynamic>.from(input),
          output: Map<String, dynamic>.from(resp.data!),
          title: (resp.data!['title'] ?? 'AI Plan').toString(),
        );

        if (!mounted) return;
        if (saved != null) {
          SnackBarHelper.showSuccess(context, 'Saved new plan.');
          Navigator.pushReplacementNamed(
            context,
            '/generatedDetail',
            arguments: {'planId': saved.id},
          );
        } else {
          SnackBarHelper.showSuccess(context, 'Regenerated.');
        }
      } else {
        SnackBarHelper.showError(context, resp.userFriendlyMessage);
      }
    } catch (e) {
      if (!mounted) return;
      LoadingDialogHelper.dismiss(context);
      SnackBarHelper.showError(context, 'Failed to regenerate: $e');
    }
  }

  Future<void> _deletePlan(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete plan?'),
            content: const Text('This will remove it from your history.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (ok == true) {
      await context.read<GeneratedPlanProvider>().deletePlan(id);
      if (!mounted) return;
      SnackBarHelper.showInfo(context, 'Deleted.');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: 'Plan',
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: Icon(
              Icons.more_vert,
              size: AppSizing.responsiveIconSize(
                context,
                mobile: 24,
                tablet: 28,
                desktop: 30,
              ),
            ),
            color: Theme.of(context).colorScheme.surface.withValues(
              alpha: Theme.of(context).colorScheme.alphaVeryHigh,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(
                  alpha: Theme.of(context).colorScheme.overlayLight,
                ),
                width: 1,
              ),
            ),
            onSelected: (value) async {
              switch (value) {
                case 'delete':
                  final p = context.read<GeneratedPlanProvider>().active;
                  if (p != null) await _deletePlan(p.id);
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.responsive(context)),
        child: Consumer<GeneratedPlanProvider>(
          builder: (context, provider, _) {
            final error = provider.error;
            final plan = provider.active;

            if (provider.isLoading && plan == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (error != null && plan == null) {
              return ErrorDisplay(
                message: error.userFriendlyMessage,
                onRetry: () => provider.loadPlan(widget.planId),
              );
            }
            if (plan == null) {
              return const Center(child: Text('Plan not found.'));
            }

            final itinerary = _itinerary(plan);

            return ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                Text(
                  plan.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inputs',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        _kv('Vibe', plan.input['vibe']),
                        _kv('Budget', plan.input['budget']),
                        _kv('Location', plan.input['location']),
                        _kv('Dates', plan.input['dates']),
                        _kv('Constraints', plan.input['constraints']),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => _regenerate(plan),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Regenerate'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed:
                          itinerary.isEmpty ? null : () => _saveAsEvents(plan),
                      icon: const Icon(Icons.save_alt_rounded),
                      label: const Text('Save as events'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Itinerary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                if (itinerary.isEmpty)
                  const Text('No itinerary items returned.'),
                for (final raw in itinerary)
                  if (raw is Map)
                    Card(
                      margin: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        title: Text((raw['title'] ?? 'Event').toString()),
                        subtitle: Text(
                          [
                                raw['startAt']?.toString(),
                                raw['venueName']?.toString(),
                              ]
                              .where(
                                (s) =>
                                    s != null && s.toString().trim().isNotEmpty,
                              )
                              .join(' • '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _kv(String k, dynamic v) {
    final s = (v ?? '').toString().trim();
    if (s.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$k: $s'),
    );
  }
}
