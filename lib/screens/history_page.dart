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
  bool _favoritesOnly = false;

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

  Future<void> _toggleFavorite(OrderSession session) async {
    final nextFavorite = !session.isFavorite;
    setState(() {
      _history = [
        for (final item in _history)
          item.id == session.id
              ? item.copyWith(isFavorite: nextFavorite)
              : item,
      ];
    });
    await OrderStore.setHistoryFavorite(
      session.id,
      nextFavorite,
      _history,
    );
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
                if (_ready && _history.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 10),
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text(strings.allOrders),
                          icon: const Icon(Icons.list_alt_rounded),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text(strings.favoriteOrders),
                          icon: const Icon(Icons.star_rounded),
                        ),
                      ],
                      selected: {_favoritesOnly},
                      onSelectionChanged: (selection) => setState(
                        () => _favoritesOnly = selection.first,
                      ),
                    ),
                  ),
                Expanded(
                  child: !_ready
                      ? Center(
                          child: Semantics(
                            label: 'Loading',
                            child: const CircularProgressIndicator(),
                          ),
                        )
                      : _visibleHistory.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '📋',
                                      style: theme.textTheme.displaySmall,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _history.isEmpty
                                          ? strings.historyEmpty
                                          : strings.favoriteOrdersEmpty,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
                              itemCount: _visibleHistory.length,
                              separatorBuilder: (a, b) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final session = _visibleHistory[i];
                                return _HistoryEntryCard(
                                  t: strings,
                                  session: session,
                                  onTap: () => _openEntry(session),
                                  onFavoriteToggle: () =>
                                      _toggleFavorite(session),
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

  List<OrderSession> get _visibleHistory => _favoritesOnly
      ? _history.where((session) => session.isFavorite).toList()
      : _history;
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.t,
    required this.session,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  final Translate t;
  final OrderSession session;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.orderedOn(dateStr),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    toggled: session.isFavorite,
                    label: session.isFavorite
                        ? t.unfavoriteOrder
                        : t.favoriteOrder,
                    child: IconButton(
                      tooltip: session.isFavorite
                          ? t.unfavoriteOrder
                          : t.favoriteOrder,
                      icon: Icon(
                        session.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: session.isFavorite ? scheme.primary : null,
                      ),
                      onPressed: onFavoriteToggle,
                    ),
                  ),
                ],
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
