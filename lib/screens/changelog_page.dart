import 'package:flutter/material.dart';

import '../core/changelog.dart';
import '../core/states/app_settings.dart';
import '../core/theme.dart';
import '../core/translate.dart';
import '../core/values/app_values.dart';

/// Versioned "What's new" page listing release notes, newest first.
class ChangelogPage extends StatelessWidget {
  const ChangelogPage({super.key});

  static const route = AppValues.routeChangelog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = Translate.instance;
    final isArabic = AppSettings.instance.isArabic;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient(scheme),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 32),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Row(
                    children: [
                      Semantics(
                        button: true,
                        label:
                            MaterialLocalizations.of(context).backButtonTooltip,
                        child: IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.new_releases_rounded,
                        color: scheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        t.whatsNewTitle,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                for (final (i, entry) in Changelog.entries.indexed)
                  _VersionCard(
                    entry: entry,
                    isArabic: isArabic,
                    isLatest: i == 0,
                    currentVersion: AppValues.appVersion,
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.entry,
    required this.isArabic,
    required this.isLatest,
    required this.currentVersion,
  });

  final ChangelogEntry entry;
  final bool isArabic;
  final bool isLatest;
  final String currentVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = Translate.instance;
    final notes = entry.notes(isArabic);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: isLatest
              ? scheme.primary.withValues(alpha: 0.6)
              : scheme.primary.withValues(alpha: 0.25),
          width: isLatest ? 2 : 1.5,
        ),
        boxShadow: AppTheme.softShadow(theme.brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'v${entry.version}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: scheme.primary,
                ),
              ),
              if (isLatest) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppValues.radiusPill),
                  ),
                  child: Text(
                    t.latestVersion,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (entry.version == currentVersion)
                Text(
                  t.currentVersionBadge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: theme.textTheme.bodyMedium),
                  Expanded(
                    child: Text(
                      note,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                      ),
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
