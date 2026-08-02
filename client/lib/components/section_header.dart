import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Editorial section header: a tight title, an optional hairline rule that
/// runs out to the trailing action, and an optional deck beneath.
///
/// The rule is what makes a stack of sections read as a printed page rather
/// than a list of cards.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding,
    this.showRule = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets? padding;

  /// Draws the hairline between the title and the trailing action.
  final bool showRule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasDeck = (subtitle ?? '').trim().isNotEmpty;

    return Padding(
      padding: padding ?? EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              if (showRule)
                Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: scheme.hairline,
                  ),
                )
              else
                const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          if (hasDeck) ...[
            const SizedBox(height: 5),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The "See all" affordance that pairs with [SectionHeader].
class SectionAction extends StatelessWidget {
  const SectionAction({super.key, required this.onTap, this.label = 'See all'});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
