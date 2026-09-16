import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/core/utils/format.dart';
import 'package:glam/src/core/utils/url_launcher.dart';
import 'package:glam/src/core/widgets/async_value_widget.dart';
import 'package:glam/src/core/widgets/state_chip.dart';
import 'package:glam/src/features/pipelines/application/pipelines_providers.dart';
import 'package:glam/src/features/pipelines/domain/pipeline.dart';

/// Job page: meta header plus the full console trace in monospace.
class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({
    required this.projectId,
    required this.jobId,
    super.key,
  });

  final Object projectId;
  final int jobId;

  JobRef get _loc => (project: projectId, id: jobId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(jobProvider(_loc));

    return Scaffold(
      appBar: AppBar(
        title: job.maybeWhen(
          data: (j) => Text(j.name),
          orElse: () => Text('Job #$jobId'),
        ),
        actions: [
          job.maybeWhen(
            data: (j) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (j.status == 'running' || j.status == 'pending')
                  IconButton(
                    tooltip: 'Cancel',
                    icon: const Icon(Icons.stop_circle_outlined),
                    onPressed: () => unawaited(_act(context, ref, 'cancel')),
                  )
                else
                  IconButton(
                    tooltip: 'Retry',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => unawaited(
                      _act(
                        context,
                        ref,
                        j.status == 'manual' ? 'play' : 'retry',
                      ),
                    ),
                  ),
                if (j.webUrl != null)
                  IconButton(
                    tooltip: 'Open in browser',
                    icon: const Icon(Icons.open_in_new, size: 20),
                    onPressed: () => unawaited(launchExternal(j.webUrl!)),
                  ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: AsyncValueWidget<Job>(
        value: job,
        onRetry: () => ref.invalidate(jobProvider(_loc)),
        data: (j) => Column(
          children: [
            _JobHeader(job: j),
            Expanded(child: _TraceView(loc: _loc)),
          ],
        ),
      ),
    );
  }

  Future<void> _act(BuildContext context, WidgetRef ref, String action) async {
    final repo = ref.read(pipelinesRepositoryProvider);
    try {
      await switch (action) {
        'cancel' => repo.cancelJob(projectId, jobId),
        'play' => repo.playJob(projectId, jobId),
        _ => repo.retryJob(projectId, jobId),
      };
      ref
        ..invalidate(jobProvider(_loc))
        ..invalidate(jobTraceProvider(_loc));
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _JobHeader extends StatelessWidget {
  const _JobHeader({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Wrap(
        spacing: Insets.lg,
        runSpacing: Insets.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StateChip.pipeline(job.status),
          if (job.stage != null)
            Text(job.stage!, style: theme.textTheme.bodySmall),
          if (job.duration != null)
            Text(
              Format.duration(job.duration?.toDouble()),
              style: theme.textTheme.bodySmall,
            ),
          if (job.user != null)
            Text('by ${job.user!.name}', style: theme.textTheme.bodySmall),
          if (job.tagList.isNotEmpty)
            Text(
              job.tagList.join(', '),
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11.5,
              ),
            ),
        ],
      ),
    );
  }
}

class _TraceView extends ConsumerWidget {
  const _TraceView({required this.loc});

  final JobRef loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trace = ref.watch(jobTraceProvider(loc));
    final colors = context.colors;

    return AsyncValueWidget<String>(
      value: trace,
      onRetry: () => ref.invalidate(jobTraceProvider(loc)),
      loading: const Center(child: CircularProgressIndicator()),
      data: (body) => Stack(
        children: [
          Container(
            color: colors.codeBackground,
            child: SelectionArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Insets.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    body.isEmpty ? '(empty trace)' : body,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11.5,
                      height: 1.5,
                      color: colors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: Insets.md,
            bottom: Insets.md,
            child: IconButton.filled(
              tooltip: 'Copy trace',
              icon: const Icon(Icons.copy_outlined, size: 18),
              onPressed: () =>
                  unawaited(Clipboard.setData(ClipboardData(text: body))),
            ),
          ),
        ],
      ),
    );
  }
}
