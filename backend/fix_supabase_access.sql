-- ================================================================
-- FIX: Enable Anonymous Access for Mobile App
-- Run this ENTIRE script in Supabase SQL Editor
-- ================================================================

-- 1. First, disable RLS temporarily to test
ALTER TABLE branches DISABLE ROW LEVEL SECURITY;
ALTER TABLE daily_sales DISABLE ROW LEVEL SECURITY;
ALTER TABLE hourly_sales DISABLE ROW LEVEL SECURITY;
ALTER TABLE product_sales DISABLE ROW LEVEL SECURITY;
ALTER TABLE void_log DISABLE ROW LEVEL SECURITY;
ALTER TABLE transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_items DISABLE ROW LEVEL SECURITY;

-- 2. Create anonymous access policies (if you want RLS enabled)
-- Branches
DROP POLICY IF EXISTS "Enable read access for all users" ON branches;
CREATE POLICY "Enable read access for all users" ON branches
    FOR SELECT
    TO authenticated, anon
    USING (true);

-- Daily Sales
DROP POLICY IF EXISTS "Enable read access for all users" ON daily_sales;
CREATE POLICY "Enable read access for all users" ON daily_sales
    FOR SELECT
    TO authenticated, anon
    USING (true);

-- Hourly Sales
DROP POLICY IF EXISTS "Enable read access for all users" ON hourly_sales;
CREATE POLICY "Enable read access for all users" ON hourly_sales
    FOR SELECT
    TO authenticated, anon
    USING (true);

-- Product Sales
DROP POLICY IF EXISTS "Enable read access for all users" ON product_sales;
CREATE POLICY "Enable read access for all users" ON product_sales
    FOR SELECT
    TO authenticated, anon
    USING (true);

-- Void Log
DROP POLICY IF EXISTS "Enable read access for all users" ON void_log;
CREATE POLICY "Enable read access for all users" ON void_log
    FOR SELECT
    TO authenticated, anon
    USING (true);

-- 3. Re-enable RLS (optional - comment out if you disabled above)
-- ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE daily_sales ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE hourly_sales ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE product_sales ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE void_log ENABLE ROW LEVEL SECURITY;

-- 4. Test query - should return data
SELECT COUNT(*) as test_count FROM daily_sales;

-- If you see a number > 0, the fix worked!
