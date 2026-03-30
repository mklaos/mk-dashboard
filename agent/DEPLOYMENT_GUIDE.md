# 🚀 MK Agent - Deployment Guide

## 📦 Distribution Package

**Folder:** `MK_Agent/`  
**Total Size:** ~45 MB  
**Startup Time:** 5-10 seconds ⚡

---

## 📁 Package Contents

```
MK_Agent/
├── MK_Agent.exe          ← Main executable (20 MB)
├── config.json           ← Configuration file
├── credentials.enc       ← Encrypted Supabase credentials
├── _internal/            ← Python runtime & libraries
├── source/               ← Place POS Excel files here
├── processed/            ← Processed files moved here
└── logs/                 ← Application logs
```

---

## 🎯 Deployment Steps

### **Step 1: Copy to Customer**

Copy the entire `MK_Agent` folder to customer's computer:

```
Example locations:
├── C:\mk_agent\
├── D:\mk_agent\
└── \\server\mk_agent\
```

### **Step 2: Configure for Branch**

Edit `config.json` on customer's computer:

```json
{
  "brand_name": "MK Restaurants",
  "branch_code": "MK001",           ← Change per branch
  "watch_folder": "D:/mk_agent/source",  ← Adjust path
  "sync_times": ["12:00", "15:00", "18:00", "23:30"],
  "auto_upload": true,
  "processed_log": "D:\\mk_agent\\processed_files.json"
}
```

**Per-Branch Configuration:**

| Branch | branch_code | watch_folder |
|--------|-------------|--------------|
| MK001 (Watnak) | `"MK001"` | `"D:/mk_agent/source"` |
| MK002 | `"MK002"` | `"C:/pos/export"` |
| MK003 | `"MK003"` | `"E:/data/pos"` |

### **Step 3: Run Application**

Double-click `MK_Agent.exe`

**System Tray Icon** appears (bottom-right corner)

---

## ⚙️ Usage

### **First Run**

1. **Right-click tray icon** → "Debug View"
2. Check status: "Supabase credentials loaded"
3. Place Excel files in `source/` folder
4. Files automatically sync to Supabase

### **Daily Operation**

- **Automatic**: Files in `source/` are synced at scheduled times
- **Manual**: Right-click tray icon → "Sync Now"
- **Monitor**: Right-click → "Debug View" to see logs

### **Configuration**

Right-click tray icon → "Configure"

- Change branch code
- Change watch folder location
- Change sync schedule
- Save and restart

---

## 🔧 Maintenance

### **View Logs**

Right-click tray icon → "Debug View"

- **💾 Save Log** - Export logs to file
- **📋 Copy Log** - Copy to clipboard
- **🗑️ Clear Log** - Clear log view

### **Check Processed Files**

File: `processed_files.json` (in MK_Agent folder)

Contains list of already processed files (prevents duplicates)

### **Clear Processed History**

Delete `processed_files.json` to re-process all files

---

## 🚨 Troubleshooting

### **App won't start**
- Check if another instance is running (check system tray)
- Check logs in `logs/agent.log`

### **Files not syncing**
- Check `watch_folder` path in config.json
- Ensure Excel files are in `source/` folder
- Check Debug View for errors

### **"No Supabase credentials found"**
- Ensure `credentials.enc` exists in MK_Agent folder
- Contact developer to regenerate credentials

### **Wrong branch data**
- Check `branch_code` in config.json
- Each branch must have unique code (MK001, MK002, MK003)

---

## 📊 Folder Structure After Deployment

```
D:\mk_agent\
├── MK_Agent.exe          ← Double-click to run
├── config.json           ← Edit branch code here
├── credentials.enc       ← Don't modify (encrypted)
├── _internal/            ← Don't modify (runtime)
├── source/               ← Place Excel files here
│   ├── ยอดขาย02.12.2024.xls
│   └── สุกี้ 02.12.2024..xls
├── processed/            ← Files moved here after sync
│   ├── ยอดขาย02.12.2024.xls
│   └── สุกี้ 02.12.2024..xls
└── logs/
    └── agent.log         ← Application logs
```

---

## 🔄 Updates

To update to new version:

1. **Close** MK_Agent (right-click tray → Quit)
2. **Backup** config.json
3. **Replace** entire MK_Agent folder
4. **Restore** config.json
5. **Run** MK_Agent.exe

---

## 📞 Support

**Developer:** Dr. Bounthong Vongxaya  
**Contact:** 020 9131 6541  
**Version:** 2.3  
**Build Date:** March 30, 2026

---

## ⚡ Performance Notes

| Metric | Value |
|--------|-------|
| **Startup Time** | 5-10 seconds |
| **Package Size** | ~45 MB |
| **Memory Usage** | ~200 MB |
| **CPU Usage** | <1% (idle) |

**Fast startup** - No extraction needed!

---

**Last Updated:** March 30, 2026
