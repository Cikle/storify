# Storify

A Flutter inventory app with barcode scanning, backed by a self-hosted PHP REST API on a MySQL database.

## Features

- Inventory management — add, edit, delete items with category, location, barcode, and expiry date
- Barcode scanner — scan to look up or create items instantly
- Stock control — +/− buttons inline and on the detail screen
- Item transfer — move stock between locations (full or partial)
- Low-stock alerts — local push notifications when stock drops below threshold
- Expiry tracking — banners and dashboard cards for expiring/expired items
- Offline-first — cached data shown immediately, writes queued and synced on reconnect
- Multi-account — switch between multiple API backends
- Export — CSV and PDF inventory reports
- Import — restock via CSV upload
- Dark theme, English/German localization

## Stack

| Layer | Tech |
|---|---|
| App | Flutter (Dart) |
| State | Provider |
| Backend | PHP 8.x REST API |
| Database | MySQL (InnoDB), hosted on Plesk |
| Auth | Static API key (`X-Api-Key` header) |

## Setup

### Backend

1. Upload `php_api/` to your web server
2. Copy `php_api/config/db.php.example` → `php_api/config/db.php` and fill in credentials
3. Run `php_api/database/schema.sql` on your MySQL database
4. Set a strong random `API_KEY` in `db.php`

### App

```bash
cd storify
flutter pub get
flutter run
```

On first launch, enter your API base URL and key in the setup screen.

## Build

```bash
flutter build apk --release   # Android
flutter build ipa              # iOS (requires Mac + Xcode)
```

## Project structure

```
php_api/          PHP REST API
  config/         DB connection + API key
  helpers/        Response helpers
  items/          /items endpoints
  locations/      /locations endpoints
  database/       schema.sql

storify/          Flutter app
  lib/
    models/       Item, Location, AppAccount
    providers/    ItemProvider, LocationProvider
    screens/      All screens
    services/     API, sync, export, import, notifications
    widgets/      BarcodeMatchSheet
    l10n/         Localizations (en, de)
    utils/        Constants, theme colors
```

## License

MIT
