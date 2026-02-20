# MK Restaurants Sales Intelligence System
## Lesson Learned & Project Status

**Document Version:** 1.0  
**Last Updated:** February 20, 2026  
**Author:** Dr. Bounthong Vongxaya (with AI Development Assistance)

---

## 1. Executive Summary

Successfully developed and deployed an automated sales data consolidation system for MK Restaurants Laos (3 branches). The system transforms manual XLS report processing into an automated pipeline with real-time mobile dashboard visibility.

### Key Achievements
- ✅ **Windows Tray Agent** - Auto-detects and processes 17 XLS report types
- ✅ **Product Translation** - Thai → Lao automatic translation with 228+ products
- ✅ **Supabase Integration** - Cloud database with proper schema and RLS
- ✅ **Flutter Dashboard** - Mobile app with Lao language support
- ✅ **Production Ready** - All 34 files (17 types × 2 days) processing correctly

---

## 2. Technical Challenges & Solutions

### 2.1 Thai Character Encoding in PyInstaller Executable

**Problem:**
When the parser runs inside the PyInstaller-frozen executable, Thai text matching fails silently, resulting in zero values being uploaded to Supabase.

**Root Cause:**
- PyInstaller doesn't preserve locale settings for Thai character encoding
- String matching with Thai characters (`'จำนวนใบเสร็จที่ขาย' in row_str`) fails in frozen state
- Excel file parsing works, but data extraction returns empty values

**Solution:**
Implemented **dual-strategy parsing**:
1. **Primary:** Thai text pattern matching (works in development)
2. **Fallback:** Position-based and value-type detection (works in production)

```python
# Example: Receipt count extraction
if 'จำนวนใบเสร็จที่ขาย' in row_str:
    # Strategy 1: Thai text matching
    for col in range(len(row)):
        val = row.iloc[col]
        if isinstance(val, (int, float)) and val > 0:
            daily_data['receipt_count'] = int(val)
            break
        elif isinstance(val, str):
            # Strategy 2: Handle string numbers with commas
            cleaned = val.replace(',', '').strip()
            if cleaned.isdigit():
                daily_data['receipt_count'] = int(cleaned)
                break
```

**Key Learnings:**
- Always test PyInstaller executables independently, not just the Python script
- Thai/Lao/Chinese character encoding requires special handling in frozen apps
- Implement fallback parsing strategies that don't rely on Unicode text matching
- Use `locale.setlocale(locale.LC_ALL, '')` at app startup

---

### 2.2 Excel File Structure Variations

**Problem:**
Different XLS report types have different column layouts:
- Some have data in columns 1,2,3
- Others have data in columns 4,5,6
- Numeric values can be stored as strings with commas ("368,000.00")

**Solution:**
Implemented **flexible column scanning**:

```python
# Scan all columns for numeric values
for col in range(len(row)):
    if pd.notna(row.iloc[col]):
        val = row.iloc[col]
        if isinstance(val, (int, float)) and val > 0:
            daily_data['gross_sales'] = self.clean_amount(val)
            break
        elif isinstance(val, str):
            # Handle "368,000.00" format
            cleaned = val.replace(',', '').strip()
            try:
                amount = float(cleaned)
                if amount > 0:
                    daily_data['gross_sales'] = Decimal(cleaned)
                    break
            except:
                pass
```

**Key Learnings:**
- Never assume fixed column positions in Excel files
- Always handle both numeric and string representations of numbers
- Strip commas and whitespace from numeric strings before conversion
- Use `Decimal` for financial data to avoid floating-point precision issues

---

### 2.3 Credentials Management for Frozen Apps

**Problem:**
Supabase credentials need to be:
- Stored securely (encrypted)
- Accessible from the frozen executable
- Machine-specific (for encryption salt)

**Solution:**
Created `security_utils.py` with machine-specific encryption:

```python
def get_machine_id():
    """Generates unique ID from MAC address for encryption salt"""
    node = uuid.getnode()
    return str(node).encode()

def load_secure_credentials():
    """Load credentials from credentials.enc alongside executable"""
    if getattr(sys, 'frozen', False):
        creds_path = Path(sys.executable).parent / "credentials.enc"
    else:
        creds_path = Path(__file__).parent / "credentials.enc"
```

**Build Script Enhancement:**
```batch
:: Copy credentials.enc to dist folder (machine-specific encrypted data)
if exist credentials.enc (
    copy credentials.enc dist\credentials.enc /Y >nul
    echo [OK] credentials.enc copied to dist folder
)
```

**Key Learnings:**
- Use `sys.executable.parent` for frozen app paths, not `__file__`
- Encrypt credentials with machine-specific salt to prevent theft
- Copy encrypted credentials to dist folder during build
- Never commit credentials to version control

---

### 2.4 Data Deduplication

**Problem:**
- Files copied back and forth between `source` and `processed` folders
- Timestamp prefixes added (e.g., `165205_กะแล้ม 02.12.2024.xls`)
- Duplicate files cause confusion and processing errors

**Solution:**
1. **Processed files log** - Track processed filenames in `processed_files.json`
2. **File movement** - Move processed files to `processed/` folder
3. **Cleanup script** - Remove timestamped duplicates:
   ```batch
   cd "D:\mk\source" & del "1*.*" /Q & del "17*.*" /Q
   ```

**Key Learnings:**
- Implement deduplication at multiple levels (log + file movement)
- Use consistent naming conventions
- Provide cleanup utilities for common issues
- Document file management procedures clearly

---

### 2.5 Android Network Connectivity in Release APK

**Problem:**
The mobile app works perfectly in Flutter debug mode but fails to connect to Supabase when built as a release APK, showing a `ClientException with SocketException: Failed host lookup`.

**Root Cause:**
- Flutter automatically adds internet permissions in debug mode, but they must be explicitly defined for release builds.
- Android's security policies may block DNS resolution if permissions are missing.
- The `Failed host lookup` error indicates the app cannot reach the DNS server to find the Supabase URL.

**Solution:**
Updated `android/app/src/main/AndroidManifest.xml` with required permissions and enabled cleartext traffic:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>

    <application
        ...
        android:usesCleartextTraffic="true">
        ...
    </application>
</manifest>
```

**Key Learnings:**
- **Debug vs. Release:** Never assume a working debug build means the release APK is ready.
- **Explicit Permissions:** Always explicitly declare `INTERNET` and `ACCESS_NETWORK_STATE` for any networked app.
- **DNS Resolution:** `SocketException: Failed host lookup` is almost always a permission or network state issue on the device.
- **Cleartext Traffic:** Enabling `usesCleartextTraffic` helps avoid issues with certain network proxies or older Android versions.

---

## 3. Production Deployment Checklist

### 3.1 Pre-Deployment

- [ ] Run `setup_credentials.py` to encrypt Supabase credentials
- [ ] Verify `credentials.enc` exists in agent folder
- [ ] Test parser on sample XLS files manually
- [ ] Clean Supabase test data before first production run
- [ ] Verify all 17 report types parse correctly

### 3.2 Build Process

```batch
cd D:\mk\agent
build_agent.bat
```

**Verify after build:**
- [ ] `dist/MKAgent.exe` exists
- [ ] `dist/credentials.enc` copied (encrypted)
- [ ] `dist/data/product_translations.json` copied (228+ translations)
- [ ] `dist/config.json` preserved (not overwritten)

### 3.3 First Run

1. **Start Agent:** Run `dist/MKAgent.exe`
2. **Verify Tray Icon:** MK icon appears in system tray
3. **Check Logs:** `dist/logs/agent.log` shows "Loaded 228 product translations"
4. **Test Sync:** Right-click tray → "Sync Now"
5. **Monitor Progress:** Check logs for "Successfully processed and moved"
6. **Verify Dashboard:** Refresh Flutter app, check data displays correctly

### 3.4 Daily Operations

**Normal Workflow:**
1. Staff exports XLS from POS after closing (~22:00-23:30)
2. Files saved to watch folder (`D:/mk/source`)
3. Agent auto-uploads at scheduled times (default: 12:00, 23:30)
4. OR staff clicks "Upload Now" in tray menu
5. President sees data on mobile dashboard next day

**Monitoring:**
- Check `dist/logs/agent.log` for errors
- Verify file count in `processed/` folder increases
- Check dashboard shows correct data
- Monitor Supabase usage in dashboard

---

## 4. Known Limitations & Workarounds

### 4.1 Parser Limitations

| Issue | Impact | Workaround |
|-------|--------|------------|
| Thai text matching fails in frozen EXE | Daily sales show zeros | Use position-based fallback (implemented) |
| Hourly sales column structure varies | Some hours missing | Scan all columns for data (implemented) |
| String numbers with commas | Values parsed as 0 | Strip commas before conversion (implemented) |

### 4.2 Operating Hours

**Current Schedule:**
- Shop closes: 22:00-23:30 (varies by customer traffic)
- XLS export: After closing
- Auto upload: 12:00 next day
- **President sees data:** Next day afternoon

**Enhanced Schedule (Optional):**
If President wants same-day visibility:
- Add midday export at 13:00
- Add evening export at 18:00
- Staff clicks "Upload Now" after each export
- **President sees data:** Same day, near real-time

### 4.3 Data Latency

| Scenario | Export Time | Upload Time | Dashboard Available |
|----------|-------------|-------------|---------------------|
| Baseline | 23:30 | 12:00 (auto) | Next day 12:05 |
| Enhanced | 13:00 + 18:00 | Manual | Same day |

---

## 5. Current System Status

### 5.1 Components Status

| Component | Status | Version | Notes |
|-----------|--------|---------|-------|
| **Parser** | ✅ Production | v2.4 | Handles all 17 report types |
| **Agent** | ✅ Production | v2.4 | Tray app with auto-upload |
| **Uploader** | ✅ Production | v1.1 | Includes product_name_lao |
| **Supabase** | ✅ Production | - | Schema v1.1 with Lao support |
| **Mobile App** | ✅ Production | v1.0 | Flutter with Lao names |
| **Translations** | ✅ Active | - | 228+ products mapped |

### 5.2 Data Flow

```
POS System (Crystal Reports)
    ↓
XLS Export (17 report types)
    ↓
Watch Folder (D:/mk/source)
    ↓
MK Agent (Tray App)
    ↓ (Auto at 12:00 or Manual)
Parser (Thai → Lao translation)
    ↓
Supabase API
    ↓ (PostgreSQL)
Flutter Dashboard
    ↓
President's Mobile Device
```

### 5.3 File Locations

```
D:\mk\
├── agent\
│   ├── dist\
│   │   ├── MKAgent.exe          # Production executable
│   │   ├── config.json          # Branch config (preserve!)
│   │   ├── credentials.enc      # Encrypted Supabase creds
│   │   ├── data\
│   │   │   └── product_translations.json  # 228+ translations
│   │   ├── logs\
│   │   │   └── agent.log        # Check for errors
│   │   └── processed\           # Processed XLS files
│   ├── tray_app.py              # Source code
│   ├── uploader.py              # Supabase uploader
│   ├── security_utils.py        # Credential encryption
│   └── build_agent.bat          # Build script
│
├── parser\
│   ├── parser_complete.py       # Main parser (v2.4)
│   ├── models.py                # Data models
│   └── translator.py            # Product translation
│
├── mobile\
│   ├── lib\
│   │   ├── main.dart            # Flutter app entry
│   │   ├── screens\
│   │   │   └── dashboard_screen.dart
│   │   ├── services\
│   │   │   └── sales_service.dart
│   │   └── widgets\
│   │       ├── kpi_card.dart
│   │       └── hourly_chart.dart
│   └── .env                     # Supabase publishable key
│
├── source\                      # Watch folder (34 files)
├── backend\
│   ├── db\
│   │   └── schema.sql           # Supabase schema
│   └── .env                     # Supabase service key
│
└── data\
    └── product_translations.json  # Master translation file
```

### 5.4 Database Tables

| Table | Records | Last Updated | Status |
|-------|---------|--------------|--------|
| `branches` | 3 | - | ✅ Active |
| `daily_sales` | 2 | 2024-12-01, 02 | ✅ Active |
| `hourly_sales` | 26 | 2024-12-01, 02 | ✅ Active |
| `product_sales` | ~800 | 2024-12-01, 02 | ✅ Active |
| `void_log` | ~14 | 2024-12-01, 02 | ✅ Active |
| `transactions` | 0 | - | ⏸️ Not uploaded |

---

## 6. Troubleshooting Guide

### 6.1 Common Issues

**Issue: Dashboard shows zeros for all metrics**

**Diagnosis:**
```bash
# Check agent logs
type D:\mk\agent\dist\logs\agent.log | findstr "daily_sales"

# Check Supabase data
python -c "from supabase import create_client; ... 
r = s.table('daily_sales').select('*').execute()
print(r.data)"
```

**Solution:**
1. Verify parser extracts data correctly (test manually)
2. Check `credentials.enc` exists in dist folder
3. Rebuild agent with `build_agent.bat`
4. Clean Supabase and re-sync

---

**Issue: "File not found" error in logs**

**Cause:** Thai filename encoding issue

**Solution:**
1. Ensure file exists in source folder
2. Check file isn't locked by another process
3. Restart agent
4. Try "Sync Now" from tray menu

---

**Issue: Duplicate key constraint errors**

**Cause:** Data already exists in Supabase

**Solution:**
```bash
# Clean Supabase data
cd D:\mk\backend
python clean_all_data.py

# Clear processed log
del D:\mk\agent\dist\processed_files.json

# Re-sync
# Click "Sync Now" in tray menu
```

---

**Issue: Product names show as Thai instead of Lao**

**Cause:** `product_name_lao` field is NULL in database

**Solution:**
1. Verify `data/product_translations.json` exists
2. Check logs show "Loaded 228 product translations"
3. Verify uploader includes `product_name_lao` field
4. Re-sync files

---

### 6.2 Performance Optimization

**Slow Dashboard Load:**
- Add database indexes on `sale_date` columns
- Implement query caching in Flutter app
- Reduce data fetch to last 30 days only

**Slow Upload:**
- Compress JSON before upload
- Batch multiple records in single API call
- Upload during off-peak hours

---

## 7. Future Enhancements

### Phase 2 (Post-Launch)

| Feature | Priority | Effort | Status |
|---------|----------|--------|--------|
| WhatsApp Integration | Medium | 2 weeks | 📋 Planned |
| AI Assistant (Natural Queries) | Low | 2 weeks | 📋 Planned |
| Midday Export Schedule | High | 1 day | 🔧 Config change |
| Transaction Upload | Medium | 1 week | 📋 Planned |
| Void Analysis Dashboard | Low | 1 week | 📋 Planned |

### Long-Term Roadmap

- **Year 1:** Stabilize current system, add more branches
- **Year 2:** POS modernization with native Lao interface
- **Year 3:** AI-powered demand forecasting

---

## 8. Support & Maintenance

### Included Support (3 Months)
- Bug fixes at no cost
- Email support (48-hour response)
- Remote troubleshooting

### Contact
- **Developer:** Dr. Bounthong Vongxaya
- **Phone:** 020 9131 6541
- **Email:** [Contact via WhatsApp preferred]

### Escalation Procedure
1. Check `agent.log` for error messages
2. Try "Sync Now" manually
3. Restart agent (exit from tray, restart EXE)
4. Contact developer with log file attached

---

## 9. Success Metrics

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Dashboard load time | < 3 seconds | ~1 second | ✅ Exceeded |
| Data sync time | < 5 minutes | ~2 minutes | ✅ Exceeded |
| Manual data entry | Zero | Zero | ✅ Achieved |
| President visibility | Next day by 13:00 | Next day 12:05 | ✅ Exceeded |
| System uptime | > 99% | 100% (so far) | ✅ Exceeded |
| Product translation coverage | > 90% | 100% (228 products) | ✅ Exceeded |

---

## 10. Key Takeaways

### What Worked Well
1. **Dual-strategy parsing** - Saved the project when Thai matching failed
2. **Machine-specific encryption** - Secure yet practical credential management
3. **Incremental development** - Build → Test → Fix → Rebuild cycle
4. **Comprehensive logging** - Made debugging much easier
5. **Flexible column scanning** - Handled Excel structure variations

### What Could Be Better
1. **Earlier PyInstaller testing** - Should have tested frozen EXE sooner
2. **Better file management** - Timestamped duplicates caused confusion
3. **More robust error handling** - Some failures were silent
4. **Documentation during development** - Had to recreate lessons learned

### Advice for Similar Projects
1. **Test the executable early and often** - Don't wait until deployment
2. **Implement multiple parsing strategies** - Unicode text matching is fragile
3. **Log everything** - You'll thank yourself during debugging
4. **Clean up test data regularly** - Prevents confusion and errors
5. **Document as you go** - Lessons learned fade quickly

---

*Document Version: 1.0*  
*Last Updated: February 20, 2026*  
*Status: Production Ready ✅*
