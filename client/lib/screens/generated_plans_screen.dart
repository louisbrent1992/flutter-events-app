import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/custom_app_bar.dart';
import '../components/error_display.dart';
import '../providers/generated_plan_provider.dart';
import '../theme/theme.dart';

class GeneratedPlansScreen extends StatefulWidget {
  const GeneratedPlansScreen({super.key});

  @override
  State<GeneratedPlansScreen> createState() => _GeneratedPlansScreenState();
}

class _GeneratedPlansScreenState extends State<GeneratedPlansScreen> {
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GeneratedPlanProvider>().loadPlans(page: 1, limit: _limit);
    });
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CustomAppBar(title: 'Generated'),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.responsive(context)),
        child: Consumer<GeneratedPlanProvider>(
          builder: (context, provider, _) {
            final error = provider.error;

            if (provider.isLoading && provider.plans.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (error != null && provider.plans.isEmpty) {
              return ErrorDisplay(
                message: error.userFriendlyMessage,
                onRetry: () => provider.loadPlans(page: 1, limit: _limit),
              );
            }

            if (provider.plans.isEmpty) {
              return Center(
                child: Text(
                  'No saved plans yet.\nGenerate an itinerary and it will appear here.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }

            return RefreshIndicator(
              onRefresh:
                  () => provider.loadPlans(
                    page: provider.currentPage,
                    limit: _limit,
                  ),
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 110),
                itemCount: provider.plans.length + 1,
                itemBuilder: (context, idx) {
                  if (idx == provider.plans.length) {
                    if (provider.totalPages <= 1)
                      return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed:
                                provider.hasPrevPage
                                    ? () => provider.loadPlans(
                                      page: provider.currentPage - 1,
                                      limit: _limit,
                                    )
                                    : null,
                            child: const Text('Prev'),
                          ),
                          Text(
                            '${provider.currentPage} / ${provider.totalPages}',
                          ),
                          TextButton(
                            onPressed:
                                provider.hasNextPage
                                    ? () => provider.loadPlans(
                                      page: provider.currentPage + 1,
                                      limit: _limit,
                                    )
                                    : null,
                            child: const Text('Next'),
                          ),
                        ],
                      ),
                    );
                  }

                  final p = provider.plans[idx];
                  return Card(
                    margin: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      title: Text(
                        p.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_formatDate(p.createdAt)),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'More',
                        icon: Icon(
                          Icons.more_vert,
                          size: AppSizing.responsiveIconSize(
                            context,
                            mobile: 22,
                            tablet: 26,
                            desktop: 28,
                          ),
                        ),
                        color: Theme.of(context).colorScheme.surface.withValues(
                          alpha: Theme.of(context).colorScheme.alphaVeryHigh,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(
                              alpha: Theme.of(context).colorScheme.overlayLight,
                            ),
                            width: 1,
                          ),
                        ),
                        onSelected: (value) async {
                          switch (value) {
                            case 'open':
                              if (!context.mounted) return;
                              Navigator.pushNamed(
                                context,
                                '/generatedDetail',
                                arguments: {'planId': p.id},
                              );
                              break;
                            case 'delete':
                              final ok = await showDialog<bool>(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text('Delete plan?'),
                                      content: Text('Delete "${p.title}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed:
                                              () => Navigator.pop(ctx, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                              );
                              if (ok == true && context.mounted) {
                                await context
                                    .read<GeneratedPlanProvider>()
                                    .deletePlan(p.id);
                              }
                              break;
                          }
                        },
                        itemBuilder:
                            (context) => [
                              PopupMenuItem<String>(
                                value: 'open',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.open_in_new_rounded,
                                      size: 18,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Open'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            '/generatedDetail',
                            arguments: {'planId': p.id},
                          ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
