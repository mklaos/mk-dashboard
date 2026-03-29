# Sales Mix Feature - Status & Solution

## Problem
The Sales Mix (Food vs Beverage) pie chart shows "No sales mix data" even though we have product sales data in Supabase.

## Root Cause
The existing product sales data in Supabase **does not have the `category_name` field populated**. 

When we look at the parser (`parser_complete.py`), it DOES include the category field when parsing:
```python
products.append({
    "product_name_th": product_name,
    "product_name_lao": product_lao,
    "product_name_en": product_en,
    "category": category,  # ← This is included!
    "quantity": ...,
    ...
})
```

And the agent uploader (`uploader.py`) also includes it:
```python
record = {
    "product_name_th": ...,
    "category_name": p.get("category", ""),  # ← This is uploaded!
    ...
}
```

**BUT** the existing data was uploaded before we properly categorized products, so the `category_name` field is empty in the database.

## Solution

### Option 1: Re-upload Data (Recommended for Testing)
1. **Clear existing product sales data** from Supabase
2. **Re-run the parser & uploader** on the Excel files
3. The new uploads will include proper `category_name` values

### Option 2: Update Existing Data (For Production)
Create a script to update existing product_sales records with category information based on product names.

---

## How Categories Work

### Parser Categories (from Excel file types)
The parser categorizes products based on which Excel report they came from:

**Food Categories:**
- `suki_items` - Suki dishes
- `suki_sets` - Suki set menus
- `duck_items` - Duck dishes
- `dim_sum` - Dim sum
- `desserts` - Desserts & ice cream
- `kitchen_categories` - Kitchen items

**Beverage Categories:**
- `beverages` - All drinks

### Mobile App Categorization Logic
The updated `sales_service.dart` now uses a **3-tier approach**:

1. **First**: Check `category_name` field from database
   - If category contains "beverage", "drink" → Beverage
   - If category contains "suki", "duck", "dim_sum", "dessert" → Food

2. **Second**: Fallback to product name keyword matching
   - Checks Thai, Lao, English keywords
   - e.g., "น้ำ", "ນ້ຳ", "water", "beer" → Beverage

3. **Default**: Everything else is Food

---

## Testing Steps

### 1. Check Current Data
Open Supabase SQL Editor and run:
```sql
SELECT 
  product_name_th, 
  category_name, 
  total_amount 
FROM product_sales 
LIMIT 10;
```

**Expected Result:**
- If `category_name` is NULL or empty → Need to re-upload
- If `category_name` has values like "beverages", "suki_items" → Should work!

### 2. Test Web App
1. Open http://localhost:8080
2. Select a date that has product sales
3. Scroll to "Sales Mix (Food vs Beverage)" section
4. Should see pie chart with Food vs Beverage breakdown

### 3. If Still No Data
Check browser console (F12) for errors.

Common issues:
- **No product sales for selected date** → Try different date
- **Category names don't match** → Check database values
- **Query error** → Check Supabase RLS policies

---

## Re-uploading Data (Option 1)

### Step 1: Clear Existing Data
In Supabase SQL Editor:
```sql
-- Delete product sales (keep the structure)
DELETE FROM product_sales;

-- Optional: Reset translations to add categories
-- (This will be re-populated automatically)
```

### Step 2: Re-run Agent
```bash
cd D:\mk\agent
python tray_app.py
```

The agent will:
1. Re-parse all Excel files
2. Include `category` field for each product
3. Upload to Supabase with `category_name`

### Step 3: Verify
Check Supabase again:
```sql
SELECT 
  category_name, 
  COUNT(*) as count,
  SUM(total_amount) as total
FROM product_sales 
GROUP BY category_name;
```

Should show categories like:
- `beverages`: X records
- `suki_items`: Y records
- `duck_items`: Z records
- etc.

---

## Future Enhancement

### Add Category Field to Product Translations
We started adding `category` to `product_translations.json`:
```json
{
  "ไอศกรีมชาเขียว": {
    "lao": "ໄອສະກຣີມຊາເຂົ້າ",
    "en": "Green Tea Ice Cream",
    "category": "dessert"
  }
}
```

This would allow manual override of categories for products that don't fit standard patterns.

### Benefits:
- More granular categories (Appetizers, Main Course, Desserts, Beverages)
- Manual correction of miscategorized items
- Support for new products not in standard reports

---

## Summary

**Current Status:**
- ✅ Parser includes category field
- ✅ Uploader sends category_name
- ✅ Mobile app reads and categorizes correctly
- ❌ Existing database lacks category_name values

**Solution:**
- Re-upload data to populate category_name field
- OR update existing records with category information

**After Fix:**
- Sales Mix pie chart will show Food vs Beverage breakdown
- Growth indicators will work (already implemented)
- Branch comparison will work (already implemented)

---

**Next Steps:**
1. Decide: Re-upload vs. update existing data
2. Execute the chosen approach
3. Test web app again
4. Deploy to production

**Date:** March 5, 2026  
**Status:** Ready for re-upload
