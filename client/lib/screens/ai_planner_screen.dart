import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:eventease/components/custom_app_bar.dart';
import 'package:eventease/providers/event_provider.dart';
import 'package:eventease/providers/subscription_provider.dart';
import 'package:eventease/services/credits_service.dart';
import 'package:eventease/services/event_ai_service.dart';
import 'package:eventease/theme/theme.dart';
import 'package:eventease/providers/generated_plan_provider.dart';
import 'package:eventease/components/glass_surface.dart';
import 'package:eventease/components/section_header.dart';
import 'package:eventease/components/pill_chip.dart';
import 'package:eventease/components/floating_bottom_bar.dart';
import '../models/event.dart';
import '../utils/loading_dialog_helper.dart';
import '../utils/snackbar_helper.dart';

class AiPlannerScreen extends StatefulWidget {
  const AiPlannerScreen({super.key});

  @override
  State<AiPlannerScreen> createState() => _AiPlannerScreenState();
}

class _AiPlannerScreenState extends State<AiPlannerScreen> {
  final _vibe = TextEditingController();
  final _budget = TextEditingController();
  final _location = TextEditingController();
  final _dates = TextEditingController();
  final _constraints = TextEditingController();

  Map<String, dynamic>? _plan;
  List<dynamic> _itinerary = const [];

  @override
  void dispose() {
    _vibe.dispose();
    _budget.dispose();
    _location.dispose();
    _dates.dispose();
    _constraints.dispose();
    super.dispose();
  }

  Future<bool> _ensureCredits(BuildContext context) async {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    try {
      await subscriptionProvider.refreshData();
    } catch (_) {}
    final ok = await subscriptionProvider.hasEnoughCredits(CreditType.aiPlan);
    if (!ok && context.mounted) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Insufficient Credits'),
              content: const Text(
                'You don\'t have enough credits to generate plans. Please purchase credits or subscribe.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/subscription');
                  },
                  child: const Text('Get Credits'),
                ),
              ],
            ),
      );
    }
    return ok;
  }

  Future<void> _generatePlan() async {
    if (!await _ensureCredits(context)) return;

    try {
      if (mounted) {
        LoadingDialogHelper.show(context, message: 'Planning…');
      }

      final resp = await EventAiService.planItinerary(
        vibe: _vibe.text.trim().isEmpty ? null : _vibe.text.trim(),
        budget: _budget.text.trim().isEmpty ? null : _budget.text.trim(),
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        dates: _dates.text.trim().isEmpty ? null : _dates.text.trim(),
        constraints:
            _constraints.text.trim().isEmpty ? null : _constraints.text.trim(),
      );

      if (mounted) LoadingDialogHelper.dismiss(context);
      if (!mounted) return;

      if (resp.success && resp.data != null) {
        setState(() {
          _plan = resp.data;
          _itinerary = (resp.data!['itinerary'] as List?) ?? const [];
        });

        // Persist to history (best-effort)
        try {
          final input = <String, dynamic>{
            'vibe': _vibe.text.trim(),
            'budget': _budget.text.trim(),
            'location': _location.text.trim(),
            'dates': _dates.text.trim(),
            'constraints': _constraints.text.trim(),
          };
          await context.read<GeneratedPlanProvider>().savePlan(
            input: input,
            output: Map<String, dynamic>.from(resp.data!),
            title: (resp.data!['title'] ?? 'AI Plan').toString(),
          );
        } catch (_) {}

        // Deduct credits (best-effort)
        if (!mounted) return;
        try {
          await context.read<SubscriptionProvider>().useCredits(
            CreditType.aiPlan,
            reason: 'AI planner',
          );
        } catch (_) {}
      } else {
        SnackBarHelper.showError(context, resp.userFriendlyMessage);
      }
    } catch (e) {
      if (mounted) {
        LoadingDialogHelper.dismiss(context);
        SnackBarHelper.showError(context, 'Failed to generate plan: $e');
      }
    }
  }

  DateTime? _parseDt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString();
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  String? _formatRecapDate(dynamic v) {
    final dt = _parseDt(v);
    if (dt == null) return null;
    return DateFormat('h:mm a').format(dt);
  }

  Future<void> _saveAsEvents() async {
    if (_itinerary.isEmpty) return;
    final provider = context.read<EventProvider>();

    int created = 0;
    for (final raw in _itinerary) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: 'Planner',
        fullTitle: 'AI Event Planner',
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
                case 'generate':
                  await _generatePlan();
                  break;
                case 'history':
                  if (!mounted) return;
                  Navigator.pushNamed(context, '/generated');
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem<String>(
                    value: 'generate',
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text('Generate'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text('History'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: ListView(
                padding: EdgeInsets.only(
                  left: AppSpacing.responsive(context),
                  right: AppSpacing.responsive(context),
                  top: AppSpacing.responsive(
                    context,
                    mobile: 10,
                    tablet: 16,
                    desktop: 18,
                  ),
                  bottom: 140,
                ),
                children: [
                  Text(
                    'Tell us what you want and we’ll draft a schedule you can save.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.78,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const SectionHeader(
                    title: 'Inputs',
                    subtitle: 'The more specific you are, the better the plan.',
                  ),
                  GlassSurface(
                    blurSigma: 18,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _vibe,
                          decoration: const InputDecoration(
                            labelText: 'Vibe',
                            hintText: 'e.g. chill, energetic, artsy, classy…',
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              PillChip(
                                label: 'Chill',
                                selected: _vibe.text.toLowerCase().contains(
                                  'chill',
                                ),
                                onTap:
                                    () => setState(() => _vibe.text = 'Chill'),
                              ),
                              const SizedBox(width: 10),
                              PillChip(
                                label: 'Energetic',
                                selected: _vibe.text.toLowerCase().contains(
                                  'energetic',
                                ),
                                onTap:
                                    () => setState(
                                      () => _vibe.text = 'Energetic',
                                    ),
                              ),
                              const SizedBox(width: 10),
                              PillChip(
                                label: 'Artsy',
                                selected: _vibe.text.toLowerCase().contains(
                                  'artsy',
                                ),
                                onTap:
                                    () => setState(() => _vibe.text = 'Artsy'),
                              ),
                              const SizedBox(width: 10),
                              PillChip(
                                label: 'Date night',
                                selected: _vibe.text.toLowerCase().contains(
                                  'date',
                                ),
                                onTap:
                                    () => setState(
                                      () => _vibe.text = 'Date night',
                                    ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _budget,
                          decoration: const InputDecoration(
                            labelText: 'Budget',
                            hintText: 'e.g. under \$75, free, mid-range…',
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _location,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            hintText: 'e.g. Downtown Austin, East London…',
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _dates,
                          decoration: const InputDecoration(
                            labelText: 'Dates',
                            hintText: 'e.g. Sat evening, or Dec 21–22',
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _constraints,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Constraints (optional)',
                            hintText:
                                'e.g. no alcohol, wheelchair accessible, near subway…',
                          ),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _generatePlan,
                            icon: const Icon(Icons.auto_awesome_rounded),
                            label: const Text('Generate itinerary'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_plan != null) ...[
                    SizedBox(height: AppSpacing.xl),
                    const SectionHeader(
                      title: 'Result',
                      subtitle: 'Review the itinerary, then save it as events.',
                    ),
                    GlassSurface(
                      blurSigma: 18,
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_plan!['title'] ?? 'Your plan').toString(),
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          if (_itinerary.isEmpty)
                            Text(
                              'No itinerary items returned. Try again with more details.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.78,
                                ),
                              ),
                            )
                          else
                            Column(
                              children: [
                                for (final raw in _itinerary)
                                  if (raw is Map)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom: AppSpacing.sm,
                                      ),
                                      child: GlassSurface(
                                        blurSigma: 12,
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.lg,
                                        ),
                                        tintColor: theme.colorScheme.surface,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              size: 10,
                                              color:
                                                  theme.colorScheme.secondary,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    (raw['title'] ?? 'Event')
                                                        .toString(),
                                                    style:
                                                        theme
                                                            .textTheme
                                                            .titleMedium,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    [
                                                          _formatRecapDate(
                                                                raw['startAt'],
                                                              ) ??
                                                              raw['startAt']
                                                                  ?.toString(),
                                                          raw['venueName']
                                                              ?.toString(),
                                                        ]
                                                        .where(
                                                          (s) =>
                                                              s != null &&
                                                              s
                                                                  .toString()
                                                                  .trim()
                                                                  .isNotEmpty,
                                                        )
                                                        .join(' • '),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.75,
                                                              ),
                                                        ),
                                                  ),
                                                  if ((raw['notes'] ?? '')
                                                      .toString()
                                                      .trim()
                                                      .isNotEmpty) ...[
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      (raw['notes'] ?? '')
                                                          .toString(),
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: theme
                                                                .colorScheme
                                                                .onSurface
                                                                .withValues(
                                                                  alpha: 0.80,
                                                                ),
                                                          ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            onPressed: _saveAsEvents,
                            icon: const Icon(Icons.save_alt_rounded),
                            label: const Text('Save itinerary as events'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const FloatingBottomBar(),
        ],
      ),
    );
  }
}
