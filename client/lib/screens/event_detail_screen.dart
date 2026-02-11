import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:eventease/providers/event_provider.dart';
import 'package:eventease/services/notification_scheduler.dart';
import 'package:eventease/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eventease/components/glass_surface.dart';
import '../components/floating_bottom_bar.dart';
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
      final dt = widget.event.startAt!;
      buffer.writeln('${_formatDate(dt)} at ${_formatTime(dt)}');
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
    final local = dt.toLocal();
    return DateFormat('EEEE, MMMM d').format(local);
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
    final isScrolled = appBarOpacity > 0.6;

    final scaffoldBg = theme.scaffoldBackgroundColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isScrolled
                ? (isDark ? Brightness.light : Brightness.dark)
                : Brightness.light,
        statusBarBrightness:
            isScrolled
                ? (isDark ? Brightness.dark : Brightness.light)
                : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: scaffoldBg,
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
                  // Hero Image (using SliverAppBar for proper parallax/stretch)
                  SliverAppBar(
                    expandedHeight: heroHeight,
                    pinned: false,
                    floating: false,
                    stretch: true,
                    backgroundColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      stretchModes: const [
                        StretchMode.zoomBackground,
                        StretchMode.blurBackground,
                      ],
                      background: _buildHeroBackground(
                        context,
                        hasImage: hasImage,
                        accentColor: accentColor,
                        scaffoldBg: scaffoldBg,
                      ),
                    ),
                  ),
                  // Content
                  SliverToBoxAdapter(
                    child: _buildContent(context, accentColor),
                  ),
                  // Bottom padding - space for floating actions + bottom bar
                  SliverToBoxAdapter(child: SizedBox(height: 220)),
                ],
              ),

              // Custom App Bar
              _buildAppBar(context, appBarOpacity, accentColor),

              // Floating Action Buttons
              _buildFloatingActions(context, accentColor),

              // Bottom Bar
              const FloatingBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBackground(
    BuildContext context, {
    required bool hasImage,
    required Color accentColor,
    required Color scaffoldBg,
  }) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        hasImage
            ? CachedNetworkImage(
              imageUrl: widget.event.imageUrl!.trim(),
              fit: BoxFit.cover,
              placeholder: (_, __) => _buildImagePlaceholder(accentColor),
              errorWidget: (_, __, ___) => _buildImagePlaceholder(accentColor),
            )
            : _buildImagePlaceholder(accentColor),

        // Deep gradient for text legibility
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.8),
                Colors.black,
              ],
              stops: const [0.0, 0.3, 0.5, 0.8, 1.0],
            ),
          ),
        ),

        // Content Overlay
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category Pill
              if (widget.event.categories.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.event.categories.first.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // Title
              Text(
                widget.event.title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Date Row
              if (widget.event.startAt != null)
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _formatDate(widget.event.startAt!).toUpperCase(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.event.startAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(widget.event.startAt!),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ],
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

    // Determine if we should show glass (over image) or solid (over content)
    final showGlass = opacity < 0.5;

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
          color: (isDark ? AppPalette.darkBg : scheme.surface).withValues(
            alpha: opacity * 0.98,
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
            // Back button - always visible with appropriate styling
            if (showGlass)
              GlassSurface(
                blurSigma: 16,
                borderRadius: BorderRadius.circular(AppRadii.full),
                padding: EdgeInsets.zero,
                tintColor: Colors.black.withValues(alpha: 0.3),
                borderColor: Colors.white.withValues(alpha: 0.2),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
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

            // Save/Bookmark button
            if (showGlass)
              GlassSurface(
                blurSigma: 16,
                borderRadius: BorderRadius.circular(AppRadii.full),
                padding: EdgeInsets.zero,
                tintColor: Colors.black.withValues(alpha: 0.3),
                borderColor: Colors.white.withValues(alpha: 0.2),
                child: IconButton(
                  onPressed: _isLoading ? null : _toggleSave,
                  icon:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Icon(
                            _isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: _isSaved ? accentColor : Colors.white,
                          ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isLoading ? null : _toggleSave,
                  icon:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Icon(
                            _isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: _isSaved ? accentColor : scheme.onSurface,
                          ),
                ),
              ),

            const SizedBox(width: 12),

            // Share button - always visible with appropriate styling
            if (showGlass)
              GlassSurface(
                blurSigma: 16,
                borderRadius: BorderRadius.circular(AppRadii.full),
                padding: EdgeInsets.zero,
                tintColor: Colors.black.withValues(alpha: 0.3),
                borderColor: Colors.white.withValues(alpha: 0.2),
                child: IconButton(
                  onPressed: _share,
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _share,
                  icon: Icon(Icons.share_rounded, color: scheme.onSurface),
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
    // Removed scaffoldBg logic as it's not needed for simple content

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.responsive(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          // Venue & Time Info Cards (Full Width)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VENUE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.event.venueName ?? 'TBA',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.event.city ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: scheme.outline.withValues(alpha: 0.1),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TIME',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.event.startAt != null
                            ? _formatTime(widget.event.startAt!)
                            : 'TBA',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.event.startAt != null
                            ? _formatDate(widget.event.startAt!)
                            : '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // About section
          Text(
            'About',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.event.description.isEmpty
                ? 'No description available for this event.'
                : widget.event.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
              height: 1.6,
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
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.1),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppPalette.accentBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: AppPalette.accentBlue,
                          size: 20,
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
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  widget.event.address!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
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
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: const Text('Get directions'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: scheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
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
            Container(
              decoration: BoxDecoration(
                gradient: AppPalette.heroGradient.scale(0.05),
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(
                  color: AppPalette.accentBlue.withValues(alpha: 0.2),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.confirmation_num_outlined,
                        color: AppPalette.accentBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.event.ticketPrice != null
                              ? 'Tickets from ${widget.event.ticketPrice}'
                              : 'Tickets available',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppPalette.accentBlue,
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

  Widget _buildFloatingActions(BuildContext context, Color accentColor) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: 100 + bottomPadding, // Above the floating bottom bar
      left: AppSpacing.responsive(context),
      right: AppSpacing.responsive(context),
      child: Row(
        children: [
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
                          : (_isSaved
                              ? 'Saved to Calendar'
                              : 'Add to Calendar'),
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
    return DateFormat('h:mm a').format(dt.toLocal());
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
