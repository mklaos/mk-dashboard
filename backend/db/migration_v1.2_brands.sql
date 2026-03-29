-- =============================================================================
-- Migration: Add Brand Hierarchy and Granular Roles
-- Version: 1.2
-- Created: 28 March 2026
-- =============================================================================

-- 1. Create Brands table
CREATE TABLE IF NOT EXISTS brands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    name_lao VARCHAR(100),
    name_en VARCHAR(100),
    logo_url TEXT,
    primary_color VARCHAR(20) DEFAULT '#E31E24', -- Default MK Red
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Add brand_id to branches
ALTER TABLE branches ADD COLUMN IF NOT EXISTS brand_id UUID REFERENCES brands(id) ON DELETE SET NULL;

-- 3. Update app_users for role-based access
ALTER TABLE app_users ADD COLUMN IF NOT EXISTS allowed_brands UUID[];
ALTER TABLE app_users ADD COLUMN IF NOT EXISTS allowed_branches UUID[];

-- 4. Seed initial MK Brand
INSERT INTO brands (name, name_lao, name_en, primary_color)
VALUES ('MK Restaurants', 'ເອັມເຄ ວັດນາກ', 'MK Restaurants', '#E31E24')
ON CONFLICT DO NOTHING;

-- Link existing MK branches to the MK Brand
DO $$
DECLARE
    mk_brand_id UUID;
BEGIN
    SELECT id INTO mk_brand_id FROM brands WHERE name = 'MK Restaurants' LIMIT 1;
    IF mk_brand_id IS NOT NULL THEN
        UPDATE branches SET brand_id = mk_brand_id WHERE code LIKE 'MK%';
    END IF;
END $$;

-- 5. Seed initial Miyazaki and Hardrock Brands (Placeholders)
INSERT INTO brands (name, name_lao, name_en, primary_color)
VALUES 
('Miyazaki', 'ມິຢາຊາກິ', 'Miyazaki', '#000000'),
('Hard Rock Cafe', 'ຮາດຣັອກ ຄາເຟ່', 'Hard Rock Cafe', '#ED1C24')
ON CONFLICT DO NOTHING;

-- 6. Update Daily Sales View to include Brand
CREATE OR REPLACE VIEW v_branch_performance AS
SELECT 
    b.id as branch_id,
    b.code as branch_code,
    b.name as branch_name,
    b.name_lao as branch_name_lao,
    b.name_en as branch_name_en,
    br.id as brand_id,
    br.name as brand_name,
    br.name_lao as brand_name_lao,
    ds.sale_date,
    ds.net_sales,
    ds.receipt_count,
    ds.customer_count,
    ds.void_amount,
    ds.discount_amount,
    ds.tax_amount,
    CASE 
        WHEN ds.receipt_count > 0 
        THEN ds.net_sales / ds.receipt_count 
        ELSE 0 
    END as avg_ticket_value
FROM daily_sales ds
JOIN branches b ON b.id = ds.branch_id
LEFT JOIN brands br ON b.brand_id = br.id
ORDER BY ds.sale_date DESC, b.code;

-- 7. Update RLS Policies (Example for Brand-Level Access)
-- This ensures users only see data for brands they are allowed to access
DROP POLICY IF EXISTS "Allow users to see their allowed brands" ON brands;
CREATE POLICY "Allow users to see their allowed brands" ON brands
FOR SELECT TO authenticated
USING (
    id = ANY (
        SELECT unnest(allowed_brands) 
        FROM app_users 
        WHERE auth_id = auth.uid()
    ) OR (
        SELECT role FROM app_users WHERE auth_id = auth.uid()
    ) = 'owner'
);

-- Apply similar logic to daily_sales, but filtered via branch_id -> brand_id
DROP POLICY IF EXISTS "Allow users to see their allowed branch sales" ON daily_sales;
CREATE POLICY "Allow users to see their allowed branch sales" ON daily_sales
FOR SELECT TO authenticated
USING (
    branch_id = ANY (
        SELECT unnest(allowed_branches) 
        FROM app_users 
        WHERE auth_id = auth.uid()
    ) OR 
    branch_id IN (
        SELECT b.id FROM branches b 
        JOIN app_users u ON b.brand_id = ANY(u.allowed_brands)
        WHERE u.auth_id = auth.uid()
    ) OR (
        SELECT role FROM app_users WHERE auth_id = auth.uid()
    ) = 'owner'
);
