# MK Restaurants - Sales Intelligence System

Automated sales data consolidation and mobile dashboard for MK Restaurants Laos.

## Project Structure

```
mk/
├── backend/           # Database schema & API
│   ├── db/           # SQL schema for Supabase
│   └── .env.example  # Environment template
├── agent/            # Windows tray application
│   ├── tray_app.py   # Main tray app
│   ├── config.json   # Configuration
│   └── run.bat       # Run script
├── parser/           # XLS file parser module
│   ├── parser_complete.py  # Full parser (all 17 types)
│   └── models.py     # Data models
├── mobile/           # Flutter mobile app
├── docs/             # Project documentation
├── source/           # Sample POS reports
└── venv/             # Python virtual environment
```

## Quick Start

### 1. Setup Virtual Environment

```bash
# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Setup Supabase Database

1. Create account at [supabase.com](https://supabase.com)
2. Create new project (free tier)
3. Go to SQL Editor
4. Run `backend/db/schema.sql`

### 3. Test Parser

```bash
# Activate venv first
venv\Scripts\activate

# Run parser test
python parser/parser_complete.py
```

### 4. Run Tray Agent

```bash
# Method 1: Using batch file
cd agent
run.bat

# Method 2: Direct command
venv\Scripts\python agent/tray_app.py
```

## Tray Agent Features

- **System tray icon** - Runs in background
- **File watching** - Auto-detects new XLS files
- **Auto-parsing** - Extracts data from 17 report types
- **Pending queue** - Stores parsed data for upload
- **Configurable** - Edit config.json for settings

### Tray Menu Options

| Option | Description |
|--------|-------------|
| Status | Toggle file watching on/off |
| Sync Now | Process all files in watch folder |
| Open Config | Edit configuration file |
| Open Logs | View agent logs |
| Open Pending | View parsed data files |
| Exit | Close the application |

### Configuration (agent/config.json)

```json
{
  "branch_code": "MK001",
  "watch_folder": "D:/mk/source",
  "supabase_url": "",
  "supabase_key": "",
  "auto_upload": false
}
```

## Parser Capabilities

### Supported Report Types (17)

| Type | Description | Records |
|------|-------------|---------|
| Daily Sales | Daily summary | 1 |
| Hourly Sales | By hour breakdown | 11 |
| Table Details | Individual bills | 58 |
| Table Summary | By table type | 2 |
| Customer Breakdown | By group size | 14 |
| Suki Items | Suki ingredients | 64 |
| Suki Sets | Suki set meals | 24 |
| Duck Items | Duck menu | 29 |
| Dim Sum | Appetizers | 14 |
| Beverages | Drinks | 7 |
| Desserts | Sweets | 18 |
| Voids | Cancelled items | 8 |
| Receipts | All receipts | 54 |
| VAT Summary | Tax summary | 1 |
| VIP | VIP sales | varies |
| Credit | Credit cards | varies |
| Kitchen Categories | By kitchen | varies |

### Sample Output

```json
{
  "success": true,
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

## Development Progress

- [x] Database schema design (with Lao support)
- [x] XLS parser module (17 report types)
- [x] Local agent (tray app)
- [ ] Supabase integration
- [ ] Flutter mobile app
- [ ] Testing & deployment

## Tech Stack

| Component | Technology |
|-----------|------------|
| Database | Supabase (PostgreSQL) |
| Backend | Supabase REST API |
| Parser | Python + pandas |
| Agent | Python + pystray |
| Mobile | Flutter |
| Hosting | Supabase Cloud (Free tier) |

## Documentation

- [Initial Plan](docs/1-initial-plan.md)
- [Proposal & Quotation](docs/2-proposal-quotation.md)

## Next Steps

1. Create Supabase account and run schema
2. Configure agent with Supabase credentials
3. Deploy to branch PCs
4. Build Flutter mobile app
