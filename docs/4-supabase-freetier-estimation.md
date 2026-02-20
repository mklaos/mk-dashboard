1. Daily Data Volume Estimation (Per Branch)
  Based on the file sizes (total ~250 KB per branch per day) and the schema in 1-initial-plan.md, here's a row count estimation:



  ┌──────────────────────────────────────────┬─────────────────┬──────────────────────────────┐
  │ Table Type                               │ Est. Rows / Day │ Storage (Est. 500 bytes/row) │
  ├──────────────────────────────────────────┼─────────────────┼──────────────────────────────┤
  │ Summary Tables (Sales, VAT, Hourly)      │ ~50             │ 25 KB                        │
  │ Transaction Tables (Receipts, Tables)    │ ~100            │ 50 KB                        │
  │ Product Sales (Suki, Drinks, Duck, etc.) │ ~500            │ 250 KB                       │
  │ Exception Logs (Voids, VIP, etc.)        │ ~50             │ 25 KB                        │
  │ Total Per Branch                         │ ~700 Rows       │ ~350 KB                      │
  └──────────────────────────────────────────┴─────────────────┴──────────────────────────────┘



  2. Full Project Estimation (3 Branches)
   * Daily Growth: ~2,100 rows / ~1.05 MB per day
   * Monthly Growth: ~63,000 rows / ~31.5 MB per month
   * Annual Growth: ~760,000 rows / ~380 MB per year

  ---

  3. Supabase Free Account Lifespan
  The Supabase Free Tier has a hard limit of 500MB for database storage.


   * Projected Lifespan: ~15 to 16 months (roughly 475 days) before hitting the 500MB limit.
   * Performance: Even at 500,000+ rows, PostgreSQL (Supabase) will remain extremely fast because these tables are well-indexed by sale_date and branch_id.


  Recommendations to Extend Lifespan:
   1. Retention Policy: If the President only needs high-level trends for older data, you can implement a "Data Purge" after 1 year—keeping daily summaries but deleting line-item
      details (like individual beverage orders) from the product_sales table for older months. This would extend the life of the free tier indefinitely.
   2. Strategic Upgrade: Once the system proves its value, upgrading to the Supabase Pro Plan ($25/month) provides 8GB of storage, which would last for over 20 years at current growth
      rates.
   3. Deduplication: Ensure the API uses "UPSERT" (Update or Insert) logic so that if staff clicks "Sync Now" 5 times a day, it doesn't duplicate the data—it just updates the existing
      records for that day.


  Summary: For the first year, you will be well within the free limits, and the dashboard will feel very snappy. You'll likely only need to consider storage management or a Pro
  upgrade around mid-2027.
