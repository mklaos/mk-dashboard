# MK Restaurants Dashboard - Proposed Future Plan

This document outlines high-value enhancements for the MK Restaurants Analytics platform, based on existing data capabilities and international restaurant management best practices.

## 1. Operational Efficiency Analytics

### Table Turnover & Service Time
*   **Metric:** Average meal duration (Time In vs. Time Out).
*   **Benefit:** Helps management understand how fast tables are turning over. Identifying "slow" tables can lead to improved floor management and higher revenue during peak hours.
*   **Data Source:** `transactions` table (`time_in`, `time_out`).

### Table Type Optimization
*   **Metric:** Sales by Table Group (2-seater, 4-seater, VIP Room).
*   **Benefit:** Identify if the current furniture layout matches customer demand. (e.g., Are we losing money because we have too many 4-seaters when most customers come in pairs?)
*   **Data Source:** `table_summary` report.

## 2. Sales Mix & Marketing Insights

### Category Revenue Breakdown (Sales Mix)
*   **Metric:** Revenue percentage by category (e.g., Suki 60%, Roast Duck 25%, Beverages 10%, Desserts 5%).
*   **Benefit:** Essential for "Menu Engineering." Management can see which categories drive profit vs. which are just "fillers."
*   **Data Source:** `product_sales` aggregated by `category`.

### Dine-In vs. Takeaway Analysis
*   **Metric:** Comparison of in-restaurant dining vs. take-home orders.
*   **Benefit:** Helps in allocating staff resources. High takeaway volume might suggest a need for a dedicated pickup area or better packaging.
*   **Data Source:** `daily_sales` (`takeaway_sales`, `takeaway_receipts`).

### Promotion & Discount Audit
*   **Metric:** Discount usage by type (VIP Cards, Credit Card Promos, Seasonal Discounts).
*   **Benefit:** Measures the ROI of marketing campaigns. Is the 10% discount actually bringing in more customers, or just reducing profit from regulars?
*   **Data Source:** `transactions` (`discount_amount`, `discount_card`).

## 3. Risk Management & Auditing

### Void Reason Deep-Dive
*   **Metric:** Voids categorized by reason (e.g., "Kitchen Error," "Customer Changed Mind," "Out of Stock").
*   **Benefit:** Reduces food waste and identifies operational bottlenecks. If "Out of Stock" is a common void reason, the inventory system needs adjustment.
*   **Data Source:** `void_log` (`reason_text`).

### Staff Audit (Loss Prevention)
*   **Metric:** Voids and discounts tracked by Staff/Approver ID.
*   **Benefit:** A standard audit tool to prevent internal theft or errors. High void rates on specific shifts can indicate a training need or a security risk.
*   **Data Source:** `void_log` (`approved_by`, `recorded_by`).

## 4. Financial & Tax Readiness

### Monthly VAT Summary
*   **Metric:** Monthly aggregated Taxable Sales vs. Tax Amount.
*   **Benefit:** Simplifies life for the accounting department by providing "tax-ready" numbers at the end of each month.
*   **Data Source:** `vat_summary` report.

## 5. Technical Roadmap

*   **Data Caching:** Implement local storage (Hive or SharedPrefs) to cache previous days' data, allowing the app to work offline and load instantly.
*   **Executive Alerts:** Push notifications for specific triggers (e.g., "Daily Sales Target Reached" or "High Void Alert at MK002").
*   **Historical Trends:** Week-over-week and Month-over-month comparison charts to see if the business is growing.
*   **Automated PDF Reports:** Generate a professional one-page summary that can be shared via WhatsApp/Email with one click.

---

**Prepared by:** Gemini CLI
**Date:** February 25, 2026
