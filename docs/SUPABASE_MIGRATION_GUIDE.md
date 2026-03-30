# Supabase Migration Guide - Personal to Dedicated Account

This guide walks you through migrating from your personal Supabase account to a new dedicated account for MK Restaurants.

---

## 📋 Migration Checklist

### Phase 1: Preparation
- [ ] Create new dedicated email account
- [ ] Sign up for new Supabase account
- [ ] Create new Supabase project
- [ ] Export data from old project
- [ ] Set up new project schema
- [ ] Import data to new project
- [ ] Update all configurations
- [ ] Test thoroughly
- [ ] Switch over production

### Phase 2: Execution
- [ ] Backup old project (export all data)
- [ ] Apply schema to new project
- [ ] Migrate lookup data (branches, categories, void_reasons)
- [ ] Migrate transactional data (sales, transactions, voids)
- [ ] Update agent configuration
- [ ] Update mobile app configuration
- [ ] Test sync process
- [ ] Monitor for 24-48 hours

---

## 🔧 Step-by-Step Instructions

### Step 1: Create New Supabase Project

1. **Sign up at [supabase.com](https://supabase.com)** with your new dedicated email
2. **Create new organization:**
   - Name: `MK Restaurants Laos`
   - Team members: Add your personal email as collaborator
3. **Create new project:**
   - Project name: `mk-sales-production`
   - Database password: **Save this securely!**
   - Region: Choose closest to Laos (Singapore/AWS ap-southeast-1)

### Step 2: Get New Credentials

After project creation, go to **Settings → API** and copy:

```
Project URL: https://xxxxxxxxxxxxx.supabase.co
anon/public key: eyJhbGc... (starts with eyJ)
service_role key: eyJhbGc... (longer key, keep secret!)
```

### Step 3: Export Data from Old Project

Run the export script (created in next section):

```bash
cd D:\mk
venv\Scripts\activate
python backend/export_data.py
```

This will create backup files in `D:\mk\backup\`

### Step 4: Apply Schema to New Project

1. Go to new project's **SQL Editor**
2. Copy entire content from `backend/db/schema.sql`
3. Paste and run
4. Verify all tables are created (should see 15+ tables)

### Step 5: Import Data to New Project

Run the import script:

```bash
python backend/import_to_new_supabase.py
```

### Step 6: Update Configuration Files

#### Update Agent Config
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

#### Create Backend .env File
Create `D:\mk\backend\.env`:

```env
SUPABASE_URL=https://NEW_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY=NEW_ANON_KEY
SUPABASE_SERVICE_KEY=NEW_SERVICE_ROLE_KEY
APP_ENV=production
LOG_LEVEL=info
```

#### Update Mobile App Config
When mobile app is ready, update with new credentials.

### Step 7: Test Connection

```bash
cd D:\mk\backend
python test_supabase.py
```

Should show:
- ✅ Connected to Supabase
- ✅ Found X branches
- ✅ Test record inserted successfully

### Step 8: Test Agent Sync

1. Start the agent:
   ```bash
   cd D:\mk\agent
   python tray_app.py
   ```

2. Check system tray icon
3. Click "Sync Now"
4. Verify data appears in new Supabase project (Table Editor)

### Step 9: Monitor

- Watch agent logs for errors
- Check Supabase Dashboard → Database → Row count increasing
- Verify mobile app can connect (when deployed)

---

## 🚨 Important Notes

### Security
- **Never commit `.env` file** to Git (it's in .gitignore)
- **Service role key** = admin access, only use in backend
- **Anon key** = client-side access (mobile app), safe to expose

### Billing
- Set up billing under new organization
- Enable spending limits to avoid surprises
- Free tier: 500MB database, 50k monthly active users

### Downtime Planning
- Plan migration during low-activity period (e.g., afternoon)
- Expected downtime: 30-60 minutes
- Old data will remain accessible until you switch configs

### Rollback Plan
If something goes wrong:
1. Keep old project active for 1-2 weeks
2. If issues arise, revert config files to old credentials
3. Fix issues in new project
4. Try migration again

---

## 📁 Files to Update

| File | What to Update |
|------|----------------|
| `agent/config.json` | Add `supabase_url` and `supabase_key` |
| `backend/.env` | Create with new credentials |
| `mobile/.env` (when exists) | Update Supabase credentials |
| Any CI/CD configs | Update environment variables |

---

## 🛠️ Migration Scripts

### 1. Export Script: `backend/export_data.py`
Exports all data from old project to JSON files

### 2. Import Script: `backend/import_to_new_supabase.py`
Imports exported data to new project

### 3. Test Script: `backend/test_supabase.py`
Verifies connection and basic operations

---

## ✅ Verification Checklist

After migration, verify:

- [ ] All 3 branches exist in new project
- [ ] Categories are populated
- [ ] Recent daily_sales records exist
- [ ] Recent product_sales records exist
- [ ] Recent transactions exist
- [ ] void_log has recent records
- [ ] sync_log shows successful imports
- [ ] Agent can upload new files
- [ ] Mobile app can fetch data (when deployed)
- [ ] Dashboard views work (v_today_summary, etc.)

---

## 🆘 Troubleshooting

### "Invalid API key"
- Check you're using correct key type (anon vs service_role)
- Verify URL is correct (no typos)

### "Table doesn't exist"
- Schema wasn't applied correctly
- Re-run schema.sql in new project's SQL Editor

### "Row level security policy violation"
- RLS policies too restrictive
- Check that policies allow authenticated users

### Agent not syncing
- Check agent logs in `agent/logs/`
- Verify config.json has correct credentials
- Test Supabase connection manually

---

## 📞 Support

If you encounter issues:
1. Check Supabase Dashboard → Logs
2. Review agent logs
3. Test connection with `test_supabase.py`
4. Contact Supabase support via dashboard

---

**Migration Date:** _________________  
**Migrated By:** _________________  
**New Project URL:** _________________  
**Old Project URL:** _________________  
