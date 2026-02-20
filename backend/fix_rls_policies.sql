-- Fix Supabase RLS Policies for Mobile App Access
-- Run this in Supabase SQL Editor

-- Allow anonymous read access to all tables needed by mobile app

-- Branches
DROP POLICY IF EXISTS "Allow anonymous read access" ON branches;
CREATE POLICY "Allow anonymous read access" ON branches
    FOR SELECT
    TO authenticated, anon
    USING (true);

-- Daily Sales
DROP POLICY IF EXISTS "Allow anonymous read access" ON daily_sales;
CREATE POLICY "Allow anonymous read access" ON daily_sales
    FOR SELECT
    TO authenticated, anon
    USING (true);

-- Hourly Sales
DROP POLICY IF EXISTS "Allow anonymous read access" ON hourly_sales;
CREATE POLICY "Allow anonymous read access" ON hourly_sales
    FOR SELECT
    TO authenticated, anon
    USING (true);

-- Product Sales
DROP POLICY IF EXISTS "Allow anonymous read access" ON product_sales;
CREATE POLICY "Allow anonymous read access" ON product_sales
    FOR SELECT
    TO authenticated, anon
    USING (true);

-- Void Log
DROP POLICY IF EXISTS "Allow anonymous read access" ON void_log;
CREATE POLICY "Allow anonymous read access" ON void_log
    FOR SELECT
    TO authenticated, anon
    USING (true);

-- Transactions
DROP POLICY IF EXISTS "Allow anonymous read access" ON transactions;
CREATE POLICY "Allow anonymous read access" ON transactions
    FOR SELECT
    TO authenticated, anon
    USING (true);

-- Transaction Items
DROP POLICY IF EXISTS "Allow anonymous read access" ON transaction_items;
CREATE POLICY "Allow anonymous read access" ON transaction_items
    FOR SELECT
    TO authenticated, anon
    USING (true);
