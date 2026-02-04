import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:eventease/providers/event_provider.dart';
import 'package:eventease/services/notification_scheduler.dart';
import 'package:eventease/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eventease/components/glass_surface.dart';
import 'package:eventease/components/html_description.dart';
import 'package:eventease/models/event.dart';
import 'package:eventease/providers/auth_provider.dart';
import '../utils/snackbar_helper.dart';

/// Premium immersive event detail screen.
///
/// Features:
/// - Full-bleed hero image with parallax scroll effect
/// - Floating action buttons with glass morphism
/// - Gradient category badges
/// - Interactive venue map preview
/// - Share and save actions with haptic feedback
/// - Collapsing app bar with blur
class EventDetailScreen extends StatefulWidget {
  final Event event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  double _scrollOffset = 0;
  bool _isSaved = false;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _scrollController =
        ScrollController()..addListener(() {
          setState(() => _scrollOffset = _scrollController.offset);
        });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfSaved();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _checkIfSaved() {
    final provider = context.read<EventProvider>();
    final saved = provider.userEvents.any((e) => e.id == widget.event.id);
    setState(() => _isSaved = saved);
  }

  Color _getCategoryColor(String category) {
    final c = category.toLowerCase();
    if (c.contains('music') || c.contains('concert'))
      return AppPalette.primaryBlue;
    if (c.contains('night') || c.contains('party')) return AppPalette.slate;
    if (c.contains('art') || c.contains('gallery')) return AppPalette.emerald;
    if (c.contains('tech') || c.contains('startup'))
      return AppPalette.accentBlue;
    if (c.contains('sport') || c.contains('fitness')) return AppPalette.amber;
    if (c.contains('food') || c.contains('culinary'))
      return AppPalette.warmGray;
    return AppPalette.accentBlue;
  }

  Future<void> _toggleSave() async {
    final isAuthed = context.read<AuthService>().user != null;
    if (!isAuthed) {
      SnackBarHelper.showInfo(context, 'Sign in to save events.');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final provider = context.read<EventProvider>();
      if (_isSaved) {
        await provider.deleteEvent(widget.event.id, context);
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Event removed from calendar');
      } else {
        await provider.createEvent(widget.event, context);
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Event saved to calendar');

        // Offer to set reminder
        _showReminderPrompt();
      }
      setState(() => _isSaved = !_isSaved);
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Could not update event. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showReminderPrompt() {
    if (widget.event.startAt == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildReminderSheet(context),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Could not open link.');
    }
  }

  Future<void> _share() async {
    HapticFeedback.lightImpact();
    // Construct share text
    final buffer = StringBuffer();
    buffer.writeln(widget.event.title);
    if (widget.event.startAt != null) {
      buffer.writeln(_formatDate(widget.event.startAt!));
    }
    if ((widget.event.venueName ?? '').isNotEmpty) {
      buffer.writeln(widget.event.venueName);
    }
    if ((widget.event.ticketUrl ?? '').isNotEmpty) {
      buffer.writeln(widget.event.ticketUrl);
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    SnackBarHelper.showSuccess(context, 'Event details copied to clipboard');
  }

  String _formatDate(DateTime dt) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day} at $hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.45;
    final hasImage = (widget.event.imageUrl ?? '').trim().isNotEmpty;
    final accentColor =
        widget.event.categories.isNotEmpty
            ? _getCategoryColor(widget.event.categories.first)
            : scheme.primary;

    // Calculate app bar opacity based on scroll
    final appBarOpacity = (_scrollOffset / (heroHeight - 100)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: isDark ? AppPalette.darkBg : AppPalette.lightBg,
      extendBodyBehindAppBar: true,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // Main content
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Hero Image
                SliverToBoxAdapter(
                  child: _buildHeroImage(
                    context,
                    heroHeight: heroHeight,
                    hasImage: hasImage,
                    accentColor: accentColor,
                  ),
                ),
                // Content
                SliverToBoxAdapter(child: _buildContent(context, accentColor)),
                // Bottom padding
                SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),

            // Custom App Bar
            _buildAppBar(context, appBarOpacity, accentColor),

            // Floating Action Buttons
            _buildFloatingActions(context, accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage(
    BuildContext context, {
    required double heroHeight,
    required bool hasImage,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Parallax effect
    final parallaxOffset = _scrollOffset * 0.4;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image with parallax
          Transform.translate(
            offset: Offset(0, parallaxOffset),
            child:
                hasImage
                    ? CachedNetworkImage(
                      imageUrl: widget.event.imageUrl!.trim(),
                      fit: BoxFit.cover,
                      placeholder:
                          (_, __) => _buildImagePlaceholder(accentColor),
                      errorWidget:
                          (_, __, ___) => _buildImagePlaceholder(accentColor),
                    )
                    : _buildImagePlaceholder(accentColor),
          ),

          // Gradient overlays
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.transparent,
                  (isDark ? AppPalette.darkBg : AppPalette.lightBg).withValues(
                    alpha: 0.8,
                  ),
                  isDark ? AppPalette.darkBg : AppPalette.lightBg,
                ],
                stops: const [0.0, 0.2, 0.5, 0.85, 1.0],
              ),
            ),
          ),

          // Accent color glow at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    accentColor.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Category badges on image
          if (widget.event.categories.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 20,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    widget.event.categories.take(3).map((cat) {
                      final color = _getCategoryColor(cat);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.8)],
                          ),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          cat,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.5),
            accentColor.withValues(alpha: 0.25),
            AppPalette.darkSurface.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event_rounded,
          size: 80,
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, double opacity, Color accentColor) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: topPadding + 8,
          left: 12,
          right: 12,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          color: (isDark ? AppPalette.darkBg : AppPalette.lightBg).withValues(
            alpha: opacity * 0.95,
          ),
          border:
              opacity > 0.5
                  ? Border(
                    bottom: BorderSide(
                      color: scheme.outline.withValues(alpha: 0.1),
                    ),
                  )
                  : null,
        ),
        child: Row(
          children: [
            // Back button
            GlassSurface(
              blurSigma: opacity < 0.5 ? 16 : 0,
              borderRadius: BorderRadius.circular(AppRadii.full),
              padding: EdgeInsets.zero,
              tintColor:
                  opacity < 0.5
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.transparent,
              borderColor: Colors.transparent,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: opacity < 0.5 ? Colors.white : scheme.onSurface,
                ),
              ),
            ),

            const Spacer(),

            // Title (appears on scroll)
            AnimatedOpacity(
              duration: AppAnimations.fast,
              opacity: opacity > 0.7 ? 1.0 : 0.0,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: Text(
                  widget.event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Share button
            GlassSurface(
              blurSigma: opacity < 0.5 ? 16 : 0,
              borderRadius: BorderRadius.circular(AppRadii.full),
              padding: EdgeInsets.zero,
              tintColor:
                  opacity < 0.5
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.transparent,
              borderColor: Colors.transparent,
              child: IconButton(
                onPressed: _share,
                icon: Icon(
                  Icons.share_rounded,
                  color: opacity < 0.5 ? Colors.white : scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color accentColor) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.responsive(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date badge
          if (widget.event.startAt != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(widget.event.startAt!),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Title
          Text(
            widget.event.title,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),

          // Quick info cards
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  context,
                  icon: Icons.location_on_rounded,
                  label: 'Venue',
                  value: widget.event.venueName ?? widget.event.city ?? 'TBA',
                  color: AppPalette.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  context,
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value:
                      widget.event.startAt != null
                          ? _formatTime(widget.event.startAt!)
                          : 'TBA',
                  color: AppPalette.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // About section
          Text(
            'About',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GlassSurface(
            blurSigma: 16,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child:
                widget.event.description.contains('<')
                    ? HtmlDescription(htmlContent: widget.event.description)
                    : Text(
                      widget.event.description.isEmpty
                          ? 'No description available.'
                          : widget.event.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.85),
                        height: 1.6,
                      ),
                    ),
          ),
          const SizedBox(height: 28),

          // Location section
          if ((widget.event.address ?? widget.event.venueName ?? '')
              .isNotEmpty) ...[
            Text(
              'Location',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            GlassSurface(
              blurSigma: 16,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              enableGlow: true,
              glowColor: AppPalette.accentBlue,
              glowIntensity: 0.1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppPalette.accentBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: AppPalette.accentBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((widget.event.venueName ?? '').isNotEmpty)
                              Text(
                                widget.event.venueName!,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if ((widget.event.address ?? '').isNotEmpty)
                              Text(
                                widget.event.address!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            Text(
                              [
                                widget.event.city,
                                widget.event.region,
                                widget.event.country,
                              ].where((s) => (s ?? '').isNotEmpty).join(', '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final query = Uri.encodeComponent(
                          '${widget.event.venueName ?? ''} ${widget.event.address ?? ''} ${widget.event.city ?? ''}',
                        );
                        _openUrl(
                          'https://www.google.com/maps/search/?api=1&query=$query',
                        );
                      },
                      icon: const Icon(Icons.directions_rounded),
                      label: const Text('Get directions'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],

          // Tickets section
          if ((widget.event.ticketUrl ?? '').isNotEmpty) ...[
            Text(
              'Tickets',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            GradientGlassSurface(
              borderRadius: BorderRadius.circular(AppRadii.xl),
              borderGradient: AppPalette.heroGradient,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.confirmation_num_rounded,
                        color: scheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Get your tickets',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _openUrl(widget.event.ticketUrl!),
                      child: const Text('Buy tickets'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return GlassSurface(
      blurSigma: 16,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions(BuildContext context, Color accentColor) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 20 + bottomPadding,
      left: AppSpacing.responsive(context),
      right: AppSpacing.responsive(context),
      child: Row(
        children: [
          // Save button
          Expanded(
            flex: 1,
            child: GlassSurface(
              blurSigma: 20,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              padding: EdgeInsets.zero,
              enableGlow: _isSaved,
              glowColor: accentColor,
              glowIntensity: 0.2,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _toggleSave,
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Icon(
                              _isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: _isSaved ? accentColor : null,
                              size: 26,
                            ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Get tickets / Primary action
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppPalette.heroGradient,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                boxShadow: [
                  BoxShadow(
                    color: AppPalette.accentBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    if ((widget.event.ticketUrl ?? '').isNotEmpty) {
                      _openUrl(widget.event.ticketUrl!);
                    } else {
                      _toggleSave();
                    }
                  },
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    alignment: Alignment.center,
                    child: Text(
                      (widget.event.ticketUrl ?? '').isNotEmpty
                          ? 'Get Tickets'
                          : (_isSaved ? 'Saved to Calendar' : 'Save Event'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  Widget _buildReminderSheet(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark ? AppPalette.darkSurfaceElevated : AppPalette.lightSurface,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: scheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              Icons.notifications_rounded,
              size: 48,
              color: AppPalette.accentBlue,
            ),
            const SizedBox(height: 16),
            Text(
              'Set a reminder?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get notified before the event starts',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Not now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final reminderTime = widget.event.startAt!.subtract(
                        const Duration(hours: 1),
                      );
                      await NotificationScheduler.scheduleEventReminder(
                        eventId: widget.event.id,
                        title: 'Event Reminder',
                        body: '${widget.event.title} starts in 1 hour',
                        remindAt: reminderTime,
                      );
                      if (!mounted) return;
                      SnackBarHelper.showSuccess(
                        context,
                        'Reminder set for 1 hour before',
                      );
                    },
                    child: const Text('Set reminder'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
