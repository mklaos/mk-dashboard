# MK Restaurants Laos - Sales Intelligence Dashboard (Executive Summary)

This document provides a comprehensive overview of the MK Restaurants Sales Intelligence System's dashboard features, designed specifically for executive-level performance monitoring across multiple brands.

## 1. Multi-Brand & Hierarchy Management
*   **Brand-Level Context:** Integrated support for **MK Restaurants, Miyazaki, and Hard Rock Cafe**.
*   **Hierarchical Filtering:** Switch between a consolidated "All Brands" view or drill down into a specific Brand or individual Branch.
*   **Visual Branding:** The interface dynamically updates context (Brand Names, Branch Codes) based on the user's selection.

## 2. Real-Time Executive KPIs
The dashboard provides an immediate snapshot of daily performance with "Previous Week Comparison" (Growth Indicators).
*   **Sales (Tax Excluded):** Accurate revenue tracking by stripping out tax (Net Sales Ex-Tax) to provide a true picture of business volume.
*   **Discount Monitoring:** A dedicated KPI to track total discounts applied across the brand.
*   **Customer & Volume Analytics:** Total Receipts, Total Customers, and **Average Ticket Value**.
*   **Visual Void Alert System:**
    *   🟢 **Normal (< 1%):** Healthy operations.
    *   🟡 **Warning (1% - 3%):** Potential manual error or operational issue.
    *   🔴 **Critical (> 3%):** Immediate management review required (High exception rate).

## 3. Advanced Sales Mix & Behavior Charts
Understand *what* is selling and *how* customers are buying.
*   **Food vs. Beverage Split:** Real-time revenue distribution between main dishes and drinks.
*   **Dine-In vs. Takeaway Analysis:** A dedicated comparison chart showing the percentage of sales from seated customers vs. those buying to take home.
*   **Peak Hour Trends:** A line chart visualizing customer volume and sales peaks throughout the day.
*   **Top 5 Product Ranking:** Automatically identifies the highest-revenue-generating items for the selected brand.

## 4. Historical Trends & Analytics
A dedicated section for long-term strategic planning and growth tracking.
*   **Daily Sales Performance (30 Days):** High-resolution tracking of daily revenue to monitor growth and identify peak performance days.
*   **Monthly Trends (6 Months):** Monitor seasonal growth and long-term revenue trajectories.
*   **Yearly Trends (3 Years):** High-level year-over-year comparison of business health.

## 5. Global Accessibility (Bilingual & Multi-Role)
*   **Lao & English Interface:** A professional, one-tap toggle switches the entire UI (Buttons, Labels, Charts) between Lao and English instantly.
*   **Tiered Access Control:** 
    *   **Group President:** Complete oversight of all restaurant brands and branches.
    *   **Brand Shareholders:** Access restricted to specific brands (e.g., only Miyazaki data).
    *   **Brand Managers:** Operational oversight of all branches within a single brand.
    *   **Branch Managers:** Granular access limited to one specific physical location.
*   **Cloud Connectivity:** Secure real-time data sync with Supabase (PostgreSQL), protected by Row Level Security (RLS).

## 6. Technical Resilience
*   **Cross-Device Compatibility:** Built as a Progressive Web App (PWA) optimized for mobile smartphones, tablets, and desktop browsers.
*   **Resilient Data Pipeline:** The system utilizes advanced PDF-to-Data parsing for long-term accuracy, eliminating errors caused by shifting columns in Excel reports and ensuring structural consistency across all restaurant brands.
*   **Cloud-First Architecture:** No local servers required; all data is securely hosted in the cloud with instant availability for decision-makers.

---
**Prepared for:** MK Restaurants (Laos)
**Updated:** 28 March 2026
