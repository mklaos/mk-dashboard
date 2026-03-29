# MK Dashboard - Web Testing Guide

## Testing URL
**http://localhost:8080**

The app is now running in Chrome. Keep the terminal open while testing.

---

## Test Checklist

### 1. Growth Indicators ✅
**What to look for:**
- [ ] Open the dashboard
- [ ] Look at the 4 KPI cards at the top (Total Sales, Receipts, Customers, Avg Ticket)
- [ ] Check if there are **green ↑** or **red ↓** arrows below each value
- [ ] Verify the percentage is displayed (e.g., "12.5%")
- [ ] **Green arrow** = Good (growth vs last week)
- [ ] **Red arrow** = Bad (decline vs last week)

**Expected Results:**
- If current sales > last week average → Green arrow ↑
- If current sales < last week average → Red arrow ↓
- Percentage shows how much change (e.g., "+15.3%" or "-8.2%")

**Test Scenarios:**
1. **All Branches** view - Should show growth indicators
2. **Individual Branch** view - Select MK001, MK002, or MK003 - Should show growth indicators
3. **Different Dates** - Select different dates to see different growth patterns

---

### 2. Sales Mix Pie Chart ✅
**What to look for:**
- [ ] Scroll down to "Sales Mix (Food vs Beverage)" section
- [ ] Should see a **pie chart** with 2 colors
- [ ] Check the **legend** on the right showing:
  - Food category with percentage
  - Beverage category with percentage
- [ ] Percentages should add up to ~100%

**Expected Results:**
- Pie chart shows proportion of Food vs Beverage sales
- Legend shows exact percentages and amounts
- Categories are color-coded

**Test Scenarios:**
1. **All Branches** - Combined sales mix
2. **Individual Branch** - Sales mix for specific branch
3. **Different Dates** - Sales mix may vary by day

---

### 3. Branch Comparison ✅
**What to look for:**
- [ ] Make sure "All Branches" is selected
- [ ] Look for "Totals View | Comparison View" toggle
- [ ] Click the **swap icon** to switch to Comparison View
- [ ] Should see all 3 branches side-by-side
- [ ] Each branch shows: Sales, Receipts, Customers, Avg Ticket, Void Rate

**Expected Results:**
- All 3 branches displayed in cards
- Easy to compare which branch performed best
- Branch codes: MK001, MK002, MK003

---

## Known Issues & Troubleshooting

### No Growth Indicators Showing
**Possible causes:**
1. **No historical data** - The selected date needs previous week data
2. **First time data** - If this is the first day of operation, no comparison available
3. **Console errors** - Check browser console (F12) for errors

**Solution:**
- Try selecting a later date that has previous week data
- Check browser console for error messages

### No Sales Mix Data
**Possible causes:**
1. **No product sales** - The date has no product sales data
2. **Categorization issue** - Products not categorized correctly

**Solution:**
- Try a different date
- Check browser console for errors

### App Not Loading
**Possible causes:**
1. **Supabase connection** - Check internet connection
2. **Environment variables** - `.env` file not loaded

**Solution:**
- Refresh the page (Ctrl+R)
- Check browser console for errors
- Verify Supabase URL is correct

---

## Browser Console Commands

Open browser console (Press **F12**) to see logs:

```javascript
// Check if app loaded correctly
console.log('App loaded');

// Check Supabase connection
// (Check console logs for any errors)
```

---

## Screenshots to Capture

Please capture screenshots of:
1. **Dashboard with Growth Indicators** - Showing green/red arrows
2. **Sales Mix Pie Chart** - Full pie chart with legend
3. **Branch Comparison View** - All 3 branches side-by-side
4. **Any errors** - If something doesn't work

---

## Feedback Questions

After testing, please provide feedback on:

1. **Growth Indicators**
   - Are the arrows clear and easy to understand?
   - Is the percentage display helpful?
   - Color scheme (green/red) - Good or needs adjustment?

2. **Sales Mix Pie Chart**
   - Is the pie chart easy to read?
   - Is the legend clear?
   - Would you like more categories? (e.g., separate Desserts, Appetizers)

3. **Branch Comparison**
   - Is the side-by-side comparison useful?
   - What other metrics would you like to see?

4. **Overall**
   - Is the dashboard easy to navigate?
   - Loading speed - Fast enough?
   - Any other features you'd like?

---

## Stopping the Test Server

When done testing, stop the server:
```bash
# In the terminal where Python is running
Ctrl+C
```

---

**Test Date:** ___________  
**Tester:** ___________  
**Browser:** Chrome  
**Version:** ___________

**Issues Found:**
- [ ] 
- [ ] 
- [ ] 

**Overall Rating:** ⭐⭐⭐⭐⭐ (1-5 stars)
