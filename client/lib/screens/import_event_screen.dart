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
      final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
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
        await _saveDraftAsEvent(resp.data!, context, fromAi: true);
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

  Future<void> _saveDraftAsEvent(Event draft, BuildContext context, {required bool fromAi}) async {
    final provider = context.read<EventProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();

    final created = await provider.createEvent(
      draft.copyWith(
        id: '',
        userId: '',
      ),
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
      Navigator.pushReplacementNamed(context, '/eventDetail', arguments: created);
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
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.responsive(context)),
            child: ListView(
              children: [
                const OfflineBanner(),
                const InlineBannerAd(),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'Event link',
                    hintText: 'Paste Instagram/TikTok/YouTube/web link…',
                    suffixIcon: IconButton(
                      tooltip: 'Paste',
                      icon: const Icon(Icons.paste_rounded),
                      onPressed: () => _pasteUrl(context),
                    ),
                  ),
                  onSubmitted: (v) => _importFromUrl(context, v),
                ),
                SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () => _importFromUrl(context, _urlController.text),
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Import from link'),
                ),
                SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () => _scanFlyer(context),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Scan flyer / screenshot'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


