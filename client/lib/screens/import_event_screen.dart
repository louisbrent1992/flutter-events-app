import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:eventease/components/custom_app_bar.dart';
import 'package:eventease/providers/event_provider.dart';
import 'package:eventease/providers/subscription_provider.dart';
import 'package:eventease/services/credits_service.dart';
import 'package:eventease/services/event_ai_service.dart';
import 'package:eventease/theme/theme.dart';
import '../models/event.dart';
import '../utils/loading_dialog_helper.dart';
import '../utils/snackbar_helper.dart';
import '../components/offline_banner.dart';
import '../components/inline_banner_ad.dart';
import '../components/glass_surface.dart';
import '../components/section_header.dart';
import 'package:file_picker/file_picker.dart';

class ImportEventScreen extends StatefulWidget {
  final String? sharedUrl;
  const ImportEventScreen({super.key, this.sharedUrl});

  @override
  State<ImportEventScreen> createState() => _ImportEventScreenState();
}

class _ImportEventScreenState extends State<ImportEventScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  bool _startedFromShare = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();

    if (widget.sharedUrl != null && widget.sharedUrl!.isNotEmpty) {
      _startedFromShare = true;
      _urlController.text = widget.sharedUrl!;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _importFromUrl(context, widget.sharedUrl!),
      );
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showInsufficientCreditsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Insufficient Credits'),
            content: const Text(
              'You don\'t have enough credits to import events. Please purchase credits or subscribe to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
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

  Future<bool> _ensureCredits(BuildContext context) async {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    try {
      await subscriptionProvider.refreshData();
    } catch (_) {}
    final hasCredits = await subscriptionProvider.hasEnoughCredits(
      CreditType.eventImport,
    );
    if (!hasCredits && context.mounted) {
      _showInsufficientCreditsDialog(context);
    }
    return hasCredits;
  }

  Future<void> _importFromUrl(BuildContext context, String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      SnackBarHelper.showWarning(context, 'Please enter a valid URL');
      return;
    }

    if (!await _ensureCredits(context)) return;

    try {
      if (context.mounted) {
        LoadingDialogHelper.show(context, message: 'Importing Event');
      }

      final resp = await EventAiService.importEventFromUrl(trimmed);

      if (context.mounted) {
        LoadingDialogHelper.dismiss(context);
      }

      if (!context.mounted) return;
      if (resp.success && resp.data != null) {
        final draft = resp.data!;
        await _saveDraftAsEvent(draft, context, fromAi: true);
      } else {
        SnackBarHelper.showError(context, resp.userFriendlyMessage);
      }
    } catch (e) {
      if (context.mounted) {
        LoadingDialogHelper.dismiss(context);
        SnackBarHelper.showError(context, 'Failed to import event: $e');
      }
    }
  }

  Future<void> _scanFlyer(BuildContext context) async {
    if (!await _ensureCredits(context)) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes =
          file.bytes ??
          (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (!context.mounted) return;
      if (bytes == null) {
        SnackBarHelper.showError(context, 'Unable to read image');
        return;
      }

      final b64 = base64Encode(bytes);

      if (context.mounted) {
        LoadingDialogHelper.show(context, message: 'Scanning Flyer');
      }

      final resp = await EventAiService.scanFlyerBase64(b64);

      if (context.mounted) {
        LoadingDialogHelper.dismiss(context);
      }

      if (!context.mounted) return;
      if (resp.success && resp.data != null) {
        var event = resp.data!;
        if ((event.imageUrl == null || event.imageUrl!.trim().isEmpty)) {
          // Use the scanned image itself if AI didn't extract a URL
          event = event.copyWith(imageUrl: 'data:image/jpeg;base64,$b64');
        }
        await _saveDraftAsEvent(event, context, fromAi: true);
      } else {
        SnackBarHelper.showError(context, resp.userFriendlyMessage);
      }
    } catch (e) {
      if (context.mounted) {
        LoadingDialogHelper.dismiss(context);
        SnackBarHelper.showError(context, 'Failed to scan flyer: $e');
      }
    }
  }

  Future<void> _saveDraftAsEvent(
    Event draft,
    BuildContext context, {
    required bool fromAi,
  }) async {
    final provider = context.read<EventProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();

    final created = await provider.createEvent(
      draft.copyWith(id: '', userId: ''),
      context,
    );

    if (!context.mounted) return;

    if (created != null) {
      // Deduct credits (best-effort)
      try {
        await subscriptionProvider.useCredits(
          CreditType.eventImport,
          reason: 'Event import',
        );
      } catch (_) {}

      if (!context.mounted) return;
      SnackBarHelper.showSuccess(context, 'Event saved');
      Navigator.pushReplacementNamed(
        context,
        '/eventDetail',
        arguments: created,
      );
    } else {
      SnackBarHelper.showError(
        context,
        provider.error?.userFriendlyMessage ?? 'Failed to save event',
      );
    }
  }

  Future<void> _pasteUrl(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        _urlController.text = clipboardData.text!;
        messenger.showSnackBar(
          SnackBar(
            content: const Text('URL pasted'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Clipboard is empty'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to paste from clipboard'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final pad = AppSpacing.responsive(context);

    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(
          title: _startedFromShare ? 'Import' : 'Import',
          fullTitle: 'Import Event',
        ),
        body: SafeArea(
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
              const OfflineBanner(),
              const InlineBannerAd(),

              // ── Hero section ──────────────────────────────
              _buildHeroSection(theme, scheme, isDark),
              SizedBox(height: AppSpacing.xl),

              // ── Import from Link ──────────────────────────
              const SectionHeader(
                title: 'Paste a Link',
                subtitle:
                    'Import from Instagram, TikTok, Eventbrite, or any web page.',
              ),
              GlassSurface(
                blurSigma: 18,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: 'Event link',
                        hintText: 'https://…',
                        prefixIcon: Icon(
                          Icons.link_rounded,
                          color: scheme.primary,
                        ),
                        suffixIcon: IconButton(
                          tooltip: 'Paste from clipboard',
                          icon: Icon(
                            Icons.content_paste_rounded,
                            color: scheme.primary.withValues(alpha: 0.8),
                          ),
                          onPressed: () => _pasteUrl(context),
                        ),
                      ),
                      onSubmitted: (v) => _importFromUrl(context, v),
                    ),
                    SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            () => _importFromUrl(context, _urlController.text),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: const Text('Import event'),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.xl),

              // ── Other methods ─────────────────────────────
              const SectionHeader(
                title: 'Other Methods',
                subtitle: 'Scan a flyer or pull in events from your calendar.',
              ),

              // Scan Flyer card
              _buildMethodCard(
                context: context,
                icon: Icons.document_scanner_rounded,
                iconColor: AppPalette.emerald,
                title: 'Scan Flyer',
                description:
                    'Upload a poster, screenshot, or flyer and our AI will extract the event details automatically.',
                buttonLabel: 'Choose image',
                onPressed: () => _scanFlyer(context),
              ),

              SizedBox(height: AppSpacing.sm),

              // Import from Calendar card
              _buildMethodCard(
                context: context,
                icon: Icons.calendar_month_rounded,
                iconColor: AppPalette.accentBlue,
                title: 'Import from Calendar',
                description:
                    'Pull events directly from your device calendar into EventEase.',
                buttonLabel: 'Open calendar',
                onPressed:
                    () => Navigator.pushNamed(context, '/importCalendar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero illustration ───────────────────────────────────────────────────────
  Widget _buildHeroSection(ThemeData theme, ColorScheme scheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: isDark ? 0.20 : 0.10),
            scheme.secondary.withValues(alpha: isDark ? 0.12 : 0.06),
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
              Icons.add_circle_outline_rounded,
              size: 30,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add events effortlessly',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Paste a link, scan a flyer, or import from your calendar — AI does the rest.',
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

  // ── Reusable method card ────────────────────────────────────────────────────
  Widget _buildMethodCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GlassSurface(
      blurSigma: 14,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onPressed,
                    child: Text(buttonLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
