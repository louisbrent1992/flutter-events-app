import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/event.dart';
import '../theme/theme.dart';

/// Premium event card with immersive visual effects.
///
/// Features:
/// - Parallax-ready image with smooth loading
/// - Gradient overlay with depth
/// - Category pills with accent colors
/// - Subtle hover/press animations
/// - Date badge with glassmorphism
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

class _EventPosterCardState extends State<EventPosterCard>
    with SingleTickerProviderStateMixin {
  // ... existing state methods ...
  bool _isPressed = false;

  String _subtitle(Event e) {
    // ...
    final parts = <String>[];
    if (e.startAt != null) {
      parts.add(_formatDate(e.startAt!));
    }
    if ((e.venueName ?? '').trim().isNotEmpty) parts.add(e.venueName!.trim());
    if ((e.city ?? '').trim().isNotEmpty) parts.add(e.city!.trim());
    return parts.join(' • ');
  }

  String _formatDate(DateTime dt) {
    // ...
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  Color _getCategoryColor(String category) {
    // ...
    final c = category.toLowerCase();
    if (c.contains('music') || c.contains('concert')) {
      return AppPalette.primaryBlue;
    }
    if (c.contains('night') || c.contains('party')) return AppPalette.slate;
    if (c.contains('art') || c.contains('gallery')) return AppPalette.emerald;
    if (c.contains('tech') || c.contains('startup')) {
      return AppPalette.accentBlue;
    }
    if (c.contains('sport') || c.contains('fitness')) return AppPalette.amber;
    if (c.contains('food') || c.contains('culinary')) {
      return AppPalette.warmGray;
    }
    return AppPalette.accentBlue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasImage = (widget.event.imageUrl ?? '').trim().isNotEmpty;
    final subtitle = _subtitle(widget.event);
    final accentColor =
        widget.accentColor ??
        (widget.event.categories.isNotEmpty
            ? _getCategoryColor(widget.event.categories.first)
            : scheme.primary);

    final radius = BorderRadius.circular(AppRadii.xl);

    // Choose height based on layout mode
    final height = widget.horizontal ? 110.0 : (widget.compact ? 200.0 : 250.0);

    Widget imageLayer;
    if (hasImage) {
      final url = widget.event.imageUrl!.trim();
      if (url.startsWith('data:')) {
        try {
          const base64Prefix = 'base64,';
          final index = url.indexOf(base64Prefix);
          if (index != -1) {
            final bytes = base64Decode(
              url.substring(index + base64Prefix.length),
            );
            imageLayer = Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(accentColor),
            );
          } else {
            imageLayer = _buildPlaceholder(accentColor);
          }
        } catch (_) {
          imageLayer = _buildPlaceholder(accentColor);
        }
      } else if (url.startsWith('assets/')) {
        imageLayer = Image.asset(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(accentColor),
        );
      } else {
        imageLayer = CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (context, _) => _buildPlaceholder(accentColor),
          errorWidget: (context, _, __) => _buildPlaceholder(accentColor),
        );
      }
    } else {
      imageLayer = _buildPlaceholder(accentColor);
    }

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.defaultCurve,
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow:
                widget.showShadow
                    ? [
                      BoxShadow(
                        color: accentColor.withValues(
                          alpha: _isPressed ? 0.25 : 0.15,
                        ),
                        blurRadius: _isPressed ? 24 : 16,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: SizedBox(
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image layer
                  imageLayer,

                  // Premium gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.5),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        stops: const [0.0, 0.4, 0.65, 1.0],
                      ),
                    ),
                  ),

                  // Accent glow at top (hidden in horizontal mode to reduce noise)
                  if (!widget.horizontal)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 60,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              accentColor.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Content
                  Padding(
                    padding: EdgeInsets.all(
                      widget.horizontal ? 12 : (widget.compact ? 12 : 16),
                    ),
                    child:
                        widget.horizontal
                            ? _buildHorizontalContent(
                              context,
                              subtitle,
                              accentColor,
                            )
                            : (widget.compact
                                ? _buildCompactContent(
                                  context,
                                  subtitle,
                                  accentColor,
                                )
                                : _buildExpandedContent(
                                  context,
                                  subtitle,
                                  accentColor,
                                )),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalContent(
    BuildContext context,
    String subtitle,
    Color accentColor,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        // Date Badge
        if (widget.event.startAt != null)
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getMonthAbbr(widget.event.startAt!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
                Text(
                  '${widget.event.startAt!.day}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(width: 16),

        // Text Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.event.categories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    widget.event.categories.first.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontSize: 10,
                    ),
                  ),
                ),
              Text(
                widget.event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              if (subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          widget.event.venueName ?? widget.event.city ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        if (widget.trailing != null) ...[
          const SizedBox(width: 12),
          widget.trailing!,
        ],
      ],
    );
  }

  Widget _buildPlaceholder(Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.4),
            accentColor.withValues(alpha: 0.2),
            AppPalette.darkSurface.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event_rounded,
          size: 32,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildCompactContent(
    BuildContext context,
    String subtitle,
    Color accentColor,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date badge for compact
            if (widget.event.startAt != null)
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getMonthAbbr(widget.event.startAt!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '${widget.event.startAt!.day}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
        const Spacer(),
        // Event info
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.event.categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.event.categories.first.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    fontSize: 10,
                  ),
                ),
              ),
            Text(
              widget.event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            if (subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        widget.event.venueName ?? widget.event.city ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    String subtitle,
    Color accentColor,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category badges
        if (widget.event.categories.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final c in widget.event.categories.take(2))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(c).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    boxShadow: [
                      BoxShadow(
                        color: _getCategoryColor(c).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    c,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        const Spacer(),
        // Date badge
        if (widget.event.startAt != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: accentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(widget.event.startAt!),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        // Title
        Text(
          widget.event.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Subtitle with location
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  if ((widget.event.venueName ?? widget.event.city ?? '')
                      .isNotEmpty) ...[
                    Icon(
                      Icons.location_on_rounded,
                      size: 15,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtitle.isEmpty ? 'Tap to view details' : subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ] else
                    Text(
                      'Tap to view details',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 8),
              widget.trailing!,
            ],
          ],
        ),
      ],
    );
  }

  String _getMonthAbbr(DateTime dt) {
    const months = [
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
    return months[dt.month - 1];
  }
}
