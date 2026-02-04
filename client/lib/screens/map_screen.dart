import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/custom_app_bar.dart';
import '../components/event_poster_card.dart';
import '../components/glass_surface.dart';
import '../components/pill_chip.dart';
import '../components/floating_bottom_bar.dart';
import '../models/event.dart';
import '../providers/discover_provider.dart';
import '../theme/theme.dart';

/// Map screen (stylized) inspired by the Behance mock.
///
/// Note: This is a lightweight “map-like” UI (pins + layout) without a real map SDK
/// dependency, so it works offline and without additional packages.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _search = TextEditingController();
  Event? _selected;

  final List<String> _chips = const [
    'All',
    'Theater & Stand-up',
    'Music',
    'Art',
    'Tech',
  ];
  String _chip = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final discover = context.read<DiscoverProvider>();
      if (!discover.isLoading && discover.events.isEmpty) {
        discover.load(page: 1, limit: 30);
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchesChip(Event e) {
    if (_chip == 'All') return true;
    final c = _chip.toLowerCase();
    return e.categories.any(
      (x) => x.toLowerCase().contains(c.split(' ').first),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CustomAppBar(title: 'Map'),
      body: SafeArea(
        bottom: false,
        child: Consumer<DiscoverProvider>(
          builder: (context, discover, _) {
            final events = discover.events.where(_matchesChip).toList();
            final pins = events.take(8).toList();
            _selected ??= pins.isNotEmpty ? pins.first : null;

            return Stack(
              children: [
                // "Map" background.
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.10),
                    ),
                    child: CustomPaint(
                      painter: _MapGridPainter(
                        line: scheme.onSurface.withValues(alpha: 0.05),
                        glowA: scheme.primary.withValues(alpha: 0.08),
                        glowB: scheme.secondary.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                ),

                // Top controls
                Positioned(
                  left: AppSpacing.responsive(context),
                  right: AppSpacing.responsive(context),
                  top: AppSpacing.responsive(
                    context,
                    mobile: 10,
                    tablet: 16,
                    desktop: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassSurface(
                        blurSigma: 18,
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                        padding: EdgeInsets.zero,
                        child: TextField(
                          controller: _search,
                          decoration: const InputDecoration(
                            hintText: 'Search events',
                            prefixIcon: Icon(Icons.search_rounded),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                          onSubmitted: (_) {
                            // No server-side map query for now; the UI is layout-focused.
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _chips.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final label = _chips[i];
                            return PillChip(
                              label: label,
                              selected: _chip == label && label != 'All',
                              onTap: () => setState(() => _chip = label),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Pins
                for (final p in pins)
                  _MapPin(
                    seed: p.id.hashCode ^ p.title.hashCode,
                    selected: identical(p, _selected),
                    onTap: () => setState(() => _selected = p),
                  ),

                // Bottom cards
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: 120 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: SizedBox(
                      height: 160,
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.responsive(context),
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: min(events.length, 12),
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final e = events[i];
                          return SizedBox(
                            width: 280,
                            child: Opacity(
                              opacity: identical(e, _selected) ? 1 : 0.92,
                              child: EventPosterCard(
                                event: e,
                                compact: true,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/eventDetail',
                                    arguments: e,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const FloatingBottomBar(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.seed,
    required this.selected,
    required this.onTap,
  });

  final int seed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rand = Random(seed);

    // Deterministic pseudo-random positions that keep pins away from the top controls.
    final dx = 0.12 + rand.nextDouble() * 0.76;
    final dy = 0.22 + rand.nextDouble() * 0.52;

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                left: constraints.maxWidth * dx,
                top: constraints.maxHeight * dy,
                child: GestureDetector(
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: AppAnimations.fast,
                    curve: AppAnimations.defaultCurve,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          selected
                              ? scheme.secondary
                              : scheme.onSurface.withValues(alpha: 0.12),
                      border: Border.all(
                        color:
                            selected
                                ? scheme.secondary
                                : scheme.outline.withValues(alpha: 0.22),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (selected ? scheme.secondary : scheme.primary)
                              .withValues(alpha: 0.30),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.place_rounded,
                      size: selected ? 22 : 20,
                      color:
                          selected
                              ? Colors.white
                              : scheme.onSurface.withValues(alpha: 0.80),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  _MapGridPainter({
    required this.line,
    required this.glowA,
    required this.glowB,
  });

  final Color line;
  final Color glowA;
  final Color glowB;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = line
          ..strokeWidth = 1;

    // Subtle grid.
    const step = 48.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Soft color washes.
    final a =
        Paint()
          ..shader = RadialGradient(
            colors: [glowA, Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.25, size.height * 0.35),
              radius: size.width * 0.7,
            ),
          );
    canvas.drawRect(Offset.zero & size, a);

    final b =
        Paint()
          ..shader = RadialGradient(
            colors: [glowB, Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.75, size.height * 0.55),
              radius: size.width * 0.7,
            ),
          );
    canvas.drawRect(Offset.zero & size, b);
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) {
    return oldDelegate.line != line ||
        oldDelegate.glowA != glowA ||
        oldDelegate.glowB != glowB;
  }
}
