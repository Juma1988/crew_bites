import 'package:flutter/material.dart';

import '../core/app_haptics.dart';
import '../core/friend_icon_style.dart';
import '../core/states/app_settings.dart';
import '../core/states/order_store.dart';
import '../core/theme.dart';
import '../core/translate.dart';
import '../core/values/app_values.dart';
import '../core/debug/debug_registry.dart';
import '../models/order_models.dart';
import '../models/output_args.dart';
import 'output_history_page.dart';

/// Past orders (last [AppValues.maxHistory]) — opened from Home.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  static const route = AppValues.routeHistory;
  static const String debugSourceFile = 'lib/screens/history_page.dart';

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<OrderSession> _history = [];
  bool _ready = false;

  static const t = Translate();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await OrderStore.loadHistory(
      null,
      () => AppSettings.instance.notePrefsCorrupt(),
    );
    if (!mounted) return;
    setState(() {
      _history = history;
      _ready = true;
    });
    if (AppSettings.instance.prefsLoadWarning && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.prefsCorruptToast)),
      );
      AppSettings.instance.clearPrefsWarning();
    }
  }

  Future<void> _openEntry(OrderSession session) async {
    AppHaptics.selectionClick();
    await Navigator.pushNamed(
      context,
      OutputHistoryPage.route,
      arguments: OutputHistoryArgs(session: session, fromHistory: true),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strings = t;
    if (DebugRegistry.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DebugRegistry.currentFile.value = 'lib/screens/history_page.dart';
      });
    }

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
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
                      Expanded(
                        child: Text(
                          strings.historyPeekTitle,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      if (_ready && _history.isNotEmpty)
                        Text(
                          strings.historySlotCount(
                            _history.length,
                            AppValues.maxHistory,
                          ),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: !_ready
                      ? Center(
                          child: Semantics(
                            label: 'Loading',
                            child: const CircularProgressIndicator(),
                          ),
                        )
                      : _history.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: scheme.primaryContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.receipt_long_outlined,
                                        size: 36,
                                        color: scheme.onPrimaryContainer,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      strings.historyEmpty,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                               padding: AppTheme.pagePadding(context),
                              itemCount: _history.length,
                              separatorBuilder: (a, b) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final session = _history[i];
                                return _HistoryEntryCard(
                                  t: strings,
                                  session: session,
                                  onTap: () => _openEntry(session),
                                );
                              },
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

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.t,
    required this.session,
    required this.onTap,
  });

  final Translate t;
  final OrderSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final date = session.updatedAt ?? session.createdAt;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final iconStyle = AppSettings.instance.friendIconStyle;

    return Material(
      color: scheme.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.orderedOn(dateStr),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                ),
              ),
              if (session.hasPlace) ...[
                const SizedBox(height: 4),
                Text(
                  session.groupName!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                t.peopleItemsSummary(
                  session.people.length,
                  session.itemCount,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final (i, p) in session.people.take(6).indexed)
                    Chip(
                      avatar: CircleAvatar(
                        backgroundColor: p.color.withValues(alpha: 0.3),
                        child: Text(
                          friendIconMark(p, iconStyle, i),
                          style: TextStyle(
                            fontSize: friendUsesEmoji(p, iconStyle) ? 14 : 10,
                            fontWeight: FontWeight.w800,
                            color:
                                friendUsesEmoji(p, iconStyle) ? null : p.color,
                          ),
                        ),
                      ),
                      label: Text(p.name),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
