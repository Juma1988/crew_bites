import 'package:flutter/material.dart';

import 'friend_icon_style.dart';
import 'states/app_settings.dart';

/// EN + **Egyptian Arabic** (simple spoken AR) for Crew Bites.
/// Locale from [AppSettings].
class Translate {
  const Translate();

  static const instance = Translate();

  bool get isAr => AppSettings.instance.isArabic;

  Locale get locale => AppSettings.instance.locale;

  TextDirection get textDirection => AppSettings.instance.textDirection;

  String _tr(String en, String ar) => isAr ? ar : en;

  // ── App ─────────────────────────────────────────────────────────────

  String get appTitle => 'Crew Bites';

  String get brandTagline =>
      _tr('Everyone knows their food 🍕', 'كل واحد عارف أكله 🍕');

  // ── Home ────────────────────────────────────────────────────────────

  String get homeGreeting => _tr('Hi there 👋', 'أهلاً 👋');

  String get homeHeadline => _tr('Who’s eating?', 'مين هياكل؟');

  String get homeEmptyTitle => _tr('No order yet', 'لسه مفيش طلب');

  String get homeEmptyBody =>
      _tr('Tap the big button… and start!', 'دوس الزر الكبير… وابدأ!');

  String get activeOrderBadge => _tr('Still going', 'لسه شغال');

  String get resumeCta => _tr('Continue', 'كمّل');

  String get startFreshCta => _tr('New order', 'طلب جديد');

  String get viewSummary => _tr('See orders', 'شوف الطلبات');

  String get historyPeekTitle => _tr('History', 'السجل');

  String historySlotCount(int count, int max) =>
      _tr('$count/$max', '$count/$max');

  String get orderAgainCta => _tr('Order again', 'اطلب تاني');

  String get pastOrderTitle => _tr('Past order', 'طلب قديم');

  String get prefsCorruptToast => _tr(
        'Some saved data looked broken. We started clean.',
        'في حاجة باظت في الحفظ. بدأنا من الأول.',
      );

  String get quickActions => _tr('More', 'كمان');

  String get currentOrder => _tr('This order', 'الطلب ده');

  String get history => _tr('Past orders', 'الطلبات القديمة');

  String get historyEmpty =>
      _tr('No past orders yet.', 'لسه مفيش طلبات قديمة.');

  String get noPeopleYet => _tr('Nobody yet', 'لسه مفيش حد');

  String get noPeopleHint =>
      _tr('Tap + and type a friend’s name.', 'دوس + واكتب اسم صاحبك.');

  String get addPerson => _tr('Add friend', 'ضيف صاحبك');

  String get addPersonTitle => _tr('New friend', 'صاحب جديد');

  String get addPersonHint => _tr('Type the name.', 'اكتب الاسم.');

  String get personNameHint => _tr('e.g. Alex', 'مثال: أحمد');

  String get nameRequired => _tr('Type a name', 'اكتب اسم');

  String get nameAlreadyExists => _tr('Name already exists', 'الاسم موجود قبل كده');

  String get pickCrewTitle => _tr('Who’s with you?', 'مين معاك؟');

  String get pickCrewSubtitle => _tr(
        'Tap a name. + for a new friend. Swipe for favorite or delete.',
        'دوس على الاسم. + لصاحب جديد. اسحب للمفضلة أو المسح.',
      );

  String get selectedCount => _tr('Selected', 'المختارين');

  String get continueToOrders => _tr('Next… food', 'يلا… الأكل');

  String get selectAtLeastOne =>
      _tr('Pick at least one', 'اختار واحد على الأقل');

  String maxCrewRosterReached(int max) => _tr(
        'Max $max friends in the list',
        'أقصى حاجة $max أصحاب في الليستة',
      );

  String maxCrewSelectedReached(int max) => _tr(
        'Max $max friends on this order',
        'أقصى حاجة $max أصحاب في الطلب ده',
      );

  String get personColor => _tr('Color', 'اللون');

  String get shuffleAvatarHint =>
      _tr('Tap face to shuffle 🎲', 'دوس على الوش عشان تغيّره 🎲');

  String get tapToChangeAvatar =>
      _tr('Tap to change avatar', 'اختر إيموجي');

  String get renamePerson => _tr('Rename', 'غيّر الاسم');

  String get deletePersonConfirm =>
      _tr('Remove this name?', 'نشيل الاسم ده؟');

  String get delete => _tr('Delete', 'امسح');

  String get cannotDeleteDefault =>
      _tr('Can’t delete — just unselect.', 'مش هيتنمسح — سيبه من غير تحديد.');

  /// Physical directions: LTR left=delete; RTL right=delete (end-to-start).
  String get longPressHint => isAr
      ? 'اسحب يمين = امسح · شمال = مفضلة'
      : 'Swipe left = delete · right = favorite';

  String get swipeDelete => _tr('Delete', 'امسح');

  String get swipeFavorite => _tr('Favorite', 'مفضلة');

  String get undo => _tr('Undo', 'رجّع');

  String personRemovedToast(String name) =>
      _tr('$name removed', 'اتشال $name');

  String get peopleSwipeHint => _tr(
        'Swipe a name: ⭐ favorite · 🗑️ delete (you can undo)',
        'اسحب الاسم: ⭐ مفضلة · 🗑️ مسح (تقدر ترجّع)',
      );

  String get peopleSwipeHintGotIt => _tr('Got it', 'ماشي');

  String get addedToFavorites =>
      _tr('Added to favorites ⭐', 'اتحط في المفضلة ⭐');

  String get removedFromFavorites =>
      _tr('Removed from favorites', 'اتشال من المفضلة');

  String get addItem => _tr('Add food', 'ضيف أكل');

  String get editItem => _tr('Edit food', 'عدّل الأكل');

  String get itemRequired => _tr('What food?', 'إيه الأكل؟');

  String get itemNote => _tr('Note (optional)', 'ملاحظة (اختياري)');

  String get ordersTitle => _tr('Who ordered what?', 'مين طلب إيه؟');

  String get ordersSubtitle => _tr(
        'Pick a friend, then tap food. Tap again for more.',
        'اختار صاحبك، بعدين دوس على الأكل. دوس تاني عشان تزود.',
      );

  String get longPressRemoveHint => _tr(
        'Swipe: undo one, or remove empty food',
        'اسحب: رجّع واحد، أو شيل أكل فاضي',
      );

  String get swipeUndoFood => _tr('Undo', 'رجّع');

  String get swipeRemoveFood => _tr('Remove', 'شيل');

  // ── Restaurant bundles ────────────────────────────────────────────

  String get bundlesLabel => _tr('Bundles', 'الباقات');

  String get placeLabel => bundlesLabel;

  String get pickPlace => _tr('Pick a bundle', 'اختار باقة');

  String get freeformPlace => _tr('Freeform', 'حر');

  String get freeformPlaceHint =>
      _tr('No bundle — add foods yourself', 'من غير باقة — ضيف الأكل بنفسك');

  String get switchPlaceTitle => _tr('Switch bundle?', 'نغيّر الباقة؟');

  String get switchPlaceBody => _tr(
        'Foods on this order will be cleared. Friends stay.',
        'الأكل هيروح. الأصحاب هيفضلوا.',
      );

  String bundleItemsAdded(String bundleName, int count) => _tr(
        'Added $count from $bundleName',
        'ضفنا $count من $bundleName',
      );

  String get bundleItemsAlreadyAdded =>
      _tr('Those items are already on the list', 'الأكل ده موجود أصلاً في الليستة');

  String get addBundle => _tr('New bundle', 'باقة جديدة');

  String get addBundleHint => _tr('Bundle name', 'اسم الباقة');

  String get addBundleNameHint => _tr('e.g. My place', 'مثال: مكاني');

  String editBundleTitle(String name) =>
      _tr('Edit $name', 'عدّل $name');

  String get editBundleHint =>
      _tr('Items this pill adds to the food list', 'الأكل اللي الباقة بتنزّله في الليستة');

  String get bundleItemEmpty =>
      _tr('No items yet — add some below', 'لسه مفيش أكل — ضيف من تحت');

  String get longPressEditBundle => _tr(
        'Tap a bundle to load foods. Long-press to edit its list. + for a new one.',
        'دوس باقة تنزل الأكل. اضغط مطول تعدّل الليستة. + باقة جديدة.',
      );

  String get deleteBundle => _tr('Delete bundle', 'امسح الباقة');

  String get done => _tr('Done', 'خلاص');

  String get removeFoodFromMenu =>
      _tr('Remove from menu?', 'نشيله من المنيو؟');

  String get removeFoodFromMenuBody => _tr(
        'This food leaves the place list. You can add it again later.',
        'الأكل هيخرج من قائمة المكان. تقدر تضيفه تاني بعدين.',
      );

  String get foodRemovedToast => _tr('Removed from menu', 'اتشال من المنيو');

  String get manageMenuHint => _tr(
        'Long-press a food to remove it from the menu',
        'اضغط مطول على أكل عشان تشيله من المنيو',
      );

  String assignFoodsTitle(String name) =>
      _tr('What does $name want?', 'إيه اللي $name عايزه؟');

  String get assignFoodsHint =>
      _tr('Tap the food… then Add.', 'دوس على الأكل… بعدين ضيف.');

  String get addMarkedFoods => _tr('Add', 'ضيف');

  String get pickFoodsFirst =>
      _tr('Mark at least one food', 'علّم أكل واحد على الأقل');

  String get selectPersonFirst =>
      _tr('Pick a person first', 'اختار حد الأول');

  String get crewColumn => _tr('Friends', 'الأصحاب');

  String get foodColumn => _tr('Food', 'الأكل');

  String get addFoodMenu => _tr('New food', 'أكل جديد');

  String get foodName => _tr('Food name', 'اسم الأكل');

  String get foodNameHint => _tr('e.g. Pizza', 'مثال: بيتزا');

  String get tapToAssign => _tr('Tap to add', 'دوس عشان تضيف');

  String get noCrewOnOrder =>
      _tr('Nobody here. Go pick friends.', 'مفيش حد. ارجع اختار أصحابك.');

  String get goPickCrew => _tr('Pick friends', 'اختار الأصحاب');

  String get continueToSummary => _tr('Next… summary', 'يلا… الملخص');

  String get addAtLeastOneItem =>
      _tr('Add at least one food', 'ضيف أكلة واحدة على الأقل');

  String get missingPricesTitle =>
      _tr('Missing prices', 'في أسعار ناقصة');

  String get missingPricesBody => _tr(
        'Some foods still need a price. Fill them in, or mark “I don’t know”.',
        'في أكل من غير سعر. اكتب السعر، أو علّم «مش عارف».',
      );

  String get priceUnknownCheckbox =>
      _tr('I don’t know the price', 'مش عارف السعر');

  String get missingPricesContinue =>
      _tr('Save prices & continue', 'احفظ الأسعار وكمّل');

  String get missingPricesInvalid =>
      _tr('Enter a price, or check “I don’t know”', 'اكتب سعر، أو علّم «مش عارف»');

  String get emptyOrder => _tr('No food yet.', 'لسه مفيش أكل.');

  String get loading => _tr('Loading…', '…جاري التحميل');

  String get welcomeBackTitle => _tr('You have an order!', 'عندكوا طلب!');

  String get cancel => _tr('No', 'لا');

  String get goBack => _tr('Go back', 'ارجع');

  String get confirm => _tr('Yes', 'أيوه');

  String get continueLabel => _tr('Continue', 'كمّل');

  String get save => _tr('Save', 'احفظ');

  String get personName => _tr('Name', 'الاسم');

  String get personEmoji => _tr('Emoji', 'إيموجي');

  String get itemName => _tr('What food?', 'إيه الأكل؟');

  String get itemQty => _tr('How many?', 'كام؟');

  String get deletePerson => _tr('Delete', 'امسح');

  String get restoreFromHistory => _tr('Use this', 'استخدم ده');

  String orderedOn(String date) => _tr('On $date', 'يوم $date');

  String peopleItemsSummary(int people, int items) => _tr(
        '$people friends · $items foods',
        '$people أصحاب · $items أكل',
      );

  // ── Output & history ────────────────────────────────────────────────

  String get summaryTitle => _tr('Here’s the list', 'أهي الليستة');

  String get orderItemsTitle => _tr('Whole order', 'الطلب كله');

  String get orderItemsSubtitle =>
      _tr('Each food and how many', 'كل أكلة وكم واحدة');

  String get whoOrderedTitle => _tr('Who ordered what', 'مين طلب إيه');

  String foodUnitsLine(String food, int qty, {double? unitPrice}) {
    final title = foodTitle(food);
    if (unitPrice != null && unitPrice > 0) {
      return '$qty | ${foodWithPrice(title, unitPrice)}';
    }
    return '$qty | $title';
  }

  String unitsOnly(int qty) => _tr('$qty', '$qty');

  String eachUnitPrice(double unitPrice) =>
      _tr('${money(unitPrice)} each', '${money(unitPrice)} للواحدة');

  String get createBundleCta => _tr('Create bundle', 'اعمل باقة');

  String get updateBundleCta => _tr('Update bundle', 'حدّث الباقة');

  String get buildBundleTitle => _tr('Name this bundle', 'سمّي الباقة');

  String get buildBundleHint => _tr('Bundle name', 'اسم الباقة');

  String get buildBundleNameHint =>
      _tr('e.g. Friday dinner', 'مثال: عشا الجمعة');

  String get buildBundleEmptyFoods =>
      _tr('Add some food first', 'ضيف أكل الأول');

  String get buildBundleCreated =>
      _tr('Bundle saved ✓', 'الباقة اتخزنت ✓');

  String updateBundleTitle(String name) =>
      _tr('Update “$name”?', 'نعدّل «$name»؟');

  String updateBundleBody(int missingCount) => _tr(
        'This name already exists. Add $missingCount new food(s) from this order?',
        'الاسم موجود. نضيف $missingCount أكل جديد من الطلب ده؟',
      );

  String get updateBundleConfirm => _tr('Add missing foods', 'ضيف اللي ناقص');

  String get updateBundleNothingNew =>
      _tr('That bundle already has all these foods', 'الباقة فيها كل الأكل ده');

  String get buildBundleUpdated =>
      _tr('Bundle updated ✓', 'الباقة اتعدّلت ✓');

  String get shareSummary => _tr('Share', 'شارك');

  String get tipLabel => _tr('Tip', 'بقشيش');

  String get deliveryLabel => _tr('Delivery', 'توصيل');

  String get tipHint => _tr('0 if none', '٠ لو مفيش');

  String get deliveryHint => _tr('0 if none', '٠ لو مفيش');

  String get extrasSectionTitle =>
      _tr('Services', 'الخدمات');

  String get extrasSectionSubtitle => _tr(
        'Optional. Split across people who ordered (by food total).',
        'اختياري. يتقسم على اللي طلبوا (حسب أكلهم).',
      );

  String get extrasShareHint => _tr(
        'your share',
        'نصيبك',
      );

  String get extrasEmptyDialogTitle => _tr(
        'No services yet',
        'مفيش خدمات',
      );

  String get extrasEmptyDialogMessage => _tr(
        'You didn\'t add a tip or delivery fee. Continue anyway?',
        'مضفتش بقشيش أو توصيل. نكمل برضو؟',
      );

  String get addNow => _tr('Add now', 'ضيف دلوقتي');

  String get tipDeliveryDialogTitle =>
      _tr('Tip & delivery?', 'بقشيش وتوصيل؟');

  String get tipDeliveryDialogBody => _tr(
        'Optional before the summary. Leave empty or skip if none.',
        'اختياري قبل الملخص. سيبه فاضي أو عدّي لو مفيش.',
      );

  String get tipDeliverySkip => _tr('Skip', 'عدّي');

  String get tipDeliveryContinue => _tr('To summary', 'للملخص');

  String get extrasTapToEdit =>
      _tr('Tap to change', 'دوس عشان تعدّل');

  String get foodSubtotalLabel =>
      _tr('Food', 'الأكل');

  String grandTotalLabel(double amount) =>
      _tr('Grand total ${money(amount)}', 'الإجمالي ${money(amount)}');

  String get copiedToast => _tr('Copied ✓', 'اتنسخ ✓');

  String get finishOrder => _tr('Done & save', 'خلص واحفظ');

  String get savedDone => _tr('Saved ✓', 'تم الحفظ ✓');

  String get noActiveOrder =>
      _tr('No order. Go back home.', 'مفيش طلب. ارجع للرئيسية.');

  String get goHome => _tr('Home', 'الرئيسية');

  String get historySection => _tr('Past (last 3)', 'القديم (آخر ٣)');

  String get usePeopleOnly =>
      _tr('Same people (no food)', 'نفس الناس (من غير أكل)');

  String get useFullOrder => _tr('Same full order', 'نفس الطلب كله');

  // ── Settings ────────────────────────────────────────────────────────

  String get settingsTitle => _tr('Settings', 'الإعدادات');

  String get settingsTheme => _tr('Theme', 'المظهر');

  String get pricesLabel => _tr('Prices', 'الأسعار');

  String get pricesOnHint => _tr('Prices on', 'الأسعار شغالة');

  String get pricesOffHint => _tr('Prices off', 'الأسعار مقفولة');

  String get priceLabel => _tr('Price', 'السعر');

  String get priceHint => _tr('0', '0');

  String get currencySuffix {
    final code = AppSettings.instance.currencyCode;
    return switch (code) {
      'USD' => _tr('\$', '\$'),
      'SAR' => _tr('SAR', 'ر.س'),
      'EUR' => _tr('€', '€'),
      _ => _tr('le', 'ج.م'),
    };
  }

  String currencyLabel(String code) => switch (code) {
        'USD' => _tr('US Dollar (\$)', 'دولار (\$)'),
        'SAR' => _tr('Saudi Riyal', 'ريال سعودي'),
        'EUR' => _tr('Euro (€)', 'يورو (€)'),
        _ => _tr('Egyptian Pound (le)', 'جنيه مصري (ج.م)'),
      };

  String get settingsCurrency => _tr('Currency', 'العملة');

  String get settingsFriendIcons =>
      _tr('Friend icons', 'أيقونات الأصدقاء');

  String get friendIconStyleBody => _tr(
        'Choose how friends appear on food rows, Home, history and share.',
        'اختار شكل ظهور الأصدقاء في قوائم الأكل والرئيسية والسجل والمشاركة.',
      );

  String friendIconStyleLabel(FriendIconStyle style) => switch (style) {
        FriendIconStyle.emoji => _tr('Emoji', 'إيموجي'),
        FriendIconStyle.roman => _tr('Roman numeral', 'رقم روماني'),
        FriendIconStyle.firstLetter => _tr('First letter', 'أول حرف'),
        FriendIconStyle.firstTwo => _tr('First two letters', 'أول حرفين'),
      };

  String formatAmount(double price) {
    if (price == price.roundToDouble()) return price.round().toString();
    return price.toStringAsFixed(2);
  }

  String money(double price, {bool hideZero = false}) {
    if (hideZero && price <= 0) return '';
    return '${formatAmount(price)} $currencySuffix';
  }

  String foodWithPrice(String title, double price) {
    if (price <= 0) return title;
    return '$title • ${money(price)}';
  }

  String get mixedBundleName => _tr('Mixed', 'مختلط');

  String get settingsPrivacy => _tr('Privacy', 'الخصوصية');

  String get settingsPrivacyBody => _tr(
        'Orders stay on this phone only. We don’t upload your names or food.',
        'الطلبات بتفضل على الموبايل ده بس. مش بنرفع أساميكم ولا الأكل.',
      );

  String get privacyReadFull =>
      _tr('Read full privacy policy', 'اقرأ سياسة الخصوصية كاملة');

  String get contactSupport => _tr('Contact support', 'تواصل مع الدعم');

  String get settingsHelp => _tr('Help', 'مساعدة');

  String get howToIntro => _tr(
        'How Crew Bites works in 4 steps:',
        'إزاي Crew Bites تشتغل في ٤ خطوات:',
      );

  String get howToStep1Title => _tr('Pick friends', 'اختار الأصحاب');

  String get howToStep1Body => _tr(
        'Tap names to select who’s eating. Add new friends with +. Swipe to favorite or delete.',
        'دوس على الأسماء عشان تختار مين هياكل. ضيف أصحاب جُدد بـ +. اسحب للمفضلة أو المسح.',
      );

  String get howToStep2Title => _tr('Choose food', 'اختار الأكل');

  String get howToStep2Body => _tr(
        'Pick a bundle or go freeform. Tap a friend then tap food to assign. Turn on Prices if needed.',
        'اختار باقة أو ابدأ من الصفر. دوس على صاحبك بعدين على الأكل عشان تخصصه. شغّل الأسعار لو عايز.',
      );

  String get howToStep3Title => _tr('Review summary', 'شوف الملخص');

  String get howToStep3Body => _tr(
        'See the full order and who ordered what. Add tip or delivery fee if sharing costs.',
        'شوف الطلب كله ومين طلب إيه. ضيف بقشيش أو توصيل لو هتقسموا.',
      );

  String get howToStep4Title => _tr('Share or save', 'شارك أو احفظ');

  String get howToStep4Body => _tr(
        'Copy or share the list as text, or save it to history. Build a bundle from any order.',
        'انسخ الليستة أو شاركها كنص، أو احفظها في السجل. اعمل باقة من أي طلب.',
      );

  // FAQ (Settings > Help)
  String get faqTitle => _tr('Quick answers', 'أسئلة سريعة');

  String get faqOwnPhones => _tr(
        'Can friends order from their own phones?',
        'أصحابي يقدروا يطلبوا من موبايلاتهم؟',
      );

  String get faqOwnPhonesBody => _tr(
        'Not yet — the order stays on one phone for now. Multi-device sharing is on the roadmap.',
        'لسه لأ — الطلب على موبايل واحد دلوقتي. المشاركة أونلاين في الخطة الجاية.',
      );

  String get faqAccount => _tr('Do I need an account?', 'أحتاج حساب؟');

  String get faqAccountBody => _tr(
        'No account, no sign-in. Everything is saved only on your phone.',
        'مفيش حساب ولا تسجيل. كل حاجة بتتحفظ على موبايلك بس.',
      );

  String get faqSplit => _tr('How does the bill split work?', 'تقسيم الحساب إزاي؟');

  String get faqSplitBody => _tr(
        'Each person pays their own food total, plus an equal share of tip and delivery.',
        'كل واحد بيدفع حساب أكله، بالضاف لنصيبه من البقشيش والتوصيل بالتساوي.',
      );

  String get faqBundles => _tr('What are bundles?', 'إيه هي الباقات؟');

  String get faqBundlesBody => _tr(
        'Saved menus you load fast. Tap a bundle to add its foods, or build your own from any order.',
        'منيو محفوظ بتفتحه بسرعة. دوس باقة عشان تنزل أكلها، أو اعمل اللي بتحبه من أي طلب.',
      );

  String get faqPrivacy => _tr('Is my data private?', 'بياناتي خصوصية؟');

  String get faqPrivacyBody => _tr(
        'Yes — names, orders and prices never leave your phone.',
        'أيوه — الأسامي والطلبات والأسعار مبتخرجش من موبايلك.',
      );

  String get whatsNewTitle => _tr("What's new", 'إيه الجديد');

  // ── Future features (roadmap card in Settings) ──────────────────────

  String get releaseNotesBody => _tr(
        '1.0.0 — First public release.\n'
        '• Group orders: friends → food → summary\n'
        '• Prices on/off, bundles, history (last 3)\n'
        '• Arabic + English, tips on first visit\n'
        '• Data stays on your phone',
        '1.0.0 — أول إصدار عام.\n'
        '• طلب جماعي: أصحاب → أكل → ملخص\n'
        '• أسعار، باقات، سجل (آخر ٣)\n'
        '• عربي + إنجليزي، تلميحات أول مرة\n'
        '• البيانات على الموبايل بس',
      );

  String get stepPeople => _tr('Friends', 'الأصحاب');
  String get stepFood => _tr('Food', 'الأكل');
  String get stepSummary => _tr('Summary', 'الملخص');

  String wizardStepLabel(int step, int total) =>
      _tr('Step $step of $total', 'خطوة $step من $total');

  String get selectBundleHint =>
      _tr('Tap a bundle to load its foods', 'دوس باقة عشان تنزل أكلها');

  String get activeBundleBadge => _tr('Active', 'المختارة');

  String get editFoodPriceTitle => _tr('Set price', 'حط السعر');

  String get longPressSetPrice =>
      _tr('Long-press or tap ✎ to set price', 'اضغط مطول أو ✎ عشان السعر');

  String get tapToSetPrice => _tr('Tap to set price', 'اضغط عشان تحط السعر');

  String personTotalLabel(double amount) =>
      _tr('Total ${money(amount)}', 'المجموع ${money(amount)}');

  String orderTotalLabel(double amount) =>
      _tr('Order total ${money(amount)}', 'إجمالي الطلب ${money(amount)}');

  String get themeSystem => _tr('Auto', 'تلقائي');

  String get themeLight => _tr('Light', 'فاتح');

  String get themeDark => _tr('Dark', 'غامق');

  String get settingsColors => _tr('Colors', 'الألوان');

  String get settingsColorsHint => _tr(
        'Pick a look for buttons and accents. Icons stay the same.',
        'اختار لون للأزرار والواجهة. الأيقونات زي ما هي.',
      );

  String get paletteCoral => _tr('Coral', 'مرجاني');

  String get paletteOcean => _tr('Ocean', 'محيطي');

  String get paletteGrape => _tr('Grape', 'عنبي');

  String get paletteMint => _tr('Mint', 'نعناعي');

  String get paletteSunset => _tr('Mango', 'مانجو');

  String paletteName(String id) => switch (id) {
        'ocean' => paletteOcean,
        'grape' => paletteGrape,
        'mint' => paletteMint,
        'sunset' => paletteSunset,
        _ => paletteCoral,
      };

  String paletteSelectedLabel(String name) =>
      _tr('$name selected', 'اتختار $name');

  String get settingsLanguage => _tr('Language', 'اللغة');

  String get languageEnglish => 'English';

  String get languageArabic => 'العربية';

  String get settingsAbout => _tr('About', 'عن التطبيق');

  String get clearCustomRoster =>
      _tr('Reset roster', 'إعادة تعيين القائمة');

  String get clearCustomRosterBody => _tr(
        'Resets to starter names (Alex/Sam/Jordan). Favorites are also cleared.',
        'يرجع الأسماء الأولية (أحمد/مريم/يوسف). المفضلة هتتمسح كمان.',
      );

  String get clearedToast => _tr('Cleared', 'اتمسح');

  String get emailOpenFailed => _tr(
        'Could not open email. Email address copied.',
        'مقدرناش نفتح الإيميل. نسخنا العنوان.',
      );

  String foodTitle(String raw) {
    final key = raw.toLowerCase().trim();
    return switch (key) {
      'extras' => extrasSectionTitle,
      'falafel' => _tr('Falafel', 'فلافل'),
      'foul' => _tr('Foul', 'فول'),
      'fries' => _tr('Fries', 'بطاطس'),
      'shawarma' => _tr('Shawarma', 'شاورما'),
      'garlic sauce' => _tr('Garlic sauce', 'ثومية'),
      'pizza' => _tr('Pizza', 'بيتزا'),
      'burger' => _tr('Burger', 'برجر'),
      'cola' => _tr('Cola', 'كولا'),
      'salad' => _tr('Salad', 'سلطة'),
      'potatoes' => _tr('Potatoes', 'بطاطس'),
      _ => raw,
    };
  }

  String get specialFoodHint => _tr(
        'Long-press to set amount',
        'اضغط مطول عشان تحط المبلغ',
      );
}
