# MK Restaurants - Sales Intelligence System

## Project Overview

**MK Restaurants** is a sales intelligence and automated data consolidation system for MK Restaurants Laos (3 branches). The system automates the collection of daily sales data from legacy POS systems, consolidates it into a cloud database, and provides real-time insights via a mobile dashboard.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ BRANCH LEVEL (Windows PCs)                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                   │
│  │ Branch 1 │  │ Branch 2 │  │ Branch 3 │                   │
│  │  Agent   │  │  Agent   │  │  Agent   │                   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                   │
│       │             │             │                          │
│       └─────────────┼─────────────┘                          │
│                     ▼                                        │
│            ┌─────────────────┐                               │
│            │   Supabase API  │                               │
│            └────────┬────────┘                               │
└─────────────────────┼───────────────────────────────────────┘
                      │
         ┌────────────┼────────────┐
         ▼            ▼            ▼
   ┌──────────┐ ┌──────────┐ ┌──────────┐
   │PostgreSQL│ │  Mobile  │ │  Admin   │
   │ Database │ │Dashboard │ │  Tools   │
   └──────────┘ └──────────┘ └──────────┘
```

### Key Components

| Component | Description | Status |
|-----------|-------------|--------|
| **Parser** | Python module parsing 17 XLS report types | ✅ Complete |
| **Agent** | Windows tray app for auto file sync | ✅ Complete |
| **Backend** | Supabase PostgreSQL database | ✅ Schema ready |
| **Mobile** | Flutter executive dashboard | 🔄 In progress |

---

## Project Structure

```
mk/
├── agent/                  # Windows tray application
│   ├── tray_app.py         # Main tray app (pystray + watchdog)
│   ├── config.json         # Configuration file
│   ├── run.bat             # Launch script
│   ├── logs/               # Runtime logs
│   ├── processed/          # Processed XLS files
│   └── pending/            # Parsed JSON awaiting upload
│
├── backend/                # Database & API
│   ├── db/
│   │   └── schema.sql      # Supabase PostgreSQL schema
│   ├── api/                # REST API endpoints
│   ├── .env                # Environment config
│   ├── .env.example        # Template
│   ├── test_supabase.py    # Connection test
│   └── upload_data.py      # Data upload utility
│
├── parser/                 # XLS file parser module
│   ├── parser_complete.py  # Full parser (17 report types)
│   ├── models.py           # Python dataclasses
│   ├── parser.py           # Legacy parser
│   ├── parser_v2.py        # Parser v2
│   ├── test_parser.py      # Parser tests
│   └── requirements.txt    # Parser dependencies
│
├── mobile/                 # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart       # App entry point
│   │   ├── screens/        # Dashboard screens
│   │   ├── widgets/        # Reusable widgets
│   │   └── services/       # Supabase API client
│   ├── pubspec.yaml        # Flutter dependencies
│   └── .env                # App configuration
│
├── source/                 # Sample POS XLS reports
├── data/                   # Processed data files
├── docs/                   # Project documentation
│   ├── 1-initial-plan.md
│   ├── 2-proposal-quotation.md
│   ├── 3-long-term-roadmap.md
│   └── Proposal2.pdf
│
├── venv/                   # Python virtual environment
├── requirements.txt        # Python dependencies
└── test_parser_standalone.py  # Standalone parser test
```

---

## Building and Running

### Prerequisites

- Python 3.11+
- Flutter 3.x (for mobile app)
- Supabase account (free tier)

### Python Environment Setup

```bash
# Create and activate virtual environment
python -m venv venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # Linux/Mac

# Install dependencies
pip install -r requirements.txt
```

### Database Setup

1. Create Supabase project at [supabase.com](https://supabase.com)
2. Navigate to SQL Editor
3. Run `backend/db/schema.sql` to create tables
4. Copy `backend/.env.example` to `backend/.env` and fill in credentials

### Run Parser Test

```bash
venv\Scripts\activate
python parser/parser_complete.py
# or
python test_parser_standalone.py
```

### Run Tray Agent

```bash
# Method 1: Batch file
cd agent
run.bat

# Method 2: Direct
venv\Scripts\python agent/tray_app.py
```

### Run Mobile App

```bash
cd mobile
flutter pub get
flutter run
```

---

## Parser Capabilities

### Supported Report Types (17)

| Type | Thai Filename Pattern | Records |
|------|----------------------|---------|
| `daily_sales` | ยอดขาย\d | 1 |
| `hourly_sales` | ยอดขาย.*ช่วงเวลา | 11 |
| `table_details` | แยกตามกุ่มโตะ | 58 |
| `table_summary` | สะหลุบตามกุ่มโตะ | 2 |
| `customer_breakdown` | แยกตามกจำนวนลุกค้า | 14 |
| `suki_items` | สุกี้[^ช] | 64 |
| `suki_sets` | สุกี้ชาม | 24 |
| `duck_items` | คัวเป็ด | 29 |
| `dim_sum` | คัวเปา | 14 |
| `beverages` | เครื่องดื่ม | 7 |
| `desserts` | กะแล้ม | 18 |
| `voids` | ยกเลิก | 8 |
| `receipts` | ใบเสร็จ | 54 |
| `vat_summary` | พาสี | 1 |
| `vip` | วีไอพี | varies |
| `credit` | เครดิต | varies |
| `kitchen_categories` | แยกตามคัว | varies |

### Sample Parser Output

```python
{
    "success": True,
    "report_type": "duck_items",
    "sale_date": "2024-12-01",
    "branch_code": "MK001",
    "count": 29,
    "products": [
        {
            "product_name_th": "เป็ดย่างเอ็มเค-เล็ก",
            "quantity": 12,
            "unit_price": 195000,
            "total_amount": 2340000
        }
    ]
}
```

---

## Tray Agent Features

### System Tray Menu

| Option | Description |
|--------|-------------|
| **Status** | Toggle file watching on/off |
| **Sync Now** | Process all files in watch folder |
| **Branch: MK001** | Current branch info |
| **Synced: X files** | Sync counter |
| **Open Config** | Edit config.json |
| **Open Logs** | View agent logs |
| **Open Pending** | View parsed JSON files |
| **Exit** | Close application |

### Configuration (agent/config.json)

```json
{
  "branch_code": "MK001",
  "watch_folder": "D:/mk/source",
  "supabase_url": "https://your-project.supabase.co",
  "supabase_key": "your-anon-key",
  "auto_upload": false
}
```

---

## Database Schema

### Core Tables

| Table | Purpose |
|-------|---------|
| `branches` | Branch locations (MK001, MK002, MK003) |
| `categories` | Product categories (Thai/English/Lao) |
| `products` | Menu items with multilingual names |
| `daily_sales` | Daily aggregated sales |
| `hourly_sales` | Hourly breakdown |
| `product_sales` | Product-level sales |
| `transactions` | Individual bills |
| `transaction_items` | Line items per bill |
| `void_log` | Cancelled items with reasons |
| `sync_log` | Data import tracking |

### Key Features

- **Multilingual Support**: Thai, English, Lao for all customer-facing data
- **Row Level Security (RLS)**: Branch-level data isolation
- **Views**: Pre-built analytics views (`v_today_summary`, `v_branch_performance`, etc.)
- **Indexes**: Optimized for date-range queries

---

## Development Conventions

### Python

- **Style**: PEP 8 compliant
- **Type Hints**: Used throughout parser and agent
- **Logging**: Structured logging to files and console
- **Error Handling**: Try-except with detailed error messages

### Flutter

- **State Management**: Provider pattern
- **Architecture**: Screen/Widget/Service separation
- **Styling**: Material Design 3

### Git Workflow

- `main`: Production-ready code
- `feature/*`: New features
- `fix/*`: Bug fixes

---

## Testing Practices

### Parser Testing

```bash
# Run standalone test
python test_parser_standalone.py

# Run parser module tests
python parser/test_parser.py
```

### Backend Testing

```bash
# Test Supabase connection
python backend/test_supabase.py
```

---

## Key Technologies

| Layer | Technology |
|-------|------------|
| **Database** | Supabase (PostgreSQL 15+) |
| **Backend API** | Supabase REST |
| **Parser** | Python + pandas + xlrd |
| **Agent** | Python + pystray + watchdog |
| **Mobile** | Flutter + supabase_flutter |
| **Charts** | fl_chart (Flutter) |
| **Hosting** | Supabase Cloud |

---

## Common Tasks

### Add New Report Type

1. Add pattern to `parser_complete.py::detect_report_type()`
2. Create dataclass in `models.py`
3. Implement parser method
4. Add table to `schema.sql` if needed

### Configure New Branch

1. Add branch to `branches` table in Supabase
2. Create agent config with new `branch_code`
3. Set `watch_folder` to branch's XLS export location

### Debug Agent Issues

1. Check `agent/logs/agent.log`
2. Verify `config.json` has valid Supabase credentials
3. Ensure watch folder exists and contains XLS files

---

## Troubleshooting

### Agent Not Starting

```bash
# Check Python version (must be 3.11+)
python --version

# Reinstall dependencies
pip install -r requirements.txt

# Run manually to see errors
python agent/tray_app.py
```

### Parser Fails on XLS

- Ensure file is genuine XLS (not XLSX)
- Check file isn't corrupted or locked
- Verify Thai filename matches expected patterns

### Supabase Connection Failed

- Verify `SUPABASE_URL` and `SUPABASE_KEY` in `.env`
- Check project is active in Supabase dashboard
- Ensure schema.sql has been run

---

## Documentation References

- [Initial Plan](docs/1-initial-plan.md) - Full architecture and requirements
- [Proposal](docs/2-proposal-quotation.md) - Client proposal details
- [Roadmap](docs/3-long-term-roadmap.md) - Future POS modernization plans

---

## Project Contacts

- **Developer**: Dr. Bounthong Vongxaya
- **Client**: MK Restaurants Laos
- **Project Start**: February 2026

---

*Last Updated: February 19, 2026*
