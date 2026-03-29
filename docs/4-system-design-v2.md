# MK Restaurants - System Design V2.0

## Executive Summary

This document outlines the comprehensive system design for expanding the MK Restaurants Sales Intelligence System to support multiple restaurant brands (MK, Mayazaki, Hardrock) with enhanced features including bilingual interface, advanced analytics, and role-based access control.

---

## 1. Multi-Business Architecture

### 1.1 Business Group Concept

```
┌─────────────────────────────────────────────────────────┐
│              MK Restaurants Laos (Group)                 │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  MK Rest.    │  │  Mayazaki    │  │  Hardrock    │  │
│  │  (3 branches)│  │  (1 branch)  │  │  (1 branch)  │  │
│  │              │  │              │  │              │  │
│  │  MK001       │  │  MZ001       │  │  HR001       │  │
│  │  MK002       │  │              │  │              │  │
│  │  MK003       │  │              │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 1.2 Database Schema Changes

```sql
-- Add business_groups table
CREATE TABLE business_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_en VARCHAR(100) NOT NULL,
    name_th VARCHAR(100) NOT NULL,
    name_lao VARCHAR(100),
    logo_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Update branches table
ALTER TABLE branches ADD COLUMN group_id UUID REFERENCES business_groups(id);
ALTER TABLE branches ADD COLUMN business_type VARCHAR(50) DEFAULT 'restaurant';
-- business_type: 'restaurant', 'cafe', 'bar', 'buffet'

-- Seed data
INSERT INTO business_groups (name_en, name_th, name_lao) VALUES
('MK Restaurants', 'เอ็มเค เรสโตรองต์', 'ຮ້ານອາຫານເອັມເຄ'),
('Mayazaki', 'มายาซากิ', 'ມາຍາຊາກິ'),
('Hardrock', 'ฮาร์ดร็อค', 'ຮາດຣ໋ອອກ');

INSERT INTO branches (code, name, name_en, name_lao, group_id, business_type) VALUES
-- MK Restaurants
('MK001', 'เอ็มเค สาขาวัดจัน', 'MK Watnak', 'ເອັມເຄ ສາຂາວັດຈັນ', [uuid], 'restaurant'),
('MK002', 'เอ็มเค สาขาไซเสดถา', 'MK Xaysedtha', 'ເອັມເຄ ສາຂາໄຊເສດຖາ', [uuid], 'restaurant'),
('MK003', 'เอ็มเค สาขาปากเซ', 'MK Pakse', 'ເອັມເຄ ສາຂາປາກເຊ', [uuid], 'restaurant'),
-- Mayazaki
('MZ001', 'มายาซากิ', 'Mayazaki', 'ມາຍາຊາກິ', [uuid], 'japanese'),
-- Hardrock
('HR001', 'ฮาร์ดร็อค คาเฟ่', 'Hardrock Cafe', 'ຮາດຣ໋ອອກ ຄາເຟ່', [uuid], 'cafe');
```

### 1.3 Agent Configuration

```json
{
  "business_group": "MK Restaurants",
  "group_id": "uuid-here",
  "branch_code": "MK001",
  "branch_id": "uuid-here",
  "watch_folder": "D:/mk/source",
  "supabase_url": "...",
  "supabase_key": "..."
}
```

---

## 2. Enhanced KPI System

### 2.1 New KPI Cards

**Current KPIs:**
- Total Sales (Net)
- Receipt Count
- Customer Count
- Average Ticket

**New KPIs to Add:**

| KPI | Thai | Lao | Calculation | Color Alert |
|-----|------|-----|-------------|-------------|
| **Pre-Tax Sales** | ยอดขายก่อนภาษี | ຍອດຂາຍກ່ອນອາກອນ | `gross_sales - tax` | - |
| **Discount Amount** | ส่วนลดทั้งหมด | ສ່ວນຫຼຸດທັງໝົດ | Sum of all discounts | 🟡 >5% of sales<br>🔴 >10% of sales |
| **Void Amount** | ยกเลิกรวม | ຍົກເລີກທັງໝົດ | Sum of voided items | 🟡 >2% of sales<br>🔴 >5% of sales |
| **Void Count** | จำนวนยกเลิกรายการ | ຈຳນວນຍົກເລີກລາຍການ | Count of void transactions | 🟡 >10 items<br>🔴 >30 items |
| **Tax Amount** | ภาษีมูลค่าเพิ่ม | ອາກອນມູນຄ່າເພີ່ມ | 7% of taxable sales | - |

### 2.2 Void Alert System (Visual Only)

**Implementation Strategy:**
- No email/push notifications (per customer request)
- Visual indicators on KPI cards with color coding
- Threshold-based color changes

```dart
enum AlertLevel { normal, warning, critical }

AlertLevel calculateVoidAlert({
  required double voidAmount,
  required double netSales,
  required int voidCount,
}) {
  final voidRate = voidAmount / netSales;
  
  if (voidRate > 0.05 || voidCount > 30) {
    return AlertLevel.critical; // Red
  } else if (voidRate > 0.02 || voidCount > 10) {
    return AlertLevel.warning; // Orange
  }
  return AlertLevel.normal; // Green
}

// UI Implementation
Widget buildVoidKPI(AlertLevel level) {
  final color = switch(level) {
    AlertLevel.critical => Colors.red,
    AlertLevel.warning => Colors.orange,
    AlertLevel.normal => Colors.green,
  };
  
  return KpiCard(
    title: 'Void Amount',
    value: formatCurrency(voidAmount),
    icon: Icons.cancel_outlined,
    color: color, // Dynamic color based on alert level
    blink: level == AlertLevel.critical, // Optional: subtle animation
  );
}
```

### 2.3 Updated KPI Card Layout

```
┌──────────────────────────────────────────────────────────┐
│  [Pre-Tax]  [Total Sales]  [Discount]   [Void]   [Tax]  │
│  33.0M ₭    35.9M ₭       434K ₭ 🟡    368K ₭ 🟢  3.3M │
│  Base       +Tax           -1.2%        +0.5%    +7%    │
├──────────────────────────────────────────────────────────┤
│  [Receipts]  [Customers]  [Avg Ticket]  [Void Count]    │
│  54          127          612K ₭        9 items 🟢      │
│  +2%         +3%          +1%           -2 items        │
└──────────────────────────────────────────────────────────┘
```

---

## 3. Dine-In vs Takeaway Visualization

### 3.1 Data Source

From Excel file `แยกตามกุ่มโตะ` (Table Details):
- Column "เลขที่ใบเสร็จ" contains table info: `"061-001"` = Table 061, Bill 001
- **Dine-in**: Has table number (e.g., `"061-001"`)
- **Takeaway**: No table number or marked as "Takeaway"/"กลับบ้าน"

### 3.2 Parser Implementation

```python
def parse_table_details(self, df: pd.DataFrame) -> List[Dict]:
    """Parse table details to extract dine-in vs takeaway"""
    records = []
    
    for idx, row in df.iterrows():
        # Skip header rows
        if 'ในร้าน' in str(row.get('ลำดับ', '')):
            continue
            
        receipt_no = row.get('เลขที่ใบเสร็จ', '')
        table_bill = row.get('โต๊ะ-เลขบิล', '')
        sales = self.clean_amount(row.get('ยอดขาย', 0))
        
        # Determine service type
        service_type = 'dine_in'
        if pd.isna(table_bill) or table_bill == '':
            service_type = 'takeaway'
        elif 'กลับบ้าน' in str(table_bill) or 'Takeaway' in str(table_bill):
            service_type = 'takeaway'
        
        records.append({
            'receipt_no': receipt_no,
            'service_type': service_type,
            'sales': sales,
            'customer_count': row.get('ลูกค้า', 0),
        })
    
    return records
```

### 3.3 Database Schema

```sql
-- Add service_type to daily_sales
ALTER TABLE daily_sales ADD COLUMN dine_in_sales DECIMAL(15,2) DEFAULT 0;
ALTER TABLE daily_sales ADD COLUMN takeaway_sales DECIMAL(15,2) DEFAULT 0;
ALTER TABLE daily_sales ADD COLUMN dine_in_receipts INT DEFAULT 0;
ALTER TABLE daily_sales ADD COLUMN takeaway_receipts INT DEFAULT 0;

-- Add service_type to transactions
ALTER TABLE transactions ADD COLUMN service_type VARCHAR(20) DEFAULT 'dine_in';
-- Values: 'dine_in', 'takeaway', 'delivery'
```

### 3.4 UI Implementation

Add to existing Sales Mix section:

```dart
// In dashboard_screen.dart
_buildSalesMixChart(context, provider)  // Food vs Beverage
_buildServiceTypeChart(context, provider)  // NEW: Dine-in vs Takeaway

Widget _buildServiceTypeChart(BuildContext context, DashboardProvider provider) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Type',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  child: ServiceTypePieChart(
                    dineInSales: provider.dailySalesData?['dine_in_sales'] ?? 0,
                    takeawaySales: provider.dailySalesData?['takeaway_sales'] ?? 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ServiceTypeLegend(
                    dineInReceipts: provider.dailySalesData?['dine_in_receipts'] ?? 0,
                    takeawayReceipts: provider.dailySalesData?['takeaway_receipts'] ?? 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

## 4. Bilingual Interface (Lao/Thai)

### 4.1 Implementation Strategy

**Option A: User Preference (Recommended)**
- Settings page to select language
- Persist selection in local storage
- Toggle button in app bar

**Option B: System Locale**
- Auto-detect device language
- Fallback to Thai if Lao not available

### 4.2 Localization Architecture

```
lib/
├── l10n/
│   ├── app_localizations.dart          # Localization class
│   ├── app_localizations_th.dart       # Thai translations
│   └── app_localizations_lo.dart       # Lao translations
```

### 4.3 Translation Files

```dart
// lib/l10n/app_localizations_th.dart
class AppLocalizationsTH {
  static const Map<String, String> translations = {
    'total_sales': 'ยอดขายรวม',
    'receipts': 'ใบเสร็จ',
    'customers': 'ลูกค้า',
    'avg_ticket': 'เฉลี่ยต่อบิล',
    'pre_tax_sales': 'ยอดขายก่อนภาษี',
    'discount': 'ส่วนลด',
    'void': 'ยกเลิก',
    'tax': 'ภาษี',
    'dine_in': 'นั่งทานที่ร้าน',
    'takeaway': 'กลับบ้าน',
    'food': 'อาหาร',
    'beverage': 'เครื่องดื่ม',
    // ... more translations
  };
}

// lib/l10n/app_localizations_lo.dart
class AppLocalizationsLO {
  static const Map<String, String> translations = {
    'total_sales': 'ຍອດຂາຍທັງໝົດ',
    'receipts': 'ໃບເສັດ',
    'customers': 'ລູກຄ້າ',
    'avg_ticket': 'ສະເລ່ຍຕໍ່ບິນ',
    'pre_tax_sales': 'ຍອດຂາຍກ່ອນອາກອນ',
    'discount': 'ສ່ວນຫຼຸດ',
    'void': 'ຍົກເລີກ',
    'tax': 'ອາກອນ',
    'dine_in': 'ນັ່ງທານທີ່ຮ້ານ',
    'takeaway': 'ກັບບ້ານ',
    'food': 'ອາຫານ',
    'beverage': 'ເຄື່ອງດື່ມ',
    // ... more translations
  };
}
```

### 4.4 Flutter Localization Setup

```yaml
# pubspec.yaml
flutter:
  generate: true
```

```dart
// main.dart
import 'package:flutter_localizations/flutter_localizations.dart';

MaterialApp(
  localizationsDelegates: [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: [
    Locale('th'), // Thai
    Locale('lo'), // Lao
  ],
  locale: Locale('lo'), // or get from settings
  // ...
)
```

### 4.5 Language Toggle UI

```dart
// In app bar
PopupMenuButton<String>(
  icon: Icon(Icons.language),
  onSelected: (locale) async {
    await provider.setLocale(locale); // Save to SharedPreferences
  },
  itemBuilder: (context) => [
    PopupMenuItem(value: 'th', child: Text('ไทย')),
    PopupMenuItem(value: 'lo', child: Text('ລາວ')),
  ],
)
```

---

## 5. Time Trend Visualizations

### 5.1 New Dashboard Page Structure

```
┌─────────────────────────────────────────────────────────┐
│  MK Sales Dashboard          [Refresh] [🌐] [⚙️]        │
├─────────────────────────────────────────────────────────┤
│  [Today] [Trends] [Branches] [Products] [Voids]        │
└─────────────────────────────────────────────────────────┘
```

### 5.2 Trends Page Layout

```
┌──────────────────────────────────────────────────────────┐
│  Time Trends                                             │
├──────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────┐ │
│  │ Daily Trend                                        │ │
│  │ [Dec 1] [Dec 2] [Dec 3] ... [Dec 28]              │ │
│  │ ╭────────────────────────────────────────────╮    │ │
│  │ │   Line Chart: Sales by Day                 │    │ │
│  │ │   Default: Month-to-date                   │    │ │
│  │ ╰────────────────────────────────────────────╯    │ │
│  └────────────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────┐ │
│  │ Monthly Trend                                      │ │
│  │ [Jul] [Aug] [Sep] [Oct] [Nov] [Dec]               │ │
│  │ ╭────────────────────────────────────────────╮    │ │
│  │ │   Bar Chart: Sales by Month                │    │ │
│  │ │   Default: 6 months                        │    │ │
│  │ ╰────────────────────────────────────────────╯    │ │
│  └────────────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────┐ │
│  │ Yearly Trend                                       │ │
│  │ [2023] [2024] [2025]                              │ │
│  │ ╭────────────────────────────────────────────╮    │ │
│  │ │   Bar Chart: Sales by Year                 │    │ │
│  │ │   Default: 3 years                         │    │ │
│  │ ╰────────────────────────────────────────────╯    │ │
│  └────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

### 5.3 Date Range Picker Widget

```dart
class DateRangeSelector extends StatelessWidget {
  final String type; // 'daily', 'monthly', 'yearly'
  final DateTimeRange? selectedRange;
  final Function(DateTimeRange) onRangeSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getLabel(type),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  icon: Icon(Icons.calendar_today),
                  label: Text(_formatRange(selectedRange)),
                  onPressed: () => _pickRange(context),
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildChart(type, selectedRange),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDate: selectedRange?.start ?? DateTime.now(),
    );
    // Handle selection
  }
}
```

### 5.4 Backend API for Trends

```dart
// sales_service.dart
Future<List<dynamic>> getDailyTrend({
  required DateTime startDate,
  required DateTime endDate,
  String? branchCode,
}) async {
  final response = await _supabase
      .from('daily_sales')
      .select('sale_date, net_sales, receipt_count, customer_count')
      .gte('sale_date', startDate.toIso8601String().split('T').first)
      .lte('sale_date', endDate.toIso8601String().split('T').first)
      .order('sale_date', ascending: true);
  
  if (branchCode != null && branchCode != 'ALL') {
    // Filter by branch
  }
  
  return response;
}

Future<List<dynamic>> getMonthlyTrend({
  required int year,
  required int startMonth,
  required int endMonth,
}) async {
  // Use PostgreSQL date_trunc for monthly aggregation
  final response = await _supabase.rpc('get_monthly_sales', params: {
    'p_year': year,
    'p_start_month': startMonth,
    'p_end_month': endMonth,
  });
  return response;
}

Future<List<dynamic>> getYearlyTrend({
  required int startYear,
  required int endYear,
}) async {
  final response = await _supabase.rpc('get_yearly_sales', params: {
    'p_start_year': startYear,
    'p_end_year': endYear,
  });
  return response;
}
```

### 5.5 Database Views for Trends

```sql
-- Monthly aggregation view
CREATE VIEW v_monthly_sales AS
SELECT 
    DATE_TRUNC('month', sale_date) AS month,
    branch_id,
    SUM(net_sales) AS total_sales,
    SUM(receipt_count) AS total_receipts,
    SUM(customer_count) AS total_customers
FROM daily_sales
GROUP BY DATE_TRUNC('month', sale_date), branch_id;

-- Yearly aggregation view
CREATE VIEW v_yearly_sales AS
SELECT 
    DATE_TRUNC('year', sale_date) AS year,
    branch_id,
    SUM(net_sales) AS total_sales,
    SUM(receipt_count) AS total_receipts,
    SUM(customer_count) AS total_customers
FROM daily_sales
GROUP BY DATE_TRUNC('year', sale_date), branch_id;
```

---

## 6. User Role Management

### 6.1 Role-Based Access Control (RBAC)

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name_th VARCHAR(100),
    full_name_en VARCHAR(100),
    full_name_lao VARCHAR(100),
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Roles
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL,
    name_th VARCHAR(100),
    name_lao VARCHAR(100),
    permissions JSONB DEFAULT '{}'
);

-- User roles assignment
CREATE TABLE user_roles (
    user_id UUID REFERENCES users(id),
    role_id UUID REFERENCES roles(id),
    PRIMARY KEY (user_id, role_id)
);

-- Business group access
CREATE TABLE user_business_access (
    user_id UUID REFERENCES users(id),
    business_group_id UUID REFERENCES business_groups(id),
    branch_id UUID REFERENCES branches(id),
    granted_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, business_group_id, branch_id)
);

-- Seed roles
INSERT INTO roles (name, name_th, name_lao, permissions) VALUES
('owner', 'เจ้าของ', 'ເຈົ້າຂອງ', '{"view_all": true, "export": true, "manage_users": true}'),
('manager', 'ผู้จัดการ', 'ຜູ້ຈັດການ', '{"view_all": true, "export": true}'),
('accountant', 'นักบัญชี', 'ນັກບັນຊີ', '{"view_assigned": true, "export": true}'),
('staff', 'พนักงาน', 'ພະນັກງານ', '{"view_assigned": true}');
```

### 6.2 Permission Matrix

| Role | MK All | MK Single | Mayazaki | Hardrock | Export | Users |
|------|--------|-----------|----------|----------|--------|-------|
| **Owner** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Manager** | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ |
| **Accountant** | ⚠️* | ✅ | ❌ | ❌ | ✅ | ❌ |
| **Staff** | ❌ | ⚠️* | ❌ | ❌ | ❌ | ❌ |

*⚠️ = Assigned branches only

### 6.3 Authentication Flow

```dart
// Login Screen
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          LogoWidget(),
          TextField(hint: 'Email'),
          TextField(hint: 'Password', obscureText: true),
          ElevatedButton(
            onPressed: () => provider.login(email, password),
            child: Text('Login'),
          ),
        ],
      ),
    );
  }
}

// Auth Provider
class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  List<Branch> _accessibleBranches = [];
  
  Future<bool> login(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (response.user != null) {
      _currentUser = response.user;
      await _loadUserPermissions();
      notifyListeners();
      return true;
    }
    return false;
  }
  
  Future<void> _loadUserPermissions() async {
    // Fetch user's business access from database
    final response = await _supabase
        .from('user_business_access')
        .select('branch_id, business_group_id')
        .eq('user_id', _currentUser!.id);
    
    _accessibleBranches = response.map((r) => Branch.fromId(r['branch_id'])).toList();
  }
  
  bool canAccessBranch(String branchCode) {
    return _accessibleBranches.any((b) => b.code == branchCode);
  }
  
  bool canExport() {
    return _hasPermission('export');
  }
  
  bool _hasPermission(String permission) {
    // Check user's role permissions
  }
}
```

### 6.4 Row Level Security (RLS) Policies

```sql
-- Enable RLS
ALTER TABLE daily_sales ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see data from their assigned branches
CREATE POLICY branch_access_policy ON daily_sales
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM user_business_access uba
        JOIN users u ON u.id = uba.user_id
        WHERE u.id = auth.uid()
        AND uba.branch_id = daily_sales.branch_id
    )
    OR
    EXISTS (
        SELECT 1 FROM user_roles ur
        JOIN roles r ON r.id = ur.role_id
        WHERE ur.user_id = auth.uid()
        AND r.permissions->>'view_all' = 'true'
    )
);
```

---

## 7. PDF Parser Integration

### 7.1 Why PDF?

**Customer Feedback:**
- Excel files often have column shifts
- Headers misaligned
- Data integrity issues

**PDF Advantages:**
- Fixed layout
- Consistent formatting
- More reliable data extraction

### 7.2 PDF Parsing Architecture

```
┌─────────────────────────────────────────────────────────┐
│  PDF Parser Module                                      │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │ PDF Extract │  │ OCR Engine  │  │ Data Clean  │    │
│  │ (pdfplumber)│  │ (optional)  │  │ & Validate  │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### 7.3 Implementation

```python
# parser/pdf_parser.py
import pdfplumber
import re
from typing import List, Dict

class MKPDFParser:
    def __init__(self, file_path: str):
        self.file_path = file_path
        self.tables = []
        
    def extract_tables(self) -> List[pd.DataFrame]:
        """Extract all tables from PDF"""
        with pdfplumber.open(self.file_path) as pdf:
            for page in pdf.pages:
                tables = page.extract_tables()
                for table in tables:
                    df = self._table_to_dataframe(table)
                    self.tables.append(df)
        return self.tables
    
    def _table_to_dataframe(self, table: List[List[str]]) -> pd.DataFrame:
        """Convert PDF table to pandas DataFrame"""
        # First row as header
        headers = table[0]
        data = table[1:]
        
        df = pd.DataFrame(data, columns=headers)
        return self._clean_dataframe(df)
    
    def _clean_dataframe(self, df: pd.DataFrame) -> pd.DataFrame:
        """Clean extracted data"""
        # Remove empty rows
        df = df.dropna(how='all')
        
        # Strip whitespace
        for col in df.columns:
            if df[col].dtype == object:
                df[col] = df[col].str.strip()
        
        # Fix common OCR errors
        df = df.replace({
            'O': '0',  # Letter O to zero
            'l': '1',  # Lowercase L to one
        }, regex=True)
        
        return df
    
    def detect_report_type(self) -> str:
        """Detect report type from PDF metadata or content"""
        with pdfplumber.open(self.file_path) as pdf:
            text = pdf.pages[0].extract_text()
            
            if 'ยอดขาย' in text:
                return 'daily_sales'
            elif 'ช่วงเวลา' in text:
                return 'hourly_sales'
            # ... other patterns
            
        return 'unknown'
```

### 7.4 Agent Configuration Update

```json
{
  "branch_code": "MK001",
  "watch_folder": "D:/mk/source",
  "file_types": ["xls", "xlsx", "pdf"],  // Support both
  "prefer_pdf": true,  // Use PDF if both exist
  "supabase_url": "...",
  "supabase_key": "..."
}
```

---

## 8. Translation Management System

### 8.1 Current State

```json
// data/product_translations.json
{
  "เป็ดย่างเอ็มเค-ใหญ่": {
    "lao": "ເປັດຍ່າງເອັມເຄ (ໃຫຍ່)",
    "en": "MK Roast Duck (Large)",
    "category": "food"
  }
}
```

### 8.2 Issues Identified

1. **Inconsistent translations**: Some products have wrong Lao translations
2. **Missing products**: New products not in mapping
3. **Manual process**: Need to review and fix all translations

### 8.3 Translation Review Process

**Phase 1: Audit Existing Translations**
```python
# Generate review report
def audit_translations():
    with open('product_translations.json', 'r') as f:
        translations = json.load(f)
    
    report = []
    for thai, trans in translations.items():
        report.append({
            'thai': thai,
            'lao': trans.get('lao', ''),
            'en': trans.get('en', ''),
            'category': trans.get('category', 'unknown'),
            'needs_review': False,  # Flag for manual review
        })
    
    # Export to Excel for review
    pd.DataFrame(report).to_excel('translation_audit.xlsx', index=False)
    return report
```

**Phase 2: Customer Review**
- Share Excel with customer
- Customer corrects Lao translations
- Customer adds missing products

**Phase 3: Update System**
```python
def update_translations(reviewed_file: str):
    df = pd.read_excel(reviewed_file)
    new_mapping = {}
    
    for _, row in df.iterrows():
        new_mapping[row['thai']] = {
            'lao': row['lao'],
            'en': row['en'],
            'category': row['category'],
        }
    
    with open('product_translations.json', 'w', encoding='utf-8') as f:
        json.dump(new_mapping, f, ensure_ascii=False, indent=2)
```

### 8.4 Auto-Detection of New Products

```python
class ProductTranslator:
    def __init__(self):
        self.mapping = self._load_mapping()
        self.new_products = []
    
    def translate(self, thai_name: str) -> Dict[str, str]:
        if thai_name not in self.mapping:
            # Auto-add to new products list
            self.new_products.append({
                'thai': thai_name,
                'lao': '',  # Needs translation
                'en': thai_name,  # Fallback
                'detected_at': datetime.now().isoformat(),
            })
            return {'lao': '', 'en': thai_name}
        
        return self.mapping[thai_name]
    
    def export_new_products(self, filepath: str = 'new_products.xlsx'):
        """Export new products for translation review"""
        if self.new_products:
            pd.DataFrame(self.new_products).to_excel(filepath, index=False)
            logger.info(f"Exported {len(self.new_products)} new products")
```

### 8.5 Database-Backed Translations (Future)

```sql
-- Product translations table
CREATE TABLE product_translations (
    product_id UUID REFERENCES products(id),
    language_code VARCHAR(5) NOT NULL, -- 'th', 'lo', 'en'
    name VARCHAR(200) NOT NULL,
    is_verified BOOLEAN DEFAULT false,
    verified_by UUID REFERENCES users(id),
    PRIMARY KEY (product_id, language_code)
);
```

---

## 9. Buffet Service Integration

### 9.1 Data Challenge

**Question for Customer:**
- Does buffet sales appear in separate Excel report?
- Is it included in daily sales total?
- How is buffet tracked in the POS?

### 9.2 Proposed Solutions

**Option A: Separate Report Type** (If POS generates buffet report)
```python
def parse_buffet_sales(self, df: pd.DataFrame) -> List[Dict]:
    """Parse buffet-specific sales data"""
    # Similar to other report types
    pass
```

**Option B: Category-Based** (If buffet is a product category)
```sql
-- Add is_buffet flag to categories
ALTER TABLE categories ADD COLUMN is_buffet BOOLEAN DEFAULT false;

-- Query buffet sales
SELECT SUM(total_amount) 
FROM product_sales 
JOIN products ON product_sales.product_id = products.id
JOIN categories ON products.category_id = categories.id
WHERE categories.is_buffet = true
AND sale_date = '2024-12-01';
```

**Option C: Manual Entry** (If not in POS)
```dart
// Add manual entry form for buffet covers
class BuffetEntryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column([
        TextFormField(label: 'Number of Buffet Customers'),
        TextFormField(label: 'Buffet Price per Person'),
        ElevatedButton(onPressed: saveBuffetData),
      ]),
    );
  }
}
```

### 9.3 Recommendation

**Wait for customer clarification** before implementation. Add to meeting agenda:
1. How is buffet sales tracked in POS?
2. Is there a separate buffet report?
3. Should buffet be shown separately in dashboard?

---

## 10. Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- [ ] Update database schema for multi-business
- [ ] Implement user authentication
- [ ] Add business group filtering
- [ ] Set up localization framework

### Phase 2: Enhanced KPIs (Week 3)
- [ ] Add Pre-Tax Sales KPI
- [ ] Add Discount KPI with alerts
- [ ] Add Void KPI with visual alerts
- [ ] Update dashboard layout

### Phase 3: New Visualizations (Week 4)
- [ ] Implement Dine-in vs Takeaway chart
- [ ] Create Trends page
- [ ] Add date range pickers
- [ ] Build monthly/yearly aggregations

### Phase 4: Access Control (Week 5)
- [ ] Complete RBAC system
- [ ] Implement RLS policies
- [ ] Add branch filtering based on permissions
- [ ] Test with sample users

### Phase 5: PDF & Translations (Week 6)
- [ ] Implement PDF parser
- [ ] Audit and fix translations
- [ ] Add new product detection
- [ ] Test with real PDF files

### Phase 6: Testing & Deployment (Week 7-8)
- [ ] User acceptance testing
- [ ] Performance optimization
- [ ] Documentation
- [ ] Production deployment

---

## 11. Open Questions for Customer

### Buffet Service
1. How is buffet sales recorded in the POS system?
2. Is there a separate buffet report file?
3. Should buffet customers be shown in the dashboard?

### Multi-Business
4. Will Mayazaki and Hardrock use the same POS system?
5. Do they export reports in the same format?
6. Should we have separate agents for each business?

### User Management
7. Who are the initial users that need accounts?
8. What roles should each user have?
9. Do users need access to multiple businesses?

### Data Migration
10. Should we import historical data from Excel files?
11. How far back should we import?

---

## 12. Technical Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Multi-tenancy | Shared DB, isolated by group_id | Cost-effective, easier maintenance |
| Authentication | Supabase Auth | Built-in, secure, supports RLS |
| Localization | Flutter intl package | Standard, well-supported |
| PDF Parsing | pdfplumber + fallback to OCR | Balance of accuracy and complexity |
| Translations | JSON file (Phase 1) → DB (Phase 2) | Quick start, scalable later |
| Void Alerts | Visual only (no emails) | Per customer request |
| Buffet Tracking | TBD (awaiting clarification) | Need more info |

---

*Last Updated: March 28, 2026*
*Version: 2.0*
