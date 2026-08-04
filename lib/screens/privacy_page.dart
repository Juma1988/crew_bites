import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_haptics.dart';
import '../core/legal_config.dart';
import '../core/states/app_settings.dart';
import '../core/theme.dart';
import '../core/translate.dart';
import '../core/values/app_values.dart';

/// Full privacy policy (bundled markdown, offline).
class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  static const route = AppValues.routePrivacy;

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  static const t = Translate();

  Future<void> _emailSupport() async {
    AppHaptics.selectionClick();
    final uri = Uri(
      scheme: 'mailto',
      path: LegalConfig.supportEmail,
      queryParameters: {'subject': 'Crew Bites privacy'},
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        await Clipboard.setData(
          const ClipboardData(text: LegalConfig.supportEmail),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.emailOpenFailed)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      await Clipboard.setData(
        const ClipboardData(text: LegalConfig.supportEmail),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.emailOpenFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final ar = AppSettings.instance.isArabic;
        final path =
            ar ? 'assets/legal/privacy_ar.md' : 'assets/legal/privacy_en.md';

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
                      padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          Expanded(
                            child: Text(
                              t.settingsPrivacy,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<String>(
                        future: rootBundle.loadString(path),
                        builder: (context, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return Center(
                              child: Semantics(
                                label: 'Loading',
                                child: const CircularProgressIndicator(),
                              ),
                            );
                          }
                          final body =
                              snap.hasData ? snap.data! : t.settingsPrivacyBody;
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color:
                                    scheme.surface.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusCard),
                                border: Border.all(
                                  color: scheme.outlineVariant
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                              child: MarkdownBody(
                                data: body,
                                selectable: true,
                                styleSheet: MarkdownStyleSheet(
                                  p: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.45,
                                    color: scheme.onSurface,
                                  ),
                                  h1: theme.textTheme.headlineSmall?.copyWith(
                                    color: scheme.onSurface,
                                  ),
                                  h2: theme.textTheme.titleLarge?.copyWith(
                                    color: scheme.onSurface,
                                  ),
                                  h3: theme.textTheme.titleMedium?.copyWith(
                                    color: scheme.onSurface,
                                  ),
                                  strong: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _emailSupport,
                                icon: const Icon(Icons.mail_outline_rounded),
                                label: Text(t.contactSupport),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () async {
                                AppHaptics.selectionClick();
                                await Clipboard.setData(
                                  const ClipboardData(
                                      text: LegalConfig.supportEmail),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t.copiedToast)),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded),
                              tooltip: t.copiedToast,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
