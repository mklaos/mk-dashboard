import pandas as pd
import json
import os
import glob
from pathlib import Path

def scan_reports_for_new_products():
    json_path = 'data/product_translations.json'
    source_dir = 'source'
    
    if not os.path.exists(json_path):
        print(f"Error: {json_path} not found.")
        return

    with open(json_path, 'r', encoding='utf-8') as f:
        translations = json.load(f)

    all_products_in_reports = set()
    
    # Files that usually contain product names
    product_report_patterns = [
        'สุกี้*.xls',
        'คัวเป็ด*.xls',
        'คัวเปา*.xls',
        'เคื่องดื่ม*.xls',
        'กะแล้ม*.xls',
        'สุกี้ชาม*.xls'
    ]

    for pattern in product_report_patterns:
        files = glob.glob(os.path.join(source_dir, pattern))
        for file in files:
            try:
                # Read XLS (assuming common MK format where name is in Column B/index 1)
                # We skip headers and try to find column that looks like product names
                df = pd.read_excel(file, header=None)
                
                # Usually product names are in column 1 (B) or 2 (C)
                # We'll just scan all strings in the dataframe
                for col in df.columns:
                    for val in df[col].dropna():
                        if isinstance(val, str) and len(val) > 2:
                            # Heuristic: Thai product names are usually strings, not purely numbers or dates
                            # and not common report headers like 'รายการ' or 'ລາຍການ'
                            if any(ord(c) >= 0x0E00 and ord(c) <= 0x0E7F for c in val): # Thai characters
                                if val not in ['รายการ', 'ชื่ออาหาร', 'รวม', 'จำนวน', 'ราคา']:
                                    all_products_in_reports.add(val.strip())
            except Exception as e:
                print(f"Error reading {file}: {e}")

    new_products = all_products_in_reports - set(translations.keys())
    
    if new_products:
        print(f"Found {len(new_products)} new products not in translation file:")
        for p in sorted(new_products):
            print(f" - {p}")
            # Add to translations with empty Lao/En so they appear in CSV next time
            translations[p] = {"lao": "", "en": p}

        # Save updated JSON
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(translations, f, ensure_ascii=False, indent=2)
        print(f"Updated {json_path} with new placeholders.")
    else:
        print("No new products found in reports.")

if __name__ == "__main__":
    scan_reports_for_new_products()
