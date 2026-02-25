# MK Restaurants Multi-Branch Dashboard Implementation Plan

## Executive Summary

Transform the current prototype dashboard into a professional multi-restaurant analytics platform with **tab-based branch switching**, **All Branches default view**, and **dual-mode consolidated display** (totals + comparison). Following international restaurant analytics best practices for executive dashboards.

## Context & Requirements

**Current State:**
- Flutter PWA prototype with single-branch aggregated view
- Shows KPI cards, hourly chart, top products
- Provider package included but not implemented
- SalesService queries all branches (no filtering)
- Missing: branch selection, comparative analytics, proper state management

**User Requirements:**
1. ✅ Tab bar UI (4 tabs: MK001, MK002, MK003, All) - fastest switching
2. ✅ All Branches as default view on startup
3. ✅ All Branches dual-mode: show totals, toggle to side-by-side comparison
4. ✅ Individual branch filtering for each restaurant
5. ✅ Maintain Material 3 design, red color scheme
6. ✅ International best practices for restaurant analytics

## Implementation Plan

### Phase 1: Foundation & Data Layer

**1. Create Branch Model**
- File: `parser/mobile/lib/models/branch.dart`
- Purpose: Type-safe branch data structure
- Fields: id, code, name, nameEn, nameLao, location, isActive
- Includes tri-lingual display logic

**2. Update SalesService with Branch Filtering**
- **Current Issue**: All queries aggregate all branches
- **Solution**: Add `branchCode` parameter to all methods
- **Files Modified**:
  - `getSalesByDate(date, branchCode)` - filter by branch
  - `getHourlySalesByDate(date, branchCode)` - filter by branch
  - `getTopProductsByDate(date, branchCode, limit)` - filter by branch
  - `getAvailableBranches()` - **NEW**: Fetch branches list
  - `getAllBranchesTotals(date)` - **NEW**: Consolidated totals
  - `getBranchComparison(date)` - **NEW**: Side-by-side comparison

**3. Database Query Strategy**
```sql
-- Individual branch filtering
SELECT * FROM daily_sales ds
JOIN branches b ON b.id = ds.branch_id
WHERE b.code = 'MK001' AND ds.sale_date = $date

-- All branches consolidated (existing v_today_summary)
SELECT * FROM v_today_summary WHERE sale_date = $date

-- Branch comparison (existing v_branch_performance)
SELECT * FROM v_branch_performance WHERE sale_date = $date
```

### Phase 2: State Management with Provider

**1. Implement DashboardProvider**
- File: `parser/mobile/lib/providers/dashboard_provider.dart`
- State variables:
  - `List<Branch> branches` - Available branches
  - `String selectedBranchCode` - Currently selected (default: 'ALL')
  - `String selectedDate` - Current date
  - `Map<String, dynamic>? dailySalesData` - KPI data
  - `List<dynamic> hourlyData` - Chart data
  - `List<dynamic> productData` - Products list
  - `bool showComparison` - Toggle between totals/comparison
  - `bool isLoading` - Loading state
  - `String? error` - Error handling

**2. State Management Flow**
```dart
DashboardProvider
  ├─ loadBranches() → fetch from Supabase
  ├─ loadData(date, branchCode) → parallel queries
  ├─ switchBranch(branchCode) → update state
  ├─ toggleComparisonMode() → switch view
  └─ refresh() → reload current data
```

**3. Benefits of Provider**
- Clean separation of concerns
- Automatic UI rebuilds on state changes
- Easy testing and debugging
- Persistence of user preferences

### Phase 3: UI Implementation

**1. Branch Selector Tab Bar**
- Location: Top of dashboard, below date selector
- 4 tabs: **MK001**, **MK002**, **MK003**, **All**
- Styling:
  - Tabs sized to content (not equal width)
  - Red accent color for active tab
  - Smooth animation on selection
  - Persistent across date changes

**2. All Branches Dual-Mode Display**

**Mode 1: Consolidated Totals (Default)**
```
┌─ Branch Tabs (MK001 | MK002 | MK003 | All) ─┐
├─ Date Selector ─────────────────────────────┤
├─ "Today Across All Branches" Subheader ────┤
├─ KPI Cards: [Total Sales] [Receipts] [...]  │
├─ Hourly Chart: Aggregated across all 3     │
├─ Top Products: Combined top 10              │
└─ Comparison Toggle Button                   │
```

**Mode 2: Side-by-Side Comparison (Toggle)**
```
┌─ Branch Tabs (MK001 | MK002 | MK003 | All) ─┐
├─ Date Selector ─────────────────────────────┤
├─ "Branch Comparison" Subheader ────────────┤
├─ KPI Comparison Cards:
│  ┌─ MK001 ─┐ ┌─ MK002 ─┐ ┌─ MK003 ─┐
│  │ Sales   │ │ Sales   │ │ Sales   │
│  │ Receipts│ │ Receipts│ │ Receipts│
├─ Combined Hourly Chart (stacked bars)      │
└─ Totals Toggle Button                       │
```

**3. Individual Branch View**
```
┌─ Branch Tabs (MK001 | MK002 | MK003 | All) ─┐
├─ Date Selector ─────────────────────────────┤
├─ "MK001 (Watnak) Performance" Subheader ───┤
├─ KPI Cards: [Total Sales] [Receipts] [...]  │
├─ Hourly Chart: Branch-specific data         │
└─ Top Products: Branch-specific list         │
```

**4. Visual Enhancements**
- **Subheaders**: Clear indication of selected view (branch name or "All Branches")
- **Color Coding**:
  - MK001: Red theme (primary)
  - MK002: Orange theme (secondary)
  - MK003: Blue theme (tertiary)
  - All: Purple theme (aggregate)
- **Comparison Toggle**: Prominent button (icon + text)
- **Loading States**: Branch-specific loading indicators

### Phase 4: Enhanced Analytics

**1. Implement Empty SalesChart Widget**
- Current status: Shows "coming soon" placeholder
- New implementation: **Branch Comparison Chart**
- Options:
  - Stacked bar chart (total sales across branches)
  - Side-by-side grouped bars
  - Line chart (historical trend for selected branch)
- Default: Stacked bar for All Branches view

**2. Additional Metrics for Comparison View**
```
Branch Performance Metrics:
├─ Total Sales (₭)
├─ Receipt Count
├─ Customer Count
├─ Avg Ticket (₭)
├─ Peak Hour Performance
├─ Top Product (branch-specific)
└─ Void Rate (%)
```

**3. Performance Indicators**
- **Branch Performance Badge**: "↗ 15% vs yesterday" (if implemented)
- **Comparison Insights**: "MK001 leads in total sales"
- **Void Rate Alerts**: "High void rate detected" (if > threshold)

### Phase 5: International Best Practices

**1. Fast Switching (Sub-500ms)**
- Cache branch data locally
- Pre-load all branch data on startup
- Use Provider to avoid rebuilds
- Implement data batching

**2. Executive-Friendly Design**
- **Mobile-First**: 44px minimum touch targets
- **High Contrast**: WCAG AA compliant
- **Clear Typography**: 14px minimum, system fonts
- **Reduced Cognitive Load**: Consistent patterns
- **Offline Indicators**: Show sync status

**3. Cultural Considerations**
- **Lao Language Priority**: Branch names use `name_lao` → `name_en` → `name`
- **Currency Display**: Lao Kip (₭) with K/M notation
- **Date Format**: Localized (Lao/Thai format)
- **Responsive**: Works on small phones

**4. Professional Features**
- **Export Data**: PDF/Excel (future)
- **Refresh on Pull**: Standard mobile pattern
- **Empty States**: Helpful messaging
- **Error States**: Clear recovery actions
- **Skeleton Loading**: Professional loading experience

## File Structure Changes

### New Files to Create
```
lib/
├── models/
│   └── branch.dart                    # Branch data model
├── providers/
│   └── dashboard_provider.dart        # Provider state management
└── widgets/
    ├── branch_selector.dart           # Tab bar component
    ├── comparison_toggle.dart         # Toggle button
    └── kpi_comparison_card.dart       # Side-by-side KPIs
```

### Files to Modify
```
- lib/main.dart                        # Add Provider wrapper
- lib/services/sales_service.dart      # Add branch filtering + new methods
- lib/screens/dashboard_screen.dart    # Implement Provider, tab bar, dual-mode
- lib/widgets/hourly_chart.dart        # Add stacked bar support
- lib/widgets/kpi_card.dart            # Minor enhancements
```

## Testing Strategy

**1. Unit Tests**
- SalesService branch filtering methods
- DashboardProvider state management
- Branch model parsing

**2. Widget Tests**
- BranchSelector tab bar interaction
- All Branches totals view
- All Branches comparison view
- Individual branch view

**3. Integration Tests**
- Full user flow: switch branches, dates, views
- Data fetching and caching
- Error handling scenarios

## Performance Optimization

**1. Data Caching**
- Cache branch list in Provider (static data)
- Cache recent date ranges locally
- Implement simple in-memory cache (5 min TTL)

**2. Query Optimization**
- Batch API calls (combine queries where possible)
- Use existing database views (`v_today_summary`, `v_branch_performance`)
- Limit queries to selected date only

**3. UI Performance**
- Use `const` constructors where possible
- Minimize widget rebuilds with Provider
- Implement `RepaintBoundary` for charts

## International Restaurant Analytics Best Practices

**1. Comparison Patterns**
- Side-by-side layout for quick scanning
- Color coding for visual distinction
- Percentage differences for performance comparison
- Consistent metric ordering

**2. Executive Dashboard Principles**
- **3-Second Rule**: Key metrics visible in 3 seconds
- **Single Screen**: All critical data on one view
- **Fast Switching**: <500ms branch changes
- **Clear Context**: Always show which branch/date
- **Actionable Insights**: Highlight performance issues

**3. Mobile-First Analytics**
- Prioritize portrait orientation
- Touch-friendly controls (44px minimum)
- Swipe gestures for date navigation
- Collapsible sections for less-used data

## Deployment & Rollout

**1. Phase 1 (Week 1)**
- Implement data layer + Provider
- Basic branch filtering

**2. Phase 2 (Week 2)**
- Tab bar UI
- All Branches totals view

**3. Phase 3 (Week 3)**
- Comparison view toggle
- Individual branch filtering
- Testing and polish

**4. Phase 4 (Week 4)**
- Enhanced analytics
- Performance optimization
- Production deployment

## Success Metrics

**1. User Experience**
- Branch switch time: <500ms
- App startup: <2 seconds
- Date navigation: <300ms

**2. Feature Adoption**
- All Branches view: Default (80% usage expected)
- Comparison toggle: 40% usage expected
- Individual branch switching: 60% usage expected

**3. Technical**
- Zero breaking changes to existing data
- Backwards compatible with existing agent uploads
- No data loss during transition

---

## Implementation Checklist

### Phase 1: Foundation & Data Layer

- [ ] **1.1** Create `lib/models/branch.dart`
  - [ ] Define Branch class with all fields
  - [ ] Implement fromJson() factory
  - [ ] Add tri-lingual displayName getter
  - [ ] Add validation for required fields

- [ ] **1.2** Update `lib/services/sales_service.dart`
  - [ ] Add `getAvailableBranches()` method
  - [ ] Add optional `branchCode` parameter to existing methods
  - [ ] Implement `getAllBranchesTotals(date)` using `v_today_summary`
  - [ ] Implement `getBranchComparison(date)` using `v_branch_performance`
  - [ ] Update all query methods to filter by branch when provided
  - [ ] Test all methods return correct data

- [ ] **1.3** Database Query Verification
  - [ ] Verify `v_today_summary` returns aggregated data
  - [ ] Verify `v_branch_performance` returns per-branch data
  - [ ] Test branch filtering on `daily_sales` table
  - [ ] Test branch filtering on `hourly_sales` table
  - [ ] Test branch filtering on `product_sales` table

### Phase 2: State Management with Provider

- [ ] **2.1** Install Provider package
  - [ ] Verify `provider: ^6.1.1` in `pubspec.yaml`
  - [ ] Run `flutter pub get`

- [ ] **2.2** Create `lib/providers/dashboard_provider.dart`
  - [ ] Define all state variables
  - [ ] Implement `loadBranches()` method
  - [ ] Implement `loadData(date, branchCode)` method
  - [ ] Implement `switchBranch(branchCode)` method
  - [ ] Implement `toggleComparisonMode()` method
  - [ ] Implement `refresh()` method
  - [ ] Add error handling for all methods
  - [ ] Test state management

- [ ] **2.3** Update `lib/main.dart`
  - [ ] Import Provider package
  - [ ] Wrap MaterialApp with Provider
  - [ ] Test app still compiles

### Phase 3: UI Implementation

- [ ] **3.1** Create `lib/widgets/branch_selector.dart`
  - [ ] Implement TabBar with 4 tabs (MK001, MK002, MK003, All)
  - [ ] Add onTap callback for tab selection
  - [ ] Style tabs with proper colors
  - [ ] Add smooth animation
  - [ ] Test on different screen sizes

- [ ] **3.2** Create `lib/widgets/comparison_toggle.dart`
  - [ ] Create toggle button component
  - [ ] Add icon and text
  - [ ] Implement onToggle callback
  - [ ] Style appropriately
  - [ ] Test toggle state

- [ ] **3.3** Create `lib/widgets/kpi_comparison_card.dart`
  - [ ] Create side-by-side KPI cards
  - [ ] Accept list of branch data
  - [ ] Display 3 columns side-by-side
  - [ ] Add proper spacing and alignment
  - [ ] Test responsive layout

- [ ] **3.4** Update `lib/screens/dashboard_screen.dart`
  - [ ] Remove manual state management
  - [ ] Import and use DashboardProvider
  - [ ] Add BranchSelector widget
  - [ ] Update date navigation to work with Provider
  - [ ] Implement All Branches totals view
  - [ ] Implement All Branches comparison view
  - [ ] Implement individual branch view
  - [ ] Add subheaders for context
  - [ ] Test all views work correctly
  - [ ] Test branch switching (should be <500ms)
  - [ ] Test comparison toggle

- [ ] **3.5** Visual Enhancements
  - [ ] Add color coding for each branch
  - [ ] Add branch-specific themes
  - [ ] Update subheader text
  - [ ] Test mobile responsiveness
  - [ ] Test on web (Chrome/Firefox/Safari)
  - [ ] Test on Android device
  - [ ] Test on iOS device

### Phase 4: Enhanced Analytics

- [ ] **4.1** Implement `lib/widgets/sales_chart.dart`
  - [ ] Remove "coming soon" placeholder
  - [ ] Create branch comparison stacked bar chart
  - [ ] Use fl_chart library
  - [ ] Add tooltips
  - [ ] Test with sample data

- [ ] **4.2** Update `lib/widgets/hourly_chart.dart`
  - [ ] Add support for stacked bars
  - [ ] Add branch comparison mode
  - [ ] Update data format to support multiple branches
  - [ ] Test hourly chart with all modes

- [ ] **4.3** Additional Metrics
  - [ ] Add void rate calculation
  - [ ] Add peak hour performance indicator
  - [ ] Add top product per branch
  - [ ] Add branch performance badges
  - [ ] Test all metrics

### Phase 5: Testing & Polish

- [ ] **5.1** Unit Tests
  - [ ] Write tests for Branch model
  - [ ] Write tests for SalesService with branch filtering
  - [ ] Write tests for DashboardProvider
  - [ ] Run `flutter test` - all tests pass

- [ ] **5.2** Widget Tests
  - [ ] Test BranchSelector tab interactions
  - [ ] Test All Branches totals view
  - [ ] Test All Branches comparison view
  - [ ] Test individual branch view
  - [ ] Test comparison toggle

- [ ] **5.3** Integration Tests
  - [ ] Test full user flow: app startup → select date → switch branches
  - [ ] Test data fetching and caching
  - [ ] Test error scenarios (no internet, invalid data)
  - [ ] Test pull-to-refresh
  - [ ] Test date navigation

- [ ] **5.4** Performance Testing
  - [ ] Measure branch switch time (target: <500ms)
  - [ ] Measure app startup time (target: <2s)
  - [ ] Measure date navigation (target: <300ms)
  - [ ] Profile memory usage
  - [ ] Optimize if needed

- [ ] **5.5** Cross-Platform Testing
  - [ ] Test on Android phone
  - [ ] Test on iPhone
  - [ ] Test on Chrome web browser
  - [ ] Test on Firefox web browser
  - [ ] Test on Safari web browser
  - [ ] Test PWA installation
  - [ ] Test offline mode (if implemented)

- [ ] **5.6** Accessibility Testing
  - [ ] Check touch targets are 44px minimum
  - [ ] Check color contrast (WCAG AA)
  - [ ] Test with screen reader
  - [ ] Check keyboard navigation
  - [ ] Verify text is readable

- [ ] **5.7** User Acceptance Testing
  - [ ] Test with real data from Supabase
  - [ ] Verify data accuracy (compare with DB)
  - [ ] Test with executives (if possible)
  - [ ] Get feedback on UI/UX
  - [ ] Make adjustments

### Phase 6: Deployment

- [ ] **6.1** Build for Production
  - [ ] Run `flutter clean`
  - [ ] Run `flutter pub get`
  - [ ] Run `flutter build apk --release`
  - [ ] Run `flutter build web --release --wasm`
  - [ ] Verify builds complete successfully

- [ ] **6.2** Deploy to Firebase
  - [ ] Update Firebase configuration if needed
  - [ ] Run `firebase deploy --only hosting`
  - [ ] Verify deployment successful
  - [ ] Test live URL
  - [ ] Share with stakeholders

- [ ] **6.3** Documentation
  - [ ] Update README.md with new features
  - [ ] Add screenshots to docs
  - [ ] Write user guide for new features
  - [ ] Update AGENTS.md with implementation notes
  - [ ] Create changelog

### Phase 7: Post-Deployment

- [ ] **7.1** Monitoring
  - [ ] Set up error tracking (if needed)
  - [ ] Monitor app performance
  - [ ] Check Supabase usage
  - [ ] Monitor user feedback

- [ ] **7.2** Future Enhancements (Backlog)
  - [ ] Historical trends view
  - [ ] Export to PDF/Excel
  - [ ] Real-time updates (WebSocket)
  - [ ] Offline mode with caching
  - [ ] User authentication
  - [ ] Role-based access
  - [ ] Push notifications
  - [ ] Custom date ranges
  - [ ] More chart types

---

## Quick Reference

**Database Views to Use:**
- `v_today_summary` - All branches aggregated
- `v_branch_performance` - Individual branch data
- `v_peak_hours` - Hourly analysis
- `v_product_performance` - Product rankings
- `v_void_summary` - Void tracking

**Branches:**
- MK001 - MK Watnak (Watnak branch in Vientiane)
- MK002 - MK Branch 2
- MK003 - MK Branch 3
- ALL - Consolidated view (default)

**Key Files:**
- New: `lib/models/branch.dart`
- New: `lib/providers/dashboard_provider.dart`
- New: `lib/widgets/branch_selector.dart`
- New: `lib/widgets/comparison_toggle.dart`
- New: `lib/widgets/kpi_comparison_card.dart`
- Modify: `lib/services/sales_service.dart`
- Modify: `lib/screens/dashboard_screen.dart`
- Modify: `lib/main.dart`

**Commands:**
```bash
# Development
flutter run -d chrome
flutter run -d <device_id>

# Testing
flutter test
flutter test test/widget_test.dart

# Building
flutter build apk --release
flutter build web --release --wasm

# Deployment
firebase deploy --only hosting
```

**Estimated Time:** 2-3 weeks
**Risk Level:** Low (additive changes only)
**Breaking Changes:** None

---

## Notes & Updates

**2026-02-25:** Initial plan created
- [ ] Plan approved
- [ ] Implementation started
- [ ] Implementation completed
- [ ] Testing completed
- [ ] Deployed to production

Update this section as implementation progresses.
