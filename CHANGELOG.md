# Changelog

All notable changes to Crew Bites will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.5] - 2026-08-08

### Added
- Debug overlay mode: shows the owning dart file name as a top-right chip on every page. Tap to copy the file path to clipboard — paste it straight into the agent to focus on that page.
- Debug mode toggle in Settings > About (persisted across sessions)

### Improved
- Delivery field moved above Tip — sets the bill the tip % scales from
- Tip % now scales from food + delivery (delivery added to the base)
- Tip amount and Tip % are mutually exclusive (one grays out the other)
- Removed tip suggestions (replaced by direct amount / % entry)
- "Services" renamed to "Tip & delivery" throughout
- Added Qatari Riyal (ر.ق); Saudi Riyal now shows the ﷼ sign
- `main.dart` cleaned up: routes, locales, navigator and bootstrap extracted

## [1.0.3] - 2026-08-05

### Added
- Support Us section (Ko-fi + InstaPay donation links)
- Step-by-step onboarding and summary guide
- Food emojis and UI polish

## [1.0.0] - 2026-07-29

### Added
- Group food ordering with friends
- Emoji + color friend avatars with favorites
- Restaurant bundles (Wemby, Abo Fars, custom)
- Price tracking with on/off toggle
- Order history (last 3 orders)
- Bilingual support (Arabic + English)
- Spotlight tips on first visit
- Extras (tip + delivery) as food list item
- PDF and text sharing
- Offline-first — no account, no ads, no cloud
