-- =============================================================================
-- MK Restaurants Laos - Database Schema for Supabase
-- Version: 1.1
-- Created: February 2026
-- Updated: Added Lao language support
-- =============================================================================

-- Enable UUID extension (Supabase has this by default)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- LOOKUP TABLES
-- =============================================================================

-- Branches
CREATE TABLE branches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    name_en VARCHAR(100),
    name_lao VARCHAR(100),
    location VARCHAR(200),
    timezone VARCHAR(50) DEFAULT 'Asia/Vientiane',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Categories
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_th VARCHAR(100) NOT NULL,
    name_en VARCHAR(100),
    name_lao VARCHAR(100),
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Void Reasons
CREATE TABLE void_reasons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reason_th VARCHAR(200) NOT NULL,
    reason_en VARCHAR(200),
    reason_lao VARCHAR(200),
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true
);

-- Seed void reasons (Thai, English, Lao)
INSERT INTO void_reasons (reason_th, reason_en, reason_lao, sort_order) VALUES
('ลูกค้าเปลี่ยนรายการ', 'Customer changed order', 'ລູກຄ້າປ່ຽນລາຍການ', 1),
('อาหารหมด', 'Food out of stock', 'ອາຫານໝົດ', 2),
('ลูกค้าปฏิเสธรายการอาหาร', 'Customer rejected item', 'ລູກຄ້າປະຕິເສດລາຍການອາຫານ', 3),
('จดรายการอาหารผิดพลาด', 'Order entry error', 'ບັນທຶກລາຍການອາຫານຜິດພາດ', 4),
('อื่นๆ', 'Other', 'ອື່ນໆ', 99);

-- =============================================================================
-- PRODUCT TABLES
-- =============================================================================

-- Products
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    product_code VARCHAR(50),
    name_th VARCHAR(200) NOT NULL,
    name_en VARCHAR(200),
    name_lao VARCHAR(200),
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    unit_price DECIMAL(12,2),
    unit VARCHAR(20) DEFAULT 'item',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(branch_id, product_code)
);

-- =============================================================================
-- SALES TABLES
-- =============================================================================

-- Daily Sales Summary
CREATE TABLE daily_sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
    sale_date DATE NOT NULL,
    
    -- Revenue
    gross_sales DECIMAL(15,2) DEFAULT 0,
    net_sales DECIMAL(15,2) DEFAULT 0,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    discount_amount DECIMAL(15,2) DEFAULT 0,
    rounding_amount DECIMAL(10,2) DEFAULT 0,
    
    -- Volume
    receipt_count INT DEFAULT 0,
    customer_count INT DEFAULT 0,
    table_count INT DEFAULT 0,
    
    -- Voids
    void_count INT DEFAULT 0,
    void_amount DECIMAL(15,2) DEFAULT 0,
    
    -- Takeaway
    takeaway_receipts INT DEFAULT 0,
    takeaway_sales DECIMAL(15,2) DEFAULT 0,
    
    -- Metadata
    data_source VARCHAR(50),
    imported_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(branch_id, sale_date)
);

-- Hourly Sales
CREATE TABLE hourly_sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
    sale_date DATE NOT NULL,
    hour INT NOT NULL CHECK (hour >= 0 AND hour <= 23),
    
    table_count INT DEFAULT 0,
    customer_count INT DEFAULT 0,
    sales DECIMAL(15,2) DEFAULT 0,
    
    imported_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(branch_id, sale_date, hour)
);

-- Product Sales (Daily aggregated by product)
CREATE TABLE product_sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
    sale_date DATE NOT NULL,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    
    -- Store original name in case product changes
    product_name_th VARCHAR(200),
    product_name_lao VARCHAR(200),
    
    quantity INT DEFAULT 0,
    unit_price DECIMAL(12,2),
    total_amount DECIMAL(15,2) DEFAULT 0,
    
    -- Category at time of sale
    category_name VARCHAR(100),
    
    imported_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(branch_id, sale_date, product_id)
);

-- =============================================================================
-- TRANSACTION TABLES
-- =============================================================================

-- Table Transactions (Individual bills)
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
    sale_date DATE NOT NULL,
    
    -- Receipt info
    receipt_no VARCHAR(50) NOT NULL,
    receipt_type VARCHAR(20),
    
    -- Table info
    table_no VARCHAR(20),
    time_in TIME,
    time_out TIME,
    
    -- Customer
    customer_count INT DEFAULT 0,
    
    -- Amounts
    gross_amount DECIMAL(15,2) DEFAULT 0,
    discount_amount DECIMAL(15,2) DEFAULT 0,
    net_amount DECIMAL(15,2) DEFAULT 0,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    rounding_amount DECIMAL(10,2) DEFAULT 0,
    
    -- Discount info
    discount_card VARCHAR(20),
    
    -- Status
    is_voided BOOLEAN DEFAULT false,
    
    -- Payment
    payment_method VARCHAR(20) DEFAULT 'cash',
    
    imported_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(branch_id, receipt_no)
);

-- Transaction Items (Line items within a bill)
CREATE TABLE transaction_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID REFERENCES transactions(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    
    product_name_th VARCHAR(200),
    product_name_lao VARCHAR(200),
    quantity INT DEFAULT 1,
    unit_price DECIMAL(12,2),
    total_amount DECIMAL(15,2),
    
    is_voided BOOLEAN DEFAULT false,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- VOID/EXCEPTION TABLES
-- =============================================================================

-- Void Log
CREATE TABLE void_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
    sale_date DATE NOT NULL,
    
    -- Transaction info
    original_receipt_no VARCHAR(50),
    table_no VARCHAR(20),
    time_voided TIME,
    
    -- Product info
    product_name_th VARCHAR(200),
    product_name_lao VARCHAR(200),
    quantity INT,
    unit_price DECIMAL(12,2),
    amount DECIMAL(15,2),
    
    -- Reason
    reason_id UUID REFERENCES void_reasons(id),
    reason_text VARCHAR(200),
    
    -- People
    approved_by VARCHAR(100),
    recorded_by VARCHAR(100),
    
    imported_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- USER MANAGEMENT (for mobile app)
-- =============================================================================

-- App Users (extends Supabase auth.users)
CREATE TABLE app_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    
    role VARCHAR(20) DEFAULT 'viewer',
    branch_access UUID[],
    
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- SYNC & AUDIT TABLES
-- =============================================================================

-- Sync Log (track data imports)
CREATE TABLE sync_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
    
    sync_date DATE NOT NULL,
    sync_time TIMESTAMPTZ DEFAULT NOW(),
    
    -- File info
    file_name VARCHAR(200),
    file_type VARCHAR(50),
    
    -- Status
    status VARCHAR(20) DEFAULT 'success',
    records_imported INT DEFAULT 0,
    error_message TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Data Import Log (raw file tracking)
CREATE TABLE import_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID REFERENCES branches(id) ON DELETE CASCADE,
    
    -- File info
    file_name VARCHAR(200) NOT NULL,
    file_type VARCHAR(50),
    file_size INT,
    
    -- Import status
    status VARCHAR(20) DEFAULT 'pending',
    imported_at TIMESTAMPTZ,
    error_message TEXT,
    
    -- Records
    total_rows INT,
    imported_rows INT,
    skipped_rows INT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Daily sales
CREATE INDEX idx_daily_sales_branch_date ON daily_sales(branch_id, sale_date DESC);
CREATE INDEX idx_daily_sales_date ON daily_sales(sale_date DESC);

-- Hourly sales
CREATE INDEX idx_hourly_sales_branch_date ON hourly_sales(branch_id, sale_date DESC);
CREATE INDEX idx_hourly_sales_date ON hourly_sales(sale_date DESC);

-- Product sales
CREATE INDEX idx_product_sales_branch_date ON product_sales(branch_id, sale_date DESC);
CREATE INDEX idx_product_sales_product ON product_sales(product_id);
CREATE INDEX idx_product_sales_date ON product_sales(sale_date DESC);

-- Transactions
CREATE INDEX idx_transactions_branch_date ON transactions(branch_id, sale_date DESC);
CREATE INDEX idx_transactions_date ON transactions(sale_date DESC);
CREATE INDEX idx_transactions_receipt ON transactions(receipt_no);

-- Void log
CREATE INDEX idx_void_log_branch_date ON void_log(branch_id, sale_date DESC);
CREATE INDEX idx_void_log_date ON void_log(sale_date DESC);

-- Sync log
CREATE INDEX idx_sync_log_branch ON sync_log(branch_id);
CREATE INDEX idx_sync_log_date ON sync_log(sync_date DESC);

-- Products
CREATE INDEX idx_products_branch ON products(branch_id);
CREATE INDEX idx_products_category ON products(category_id);

-- =============================================================================
-- VIEWS FOR DASHBOARD
-- =============================================================================

-- View: Today's Summary (all branches)
CREATE OR REPLACE VIEW v_today_summary AS
SELECT 
    sale_date,
    COUNT(DISTINCT branch_id) as branch_count,
    SUM(gross_sales) as total_gross_sales,
    SUM(net_sales) as total_net_sales,
    SUM(receipt_count) as total_receipts,
    SUM(customer_count) as total_customers,
    SUM(void_amount) as total_voids,
    CASE 
        WHEN SUM(receipt_count) > 0 
        THEN SUM(net_sales) / SUM(receipt_count) 
        ELSE 0 
    END as avg_ticket_value,
    CASE 
        WHEN SUM(customer_count) > 0 
        THEN SUM(net_sales) / SUM(customer_count) 
        ELSE 0 
    END as avg_per_customer
FROM daily_sales
WHERE sale_date = CURRENT_DATE
GROUP BY sale_date;

-- View: Branch Performance
CREATE OR REPLACE VIEW v_branch_performance AS
SELECT 
    b.id as branch_id,
    b.code as branch_code,
    b.name as branch_name,
    b.name_lao as branch_name_lao,
    b.name_en as branch_name_en,
    ds.sale_date,
    ds.net_sales,
    ds.receipt_count,
    ds.customer_count,
    ds.void_amount,
    CASE 
        WHEN ds.receipt_count > 0 
        THEN ds.net_sales / ds.receipt_count 
        ELSE 0 
    END as avg_ticket_value
FROM daily_sales ds
JOIN branches b ON b.id = ds.branch_id
ORDER BY ds.sale_date DESC, b.code;

-- View: Peak Hours Analysis
CREATE OR REPLACE VIEW v_peak_hours AS
SELECT 
    hs.sale_date,
    hs.hour,
    SUM(hs.sales) as total_sales,
    SUM(hs.customer_count) as total_customers,
    SUM(hs.table_count) as total_tables
FROM hourly_sales hs
GROUP BY hs.sale_date, hs.hour
ORDER BY hs.sale_date DESC, hs.hour;

-- View: Product Performance
CREATE OR REPLACE VIEW v_product_performance AS
SELECT 
    ps.sale_date,
    ps.category_name,
    ps.product_name_th,
    ps.product_name_lao,
    SUM(ps.quantity) as total_qty,
    SUM(ps.total_amount) as total_sales
FROM product_sales ps
GROUP BY ps.sale_date, ps.category_name, ps.product_name_th, ps.product_name_lao
ORDER BY ps.sale_date DESC, total_sales DESC;

-- View: Void Summary
CREATE OR REPLACE VIEW v_void_summary AS
SELECT 
    vl.sale_date,
    b.code as branch_code,
    b.name as branch_name,
    b.name_lao as branch_name_lao,
    COUNT(*) as void_count,
    SUM(vl.amount) as void_amount,
    vr.reason_en as reason_en,
    vr.reason_lao as reason_lao
FROM void_log vl
JOIN branches b ON b.id = vl.branch_id
LEFT JOIN void_reasons vr ON vr.id = vl.reason_id
GROUP BY vl.sale_date, b.code, b.name, b.name_lao, vr.reason_en, vr.reason_lao
ORDER BY vl.sale_date DESC, void_amount DESC;

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function: Update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to tables with updated_at
CREATE TRIGGER update_branches_updated_at BEFORE UPDATE ON branches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_app_users_updated_at BEFORE UPDATE ON app_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE hourly_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE void_log ENABLE ROW LEVEL SECURITY;

-- Policy: Allow all for authenticated users (can be refined later)
CREATE POLICY "Allow all for authenticated users" ON branches
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow all for authenticated users" ON daily_sales
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow all for authenticated users" ON hourly_sales
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow all for authenticated users" ON product_sales
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow all for authenticated users" ON transactions
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow all for authenticated users" ON transaction_items
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow all for authenticated users" ON void_log
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- =============================================================================
-- SEED DATA
-- =============================================================================

-- Insert default branches (Thai name, English, Lao)
INSERT INTO branches (code, name, name_en, name_lao, location) VALUES
('MK001', 'MK Watnak', 'MK Watnak', 'ເອັມເຄ ວັດນາກ', 'ວຽງຈັນ'),
('MK002', 'MK Branch 2', 'MK Branch 2', 'ເອັມເຄ ສາຂາ 2', 'TBD'),
('MK003', 'MK Branch 3', 'MK Branch 3', 'ເອັມເຄ ສາຂາ 3', 'TBD');

-- Insert common categories (Thai, English, Lao)
INSERT INTO categories (name_th, name_en, name_lao, sort_order) VALUES
('เป็ดย่าง', 'Roast Duck', 'ເປັດຍ່າງ', 1),
('สุกี้', 'Suki', 'ສຸກີ', 2),
('สุกี้ชาม', 'Suki Sets', 'ສຸກີຊາມ', 3),
('คัวเปา', 'Dim Sum', 'ຂະໜົມຈີນ', 4),
('เครื่องดื่ม', 'Beverages', 'ເຄື່ອງດື່ມ', 5),
('กะแล้ม', 'Desserts', 'ຂອງຫວານ', 6),
('ขนมและเครื่องดื่ม', 'Snacks & Drinks', 'ຂະໜົມ ແລະ ເຄື່ອງດື່ມ', 7),
('Wisky', 'Whisky', 'ວິສກີ', 8);

-- =============================================================================
-- END OF SCHEMA
-- =============================================================================
