import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'states/app_settings.dart';
import 'translate.dart';
import 'values/app_values.dart';

/// One release entry in the changelog: version + localized bullet notes.
class ChangelogEntry {
  const ChangelogEntry({
    required this.version,
    required this.notesEn,
    required this.notesAr,
  });

  final String version;
  final List<String> notesEn;
  final List<String> notesAr;

  List<String> notes(bool isArabic) => isArabic ? notesAr : notesEn;
}

/// Versioned release notes, newest first. Add a new entry at the top on
/// every release — the launch notice and the What's new page read it.
abstract final class Changelog {
  static const List<ChangelogEntry> entries = [
    ChangelogEntry(
      version: '1.0.5',
      notesEn: [
        'Split tip & delivery: equal shares or by order value (Settings)',
        'Round shares to whole numbers so the totals sum exactly',
        'Tip as a % of your food subtotal',
        'Keep-unfavorited-friends reminder when you start an order',
        'Tap the empty "Nobody yet" card to add your first friend',
        'What\'s new: versioned release notes, shown once per update',
      ],
      notesAr: [
        'قسمة البقشيش والتوصيل: بالتساوي أو حسب قيمة الطلب (الإعدادات)',
        'قرّب النصيب للأرقام الصحيحة عشان المجاميع تظبط',
        'بقشيش بنسبة % من قيمة الأكل',
        'تذكير بالاحتفاظ بأصحابك غير المفضلين قبل ما تبدأ الطلب',
        'دوس على "لسه مفيش حد" عشان تضيف أول صاحب',
        'إيه الجديد: سجل الإصدارات، بيظهر مرة واحدة بعد كل تحديث',
      ],
    ),
    ChangelogEntry(
      version: '1.0.3',
      notesEn: [
        'Support Us section (Ko-fi + InstaPay)',
        'Step-by-step onboarding and summary guide',
        'Fun food emojis and UI polish',
      ],
      notesAr: [
        'قسم ادعمنا (Ko-fi + InstaPay)',
        'شرح خطوة بخطوة للبداية والملخص',
        'إيموجي أكل وبوليش للشكل',
      ],
    ),
    ChangelogEntry(
      version: '1.0.0',
      notesEn: [
        'Group orders: friends → food → summary',
        'Prices on/off, bundles, history (last 3)',
        'Arabic + English, tips on first visit',
        'Data stays on your phone',
      ],
      notesAr: [
        'طلب جماعي: أصحاب → أكل → ملخص',
        'أسعار، باقات، سجل (آخر ٣)',
        'عربي + إنجليزي، تلميحات أول مرة',
        'البيانات على الموبايل بس',
      ],
    ),
  ];

  static ChangelogEntry? entryFor(String version) {
    for (final e in entries) {
      if (e.version == version) return e;
    }
    return null;
  }
}

/// Show the "What's new" sheet once per app version.
/// Fresh installs (onboarding not started) never see it.
Future<void> maybeShowWhatsNew(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final current = AppValues.appVersion;
  final lastSeen = prefs.getString(AppValues.prefsLastSeenChangelog);
  final freshInstall = !(prefs.getBool(AppValues.prefsOnboardingDone) ?? false);
  await prefs.setString(AppValues.prefsLastSeenChangelog, current);
  if (freshInstall || lastSeen == current || !context.mounted) return;
  final entry = Changelog.entryFor(current);
  if (entry == null || !context.mounted) return;
  await showWhatsNewSheet(context, entry);
}

/// Bottom sheet listing one release's notes, with a "Got it" button.
Future<void> showWhatsNewSheet(
  BuildContext context,
  ChangelogEntry entry,
) async {
  final t = Translate.instance;
  final notes = entry.notes(AppSettings.instance.isArabic);
  final scheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.new_releases_rounded, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${t.whatsNewTitle} • v${entry.version}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: textTheme.bodyMedium),
                    Expanded(
                      child: Text(
                        note,
                        style: textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.gotIt),
            ),
          ],
        ),
      ),
    ),
  );
}
