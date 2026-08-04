/// Store / legal constants for Play Console + in-app Privacy.
/// App stays offline-first. [privacyPolicyUrl] is only for Play Console
/// if/when you publish — not required for normal offline use (in-app policy).
abstract final class LegalConfig {
  static const String supportEmail = 'i1988.support@gmail.com';

  /// Public URL for **Google Play Console** (not used by the offline app).
  /// REQUIRED before uploading to any Play Store track — host your privacy
  /// policy somewhere (GitHub Pages, Firebase Hosting, etc.) and set this.
  static const String privacyPolicyUrl = '';

  static const String dataSafetySummaryEn =
      'Crew Bites stores friend names, food orders, and optional prices only '
      'on your device. No account. No ads. No cloud upload of order data.';

  static const String packageId = 'com.i1988.crewbites';
  static const String developerName = 'i1988';
}
