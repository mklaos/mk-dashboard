# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MK Restaurants Sales Intelligence System - A multi-component application for automated sales data consolidation and executive dashboard for MK Restaurants in Laos.

**Architecture:**
- **Parser** (Python): Extracts data from POS XLS reports (17 report types)
- **Agent** (Python): Windows tray application that watches for files and uploads data
- **Dashboard** (Flutter): Mobile/web PWA for executives to view sales analytics
- **Database** (Supabase): PostgreSQL backend with auto-generated REST API

## Common Development Commands

### Python Components (Parser & Agent)

```bash
# Setup (one-time)
python -m venv venv
venv/Scripts/activate  # Windows
pip install -r requirements.txt

# Run parser on sample data
python parser/parser_complete.py

# Run tray agent (Windows only)
python agent/tray_app.py

# Or use batch file
cd agent && run.bat

# Test parser module
python test_parser_standalone.py
```

### Flutter Mobile App

```bash
cd parser/mobile

# Install dependencies
flutter pub get

# Run in development
flutter run -d chrome      # Web browser
flutter run -d <device_id> # Physical device

# Build for production
flutter build apk --release           # Android APK
flutter build web --release           # Web PWA
flutter build web --release --wasm    # Web PWA with WASM optimization

# Deploy to Firebase hosting
firebase deploy --only hosting

# Run tests
flutter test
flutter test test/widget_test.dart --name="test name"

# Lint and fix
flutter analyze
flutter analyze --fix
```

## Code Architecture

### Directory Structure

```
mk/
├── backend/                  # Database & API configuration
│   ├── db/schema.sql        # PostgreSQL schema (17 tables, 5 views)
│   └── .env.example         # Environment template
│
├── parser/                  # XLS file parser (Python)
│   ├── parser_complete.py  # Main parser (761 lines)
│   ├── models.py           # Data models (ReportType enum, dataclasses)
│   └── mobile/             # Flutter dashboard app
│       ├── lib/
│       │   ├── main.dart   # App entry point
│       │   ├── screens/    # Dashboard screens
│       │   ├── services/   # Supabase integration
│       │   └── widgets/    # Reusable UI components
│       └── pubspec.yaml    # Dependencies & config
│
├── agent/                   # Windows tray application
│   ├── tray_app.py         # Main application
│   ├── uploader.py         # Supabase upload logic
│   ├── config.json         # Configuration
│   └── build_agent.bat     # Build script
│
├── data/
│   └── product_translations.json  # Thai → Lao/English translations
│
└── docs/                    # Project documentation
```

### Key Components

**1. Parser (parser/parser_complete.py)**
- Parses 17 types of XLS POS reports
- Extracts: daily sales, hourly breakdown, products, transactions, voids
- Outputs structured JSON to Supabase
- Uses pandas for XLS processing

**2. Agent (agent/tray_app.py)**
- Windows system tray application
- Watches `D:/mk/source` for new XLS files
- Auto-parses and uploads to Supabase
- Configurable sync times: 12:00, 15:00, 18:00, 23:30

**3. Flutter Dashboard (parser/mobile/)**
- PWA (Progressive Web App) deployed on Firebase
- Charts using `fl_chart` library
- State management with `provider`
- Connects to Supabase via `supabase_flutter`
- Supports Thai/Lao/English via translation JSON

**4. Database (backend/db/schema.sql)**
- Supabase PostgreSQL with Row Level Security (RLS)
- Core tables: `branches`, `daily_sales`, `hourly_sales`, `product_sales`, `transactions`, `void_log`
- Views for analytics: `v_today_summary`, `v_branch_performance`, `v_peak_hours`, `v_product_performance`, `v_void_summary`

## Configuration Files

### Python Environment
- `requirements.txt` - Python dependencies (pandas, pystray, supabase, etc.)
- `.env` - Supabase credentials (never commit)

### Flutter Environment
- `parser/mobile/.env` - Supabase URL and anon key
- `parser/mobile/pubspec.yaml` - Dependencies and app metadata
- `parser/mobile/firebase.json` - Firebase hosting configuration
- `parser/mobile/web/manifest.json` - PWA manifest

### Agent Configuration
- `agent/config.json`:
  ```json
  {
    "branch_code": "MK001",
    "watch_folder": "D:/mk/source",
    "sync_times": ["12:00", "15:00", "18:00", "23:30"],
    "auto_upload": true
  }
  ```

## Data Models

All data models are in `parser/models.py`:

- **ReportType** (Enum): 17 report types (DAILY_SALES, HOURLY_SALES, PRODUCT_SALES, etc.)
- **DailySales**: Daily summary with totals, counts, void info
- **HourlySales**: Hourly breakdown (11 hours: 10:00-21:00)
- **ProductSale**: Individual product sales with Thai/Lao/English names
- **Transaction**: Individual customer bills
- **VoidRecord**: Cancelled items tracking

## Supabase Integration

**Project Details:**
- URL: Configured in `.env` files
- Anon key: Client-side (Flutter) read access
- Service role key: Server-side (Python agent) full access

**API Usage:**
- Auto-generated REST API from PostgreSQL schema
- RLS policies for data security
- UUID primary keys for all tables

## Supported Report Types

The parser handles 17 XLS report types from POS system:

1. **Daily Sales** - Summary (1 record)
2. **Hourly Sales** - By hour breakdown (11 records)
3. **Table Details** - Individual bills (58 records)
4. **Table Summary** - By table type (2 records)
5. **Customer Breakdown** - Group sizes (14 records)
6. **Suki Items** - Ingredients (64 records)
7. **Suki Sets** - Set meals (24 records)
8. **Duck Items** - Duck menu (29 records)
9. **Dim Sum** - Appetizers (14 records)
10. **Beverages** - Drinks (7 records)
11. **Desserts** - Sweets (18 records)
12. **Voids** - Cancelled items (8 records)
13. **Receipts** - All receipts (54 records)
14. **VAT Summary** - Tax summary (1 record)
15. **VIP** - VIP sales (varies)
16. **Credit** - Credit card payments (varies)
17. **Kitchen Categories** - By kitchen (varies)

## Translation System

Thai product names are translated to Lao/English via `data/product_translations.json`:
- Key: Thai product name
- Values: Lao and English translations
- Always use Unicode Lao script (ພາສາລາວ), not Romanized

## Key Workflows

### Data Flow
1. POS generates XLS reports → saved to watch folder
2. Agent detects new files → triggers parser
3. Parser extracts data → converts to structured format
4. Agent uploads to Supabase → stored in PostgreSQL
5. Flutter app queries Supabase → displays dashboard

### Development Workflow
1. Make changes to Python/Flutter code
2. Run parser test: `python parser/parser_complete.py`
3. Test Flutter: `flutter run -d chrome`
4. Build release: `flutter build web --release`
5. Deploy: `firebase deploy --only hosting`

## Important Documentation

- `README.md` - Project overview and quick start
- `backend/README.md` - Supabase setup and API usage
- `docs/6-firebase-pwa-web-setup.md` - PWA deployment guide
- `AGENTS.md` - Detailed developer guidelines and code style

## Common Tasks

### Adding a New Product Translation
1. Edit `data/product_translations.json`
2. Add Thai key with Lao/English values
3. Commit the change

### Adding a New Report Type
1. Add to `ReportType` enum in `parser/models.py`
2. Implement parsing logic in `parser/parser_complete.py`
3. Add corresponding table/view in `backend/db/schema.sql`
4. Update Flutter dashboard if needed

### Modifying Database Schema
1. Edit `backend/db/schema.sql`
2. Run in Supabase SQL Editor
3. Update Flutter models if needed

## Environment-Specific Notes

**Windows Tray Agent:**
- Requires Windows OS
- Uses `pystray` for system tray
- Runs as background service
- Auto-starts with Windows (when deployed)

**Flutter Web Deployment:**
- Firebase Hosting project: `mk-restaurants-dashboard`
- Built with `flutter build web --release --wasm`
- PWA installable on mobile (Android/iOS)
- Service worker enabled for offline capability

## Testing

**Python:**
```bash
# Test parser with sample data
python test_parser_standalone.py

# Run with pytest (if tests exist)
python -m pytest parser/tests/ -v
```

**Flutter:**
```bash
# All tests
flutter test

# Specific test file
flutter test test/widget_test.dart

# With test name filter
flutter test test/widget_test.dart --name="test name"
```

## Security Considerations

- Never commit `.env` files or Supabase credentials
- RLS enabled on all Supabase tables
- Anon key for read-only client access
- Service role key for server-side uploads only
- Agent credentials stored in `agent/credentials.enc` (encrypted)