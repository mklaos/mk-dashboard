# 🚀 Supabase Migration - Quick Start

## 3-Minute Setup

### Step 1: Create New Supabase Project (5 mins)

1. Go to [supabase.com](https://supabase.com)
2. Sign in with your **new dedicated email**
3. Click "New Project"
4. Fill in:
   - **Name:** `mk-sales-production`
   - **Database Password:** (save this!)
   - **Region:** Singapore (closest to Laos)
5. Wait 2-3 minutes for setup

### Step 2: Copy Credentials (2 mins)

After project creation:

1. Go to **Settings** (gear icon) → **API**
2. Copy these 3 values:
   ```
   Project URL: https://xxxxxxxxx.supabase.co
   anon/public key: eyJhbGc...
   service_role key: eyJhbGc... (longer one)
   ```

### Step 3: Create Credential Files (2 mins)

Create `D:\mk\backend\.env.new`:

```env
SUPABASE_URL=https://xxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc... (anon key)
SUPABASE_SERVICE_KEY=eyJhbGc... (service role key)
APP_ENV=production
```

### Step 4: Test New Project (1 min)

```bash
cd D:\mk
venv\Scripts\activate
python backend/test_supabase.py --new
```

Should show: ✅ All tests passed

---

## 📦 Migration Process

### Export Data from Old Project

```bash
# Make sure backend/.env has OLD project credentials
python backend/export_data.py
```

Creates backup in `D:\mk\backup\`

### Apply Schema to New Project

1. Open new project dashboard
2. Go to **SQL Editor**
3. Copy entire content from `backend/db/schema.sql`
4. Paste and click **Run**
5. Verify: Should show "Success. No rows returned"

### Import Data to New Project

```bash
python backend/import_to_new_supabase.py
```

---

## 🔄 Switch to Production

### Update Agent Config

Edit `D:\mk\agent\config.json`:

```json
{
  "brand_name": "MK Restaurants",
  "branch_code": "MK001",
  "watch_folder": "D:/mk/agent/dist/source",
  "sync_times": ["12:00", "15:00", "18:00", "23:30"],
  "auto_upload": true,
  "supabase_url": "https://NEW_PROJECT_ID.supabase.co",
  "supabase_key": "NEW_ANON_KEY",
  "processed_log": "D:\\mk\\agent\\processed_files.json"
}
```

### Update Backend Config

Rename `backend/.env.new` to `backend/.env`:

```bash
# In Windows Explorer, just rename the file
# Or use command:
move /Y backend\.env.new backend\.env
```

### Test Everything

```bash
# Test connection
python backend/test_supabase.py

# Should show:
# ✅ Connection successful
# ✅ All tables exist
# ✅ Test upload successful
```

---

## ✅ Verification Checklist

After migration, check:

- [ ] Agent starts without errors
- [ ] System tray shows "Synced: X files"
- [ ] New data appears in Supabase dashboard
- [ ] All 3 branches visible in Table Editor
- [ ] Recent sales data imported
- [ ] No error logs in `agent/logs/`

---

## 🆘 If Something Goes Wrong

### Problem: "Invalid API key"
**Solution:** Check you copied the correct key (anon vs service_role)

### Problem: "Table doesn't exist"
**Solution:** Re-run `schema.sql` in SQL Editor

### Problem: Agent won't start
**Solution:** 
1. Check `agent/logs/agent.log`
2. Verify `config.json` has correct URL and key
3. Test manually: `python backend/test_supabase.py`

### Need to Rollback?
Keep old project active for 1 week. To rollback:
1. Rename `backend/.env` → `backend/.env.new`
2. Rename `backend/.env.old` → `backend/.env` (backup first)
3. Revert `agent/config.json` changes

---

## 📞 Quick Reference

| File | Purpose |
|------|---------|
| `backend/.env` | Current project credentials |
| `backend/.env.new` | New project credentials (before switch) |
| `agent/config.json` | Agent's Supabase connection |
| `backend/test_supabase.py` | Test connection script |
| `backend/export_data.py` | Export data script |
| `backend/import_to_new_supabase.py` | Import data script |

---

## 📊 Migration Timeline

| Phase | Duration | Downtime |
|-------|----------|----------|
| Export data | 5-10 mins | None |
| Apply schema | 2 mins | None |
| Import data | 10-15 mins | None |
| Update configs | 5 mins | None |
| Test sync | 10 mins | None |
| **Total** | **30-40 mins** | **Zero** |

You can continue using old system while setting up new one!

---

**Migration Date:** _________________  
**New Project URL:** _________________  
**Status:** ⬜ Not Started ⬜ In Progress ⬜ Complete ✅
