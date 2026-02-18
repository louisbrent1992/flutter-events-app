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
        imageUrl: 'assets/images/generic_event_placeholder.png',
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
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final pad = AppSpacing.responsive(context);

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
            color: scheme.surface.withValues(alpha: scheme.alphaVeryHigh),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: scheme.outline.withValues(alpha: scheme.overlayLight),
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
                          color: scheme.primary,
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
                          color: scheme.primary,
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
                  left: pad,
                  right: pad,
                  top: AppSpacing.responsive(
                    context,
                    mobile: 10,
                    tablet: 16,
                    desktop: 18,
                  ),
                  bottom: 140,
                ),
                children: [
                  // ── Hero banner ─────────────────────────────
                  _buildHeroBanner(theme, scheme, isDark),
                  SizedBox(height: AppSpacing.xl),

                  // ── Vibe section ────────────────────────────
                  const SectionHeader(
                    title: "What's the vibe?",
                    subtitle: 'Pick a mood or type your own.',
                  ),
                  _buildVibeSection(theme, scheme, isDark),
                  SizedBox(height: AppSpacing.lg),

                  // ── Details section ─────────────────────────
                  const SectionHeader(
                    title: 'Details',
                    subtitle: 'The more you share, the better the itinerary.',
                  ),
                  _buildDetailsSection(theme, scheme, isDark),
                  SizedBox(height: AppSpacing.lg),

                  // ── Generate CTA ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _generatePlan,
                      icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                      label: const Text('Generate itinerary'),
                      style: FilledButton.styleFrom(
                        textStyle: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  // ── Results ─────────────────────────────────
                  if (_plan != null) ...[
                    SizedBox(height: AppSpacing.xl),
                    _buildResultSection(theme, scheme, isDark),
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

  // ── Hero banner ─────────────────────────────────────────────────────────────
  Widget _buildHeroBanner(ThemeData theme, ColorScheme scheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: isDark ? 0.20 : 0.10),
            scheme.tertiary.withValues(alpha: isDark ? 0.12 : 0.06),
          ],
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: isDark ? 0.20 : 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: isDark ? 0.25 : 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 28,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan your perfect outing',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Tell us what you're in the mood for and AI will draft a schedule you can save as events.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.70),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Vibe section ────────────────────────────────────────────────────────────
  Widget _buildVibeSection(ThemeData theme, ColorScheme scheme, bool isDark) {
    final vibes = [
      ('Chill', Icons.spa_rounded),
      ('Energetic', Icons.bolt_rounded),
      ('Artsy', Icons.palette_rounded),
      ('Date night', Icons.favorite_rounded),
      ('Family', Icons.family_restroom_rounded),
      ('Outdoor', Icons.park_rounded),
    ];

    return GlassSurface(
      blurSigma: 18,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, icon) in vibes)
                PillChip(
                  label: label,
                  icon: icon,
                  selected: _vibe.text.toLowerCase().contains(
                    label.toLowerCase(),
                  ),
                  onTap: () => setState(() => _vibe.text = label),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          TextField(
            controller: _vibe,
            decoration: InputDecoration(
              labelText: 'Or describe your vibe',
              hintText: 'e.g. classy brunch, weekend adventure…',
              prefixIcon: Icon(
                Icons.mood_rounded,
                color: scheme.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Details section ─────────────────────────────────────────────────────────
  Widget _buildDetailsSection(
    ThemeData theme,
    ColorScheme scheme,
    bool isDark,
  ) {
    return GlassSurface(
      blurSigma: 18,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _location,
            decoration: InputDecoration(
              labelText: 'Location',
              hintText: 'e.g. Downtown Austin, East London…',
              prefixIcon: Icon(
                Icons.location_on_rounded,
                color: AppPalette.emerald.withValues(alpha: 0.8),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          TextField(
            controller: _dates,
            decoration: InputDecoration(
              labelText: 'When',
              hintText: 'e.g. Saturday evening, Dec 21–22',
              prefixIcon: Icon(
                Icons.calendar_today_rounded,
                color: AppPalette.accentBlue.withValues(alpha: 0.8),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          TextField(
            controller: _budget,
            decoration: InputDecoration(
              labelText: 'Budget',
              hintText: 'e.g. under \$75, free, mid-range…',
              prefixIcon: Icon(
                Icons.attach_money_rounded,
                color: AppPalette.amber.withValues(alpha: 0.8),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          TextField(
            controller: _constraints,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Constraints (optional)',
              hintText: 'e.g. no alcohol, wheelchair accessible, near subway…',
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Icon(
                  Icons.tune_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Result section ──────────────────────────────────────────────────────────
  Widget _buildResultSection(ThemeData theme, ColorScheme scheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Your Itinerary',
          subtitle: 'Review the plan, then save it as events.',
        ),

        // Plan title card
        GlassSurface(
          blurSigma: 18,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_note_rounded,
                  size: 22,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  (_plan!['title'] ?? 'Your plan').toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: AppSpacing.sm),

        if (_itinerary.isEmpty)
          GlassSurface(
            blurSigma: 14,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No itinerary items returned. Try again with more details.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.70),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          // Timeline items
          for (int i = 0; i < _itinerary.length; i++)
            if (_itinerary[i] is Map)
              _buildTimelineItem(
                theme,
                scheme,
                isDark,
                _itinerary[i] as Map,
                index: i,
                isLast: i == _itinerary.length - 1,
              ),

        SizedBox(height: AppSpacing.md),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _saveAsEvents,
                icon: const Icon(Icons.save_alt_rounded, size: 18),
                label: const Text('Save as events'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _generatePlan,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Regenerate'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Individual timeline item ────────────────────────────────────────────────
  Widget _buildTimelineItem(
    ThemeData theme,
    ColorScheme scheme,
    bool isDark,
    Map raw, {
    required int index,
    required bool isLast,
  }) {
    final timeStr =
        _formatRecapDate(raw['startAt']) ?? raw['startAt']?.toString() ?? '';
    final venue = raw['venueName']?.toString() ?? '';
    final notes = (raw['notes'] ?? '').toString().trim();
    final subtitle = [timeStr, venue].where((s) => s.isNotEmpty).join(' • ');

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xs),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline rail
            SizedBox(
              width: 36,
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(
                        alpha: isDark ? 0.22 : 0.12,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: scheme.outline.withValues(
                          alpha: isDark ? 0.15 : 0.10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Content card
            Expanded(
              child: GlassSurface(
                blurSigma: 12,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                tintColor: scheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (raw['title'] ?? 'Event').toString(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (timeStr.isNotEmpty)
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: scheme.primary.withValues(alpha: 0.7),
                            ),
                          if (timeStr.isNotEmpty) const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        notes,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.75),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
