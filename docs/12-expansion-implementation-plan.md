# Expansion Implementation Plan: MK, Miyazaki & Hardrock (Laos)

This document outlines the roadmap for expanding the MK Restaurants Sales Intelligence System to support multiple brands, advanced analytics, and granular user roles.

> **Last Code Audit:** 28 March 2026
> **Audited By:** Claude Sonnet (verified against actual source files — not documentation assumptions)

---

## Phase 1: Database & Data Model (The Foundation)

- [x] **Brand Hierarchy:**
    - [x] Create `brands` table (`id`, `name`, `name_lao`, `logo_url`, `primary_color`).
        - ✅ Confirmed in `backend/db/migration_v1.2_brands.sql`. All required columns present.
    - [x] Add `brand_id` to `branches` table.
        - ✅ `ALTER TABLE branches ADD COLUMN IF NOT EXISTS brand_id UUID REFERENCES brands(id)` confirmed in migration.
    - [x] Migrate existing MK branches to the MK Brand.
        - ✅ Migration script seeds MK, Miyazaki, and Hard Rock Cafe brands and links all `MK%` branch codes to the MK brand via a PL/pgSQL block.

- [x] **User Role Management:**
    - [x] Update `app_users` table with `allowed_brands` (UUID array) and `allowed_branches` (UUID array).
        - ✅ Confirmed in `migration_v1.2_brands.sql` and mirrored in `lib/models/user.dart` (`AppUser.allowedBrands`, `AppUser.allowedBranches`).
    - [x] Implement Row Level Security (RLS) policies to filter data based on user access.
        - ✅ RLS policies on `brands` and `daily_sales` confirmed in migration. Owner bypass also implemented.
    - ⚠️ **Role Naming Gap:** The plan documents a 4-tier hierarchy (President, Shareholder, Brand Mgr, Branch Mgr), but the actual code (`lib/models/user.dart`) implements **3 roles**: `owner`, `manager`, `viewer`. The access-control *logic* (filtering via `allowed_brands` / `allowed_branches`) is fully functional. Role names just differ from the original spec.

- [x] **KPI Data Updates:**
    - [x] Ensure `daily_sales` explicitly stores `net_sales_ex_tax` (Tax Excluded).
        - ✅ Computed dynamically in `lib/services/sales_service.dart` as `net_sales - tax_amount` and injected into every response map. Not a stored column, but consistently available to the UI.
    - [x] Verify `takeaway_sales` and `takeaway_receipts` are consistently populated.
        - ✅ Both fields exist in `backend/db/schema.sql` (`daily_sales` table), in `parser/models.py` (`DailySales` dataclass), and are extracted by `parser_complete.py` via the keyword `'ซื้อกลับบ้าน'` / `'Take Away'`.

---

## Phase 2: Backend & Parser Enhancements (Data Quality)

- [x] **Keyword-Anchored Parser:**
    - [x] Refactor `parser_complete.py` to use keyword searching instead of fixed column indexes.
        - ✅ Confirmed. `parse_daily_sales()` is fully keyword-anchored (searches for Thai strings like `'จำนวนใบเสร็จที่ขาย'`, `'รายรับทั้งสิ้น'`, `'ส่วนลด'`, etc.). The function's docstring even reads *"using keyword anchoring for resilience"*. Other parsers (`parse_voids`, `parse_hourly_sales`, etc.) use `row_str` for skip-row detection but still use positional `iloc` for data extraction — acceptable given those sheet layouts are stable.

- [x] **PDF Support (Investigation/POC):**
    - [x] Evaluate `pdfplumber` for extracting data from POS PDF reports.
        - ✅ `parser/pdf_parser.py` exists. Uses `pdfplumber` to extract full text and tables. `MKPDFParser` class has `parse_daily_summary()` (regex/keyword-based) and `extract_table_data()` methods.
    - [ ] Implement PDF fallback for branches where Excel is unreliable.
        - ❌ POC only. `pdf_parser.py` is not integrated into `tray_app.py` or the main data pipeline yet.

- [ ] **Multi-Brand Profiles:**
    - [ ] Create parser profiles for **Miyazaki** and **Hardrock**.
        - ❌ **Not implemented.** No Miyazaki or Hardrock parsing logic exists anywhere in the Python codebase. The brands are seeded in the database as placeholders, but there are no corresponding parser classes or config profiles.
    - [ ] Map unique category names for new brands.
        - ❌ Not implemented.

- [ ] **Buffet Integration:**
    - [ ] Identify "Buffet" items in POS reports.
        - ❌ No buffet detection logic in any parser file.
    - [ ] Add `is_buffet` flag to `product_sales` or a specific summary field.
        - ❌ No `is_buffet` field in schema or models.

---

## Phase 3: Core Dashboard Improvements (New KPIs & Sales Mix)

- [x] **KPI Enhancements:**
    - [x] Add **Discount** KPI card (Sum of all discounts).
        - ✅ Confirmed in `lib/screens/dashboard_screen.dart` → `_buildKPICards()`. A `KpiCard` with `provider.translate('discounts')` and value `data?['discount_amount']` is rendered. Growth comparison also wired up.
    - [x] Implement **Visual Void Alert**:
        - ✅ Confirmed. `voidPercentage` is computed as `voidAmount / netSales * 100`. Color is set to:
            - 🟢 `Colors.green` — < 1%
            - 🟡 `Colors.orange` — 1% – 3%
            - 🔴 `Colors.red` — > 3%
        - The void `KpiCard` receives this dynamic `color` value.
    - [x] Switch main sales display to **Tax Excluded**.
        - ✅ The **first** KPI card in the grid uses `net_sales_ex_tax` with the label key `'sales_ex_tax'` (translates to "ຍອດຂາຍ (ບໍ່ລວມພາສີ)" in Lao / "Sales (Ex Tax)" in English).

- [x] **Enhanced Sales Mix:**
    - [x] Add **Dine-In vs. Takeaway** chart (Pie or Side-by-Side Bar).
        - ✅ `_buildSalesMixChart()` in `dashboard_screen.dart` renders two `SalesMixPieChart` widgets side-by-side. The right one uses `provider.dineInVsTakeawayData`, which is populated by `sales_service.dart` → `getDineInVsTakeaway()` (queries `takeaway_sales` vs `net_sales - takeaway_sales`).
    - [x] Align Sales Mix charts in a single row/section for easy comparison.
        - ✅ Both charts are inside a `Row` widget with `Expanded` children, displaying side-by-side in a single section.

---

## Phase 4: Localization & UX (Bilingual & Theming)

- [x] **Bilingual Interface:**
    - [x] Set up Flutter `intl` localization for Lao and English.
        - ✅ `intl` package is imported. A `translate(String key)` method in `DashboardProvider` holds a full Lao/English map for all UI strings.
    - [x] Add Language Toggle in the App Bar.
        - ✅ A `TextButton` in the `AppBar` of both `DashboardScreen` and `TrendsScreen` calls `provider.toggleLocale()`, switching between `'lo'` and `'en'`.
    - [x] Ensure all UI labels (Total Sales, Top Products, etc.) translate instantly.
        - ✅ All KPI titles, chart labels, nav bar items, and button text use `provider.translate(key)` or inline `provider.isLao ? '...' : '...'` ternaries. The switch is instant via `notifyListeners()`.

- [ ] **Dynamic Theming:**
    - [ ] Set app accent color based on the selected brand (e.g., MK=Red, Hardrock=Black).
        - ⚠️ **Partially implemented.** The `Brand` model has a `primaryColor` field (hex string) and `BrandSelector` correctly parses it to color the selected filter chip. **However**, the app's overall `MaterialApp` theme is hardcoded to `const Color(0xFFE53935)` (MK Red) in `main.dart`. There is **no** mechanism to rebuild the app theme when the user switches brands. This feature is incomplete.

---

## Phase 5: Advanced Analytics (Historical Trends)

- [x] **Trends Page:**
    - [x] Create a new "Trends" navigation tab.
        - ✅ `TrendsScreen` is a full screen, registered as the second tab in `MainNavigationScreen`'s `BottomNavigationBar`.
    - [x] **Daily Trend:** Line chart (Last 30 days, selectable range).
        - ✅ `getDailyTrends()` fetches 30 days of `daily_sales`, aggregates by date, and renders a `LineChart` via `fl_chart`.
    - [x] **Monthly Trend:** Bar chart (Last 6–12 months).
        - ✅ `getMonthlyTrends()` aggregates by `YYYY-MM` across the last 6 months. Rendered as a `LineChart` (not a bar chart as originally planned, but functionally equivalent).
    - [x] **Yearly Trend:** Comparison bar chart (Last 3 years).
        - ✅ `getYearlyTrends()` aggregates by year for the last 3 years. Also rendered as a `LineChart`.

- [x] **Context-Aware Filtering:**
    - [x] Ensure Trends follow the main filter (All Brands -> Brand -> Branch).
        - ✅ `TrendsScreen` embeds both `BrandSelector` and `BranchSelector`. Each triggers `provider.loadTrends()`, which passes `_selectedBranchCode` and `_selectedBrandId` into all three trend queries.

---

## Phase 6: Translation & Product Management

- [x] **Master Translation Cleanup:**
    - [x] Script to export all Thai product names to a CSV for customer review.
        - ✅ `parser/generate_translation_csv.py` exists.
    - [x] Update `product_translations.json` with final "Lao-Short" names.
        - ✅ `parser/import_translations.py` exists with `import_translations_from_csv()` that reads a reviewed CSV and merges changes back into `data/product_translations.json`.

- [ ] **Pending Translation Workflow:**
    - [ ] UI screen for admins to translate newly detected products within the app.
        - ❌ **Not implemented.** There is no admin screen, dialog, or in-app UI anywhere in the Flutter codebase for managing product translations. This remains a CLI-only workflow.

---

## Status Tracking

- **Last Updated:** 28 March 2026 (Code-verified audit)
- **Current Focus:** Phase 2 — Multi-Brand Parser Profiles (Miyazaki & Hardrock)

### ✅ Confirmed Complete (verified in source code)

| Feature | Evidence |
|---|---|
| Brand Hierarchy (DB) | `migration_v1.2_brands.sql` |
| User Role Management + RLS | `migration_v1.2_brands.sql`, `user.dart`, `dashboard_provider.dart` |
| KPI Data (tax-ex, takeaway, discount) | `sales_service.dart`, `parser_complete.py`, `schema.sql` |
| Keyword-Anchored Parser | `parser_complete.py` → `parse_daily_sales()` |
| PDF Parser POC | `parser/pdf_parser.py` |
| Discount KPI Card | `dashboard_screen.dart` → `_buildKPICards()` |
| Visual Void Alert (color-coded) | `dashboard_screen.dart` → `_buildKPICards()` |
| Tax-Excluded as primary KPI | `dashboard_screen.dart` → first KPI card |
| Dine-In vs. Takeaway chart | `dashboard_screen.dart`, `sales_service.dart` |
| Aligned Sales Mix (side-by-side Row) | `dashboard_screen.dart` → `_buildSalesMixChart()` |
| Bilingual Interface (Lao/EN toggle) | `dashboard_provider.dart`, `dashboard_screen.dart`, `trends_screen.dart` |
| Trends Page (Daily/Monthly/Yearly) | `trends_screen.dart`, `sales_service.dart` |
| Context-Aware Trend Filtering | `trends_screen.dart` |
| Translation CSV Export/Import scripts | `parser/generate_translation_csv.py`, `parser/import_translations.py` |

### ⚠️ Partially Implemented

| Feature | Gap |
|---|---|
| Dynamic Theming | Brand colors work for selector chips only. `MaterialApp` theme is hardcoded to MK Red in `main.dart` — does not change when user switches brand. |
| PDF Pipeline Integration | `pdf_parser.py` is a standalone POC; not wired into `tray_app.py` or the file-watch pipeline. |

### ❌ Not Yet Implemented

| Feature | Notes |
|---|---|
| Multi-Brand Parser Profiles (Miyazaki, Hardrock) | **Highest priority.** Brands exist in DB but no parsing logic exists for their POS reports. |
| Buffet Integration (`is_buffet` flag) | No detection logic in parser; no schema field. |
| Pending Translation Workflow (in-app UI) | No admin screen in Flutter. CLI scripts only. |

---

## Recommended Next Steps (Priority Order)

1. **🔴 Multi-Brand Parser Profiles** — Obtain sample POS XLS/PDF files from Miyazaki and Hardrock, create parser profiles in `parser_complete.py` (or a new `brand_parser.py` module), and wire them into the agent.
2. **🟡 Dynamic Theming** — In `main.dart` / `MKDashboardApp`, listen to `DashboardProvider.selectedBrand` and rebuild `MaterialApp` theme using `brand.primaryColor` when the brand changes.
3. **🟡 PDF Pipeline Integration** — Connect `pdf_parser.py` into `tray_app.py` as a fallback when no XLS is found for a given date/branch.
4. **🟢 Buffet Integration** — Add an `is_buffet` boolean column to `product_sales`, identify buffet item keywords per brand, and flag them during parsing.
5. **🟢 In-App Translation Workflow** — Build a simple admin screen in Flutter that lists untranslated products and allows the admin to enter Lao names, calling a Supabase update via `sales_service`.