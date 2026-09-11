# Optional crash reporting

Crew Bites remains offline and privacy-first by default. Crash reporting is
disabled unless a Sentry DSN is supplied at build/run time with a Dart define.
No DSN or secret is stored in this repository.

```bash
flutter run --dart-define=SENTRY_DSN=https://<public-key>@sentry.io/<project-id>
flutter build apk --dart-define=SENTRY_DSN=https://<public-key>@sentry.io/<project-id>
```

When configured, uncaught Flutter framework errors and uncaught zone errors
are sent to Sentry. Default PII collection is disabled. Do not put an auth
token or other private credential in the DSN value. To produce the normal
offline build, omit `SENTRY_DSN` entirely.
