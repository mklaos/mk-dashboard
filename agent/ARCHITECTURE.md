# MK Agent - Architecture & Configuration

## 📋 Overview

MK Agent is a Windows tray application that monitors a folder for POS report files and automatically syncs them to Supabase.

---

## 🔐 Credential System

### **credentials.enc** (Encrypted Supabase Credentials)

**Location:** Same folder as `MK_Agent.exe`

**Contains:**
- Supabase URL (encrypted)
- Supabase Key (encrypted)

**Created by:**
```bash
cd D:\mk\agent
python setup_credentials.py --setup
```

**Reads from:**
- `D:\mk\backend\.env`

**Encryption:**
- Uses **fixed salt**: `b"MK_RESTAURANTS_LAOS_SALT_2026"`
- **Works on ALL machines** (not machine-specific)
- Created **once**, deployed everywhere

**Deployment:**
```
Copy these 3 files to each branch:
├── MK_Agent.exe
├── config.json
└── credentials.enc     ← Same file for all branches!
```

---

## ⚙️ Configuration

### **config.json** (Application Settings)

**Location:** Same folder as `MK_Agent.exe`

**Contains:**
```json
{
  "brand_name": "MK Restaurants",
  "branch_code": "MK001",           ← Branch identifier
  "watch_folder": "D:/mk/agent/dist/source",  ← Where to look for files
  "sync_times": ["12:00", "15:00", "18:00", "23:30"],  ← Auto-sync times
  "auto_upload": true,
  "processed_log": "D:\\mk\\agent\\processed_files.json"
}
```

**Purpose:**
- `branch_code`: Identifies which branch (MK001, MK002, MK003)
- `watch_folder`: Local folder to monitor for new files
- `sync_times`: Schedule for automatic sync (local time)
- `processed_log`: Track which files have been processed

**Per-Branch Customization:**
Each branch has **different** `config.json`:
- Branch 1: `branch_code: "MK001"`, `watch_folder: "D:/pos/export"`
- Branch 2: `branch_code: "MK002"`, `watch_folder: "C:/pos/data"`
- Branch 3: `branch_code: "MK003"`, `watch_folder: "E:/exports"`

---

## 📁 File Flow

```
┌─────────────────────────────────────────────────────────┐
│ BRANCH COMPUTER                                         │
│                                                         │
│  POS System → Export XLS/PDF → watch_folder/           │
│                                           ↓             │
│                                    MK_Agent.exe        │
│                                    (monitors folder)   │
│                                           ↓             │
│  credentials.enc  ←─── Reads ───┐                     │
│  config.json      ←─── Reads ───┤                     │
│                                 ↓                       │
│                          Parse & Upload                │
│                                 ↓                       │
└─────────────────────────────────┼───────────────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────┐
                    │   Supabase Cloud        │
                    │   (Central Database)    │
                    │                         │
                    │   - daily_sales         │
                    │   - product_sales       │
                    │   - transactions        │
                    │   - void_log            │
                    └─────────────────────────┘
```

---

## 🔄 Sync Process

### **1. File Detection**
- **Watchdog** monitors `watch_folder/`
- Triggers on: `.xls`, `.xlsx`, `.pdf` files
- Debounce: 2 seconds (waits for file copy to complete)

### **2. Parsing**
- **Excel files**: `parser_complete.py` (17 report types)
- **PDF files**: Future implementation (OCR)

### **3. Upload**
- Uploads to Supabase via REST API
- Uses credentials from `credentials.enc`
- Uses branch info from `config.json`

### **4. Scheduled Sync**
- Runs at times specified in `config.json`
- Processes all files in `watch_folder/`
- Prevents duplicate processing via `processed_log`

---

## 📊 Data Flow

### **Input Files (POS Reports)**

| Thai Filename | Report Type | Data Uploaded |
|--------------|-------------|---------------|
| `ยอดขาย*.xls` | daily_sales | Daily summary |
| `ยอดขายตามช่วงเวลา*.xls` | hourly_sales | Hourly breakdown |
| `สุกี้*.xls` | suki_items | Product sales |
| `คัวเป็ด*.xls` | duck_items | Product sales |
| `เคื่องดื่ม*.xls` | beverages | Product sales |
| `ยกเลีก*.xls` | voids | Void log |
| `ใบเส็ด*.xls` | receipts | Transactions |
| `*.pdf` | (future) | TBD |

### **Database Tables**

All data uploaded to Supabase PostgreSQL:

```sql
branches          ← Branch info (MK001, MK002, MK003)
categories        ← Product categories
products          ← Menu items (with translations)
daily_sales       ← Daily summaries
hourly_sales      ← Hourly breakdowns
product_sales     ← Product-level sales
transactions      ← Individual bills
transaction_items ← Line items per bill
void_log          ← Cancelled items
sync_log          ← Import tracking
```

---

## 🛠️ Deployment

### **Development**
```bash
# 1. Update credentials (if Supabase changes)
python setup_credentials.py --setup

# 2. Build executable
build.bat

# 3. Test
cd dist
.\MK_Agent.exe
```

### **Production (Branch Deployment)**

**On your development machine:**
```bash
# 1. Build
cd D:\mk\agent
build.bat

# 2. Copy to branch folder
xcopy /E /I /Y dist \\BRANCH-PC\mk_agent\
```

**On branch computer:**
```bash
# 1. Edit config.json
notepad D:\mk_agent\config.json
# - Set branch_code (MK001, MK002, MK003)
# - Set watch_folder to POS export location

# 2. Run
D:\mk_agent\MK_Agent.exe
```

---

## 🔧 Configuration Examples

### **Branch 1 (MK001 - Watnak)**
```json
{
  "brand_name": "MK Restaurants",
  "branch_code": "MK001",
  "watch_folder": "D:/pos/export",
  "sync_times": ["12:00", "15:00", "18:00", "23:30"],
  "auto_upload": true
}
```

### **Branch 2 (MK002)**
```json
{
  "brand_name": "MK Restaurants",
  "branch_code": "MK002",
  "watch_folder": "C:/pos_data/daily",
  "sync_times": ["13:00", "20:00"],
  "auto_upload": true
}
```

---

## 📝 Maintenance

### **Change Supabase Credentials**
```bash
# On ALL branch computers:
cd D:\mk\agent
python setup_credentials.py --setup
```

### **Change Sync Schedule**
Edit `config.json` on each branch:
```json
"sync_times": ["11:00", "14:00", "17:00", "22:00"]
```

### **Change Watch Folder**
Edit `config.json` on each branch:
```json
"watch_folder": "E:/new_pos_exports"
```

### **View Logs**
```
D:\mk\agent\logs\agent.log
```

### **Check Processed Files**
```
D:\mk\agent\processed_files.json
```

---

## 🚨 Troubleshooting

### **"No Supabase credentials found"**
- Check `credentials.enc` exists in same folder as exe
- Run `python setup_credentials.py --setup`

### **"Watch folder not found"**
- Check `config.json` has correct `watch_folder` path
- Ensure folder exists

### **Files not syncing**
- Check `agent.log` for errors
- Verify file extensions (.xls, .xlsx, .pdf)
- Check `processed_files.json` - file may already be processed

### **Wrong branch data**
- Check `branch_code` in `config.json`
- Each branch must have unique code

---

## 🔒 Security Notes

- `credentials.enc` is encrypted (but with fixed salt for deployment)
- Store Supabase service role key carefully
- Use RLS (Row Level Security) in Supabase
- Branch computers only need anon key (not service role)

---

**Last Updated:** March 30, 2026  
**Version:** 2.3
