import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_haptics.dart';
import '../core/extras_split_mode.dart';
import '../core/friend_icon_style.dart';
import '../core/legal_config.dart';
import '../core/states/app_settings.dart';
import '../core/theme.dart';
import '../core/translate.dart';
import '../core/values/app_values.dart';
import '../models/order_models.dart';
import 'changelog_page.dart';
import 'privacy_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const route = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const strings = Translate();
  String? _expandedSection;

  Future<void> _clearCustom() async {
    AppHaptics.selectionClick();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.clearCustomRoster),
        content: Text(strings.clearCustomRosterBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AppSettings.instance.clearCustomRoster();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.clearedToast)),
    );
  }

  Future<void> _emailSupport() async {
    AppHaptics.selectionClick();
    // Open the default email app with the dev address in the "To" field.
    // Subject + body are left empty so the user fills in their message.
    final uri = Uri(scheme: 'mailto', path: LegalConfig.supportEmail);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        await _copySupportEmail();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.emailOpenFailed)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      await _copySupportEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.emailOpenFailed)),
      );
    }
  }

  Future<void> _copySupportEmail() async {
    await Clipboard.setData(
      const ClipboardData(text: LegalConfig.supportEmail),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.copiedToast)),
    );
  }

  Future<void> _launchUrl(String url) async {
    AppHaptics.selectionClick();
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.emailOpenFailed)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.emailOpenFailed)),
      );
    }
  }

  void _onToggleSection(String id, bool expanding) {
    setState(() {
      _expandedSection = expanding ? id : null;
    });
  }

  Future<void> _openColorThemes(
    BuildContext context, {
    required ColorPalette selected,
  }) async {
    AppHaptics.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    final neonUnlocked = prefs.getBool(AppValues.prefsNeonUnlocked) ?? false;
    final palettes = ColorPalette.values
        .where((p) => p != ColorPalette.neon || neonUnlocked)
        .toList();
    if (!context.mounted) return;
    final picked = await showModalBottomSheet<ColorPalette>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    strings.settingsColors,
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final palette in palettes)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 2,
                          ),
                          leading: _PaletteDot(palette: palette, size: 36),
                          title: Text(strings.paletteName(palette.id)),
                          trailing: palette == selected
                              ? Icon(
                                  Icons.check_rounded,
                                  color: Theme.of(ctx).colorScheme.primary,
                                )
                              : null,
                          selected: palette == selected,
                          onTap: () {
                            AppHaptics.selectionClick();
                            Navigator.pop(ctx, palette);
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    await AppSettings.instance.setColorPalette(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final settings = AppSettings.instance;
        final mode = settings.themeMode;
        final localeCode = settings.localeCode;
        final currency = settings.currencyCode;

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
                            label: MaterialLocalizations.of(context)
                                .backButtonTooltip,
                            child: IconButton(
                              onPressed: () => Navigator.maybePop(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.tune_rounded,
                              color: scheme.primary, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            strings.settingsTitle,
                            style: theme.textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CollapsibleCard(
                      sectionId: 'theme',
                      isExpanded: _expandedSection == 'theme',
                      onToggle: _onToggleSection,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      icon: Icons.palette_outlined,
                      title: strings.settingsTheme,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SegmentedButton<ThemeMode>(
                            segments: [
                              ButtonSegment(
                                value: ThemeMode.system,
                                label: Text(strings.themeSystem),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text(strings.themeLight),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text(strings.themeDark),
                              ),
                            ],
                            selected: {mode},
                            onSelectionChanged: (s) {
                              AppHaptics.selectionClick();
                              AppSettings.instance.setThemeMode(s.first);
                            },
                          ),
                          const SizedBox(height: 12),
                          _ColorThemeCard(
                            selected: settings.colorPalette,
                            name: strings.paletteName(settings.colorPalette.id),
                            onTap: () => _openColorThemes(
                              context,
                              selected: settings.colorPalette,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CollapsibleCard(
                      sectionId: 'lang',
                      isExpanded: _expandedSection == 'lang',
                      onToggle: _onToggleSection,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      icon: Icons.language_outlined,
                      title: strings.settingsLanguage,
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'en',
                            label: Text(strings.languageEnglish),
                          ),
                          ButtonSegment(
                            value: 'ar',
                            label: Text(strings.languageArabic),
                          ),
                        ],
                        selected: {localeCode},
                        onSelectionChanged: (s) {
                          AppHaptics.selectionClick();
                          AppSettings.instance.setLocaleCode(s.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CollapsibleCard(
                      sectionId: 'currency',
                      isExpanded: _expandedSection == 'currency',
                      onToggle: _onToggleSection,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      icon: Icons.attach_money_rounded,
                      title: strings.settingsCurrency,
                      child: DropdownButtonFormField<String>(
                        initialValue: currency,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (final code in AppValues.currencyCodes)
                            DropdownMenuItem(
                              value: code,
                              child: Text(strings.currencyLabel(code)),
                            ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          AppHaptics.selectionClick();
                          AppSettings.instance.setCurrencyCode(v);
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CollapsibleCard(
                      sectionId: 'friendIcons',
                      isExpanded: _expandedSection == 'friendIcons',
                      onToggle: _onToggleSection,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      icon: Icons.face_retouching_natural_rounded,
                      title: strings.settingsFriendIcons,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            strings.friendIconStyleBody,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          for (final style in FriendIconStyle.values)
                            _IconStyleRow(
                              style: style,
                              selected: settings.friendIconStyle == style,
                              onTap: () {
                                AppHaptics.selectionClick();
                                AppSettings.instance.setFriendIconStyle(style);
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CollapsibleCard(
                      sectionId: 'split',
                      isExpanded: _expandedSection == 'split',
                      onToggle: _onToggleSection,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      icon: Icons.splitscreen_rounded,
                      title: strings.settingsExtrasSplit,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            strings.extrasSplitBody,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<ExtrasSplitMode>(
                            segments: [
                              ButtonSegment(
                                value: ExtrasSplitMode.even,
                                label: Text(strings.splitModeEven),
                              ),
                              ButtonSegment(
                                value: ExtrasSplitMode.byValue,
                                label: Text(strings.splitModeByValue),
                              ),
                            ],
                            selected: {settings.extrasSplitMode},
                            onSelectionChanged: (s) {
                              AppHaptics.selectionClick();
                              AppSettings.instance.setExtrasSplitMode(
                                s.first,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Material(
                            color: Colors.transparent,
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(strings.roundTotalsLabel),
                              subtitle: Text(strings.roundTotalsBody),
                              value: settings.roundTotals,
                              onChanged: (v) {
                                AppHaptics.selectionClick();
                                AppSettings.instance.setRoundTotals(v);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CollapsibleCard(
                      sectionId: 'help',
                      isExpanded: _expandedSection == 'help',
                      onToggle: _onToggleSection,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      icon: Icons.help_outline_rounded,
                      title: strings.settingsHelp,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            strings.howToIntro,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _StepRow(
                            number: 1,
                            icon: Icons.people_outline_rounded,
                            title: strings.howToStep1Title,
                            body: strings.howToStep1Body,
                          ),
                          const SizedBox(height: 12),
                          _StepRow(
                            number: 2,
                            icon: Icons.restaurant_menu_outlined,
                            title: strings.howToStep2Title,
                            body: strings.howToStep2Body,
                          ),
                          const SizedBox(height: 12),
                          _StepRow(
                            number: 3,
                            icon: Icons.summarize_outlined,
                            title: strings.howToStep3Title,
                            body: strings.howToStep3Body,
                          ),
                          const SizedBox(height: 12),
                          _StepRow(
                            number: 4,
                            icon: Icons.share_outlined,
                            title: strings.howToStep4Title,
                            body: strings.howToStep4Body,
                          ),
                          const Divider(height: 32),
                          Row(
                            children: [
                              Icon(
                                Icons.help_center_outlined,
                                size: 20,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                strings.faqTitle,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _FaqRow(
                            question: strings.faqOwnPhones,
                            answer: strings.faqOwnPhonesBody,
                          ),
                          const SizedBox(height: 14),
                          _FaqRow(
                            question: strings.faqAccount,
                            answer: strings.faqAccountBody,
                          ),
                          const SizedBox(height: 14),
                          _FaqRow(
                            question: strings.faqSplit,
                            answer: strings.faqSplitBody,
                          ),
                          const SizedBox(height: 14),
                          _FaqRow(
                            question: strings.faqBundles,
                            answer: strings.faqBundlesBody,
                          ),
                          const SizedBox(height: 14),
                          _FaqRow(
                            question: strings.faqPrivacy,
                            answer: strings.faqPrivacyBody,
                          ),
                          const SizedBox(height: 14),
                          _FaqRow(
                            question: strings.faqSwipeTitle,
                            answer: strings.faqSwipeBody,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CollapsibleCard(
                      sectionId: 'support',
                      isExpanded: _expandedSection == 'support',
                      onToggle: _onToggleSection,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      icon: Icons.favorite_outline_rounded,
                      title: strings.supportUs,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            strings.supportUsBody,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () => _launchUrl(
                              'https://ko-fi.com/i1988',
                            ),
                            icon: const Icon(Icons.coffee_outlined),
                            label: Text(strings.supportKofi),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => _launchUrl(
                              'https://ipn.eg/S/i.juma1988/instapay/4Fjcw3',
                            ),
                            icon: const Icon(
                                Icons.account_balance_wallet_outlined),
                            label: Text(strings.supportInstapay),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CollapsibleCard(
                      sectionId: 'privacy',
                      isExpanded: _expandedSection == 'privacy',
                      onToggle: _onToggleSection,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      icon: Icons.shield_outlined,
                      title: strings.settingsPrivacy,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            strings.settingsPrivacyBody,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              AppHaptics.selectionClick();
                              Navigator.pushNamed(context, PrivacyPage.route);
                            },
                            icon: const Icon(Icons.policy_outlined),
                            label: Text(strings.privacyReadFull),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CollapsibleCard(
                      sectionId: 'contact',
                      isExpanded: _expandedSection == 'contact',
                      onToggle: _onToggleSection,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      icon: Icons.mail_outline_rounded,
                      title: strings.contactSupport,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _emailSupport,
                              onLongPress: _copySupportEmail,
                              icon: const Icon(Icons.mail_outline_rounded),
                              label: Text(strings.contactSupport),
                            ),
                          ),
                          IconButton(
                            onPressed: _copySupportEmail,
                            icon: const Icon(Icons.copy_rounded),
                            tooltip: strings.copiedToast,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CollapsibleCard(
                      sectionId: 'about',
                      isExpanded: _expandedSection == 'about',
                      onToggle: _onToggleSection,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      icon: Icons.info_outline_rounded,
                      title: strings.settingsAbout,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    'CB',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: scheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppTheme.brandName,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    strings.brandTagline,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Version ${AppValues.appVersion}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.new_releases_rounded,
                                color: scheme.primary,
                              ),
                              title: Text(
                                strings.whatsNewTitle,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text('v${AppValues.appVersion}'),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: scheme.onSurfaceVariant,
                              ),
                              onTap: () {
                                AppHaptics.selectionClick();
                                Navigator.pushNamed(
                                  context,
                                  ChangelogPage.route,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _clearCustom,
                            icon: const Icon(Icons.person_off_outlined),
                            label: Text(strings.clearCustomRoster),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CollapsibleCard(
                      sectionId: 'licenses',
                      isExpanded: _expandedSection == 'licenses',
                      onToggle: _onToggleSection,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      icon: Icons.description_outlined,
                      title: 'Open source licenses',
                      child: TextButton.icon(
                        onPressed: () => showLicensePage(context: context),
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Open source licenses'),
                      ),
                    ),
                    const SizedBox(height: 24),
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

/// A collapsible card matching SectionCard styling.
/// Expansion is fully controlled by the parent via [isExpanded] / [onToggle]
/// so one tap opens a card and closes the others in the same frame.
class _CollapsibleCard extends StatelessWidget {
  const _CollapsibleCard({
    required this.sectionId,
    required this.isExpanded,
    required this.onToggle,
    required this.title,
    required this.child,
    this.icon,
    this.margin,
  });

  final String sectionId;
  final bool isExpanded;
  final void Function(String id, bool expanding) onToggle;
  final String title;
  final Widget child;
  final IconData? icon;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: AppTheme.softShadow(theme.brightness),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => onToggle(sectionId, !isExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: scheme.primary),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: AppValues.animFast,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: AppValues.animNormal,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: child,
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}

/// A numbered step with icon, title, and body text for the how-to guide.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  final int number;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A question/answer pair inside the Help card.
class _FaqRow extends StatelessWidget {
  const _FaqRow({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            question,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled list used inside the Log card (Done / Doing / Planned).
/// One row of the Friend icons picker — sample mark + label + check.
class _IconStyleRow extends StatelessWidget {
  const _IconStyleRow({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final FriendIconStyle style;
  final bool selected;
  final VoidCallback onTap;

  static final Person _sample = Person(
    id: 'sample',
    name: 'Ahmed',
    emoji: '🙂',
    colorValue: 0xFF4D96FF,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mark = friendIconMark(_sample, style, 0);
    final isEmoji = friendUsesEmoji(_sample, style);

    return Semantics(
      selected: selected,
      button: true,
      label: Translate.instance.friendIconStyleLabel(style),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: _sample.color.withValues(alpha: 0.25),
                child: Text(
                  mark,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: isEmoji ? 14 : 10,
                    color: isEmoji ? null : _sample.color,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  Translate.instance.friendIconStyleLabel(style),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: scheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple row: current color + name → opens theme list.
class _ColorThemeCard extends StatelessWidget {
  const _ColorThemeCard({
    required this.selected,
    required this.name,
    required this.onTap,
  });

  final ColorPalette selected;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: '${strings.settingsColors}: $name',
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppValues.minTouch),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  _PaletteDot(palette: selected, size: 40),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const strings = Translate();
}

class _PaletteDot extends StatelessWidget {
  const _PaletteDot({required this.palette, required this.size});

  final ColorPalette palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.seed, palette.accent],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          width: 2,
        ),
      ),
    );
  }
}
