# MK Restaurants Dashboard - Testing Guide

## ✅ What's Ready

### 1. Agent Executable
- **Location**: `D:\mk\agent\dist\MKAgent.exe`
- **Status**: ✅ Compiled and ready
- **Features**: 
  - Auto-upload at scheduled times (12:00, 15:00, 18:00, 23:30)
  - Manual sync via tray menu
  - Uploads product categories (food vs beverage)

### 2. Database
- **Status**: ✅ Clean and empty
- **Tables Ready**: daily_sales, hourly_sales, product_sales, void_log, transactions
- **Category Field**: ✅ product_sales.category_name will be populated

### 3. Mobile Dashboard (Web)
- **URL**: http://localhost:8080
- **Status**: ✅ Built and ready
- **New Features**:
  - ✅ Growth Indicators (green/red arrows)
  - ✅ Sales Mix Pie Chart (Food vs Beverage)
  - ✅ Enhanced Branch Comparison

---

## 📋 Testing Steps

### Step 1: Run the Agent

1. **Open**: `D:\mk\agent\dist\MKAgent.exe`
2. **Check Tray**: Look for MK icon in system tray (bottom-right)
3. **Right-click Tray Icon**: You should see menu:
   - Status: Running
   - Sync Now ← Click this to upload immediately
   - Branch: MK001
   - Synced: 0 files
   - Open Config
   - Open Logs
   - Open Pending
   - Exit

### Step 2: Upload Data

**Option A: Manual Sync (Recommended for Testing)**
1. Right-click tray icon
2. Click **"Sync Now"**
3. Wait 30-60 seconds for upload to complete

**Option B: Wait for Auto-upload**
- Next upload time: 12:00, 15:00, 18:00, or 23:30
- Agent will automatically upload at scheduled times

### Step 3: Verify Upload

1. **Check Logs**:
   - Right-click tray icon → "Open Logs"
   - Or open: `D:\mk\agent\dist\logs\agent.log`
   - Look for: "Successfully uploaded" messages

2. **Check Supabase** (Optional):
   - Go to: https://vlrnmbydsmpdijmajamr.supabase.co
   - Go to Table Editor
   - Check tables:
     - `daily_sales` (should have 2 records)
     - `hourly_sales` (should have ~22 records)
     - `product_sales` (should have ~300+ records)
     - **Important**: Check `category_name` column has values!

### Step 4: Test Dashboard

1. **Open Chrome**: http://localhost:8080
2. **Select Date**: Use date picker at top (select 2024-12-01 or 2024-12-02)
3. **Check Features**:

#### ✅ Growth Indicators
- Look at 4 KPI cards at top
- Should see **green ↑** or **red ↓** arrows with percentages
- Example: "+12.5%" (green) or "-5.3%" (red)

#### ✅ Sales Mix Pie Chart
- Scroll down to "Sales Mix (Food vs Beverage)"
- Should see **pie chart** with 2 colors
- Legend showing:
  - Food: XX%
  - Beverage: YY%
- Percentages should add to ~100%

#### ✅ Branch Comparison
- Make sure "All Branches" is selected
- Click the **swap icon** ↔️ next to "Totals View"
- Should see all 3 branches side-by-side
- Each branch shows: Sales, Receipts, Customers, Avg Ticket, Void Rate

### Step 5: Test Individual Branch

1. **Select Branch**: Click "MK001" (or MK002, MK003) from branch selector
2. **Check**: Growth indicators should still show
3. **Check**: Sales mix should update for that branch

---

## 🐛 Troubleshooting

### No Growth Indicators
**Possible Causes:**
1. **No historical data** - Need previous week's data for comparison
2. **First upload** - This is normal for first-time data

**Solution:**
- Upload data for multiple dates (e.g., Dec 1-7)
- Growth indicators will show for dates after the first week

### No Sales Mix Data
**Possible Causes:**
1. **No product sales** - Check if product_sales table has data
2. **Missing categories** - Check if category_name field is populated

**Check:**
```sql
-- In Supabase SQL Editor
SELECT category_name, COUNT(*) 
FROM product_sales 
GROUP BY category_name;
```

**Expected:**
- `beverages`: XX records
- `suki_items`: XX records
- `duck_items`: XX records
- etc.

### Dashboard Not Loading
1. **Check Console**: Press F12, check for errors
2. **Check Connection**: Verify internet connection
3. **Refresh**: Press Ctrl+R
4. **Check .env**: Verify Supabase credentials in `D:\mk\parser\mobile\.env`

### Agent Not Uploading
1. **Check Logs**: `D:\mk\agent\dist\logs\agent.log`
2. **Check Files**: Ensure Excel files are in `D:\mk\source\`
3. **Restart Agent**: Exit from tray, restart MKAgent.exe
4. **Check Credentials**: Verify `D:\mk\agent\credentials.enc` exists

---

## 📊 Expected Results

### After Successful Upload

**Database:**
- daily_sales: 2 records (Dec 1 & 2)
- hourly_sales: 22 records (11 hours × 2 days)
- product_sales: ~300+ records
- void_log: ~30+ records

**Dashboard:**
- ✅ Growth indicators visible (may be null for first date)
- ✅ Sales mix shows ~70-80% Food, ~20-30% Beverage
- ✅ Branch comparison shows all 3 branches
- ✅ Top products list populated

---

## 🎯 Test Checklist

### Agent Testing
- [ ] Agent starts successfully
- [ ] Tray icon appears
- [ ] "Sync Now" works
- [ ] Logs show successful upload
- [ ] Excel files moved to `processed` folder

### Database Testing
- [ ] daily_sales has data
- [ ] hourly_sales has data
- [ ] product_sales has data
- [ ] **category_name is populated** (Important!)
- [ ] void_log has data

### Dashboard Testing
- [ ] Dashboard loads
- [ ] Date picker works
- [ ] Branch selector works
- [ ] **Growth indicators show** (arrows + percentages)
- [ ] **Sales mix pie chart shows** (Food vs Beverage)
- [ ] Branch comparison works
- [ ] Top products show
- [ ] Hourly chart shows

---

## 📝 Test Report Template

**Test Date:** ___________  
**Tester:** ___________

### Results

| Feature | Status | Notes |
|---------|--------|-------|
| Agent Upload | ☐ Pass ☐ Fail | |
| Database (with categories) | ☐ Pass ☐ Fail | |
| Growth Indicators | ☐ Pass ☐ Fail | |
| Sales Mix Chart | ☐ Pass ☐ Fail | |
| Branch Comparison | ☐ Pass ☐ Fail | |

### Issues Found
1. 
2. 
3. 

### Screenshots
- [ ] Dashboard with growth indicators
- [ ] Sales mix pie chart
- [ ] Branch comparison view
- [ ] Any error messages

---

## 🚀 Next Steps After Testing

1. **If Everything Works**:
   - Deploy to production
   - Install agent on all 3 branches
   - Train staff on usage

2. **If Issues Found**:
   - Document issues
   - Send screenshots/logs
   - We'll fix and rebuild

---

## 📞 Support

**Developer**: Dr. Bounthong Vongxaya  
**Contact**: 020 9131 6541 (WhatsApp)

---

**Version**: 2.0  
**Date**: March 5, 2026  
**Status**: Ready for Testing ✅
