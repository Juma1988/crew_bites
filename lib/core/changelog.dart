import 'package:flutter/material.dart';
import 'services/shared_preferences_service.dart';
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
      version: '1.0.7',
      notesEn: [
        'Redesigned Add-ons as a scrollable list — all 4 sections visible at once · K. Ali',
        'Tip now uses a slider with %/fixed toggle, just like Service & Tax · K. Ali',
        'Delivery: inline custom input replaces the 4th chip · K. Ali',
        'Settings reorganized into grouped sections · K. Ali',
        'Person card ⓘ shows a per-item extras breakdown · K. Ali',
        'Add-ons (VAT, Service, Delivery) now carry over when switching bundles · K. Ali',
        'Tip preview always visible · K. Ali',
      ],
      notesAr: [
        'إعادة تصميم الإضافات كقائمة — كل الأقسام ظاهرة مرة واحدة · K. Ali',
        'البقشيش: شريط تحكم مع تبديل نسبة/مبلغ، مثل الخدمة والضريبة · K. Ali',
        'التوصيل: حقل إدخال مخصص بدل الشريحة الرابعة · K. Ali',
        'الإعدادات: تنظيم في مجموعات · K. Ali',
        'بطاقة الشخص ⓘ تعرض تفاصيل الإضافات · K. Ali',
        'الإضافات (الضريبة، الخدمة، التوصيل) تنتقل مع تبديل البندل · K. Ali',
        'معاينة البقشيش ظاهرة دائماً · K. Ali',
      ],
    ),
    ChangelogEntry(
      version: '1.0.6',
      notesEn: [
        'Fixed a crash when opening the add-ons dialog',
        'Redesigned add-ons with a 2×2 grid layout and icons · K. Ali',
        'Service & Tax now default to 12% and 14% — switch between % and fixed amount · K. Ali',
        'Tip: quick-select chips for 5%, 10%, or 15% · K. Ali',
        'Delivery: quick-select chips for 0, 15, or 25 · K. Ali',
        'Tap any add-on to edit it directly — no extra icon needed · K. Ali',
        'Add-ons (VAT, Service, Delivery) now save with your bundles · K. Ali',
        'What\'s New moved to its own card at the bottom of Settings',
      ],
      notesAr: [
        'إصلاح خطأ عند فتح شاشة الإضافات',
        'تصميم جديد للإضافات: شبكة ٢×٢ بأيقونات · K. Ali',
        'الخدمة والضريبة: ١٢٪ و ١٤٪ افتراضي — التبديل بين النسبة والمبلغ · K. Ali',
        'البقشيش: أزرار سريعة (٥٪، ١٠٪، ١٥٪) · K. Ali',
        'التوصيل: أزرار سريعة (٠، ١٥، ٢٥) · K. Ali',
        'اضغط على أي إضافة لتعديلها مباشرة · K. Ali',
        'الإضافات (الضريبة، الخدمة، التوصيل) تُحفظ مع البندل · K. Ali',
        'نقل "ايه الجديد" لبطاقة منفصلة أسفل الإعدادات',
      ],
    ),
    ChangelogEntry(
      version: '1.0.5',
      notesEn: [
        'Split tip & delivery: equal shares or by order value · K. Ali',
        'Round shares to whole numbers · K. Ali',
        'Tip as a % of your food subtotal · K. Ali',
        'Keep-unfavorited-friends reminder · E. Hossam',
        'Tap the empty "Nobody yet" card to add your first friend · K. Ali',
      ],
      notesAr: [
        'قسمة البقشيش والتوصيل: بالتساوي أو حسب قيمة الطلب · K. Ali',
        'قرّب النصيب للأرقام الصحيحة · K. Ali',
        'بقشيش بنسبة % من قيمة الأكل · K. Ali',
        'تذكير بالاحتفاظ بأصحابك غير المفضلين · E. Hossam',
        'دوس على "لسه مفيش حد" عشان تضيف أول صاحب · K. Ali',
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
  final prefs = await SharedPreferencesService.instance.get();
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
