# GEMINI.md - MK Restaurants Sales Intelligence System

This file provides the essential context, architectural overview, and development guidelines for the MK Restaurants Sales Intelligence System (Laos).

## Project Overview

An automated data pipeline and executive dashboard system designed to consolidate sales reports from MK Restaurants' POS systems in Laos. The system transforms raw XLS reports into actionable insights via a real-time mobile dashboard.

### Core Components

1.  **Parser (Python):** Located in `parser/`. Extracts structured data from 17 different types of POS XLS reports using `pandas`.
2.  **Agent (Python):** Located in `agent/`. A Windows system tray application that monitors a "watch folder" for new reports, parses them locally, and uploads the results to Supabase.
3.  **Backend (Supabase):** Located in `backend/`. A PostgreSQL database hosted on Supabase with Row Level Security (RLS), custom views for analytics, and full support for Thai, Lao, and English.
4.  **Dashboard (Flutter):** Located in `parser/mobile/`. A Progressive Web App (PWA) that provides executive-level visualizations and sales summaries.
5.  **Translations (Data):** Located in `data/product_translations.json`. Maps Thai product names from POS reports to Lao and English for the dashboard.

---

## Technical Stack

- **Database:** Supabase (PostgreSQL)
- **Parser/Agent:** Python 3.x, `pandas`, `pystray`, `supabase-py`, `watchdog`
- **Dashboard:** Flutter (Web/PWA), `provider`, `fl_chart`, `supabase_flutter`
- **Deployment:** Firebase Hosting (for Flutter PWA), Windows (for Agent)

---

## Getting Started

### Prerequisites
- Python 3.10+
- Flutter SDK
- Supabase Account

### Environment Setup
1.  **Python Virtual Environment:**
    ```bash
    python -m venv venv
    venv\Scripts\activate
    pip install -r requirements.txt
    ```
2.  **Supabase Credentials:**
    - Create a `.env` file in the `backend/` directory based on `.env.example`.
    - Configure `agent/config.json` with your branch code and watch folder path.

---

## Key Development Commands

### Parser & Agent
- **Test Parser:** `python test_parser_standalone.py` or `python parser/parser_complete.py`
- **Run Agent:** `python agent/tray_app.py` or `agent/run.bat`
- **Upload Data:** `python backend/upload_data.py`

### Flutter Dashboard
- **Install Dependencies:** `cd parser/mobile && flutter pub get`
- **Run Web Dev:** `flutter run -d chrome`
- **Build Release:** `flutter build web --release --wasm`
- **Deploy to Firebase:** `firebase deploy --only hosting`

---

## Development Conventions

### Data Models
Refer to `parser/models.py` for all structured data types (`DailySales`, `HourlySales`, `ProductSale`, `Transaction`, `VoidRecord`).

### Translations
- **Source Language:** Thai (from POS).
- **Target Languages:** Lao (Unicode script) and English.
- **Rule:** Every new product appearing in reports must be added to `data/product_translations.json`.

### Database Schema
- **Primary Keys:** UUIDs (`uuid-ossp`).
- **RLS:** Row Level Security is enforced. Use the `anon` key for Flutter (read-only) and the `service_role` key for the Python Agent (write).
- **Analytics:** Prefer using the PostgreSQL views (e.g., `v_today_summary`, `v_peak_hours`) for dashboard queries.

### File Naming Convention (POS Reports)
The parser extracts the sale date from the filename using the pattern `DD.MM.YYYY.xls` (e.g., `ยอดขาย01.12.2024.xls`).

---

## Project Structure

```text
mk/
├── agent/            # Windows Tray Agent (Python)
├── backend/          # DB Schema & Supabase Utils
│   └── db/           # SQL Migrations
├── data/             # JSON Translations
├── docs/             # Technical & Project Docs
├── parser/           # Core Parsing Logic
│   └── mobile/       # Flutter Dashboard Source
├── source/           # Sample POS XLS Reports
└── requirements.txt  # Python Dependencies
```

## Important Files
- `parser/parser_complete.py`: The heart of the extraction logic.
- `agent/tray_app.py`: Background worker for branch PCs.
- `backend/db/schema.sql`: Source of truth for the data model.
- `data/product_translations.json`: Translation dictionary.
