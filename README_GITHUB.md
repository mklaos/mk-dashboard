# MK Restaurants Sales Intelligence System

Automated sales data consolidation and mobile dashboard for MK Restaurants Laos.

## 🚀 Features

- **Windows Tray Agent** - Auto-detects and processes 17 XLS report types
- **Thai → Lao Translation** - Automatic product name translation (228+ products)
- **Supabase Integration** - Cloud database with real-time sync
- **Flutter Mobile App** - Executive dashboard with Lao language support
- **Automated Scheduling** - Configurable sync times

## 📁 Project Structure

```
mk/
├── agent/              # Windows tray application
│   ├── tray_app.py     # Main agent logic
│   ├── uploader.py     # Supabase uploader
│   ├── security_utils.py  # Credential encryption
│   └── build_agent.bat  # Build script
├── parser/             # XLS file parser module
│   ├── parser_complete.py  # Full parser (17 types)
│   ├── models.py       # Data models
│   └── translator.py   # Product translation
├── mobile/             # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   └── android/
├── backend/            # Database & API
│   ├── db/schema.sql   # Supabase schema
│   └── .env.example    # Environment template
├── data/               # Translation data
│   └── product_translations.json
├── docs/               # Documentation
└── source/             # Watch folder for XLS files
```

## 🛠️ Installation

### 1. Setup Python Environment

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
2. Create new project
3. Go to SQL Editor
4. Run `backend/db/schema.sql`

### 3. Configure Agent

1. Run `agent/setup_credentials.py` to encrypt Supabase credentials
2. Edit `agent/config.json`:
   ```json
   {
     "branch_code": "MK001",
     "watch_folder": "D:/mk/source",
     "sync_times": ["12:00", "23:30"],
     "auto_upload": true
   }
   ```

### 4. Build Agent

```batch
cd agent
build_agent.bat
```

### 5. Run Agent

```batch
cd agent
run.bat
```

## 📱 Mobile App

### Build APK

```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --release --split-per-abi
```

APKs will be in `mobile/build/app/outputs/flutter-apk/`

### Install on Phone

1. Transfer APK to phone
2. Enable "Unknown Sources" in Settings
3. Install APK
4. Launch app

## 📊 Supported Report Types (17)

| Type | Thai Filename | Records |
|------|--------------|---------|
| Daily Sales | ยอดขาย | 1 |
| Hourly Sales | ยอดขายตามช่วงเวลา | 11 |
| Table Details | แยกตามกุ่มโตะ | 58 |
| Suki Items | สุกี้ | 64 |
| Duck Items | คัวเป็ด | 29 |
| Dim Sum | คัวเปา | 14 |
| Beverages | เครื่องดื่ม | 7 |
| Desserts | กะแล้ม | 18 |
| Voids | ยกเลิก | 8 |
| Receipts | ใบเสร็จ | 54 |
| VAT Summary | พาสี | 1 |
| VIP | วีไอพี | varies |
| Credit | เครดิต | varies |
| Kitchen Categories | แยกตามคัว | varies |
| Customer Breakdown | แยกตามจำนวนลูกค้า | 14 |
| Table Summary | สะหลุบตามกุ่มโตะ | 2 |
| Suki Sets | สุกี้ชาม | 24 |

## 🔧 Troubleshooting

### Agent not uploading data?
1. Check `agent/logs/agent.log` for errors
2. Verify `credentials.enc` exists in agent folder
3. Check Supabase credentials are correct

### Mobile app shows connection error?
1. Ensure AndroidManifest.xml has internet permissions
2. Check Supabase URL in `.env`
3. Verify RLS policies allow access

### Parser returns zeros?
1. Check XLS file structure matches expected format
2. Verify Thai text encoding is correct
3. Rebuild agent with latest parser

## 📖 Documentation

- [Initial Plan](docs/1-initial-plan.md)
- [Proposal & Quotation](docs/2-proposal-quotation.md)
- [Long-term Roadmap](docs/3-long-term-roadmap.md)
- [Lesson Learned & Status](docs/4-lesson-learn-status.md)

## 🎯 Key Learnings

See [docs/4-lesson-learn-status.md](docs/4-lesson-learn-status.md) for detailed technical challenges and solutions:

1. **Thai Character Encoding** - Dual-strategy parsing for PyInstaller
2. **Excel Structure Variations** - Flexible column scanning
3. **Credentials Management** - Machine-specific encryption
4. **Data Deduplication** - File tracking and cleanup
5. **Android Network Permissions** - Manifest configuration

## 📞 Support

- **Developer:** Dr. Bounthong Vongxaya
- **Phone:** 020 9131 6541
- **Email:** Contact via WhatsApp

## 📄 License

Proprietary - MK Restaurants Laos Internal Use Only

---

*Version: 1.0*  
*Last Updated: February 20, 2026*  
*Status: Production Ready ✅*
