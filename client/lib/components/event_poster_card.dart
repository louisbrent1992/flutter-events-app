import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/event.dart';
import '../theme/theme.dart';

/// Editorial event card.
///
/// Two shapes, deliberately different jobs:
///
/// * **Poster** (default / `compact`) - a full-bleed photograph with a
///   bottom-anchored scrim. Text sits on the image: an accent kicker, a
///   tight Space Grotesk title, then muted meta. Used where an event is
///   being *sold* - carousels, hero rails, featured rows.
/// * **Row** (`horizontal`) - a square thumbnail beside text on the page
///   surface. Nothing is set over the photo, so long lists stay legible
///   and scannable. Used where an event is being *listed*.
class EventPosterCard extends StatefulWidget {
  const EventPosterCard({
    super.key,
    required this.event,
    this.onTap,
    this.trailing,
    this.compact = false,
    this.horizontal = false,
    this.showShadow = true,
    this.accentColor,
  });

  final Event event;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool compact;
  final bool horizontal;
  final bool showShadow;
  final Color? accentColor;

  @override
  State<EventPosterCard> createState() => _EventPosterCardState();
}

class _EventPosterCardState extends State<EventPosterCard> {
  bool _isPressed = false;

  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  static const _weekdays = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  /// The kicker line. Prefers relative time - "TONIGHT", "TOMORROW" - because
  /// urgency is what makes someone tap.
  String _kicker(Event e) {
    final start = e.startAt;
    if (start == null) {
      return e.categories.isNotEmpty ? e.categories.first.toUpperCase() : '';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(start.year, start.month, start.day);
    final delta = day.difference(today).inDays;

    final time =
        '${start.hour.toString().padLeft(2, '0')}:'
        '${start.minute.toString().padLeft(2, '0')}';

    if (delta == 0) return 'TONIGHT · $time';
    if (delta == 1) return 'TOMORROW · $time';
    if (delta > 1 && delta < 7) {
      return '${_weekdays[start.weekday - 1]} · $time';
    }
    return '${_months[start.month - 1]} ${start.day} · $time';
  }

  String _venueLine(Event e) {
    final parts = <String>[
      if ((e.venueName ?? '').trim().isNotEmpty) e.venueName!.trim(),
      if ((e.city ?? '').trim().isNotEmpty) e.city!.trim(),
    ];
    return parts.join(' · ');
  }

  Widget _image(String? raw, {BoxFit fit = BoxFit.cover}) {
    final url = (raw ?? '').trim();
    if (url.isEmpty) return _placeholder();

    if (url.startsWith('data:')) {
      try {
        const marker = 'base64,';
        final i = url.indexOf(marker);
        if (i == -1) return _placeholder();
        return Image.memory(
          base64Decode(url.substring(i + marker.length)),
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      } catch (_) {
        return _placeholder();
      }
    }
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 220),
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  /// A quiet neutral fallback. Never a coloured gradient - a fake accent
  /// block next to real photography looks broken.
  Widget _placeholder() {
    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return ColoredBox(
          color: scheme.well,
          child: Center(
            child: Icon(
              Icons.event_rounded,
              size: 26,
              color: scheme.onSurface.withValues(alpha: 0.18),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final child =
        widget.horizontal ? _buildRow(context) : _buildPoster(context);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : 1.0,
        duration: AppAnimations.fast,
        curve: AppAnimations.defaultCurve,
        child: child,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Poster
  // -------------------------------------------------------------------------

  Widget _buildPoster(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = widget.accentColor ?? AppPalette.accentBright;
    final radius = BorderRadius.circular(AppRadii.lg);
    final height = widget.compact ? 200.0 : 260.0;

    final kicker = _kicker(widget.event);
    final venue = _venueLine(widget.event);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: widget.showShadow ? AppShadows.card(context) : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _image(widget.event.imageUrl),

              // Editorial scrim - transparent across the top third so the
              // photograph is not greyed, opaque where the text sits.
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppPalette.posterScrim),
              ),

              // Hairline inside the crop, so the plate has a defined edge
              // even against a light photograph.
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1,
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(widget.compact ? 14 : 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.event.startAt != null)
                          _dateStamp(context, accent),
                        const Spacer(),
                        if (widget.trailing != null) widget.trailing!,
                      ],
                    ),
                    const Spacer(),
                    if (kicker.isNotEmpty)
                      Text(
                        kicker,
                        style: theme.textTheme.eyebrow?.copyWith(color: accent),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      widget.event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: (widget.compact
                              ? theme.textTheme.headlineSmall
                              : theme.textTheme.headlineMedium)
                          ?.copyWith(color: Colors.white),
                    ),
                    if (venue.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              venue,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              if (_isPressed)
                ColoredBox(color: scheme.canvas.withValues(alpha: 0.12)),
            ],
          ),
        ),
      ),
    );
  }

  /// A small printed plate: month eyebrow over a large day numeral.
  Widget _dateStamp(BuildContext context, Color accent) {
    final theme = Theme.of(context);
    final date = widget.event.startAt!;

    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _months[date.month - 1],
            style: theme.textTheme.eyebrow?.copyWith(
              color: accent,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${date.day}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Row
  // -------------------------------------------------------------------------

  Widget _buildRow(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = widget.accentColor ?? scheme.accent;

    final kicker = _kicker(widget.event);
    final venue = _venueLine(widget.event);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: scheme.hairline),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: SizedBox(
              width: 78,
              height: 78,
              child: _image(widget.event.imageUrl),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (kicker.isNotEmpty)
                  Text(
                    kicker,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.eyebrow?.copyWith(color: accent),
                  ),
                const SizedBox(height: 5),
                Text(
                  widget.event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (venue.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    venue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 8),
            widget.trailing!,
          ],
        ],
      ),
    );
  }
}

/// The full-bleed hero used at the top of Home and Discover: a 16:9-ish
/// photograph with the kicker, title and a single accent action over it.
class EventHeroCard extends StatelessWidget {
  const EventHeroCard({
    super.key,
    required this.event,
    this.onTap,
    this.actionLabel = 'View event',
    this.height = 380,
  });

  final Event event;
  final VoidCallback? onTap;
  final String actionLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _HeroImage(url: event.imageUrl),
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppPalette.heroScrim),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.categories.isNotEmpty)
                    Text(
                      event.categories.first.toUpperCase(),
                      style: theme.textTheme.eyebrow?.copyWith(
                        color: AppPalette.accentBright,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    event.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(onPressed: onTap, child: Text(actionLabel)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final raw = (url ?? '').trim();
    if (raw.isEmpty || raw.startsWith('data:')) {
      return ColoredBox(color: scheme.well);
    }
    if (raw.startsWith('assets/')) {
      return Image.asset(
        raw,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ColoredBox(color: scheme.well),
      );
    }
    return CachedNetworkImage(
      imageUrl: raw,
      fit: BoxFit.cover,
      placeholder: (_, __) => ColoredBox(color: scheme.well),
      errorWidget: (_, __, ___) => ColoredBox(color: scheme.well),
    );
  }
}
