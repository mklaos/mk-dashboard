# MK Restaurants - Automated Sales Intelligence System
## Initial Implementation Plan

**Project**: Mobile Executive Dashboard & Automated Sales Consolidation  
**Client**: MK Restaurants Laos  
**Date**: February 2026  
**Prepared by**: Dr. Bounthong Vongxaya (with AI Development Assistance)

---

## 1. Project Overview

### Current Situation
- 3 MK Restaurant branches in Laos using legacy POS system (Crystal Reports)
- Daily sales reports exported as XLS files (17 different report types)
- Manual consolidation required - accounting team spends hours daily
- Management has delayed visibility into business performance

### Objective
Build an automated system that:
1. Collects sales data from all branches automatically
2. Consolidates into a cloud database
3. Presents real-time insights via mobile dashboard app

---

## 2. System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         BRANCH LEVEL                                 │
├─────────────────┬─────────────────┬─────────────────┬───────────────┤
│   Branch 1      │   Branch 2      │   Branch 3      │               │
│                 │                 │                 │               │
│ ┌─────────────┐ │ ┌─────────────┐ │ ┌─────────────┐ │               │
│ │  POS System │ │ │  POS System │ │ │  POS System │ │               │
│ │  (Crystal)  │ │ │  (Crystal)  │ │ │  (Crystal)  │               │
│ └──────┬──────┘ │ └──────┬──────┘ │ └──────┬──────┘ │               │
│        │        │        │        │        │        │               │
│        ▼        │        ▼        │        ▼        │               │
│ ┌─────────────┐ │ ┌─────────────┐ │ ┌─────────────┐ │               │
│ │ XLS Reports │ │ │ XLS Reports │ │ │ XLS Reports │ │               │
│ │ (Scheduled) │ │ │ (Scheduled) │ │ │ (Scheduled) │ │               │
│ └──────┬──────┘ │ └──────┬──────┘ │ └──────┬──────┘ │               │
│        │        │        │        │        │        │               │
│ ┌──────▼──────┐ │ ┌──────▼──────┐ │ ┌──────▼──────┐ │               │
│ │ Local Agent │ │ │ Local Agent │ │ │ Local Agent │ │               │
│ │ (Tray App)  │ │ │ (Tray App)  │ │ │ (Tray App)  │ │               │
│ └──────┬──────┘ │ └──────┬──────┘ │ └──────┬──────┘ │               │
└────────┼────────┴────────┼────────┴────────┼────────┘               │
         │                 │                 │                        │
         └─────────────────┼─────────────────┘                        │
                           │                                          │
                           ▼                                          │
                  ┌─────────────────┐                                 │
                  │   Cloud API     │                                 │
                  │   (REST/WS)     │                                 │
                  └────────┬────────┘                                 │
                           │                                          │
         ┌─────────────────┼─────────────────┐                        │
         │                 │                 │                        │
         ▼                 ▼                 ▼                        │
┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  PostgreSQL │    │    Redis    │    │   Node.js   │                 │
│  Database   │    │   (Cache)   │    │   Backend   │                 │
└─────────────┘    └─────────────┘    └─────────────┘                 │
                                                                     │
                  ┌─────────────────┐                                 │
                  │ Flutter Mobile  │  ◄── President's Dashboard     │
                  │      App        │                                 │
                  └─────────────────┘                                 │
                                                                     │
                  ┌─────────────────┐                                 │
                  │   WhatsApp +    │  ◄── Phase 2: AI Assistant     │
                  │   OpenAI API    │                                 │
                  └─────────────────┘                                 │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. Data Sources Analysis

### POS Report Files (17 types, all same format across branches)

| File Name (Thai) | English Name | Purpose |
|------------------|--------------|---------|
| ยอดขาย | Daily Sales | Summary of daily transactions |
| ยอดขายตามช่วงเวลา | Hourly Sales | Sales breakdown by hour |
| แยกตามกุ่มโตะ | Table Details | Individual table transactions |
| แยกตามจำนวนลูกค้า | Customer Count | Sales by customer group size |
| แยกตามครัว | Kitchen Categories | Sales by food category |
| ใบเสร็จ | Receipts | All receipt details |
| สุกี้ | Suki Items | Suki product sales |
| สุกี้ชาม | Suki Sets | Suki set meals |
| คัวเป็ด | Duck Items | Duck menu sales |
| คัวเปา | Dim Sum | Dim sum/appetizer sales |
| เครื่องดื่ม | Beverages | Drink sales |
| กะแล้ม | Desserts | Dessert sales |
| ยกเลิก | Voided Items | Cancelled items log |
| วีไอพี | VIP | VIP customer sales |
| เครดิต | Credit | Credit card payments |
| พาสี | VAT Summary | Tax summary report |
| สะหลุบตามกุ่มโตะ | Table Type Summary | Dine-in vs Takeaway |

### Sample Data Metrics (Dec 1, 2024 - Single Branch)

| Metric | Value |
|--------|-------|
| Total Sales | 35,887,500 LAK |
| Receipts | 54 |
| Customers | 127 |
| Avg per Receipt | 612,171 LAK |
| Avg per Customer | 260,293 LAK |
| Peak Hour | 18:00 (17.7M LAK) |
| Dinner Share | 68% of daily sales |

---

## 4. Implementation Approach

### Integration Method: Option B - Checkpoint Automation

**Why Checkpoint (not Real-Time):**
- POS system is legacy (Crystal Reports based)
- No API or direct database access available
- Files are already generated automatically by POS schedule

**Checkpoint Schedule:**
| Checkpoint | Time | Purpose |
|------------|------|---------|
| Lunch | 14:30 | Post-lunch summary |
| Dinner | 22:30 | End of day closing |
| Optional | 17:00 | Pre-dinner status (Phase 2) |

### Local Agent: Windows Tray Application

We will build a lightweight Windows tray application that:
- Runs in system tray (background)
- Watches for new XLS files in designated folder
- Parses and uploads to cloud API
- Shows connection status and last sync time
- Auto-starts with Windows
- No technical knowledge required to operate

---

## 5. Technology Stack

### Branch Level (Local Agent)
| Component | Technology | Purpose |
|-----------|------------|---------|
| Language | Python 3.11+ | Core development |
| GUI | PyQt5 / CustomTkinter | System tray interface |
| File Watcher | watchdog | Monitor XLS file creation |
| Parser | pandas + xlrd | Parse XLS files |
| HTTP Client | requests | API communication |
| Packaging | PyInstaller | Create .exe installer |

### Cloud Backend
| Component | Technology | Purpose |
|-----------|------------|---------|
| Runtime | Node.js 20+ | API server |
| Framework | Fastify / Express | REST API |
| Database | PostgreSQL 16 | Primary data store |
| Cache | Redis | Session & data caching |
| ORM | Prisma / Drizzle | Database access |
| Auth | JWT | Mobile app authentication |
| Hosting | DigitalOcean / Railway | Cloud infrastructure |

### Mobile App
| Component | Technology | Purpose |
|-----------|------------|---------|
| Framework | Flutter 3.x | Cross-platform app |
| State | Riverpod / Bloc | State management |
| Charts | FL Chart | Data visualization |
| HTTP | Dio | API client |
| Auth | Firebase Auth / Custom | User authentication |

### Phase 2 Additions
| Component | Technology | Purpose |
|-----------|------------|---------|
| AI | OpenAI API | Natural language queries |
| Messaging | WhatsApp Business API | Chat interface |

---

## 6. Database Schema (Core Tables)

```sql
-- Branches
CREATE TABLE branches (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(200),
    timezone VARCHAR(50) DEFAULT 'Asia/Vientiane',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Daily Sales Summary
CREATE TABLE daily_sales (
    id SERIAL PRIMARY KEY,
    branch_id INT REFERENCES branches(id),
    sale_date DATE NOT NULL,
    gross_sales DECIMAL(15,2),
    net_sales DECIMAL(15,2),
    tax_amount DECIMAL(15,2),
    receipt_count INT,
    customer_count INT,
    void_count INT,
    void_amount DECIMAL(15,2),
    discount_amount DECIMAL(15,2),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(branch_id, sale_date)
);

-- Hourly Sales
CREATE TABLE hourly_sales (
    id SERIAL PRIMARY KEY,
    branch_id INT REFERENCES branches(id),
    sale_date DATE NOT NULL,
    hour INT NOT NULL, -- 0-23
    table_count INT,
    customer_count INT,
    sales DECIMAL(15,2),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(branch_id, sale_date, hour)
);

-- Products Catalog (Updated with Lao Support)
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    branch_id INT REFERENCES branches(id),
    product_code VARCHAR(50),
    name_th VARCHAR(200),      -- Original Thai name from POS
    name_en VARCHAR(200),      -- English translation
    name_lao VARCHAR(200),     -- Lao translation (for dashboard display)
    category VARCHAR(100),
    unit_price DECIMAL(10,2),
    is_active BOOLEAN DEFAULT true,
    UNIQUE(branch_id, product_code)
);

-- Note: Dashboard will display in Lao + English (not Thai)
-- See backend/db/schema.sql for complete schema with full Lao support

-- Product Sales
CREATE TABLE product_sales (
    id SERIAL PRIMARY KEY,
    branch_id INT REFERENCES branches(id),
    sale_date DATE NOT NULL,
    product_id INT REFERENCES products(id),
    quantity INT,
    unit_price DECIMAL(10,2),
    total_amount DECIMAL(15,2),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(branch_id, sale_date, product_id)
);

-- Table Transactions
CREATE TABLE table_transactions (
    id SERIAL PRIMARY KEY,
    branch_id INT REFERENCES branches(id),
    sale_date DATE NOT NULL,
    receipt_no VARCHAR(50),
    table_no VARCHAR(20),
    time_in TIME,
    time_out TIME,
    customer_count INT,
    gross_amount DECIMAL(15,2),
    discount_amount DECIMAL(15,2),
    net_amount DECIMAL(15,2),
    payment_method VARCHAR(20),
    is_voided BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(branch_id, receipt_no)
);

-- Void Log
CREATE TABLE void_log (
    id SERIAL PRIMARY KEY,
    branch_id INT REFERENCES branches(id),
    sale_date DATE NOT NULL,
    receipt_no VARCHAR(50),
    table_no VARCHAR(20),
    time_voided TIME,
    product_name VARCHAR(200),
    quantity INT,
    amount DECIMAL(15,2),
    reason VARCHAR(200),
    approved_by VARCHAR(100),
    recorded_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Users (for mobile app)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(100),
    role VARCHAR(20) DEFAULT 'viewer', -- admin, manager, viewer
    branch_access INT[], -- array of branch IDs, null = all
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 7. Mobile App Features (Phase 1)

### Dashboard Screens

#### 7.1 Home Screen - Today's Overview
- Total sales across all branches (with comparison to yesterday)
- Customer count & average ticket value
- Branch-by-branch breakdown cards
- Quick alerts (high voids, low performance)

#### 7.2 Sales Trends Screen
- Line chart: Daily sales for past 30 days
- Branch comparison toggle
- Day-of-week patterns

#### 7.3 Peak Hours Heatmap
- Visual heatmap of sales by hour
- Day selection (today, yesterday, this week)
- Staffing recommendations based on traffic

#### 7.4 Product Performance
- Top 10 products by revenue
- Category breakdown (pie chart)
- Trend indicators (up/down vs last week)

#### 7.5 Branch Details
- Individual branch deep-dive
- Hourly breakdown
- Table turnover metrics
- Product mix for that branch

#### 7.6 Alerts & Exceptions
- Void transactions (with details)
- High discount alerts
- Data sync status per branch

---

## 8. Key Performance Indicators (KPIs)

| KPI | Formula | Target | Alert Threshold |
|-----|---------|--------|-----------------|
| ATV (Average Ticket Value) | Net Sales / Receipts | 600,000 LAK | < 500,000 |
| Spend Per Head | Net Sales / Customers | 250,000 LAK | < 200,000 |
| Dinner Share | Dinner Sales / Daily Sales | 60-70% | < 50% |
| Void Rate | Void Amount / Gross Sales | < 2% | > 3% |
| Peak Hour % | Peak Hour Sales / Daily Sales | 30-40% | Monitor |
| Customer Per Table | Customers / Tables | 2.0-2.5 | Monitor |

---

## 9. Implementation Timeline

### Phase 1: Core System (8 weeks)

| Week | Task | Deliverable |
|------|------|-------------|
| 1 | Database design & setup | PostgreSQL schema deployed |
| 2 | XLS parser development | Python module parsing all 17 formats |
| 3 | Cloud API development | REST endpoints for data ingestion |
| 4 | Local agent (CLI version) | Command-line sync tool |
| 5 | Local agent (Tray app) | Windows system tray application |
| 6 | Flutter app - core screens | Dashboard, sales, alerts |
| 7 | Flutter app - charts & polish | All visualizations complete |
| 8 | Testing & deployment | Production deployment |

### Phase 2: Enhanced Features (4 weeks)

| Week | Task | Deliverable |
|------|------|-------------|
| 9 | Historical data import | Backfill past data |
| 10 | WhatsApp integration setup | Business API connected |
| 11 | AI assistant development | Natural language queries |
| 12 | Final testing & handover | Complete system |

---

## 10. Deployment Plan

### Branch Agent Installation
1. Provide installer (.exe) to IT head
2. Agent auto-installs to Program Files
3. Configuration: API endpoint + branch code
4. Agent auto-starts with Windows
5. Initial sync of current day data

### Mobile App Distribution
- Android: APK direct download or Play Store
- iOS: TestFlight for internal testing, then App Store

### Cloud Infrastructure
- DigitalOcean Droplet or Railway.app
- PostgreSQL managed database
- Daily backups configured
- SSL certificate for API

---

## 11. Security Measures

| Aspect | Implementation |
|--------|----------------|
| Data in Transit | HTTPS/TLS for all API calls |
| Data at Rest | PostgreSQL encryption |
| Authentication | JWT tokens for mobile app |
| Authorization | Role-based access (admin/manager/viewer) |
| Branch Isolation | User-level branch access control |
| Audit Trail | All data changes logged |
| NDA | Signed before accessing real data |

---

## 12. Support & Maintenance

### Included in Project
- 3 months post-launch support
- Bug fixes and minor adjustments
- User training documentation

### Optional Annual Maintenance
- Server monitoring & updates
- Database backups
- Feature enhancements
- Priority support

---

## 13. Assumptions & Dependencies

| Assumption | Mitigation if False |
|------------|---------------------|
| All branches have same POS version | Verify with sample files from each branch |
| Internet available at all branches | Local queue in agent, retry on reconnection |
| Windows PCs available at branches | Agent designed for Windows; discuss alternatives if needed |
| Management provides WiFi credentials | Include in installation checklist |

---

## 14. Success Criteria

- All 3 branches syncing data automatically
- Dashboard updates within 5 minutes of checkpoint
- Mobile app load time < 3 seconds
- Zero manual data entry required
- President can view daily performance before 11 PM same day

---

## 15. Next Steps

1. **Immediate**: Begin database schema setup
2. **Week 1**: Develop XLS parser module
3. **Week 2**: Start API development
4. **Week 3**: Build local agent prototype
5. **Week 4**: Begin Flutter app development

---

*Document Version: 1.0*  
*Last Updated: February 17, 2026*  
*Author: Dr. Bounthong Vongxaya (with AI Development Assistance)*
