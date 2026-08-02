import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
  late Event _currentEvent;
  late ScrollController _scrollController;
  double _scrollOffset = 0;
  bool _isSaved = false;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
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
    final saved = provider.userEvents.any((e) => e.id == _currentEvent.id);
    setState(() => _isSaved = saved);
  }

  /// One accent, whatever the category. Tinting the page per genre made the
  /// same screen look like six different products and fought the photograph.
  Color _getCategoryColor(String category) => AppPalette.accentBright;

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
        await provider.deleteEvent(_currentEvent.id, context);
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Event removed from calendar');
      } else {
        await provider.createEvent(_currentEvent, context);
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
    if (_currentEvent.startAt == null) return;

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
    buffer.writeln(_currentEvent.title);
    if (_currentEvent.startAt != null) {
      final dt = _currentEvent.startAt!;
      buffer.writeln('${_formatDate(dt)} at ${_formatTime(dt)}');
    }
    if ((_currentEvent.venueName ?? '').isNotEmpty) {
      buffer.writeln(_currentEvent.venueName);
    }
    if ((_currentEvent.ticketUrl ?? '').isNotEmpty) {
      buffer.writeln(_currentEvent.ticketUrl);
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    SnackBarHelper.showSuccess(context, 'Event details copied to clipboard');
  }

  Future<void> _editEvent() async {
    final updatedEvent =
        await Navigator.pushNamed(
              context,
              '/createEvent',
              arguments: _currentEvent,
            )
            as Event?;

    if (updatedEvent != null && mounted) {
      setState(() {
        _currentEvent = updatedEvent;
      });
    }
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
    final hasImage = (_currentEvent.imageUrl ?? '').trim().isNotEmpty;
    final accentColor =
        _currentEvent.categories.isNotEmpty
            ? _getCategoryColor(_currentEvent.categories.first)
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
              imageUrl: _currentEvent.imageUrl!.trim(),
              fit: BoxFit.cover,
              placeholder: (_, __) => _buildImagePlaceholder(accentColor),
              errorWidget: (_, __, ___) => _buildImagePlaceholder(accentColor),
            )
            : _buildImagePlaceholder(accentColor),

        // Editorial scrim: dark at the very top so the back button reads,
        // clear through the middle of the photograph, heavy at the base.
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppPalette.heroScrim),
        ),

        // Masthead block
        Positioned(
          bottom: 26,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kicker: category and date on one tracked line.
              Text(
                [
                  if (_currentEvent.categories.isNotEmpty)
                    _currentEvent.categories.first.toUpperCase(),
                  if (_currentEvent.startAt != null)
                    _formatDate(_currentEvent.startAt!).toUpperCase(),
                ].join('  ·  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.eyebrow?.copyWith(color: accentColor),
              ),
              const SizedBox(height: 12),

              Text(
                _currentEvent.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                ),
              ),

              if (_currentEvent.startAt != null ||
                  (_currentEvent.venueName ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_currentEvent.startAt != null) ...[
                      Icon(
                        Icons.schedule_rounded,
                        color: Colors.white.withValues(alpha: 0.65),
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(_currentEvent.startAt!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                    if (_currentEvent.startAt != null &&
                        (_currentEvent.venueName ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    if ((_currentEvent.venueName ?? '').isNotEmpty)
                      Flexible(
                        child: Text(
                          _currentEvent.venueName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(Color accentColor) {
    return Builder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return ColoredBox(
          color: scheme.well,
          child: Center(
            child: Icon(
              Icons.event_rounded,
              size: 56,
              color: scheme.onSurface.withValues(alpha: 0.15),
            ),
          ),
        );
      },
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
                      color: scheme.hairline,
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

            const SizedBox(width: 8),

            // Title (appears on scroll)
            Expanded(
              child: AnimatedOpacity(
                duration: AppAnimations.fast,
                opacity: opacity > 0.7 ? 1.0 : 0.0,
                child: Text(
                  _currentEvent.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

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

            const SizedBox(width: 4),

            // Edit button (only if user owns it)
            if (context.watch<AuthService>().user?.uid ==
                    _currentEvent.userId &&
                _currentEvent.userId.isNotEmpty) ...[
              if (showGlass)
                GlassSurface(
                  blurSigma: 16,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  padding: EdgeInsets.zero,
                  tintColor: Colors.black.withValues(alpha: 0.3),
                  borderColor: Colors.white.withValues(alpha: 0.2),
                  child: IconButton(
                    onPressed: _editEvent,
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _editEvent,
                    icon: Icon(Icons.edit_rounded, color: scheme.onSurface),
                  ),
                ),
              const SizedBox(width: 4),
            ],

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
          const SizedBox(height: 26),

          // Fact strip: two columns split by a vertical hairline. No fill,
          // no card - the rule alone is enough structure.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _factColumn(
                    context,
                    label: 'VENUE',
                    value: _currentEvent.venueName ?? 'TBA',
                    detail: _currentEvent.city ?? '',
                  ),
                ),
                Container(width: 1, color: scheme.hairline),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: _factColumn(
                      context,
                      label: 'DOORS',
                      value:
                          _currentEvent.startAt != null
                              ? _formatTime(_currentEvent.startAt!)
                              : 'TBA',
                      detail:
                          _currentEvent.startAt != null
                              ? _formatDate(_currentEvent.startAt!)
                              : '',
                    ),
                  ),
                ),
              ],
            ),
          ),

          _sectionRule(context, 'About'),
          _buildStructuredDescription(context, _currentEvent.description),

          // Location
          if ((_currentEvent.address ?? _currentEvent.venueName ?? '')
              .isNotEmpty) ...[
            _sectionRule(context, 'Location'),
            if ((_currentEvent.venueName ?? '').isNotEmpty)
              Text(
                _currentEvent.venueName!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            if ((_currentEvent.address ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _currentEvent.address!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                [
                  _currentEvent.city,
                  _currentEvent.region,
                  _currentEvent.country,
                ].where((s) => (s ?? '').isNotEmpty).join(', '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final query = Uri.encodeComponent(
                    '${_currentEvent.venueName ?? ''} '
                    '${_currentEvent.address ?? ''} '
                    '${_currentEvent.city ?? ''}',
                  );
                  _openUrl(
                    'https://www.google.com/maps/search/?api=1&query=$query',
                  );
                },
                icon: const Icon(Icons.directions_rounded, size: 18),
                label: const Text('Get directions'),
              ),
            ),
          ],

          // Tickets
          if ((_currentEvent.ticketUrl ?? '').isNotEmpty) ...[
            _sectionRule(context, 'Tickets'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentEvent.ticketPrice != null ? 'FROM' : 'STATUS',
                        style: theme.textTheme.eyebrow?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _currentEvent.ticketPrice != null
                            ? '${_currentEvent.ticketPrice}'
                            : 'Available',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _openUrl(_currentEvent.ticketUrl!),
                  child: const Text('Buy tickets'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// A label/value pair in the fact strip.
  Widget _factColumn(
    BuildContext context, {
    required String label,
    required String value,
    required String detail,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.eyebrow?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (detail.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  /// Section break: a hairline the full width, then the heading beneath it.
  /// Cheaper than a card and it keeps the whole page on one column.
  Widget _sectionRule(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Container(height: 1, color: theme.colorScheme.hairline),
        const SizedBox(height: 20),
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
      ],
    );
  }

  /// The single loud element on the page: one crimson pill, floating above
  /// the nav bar with an accent glow so it reads as the page's one job.
  Widget _buildFloatingActions(BuildContext context, Color accentColor) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final hasTickets = (_currentEvent.ticketUrl ?? '').isNotEmpty;

    return Positioned(
      bottom: 100 + bottomPadding,
      left: AppSpacing.responsive(context),
      right: AppSpacing.responsive(context),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.full),
          boxShadow: AppShadows.accentGlow(),
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              if (hasTickets) {
                _openUrl(_currentEvent.ticketUrl!);
              } else {
                _toggleSave();
              }
            },
            child: Text(
              hasTickets
                  ? 'Get tickets'
                  : (_isSaved ? 'Saved to calendar' : 'Add to calendar'),
            ),
          ),
        ),
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
                color: scheme.hairline,
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
                      final reminderTime = _currentEvent.startAt!.subtract(
                        const Duration(hours: 1),
                      );
                      await NotificationScheduler.scheduleEventReminder(
                        eventId: _currentEvent.id,
                        title: 'Event Reminder',
                        body: '${_currentEvent.title} starts in 1 hour',
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

  Widget _buildStructuredDescription(BuildContext context, String description) {
    if (description.isEmpty) {
      return _buildRichText(
        context,
        'No description available for this event.',
      );
    }

    final keywords = [
      'Source',
      'Contact',
      'Date/time',
      'Official site',
      'Ticket information',
      'Organizer',
    ];

    // Create a generic regex pattern
    final pattern = keywords.map((k) => RegExp.escape(k)).join('|');
    final splitRegExp = RegExp(
      r'\b(' + pattern + r'):\s*',
      caseSensitive: false,
    );

    // Check if we have any matches
    if (!splitRegExp.hasMatch(description)) {
      return _buildRichText(context, description);
    }

    // Parse
    final sections = <MapEntry<String, String>>[];
    final matches = splitRegExp.allMatches(description).toList();

    // Intro text (before first match)
    if (matches.isNotEmpty && matches.first.start > 0) {
      sections.add(
        MapEntry('About', description.substring(0, matches.first.start).trim()),
      );
    }

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final key =
          description
              .substring(match.start, match.end)
              .replaceAll(':', '')
              .trim();
      final start = match.end;
      final end =
          (i + 1 < matches.length) ? matches[i + 1].start : description.length;
      var value = description.substring(start, end).trim();
      // Remove trailing period if it looks like a sentence end after a value
      if (value.endsWith('.') && value.length > 1) {
        value = value.substring(0, value.length - 1);
      }

      if (value.isNotEmpty) {
        sections.add(MapEntry(key, value));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          sections.map((entry) {
            final isAbout = entry.key == 'About';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child:
                  isAbout
                      ? _buildRichText(context, entry.value)
                      : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 90,
                            child: Text(
                              entry.key,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          Expanded(child: _buildRichText(context, entry.value)),
                        ],
                      ),
            );
          }).toList(),
    );
  }

  Widget _buildRichText(BuildContext context, String text) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (text.isEmpty) return const SizedBox.shrink();

    // Improved Regex for URLs and Emails
    // Captures http/https/www URLs, domain.tld, and emails
    final urlPattern =
        r'((?:https?:\/\/|www\.)[^\s\u200B]+|\b(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}\b(?:/[^\s\u200B]*)?)';
    final emailPattern = r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}';
    final combinedPattern = '($urlPattern)|($emailPattern)';
    final regExp = RegExp(combinedPattern, caseSensitive: false);

    final matches = regExp.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.8),
          height: 1.6,
        ),
      );
    }

    final spans = <InlineSpan>[];
    int start = 0;

    for (final match in matches) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, match.start),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
              height: 1.6,
            ),
          ),
        );
      }

      var matchedText = text.substring(match.start, match.end);

      // Clean trailing punctuation
      String trailing = '';
      final punctuationMatch = RegExp(r'[.,;?!)]+$').firstMatch(matchedText);
      if (punctuationMatch != null) {
        trailing = matchedText.substring(punctuationMatch.start);
        matchedText = matchedText.substring(0, punctuationMatch.start);
      }

      if (matchedText.isEmpty) {
        // If match was ONLY punctuation, just print it
        spans.add(
          TextSpan(
            text: trailing,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
              height: 1.6,
            ),
          ),
        );
        start = match.end;
        continue;
      }

      // Determine URL
      final isEmail = RegExp(emailPattern).hasMatch(matchedText);
      String url;
      if (isEmail) {
        url = 'mailto:$matchedText';
      } else {
        url = matchedText;
        if (!url.startsWith('http')) {
          url = 'https://$url';
        }
      }

      spans.add(
        TextSpan(
          text: matchedText,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.primary,
            height: 1.6,
            decoration: TextDecoration.underline,
            decorationColor: scheme.primary,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => _openUrl(url),
        ),
      );

      if (trailing.isNotEmpty) {
        spans.add(
          TextSpan(
            text: trailing,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
              height: 1.6,
            ),
          ),
        );
      }

      start = match.end;
    }

    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.8),
            height: 1.6,
          ),
        ),
      );
    }

    return Text.rich(TextSpan(children: spans));
  }
}
