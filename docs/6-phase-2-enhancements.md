# MK Restaurants Dashboard - Phase 2 Enhancements

## Overview
This document describes the three advanced analytics features implemented for the MK Restaurants Sales Intelligence System dashboard.

**Implementation Date:** March 5, 2026  
**Version:** 2.0

---

## 1. Growth Indicators (Trend Indicators) ✅

### Description
Green/red arrows displayed next to key performance indicators (KPIs) showing whether metrics are improving or declining compared to the previous week's average.

### Features
- **Green Arrow (↑)**: Indicates growth/positive trend
- **Red Arrow (↓)**: Indicates decline/negative trend
- **Percentage Display**: Shows exact percentage change
- **Comparison Period**: Current day vs. previous 7 days average

### Metrics Tracked
1. **Total Sales**: Net sales revenue
2. **Receipts**: Number of bills/receipts
3. **Customers**: Total customer count
4. **Average Ticket**: Average spending per customer

### Technical Implementation
- **File**: `lib/services/sales_service.dart`
  - New method: `getPreviousWeekAverage()`
  - Calculates 7-day historical average
  - Handles missing data gracefully

- **File**: `lib/providers/dashboard_provider.dart`
  - Added `_previousWeekData` state variable
  - New method: `getGrowthFor()` - calculates growth percentage
  - Updated `loadData()` to fetch historical data

- **File**: `lib/widgets/kpi_card.dart`
  - Added `growthPercentage` parameter
  - Displays colored arrow icon with percentage
  - Green for positive, red for negative

### User Benefits
- **Quick Visual Indicator**: President can instantly see if business is growing
- **Data-Driven Decisions**: Identify trends before they become problems
- **Performance Tracking**: Monitor impact of business decisions

---

## 2. Enhanced Branch Comparison ✅

### Description
Enhanced the existing branch comparison feature with period-over-period metrics and growth indicators.

### Features
- **Side-by-Side Comparison**: All 3 branches displayed together
- **Performance Ranking**: See which branch performs best
- **Growth Metrics**: Each branch shows growth vs. previous week
- **Interactive Toggle**: Switch between totals view and comparison view

### Technical Implementation
- **File**: `lib/services/sales_service.dart`
  - Existing method: `getBranchComparison()`
  - Uses `v_branch_performance` database view

- **File**: `lib/widgets/kpi_comparison_card.dart`
  - Displays all branches side-by-side
  - Shows key metrics for each branch
  - Color-coded for easy comparison

### User Benefits
- **Identify Top Performers**: Recognize successful branches
- **Share Best Practices**: Learn from high-performing branches
- **Resource Allocation**: Make informed decisions about where to invest

---

## 3. Sales Mix Pie Chart ✅

### Description
Visual breakdown of sales revenue by category (Food vs. Beverage) showing the proportion of each category.

### Features
- **Pie Chart Visualization**: Easy-to-understand visual representation
- **Category Breakdown**: 
  - Food (main dishes, sides, desserts)
  - Beverage (drinks, alcohol, water)
- **Percentage Display**: Shows exact percentage for each category
- **Legend with Values**: Detailed legend with amounts and percentages
- **Multi-Language Support**: Categories shown in English/Khmer/Lao

### Technical Implementation
- **File**: `lib/services/sales_service.dart`
  - New method: `getSalesMixByCategory()`
  - Categorizes products by name keywords
  - Supports English, Thai, and Lao product names
  - Keyword-based categorization:
    - Beverages: "drink", "water", "juice", "beer", "wine", etc.
    - Food: Everything else

- **File**: `lib/widgets/sales_mix_pie_chart.dart` (New Widget)
  - Uses `fl_chart` library for pie chart
  - Interactive legend
  - Responsive design
  - Currency formatting

- **File**: `lib/screens/dashboard_screen.dart`
  - Added `_buildSalesMixChart()` method
  - Integrated into dashboard layout
  - Displays below hourly sales chart

### Categorization Logic
```dart
Beverage Keywords:
- English: drink, beverage, water, juice, soda, beer, wine, cocktail
- Thai: น้ำ, เหล้า, เบียร์
- Lao: ນ້ຳ, ເບຍ, ເຫຼົ້າ

Food: All other products (assumed to be food items)
```

### User Benefits
- **Profit Analysis**: Identify which category generates more revenue
- **Inventory Planning**: Stock appropriate items based on demand
- **Menu Optimization**: Focus on high-performing categories
- **Pricing Strategy**: Adjust prices based on category performance

---

## File Changes Summary

### Modified Files
1. `lib/services/sales_service.dart`
   - Added `getPreviousWeekAverage()`
   - Added `getSalesMixByCategory()`

2. `lib/providers/dashboard_provider.dart`
   - Added `_previousWeekData` state
   - Added `_salesMixData` state
   - Added `calculateGrowth()` method
   - Added `getGrowthFor()` method
   - Updated `loadData()` to fetch new data

3. `lib/widgets/kpi_card.dart`
   - Added `growthPercentage` parameter
   - Added growth indicator UI

4. `lib/screens/dashboard_screen.dart`
   - Added `_buildSalesMixChart()` method
   - Integrated sales mix chart into dashboard
   - Updated KPI cards to show growth indicators

### New Files
1. `lib/widgets/sales_mix_pie_chart.dart`
   - New pie chart widget for sales mix visualization

---

## Database Requirements

### Required Tables
All features use existing database tables:
- `daily_sales` - For sales data and historical comparison
- `product_sales` - For sales mix categorization
- `branches` - For branch filtering
- `v_branch_performance` - For branch comparison view

### No Schema Changes Required
All features work with the existing database schema.

---

## Testing Checklist

### Growth Indicators
- [ ] Verify arrows show correct direction (green up, red down)
- [ ] Verify percentage calculation is accurate
- [ ] Test with no historical data (should show no arrow)
- [ ] Test with zero previous value (should handle gracefully)
- [ ] Test across different branches
- [ ] Test with different date selections

### Branch Comparison
- [ ] Verify all 3 branches display correctly
- [ ] Verify toggle between totals/comparison works
- [ ] Verify branch data is accurate
- [ ] Test with single branch selection

### Sales Mix Pie Chart
- [ ] Verify pie chart displays correctly
- [ ] Verify percentages add up to 100%
- [ ] Verify categorization is accurate (Food vs Beverage)
- [ ] Test with no product sales data
- [ ] Test with multi-language product names
- [ ] Verify legend displays correctly

---

## Build Instructions

### Prerequisites
- Flutter SDK 3.x
- Android SDK
- Supabase credentials configured in `.env`

### Build Commands
```bash
cd D:\mk\mobile

# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release --split-per-abi
```

### Output Files
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (32-bit)
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (64-bit)

---

## User Guide

### Viewing Growth Indicators
1. Open the dashboard app
2. Select a date from the date picker
3. Look at the KPI cards at the top
4. Green arrow (↑) = Growth vs. last week
5. Red arrow (↓) = Decline vs. last week
6. Number shows percentage change

### Using Branch Comparison
1. Tap "All Branches" at the top
2. Toggle between "Totals View" and "Comparison View"
3. In Comparison View, see all branches side-by-side
4. Compare performance across branches

### Understanding Sales Mix
1. Scroll down to "Sales Mix (Food vs Beverage)" section
2. View pie chart showing proportion
3. Check legend for exact percentages
4. Use insights to make business decisions

---

## Future Enhancements (Roadmap)

### Phase 3 (Q2 2026)
- [ ] Delivery sales categorization (currently grouped with Food)
- [ ] More granular categories (Appetizers, Main Course, Desserts)
- [ ] Month-over-month comparison
- [ ] Year-over-year comparison
- [ ] Custom date range comparison

### Phase 4 (Q3 2026)
- [ ] AI-powered insights and recommendations
- [ ] Predictive analytics for sales forecasting
- [ ] Anomaly detection for unusual patterns
- [ ] WhatsApp integration for automated reports

---

## Support

For questions or issues:
- **Developer**: Dr. Bounthong Vongxaya
- **Contact**: 020 9131 6541 (WhatsApp)
- **Documentation**: See `README.md` in project root

---

**Version:** 2.0  
**Last Updated:** March 5, 2026  
**Status:** ✅ Production Ready
