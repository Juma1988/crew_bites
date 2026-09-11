import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_haptics.dart';
import '../translate.dart';
import 'debug_registry.dart';

/// Top-right chip shown on top of every page when debug mode is on. Tapping
/// copies the current page's relative dart path to the clipboard so it can be
/// pasted straight into the agent.
///
/// Lives at the app root (mounted in `main.dart`), so it stays above navigation
/// transitions and respects SafeArea.
class DebugOverlay extends StatelessWidget {
  const DebugOverlay({super.key, required this.enabled, required this.child});

  /// Controlled by the parent (already inside a `ListenableBuilder` on
  /// `AppSettings`), so this widget never listens to `AppSettings` directly.
  final bool enabled;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (enabled)
          const Positioned(
            top: 0,
            right: 0,
            child: SafeArea(child: _DebugChip()),
          ),
      ],
    );
  }
}

class _DebugChip extends StatelessWidget {
  const _DebugChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = Translate.instance;

    return ValueListenableBuilder<String?>(
      valueListenable: DebugRegistry.currentFile,
      builder: (context, file, _) {
        if (file == null) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: _ChipShell(
              theme: theme,
              scheme: scheme,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bug_report_rounded, size: 14, color: scheme.onSurface),
                  const SizedBox(width: 6),
                  Text(
                    t.debugOverlayNoTag,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final fileName = file.split('/').last;

        return Padding(
          padding: const EdgeInsets.all(8),
          child: Semantics(
            button: true,
            label: '${t.debugOverlayCopyTooltip} $file',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _copy(context, file),
                child: _ChipShell(
                  theme: theme,
                  scheme: scheme,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bug_report_rounded, size: 14, color: scheme.onSurface),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          fileName,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: scheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _copy(BuildContext context, String file) async {
    AppHaptics.selectionClick();
    await Clipboard.setData(ClipboardData(text: file));
    if (!context.mounted) return;
    final t = Translate.instance;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${t.debugOverlayCopiedToast}\n$file'),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _ChipShell extends StatelessWidget {
  const _ChipShell({
    required this.theme,
    required this.scheme,
    required this.child,
  });

  final ThemeData theme;
  final ColorScheme scheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.4 : 0.18,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
