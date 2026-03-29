-- =============================================================================
-- Final Role Hierarchy Setup (President -> Shareholder -> Manager)
-- =============================================================================

-- 1. Update app_users table roles
ALTER TABLE app_users DROP CONSTRAINT IF EXISTS app_users_role_check;
ALTER TABLE app_users ADD CONSTRAINT app_users_role_check 
CHECK (role IN ('president', 'shareholder', 'brand_manager', 'branch_manager', 'viewer'));

-- 2. Refined RLS Policy for Tiered Access
DROP POLICY IF EXISTS "Allow users to see their allowed branch sales" ON daily_sales;
CREATE POLICY "Allow tiered access to daily sales" ON daily_sales
FOR SELECT TO authenticated
USING (
    -- Tier 1: President
    (SELECT role FROM app_users WHERE auth_id = auth.uid()) = 'president'
    OR
    -- Tier 2 & 3: Shareholder / Brand Manager
    branch_id IN (
        SELECT b.id FROM branches b 
        JOIN app_users u ON b.brand_id = ANY(u.allowed_brands)
        WHERE u.auth_id = auth.uid() AND u.role IN ('shareholder', 'brand_manager')
    )
    OR
    -- Tier 4: Branch Manager
    branch_id = ANY (
        SELECT unnest(allowed_branches) 
        FROM app_users 
        WHERE auth_id = auth.uid() AND role = 'branch_manager'
    )
);
