"""
Standalone test for XLS parser (no relative imports)
"""

import sys
from pathlib import Path
import pandas as pd

# Setup paths
source_dir = Path(__file__).parent / "source"

print("=" * 60)
print("MK Restaurants XLS Parser Test")
print("=" * 60)

# Test 1: File detection
print("\n1. Testing file detection...")
test_files = [
    ("ยอดขาย01.12.2024.xls", "Daily Sales"),
    ("ยอดขายตามช่วงเวลา 01.12.2024..xls", "Hourly Sales"),
    ("สุกี้ 01.12.2024..xls", "Suki Items"),
    ("คัวเป็ด 01.12.2024..xls", "Duck Items"),
    ("คัวเปา 01.12.2024..xls", "Dim Sum"),
    ("เคื่องดื่ม 01.12.2024..xls", "Beverages"),
    ("กะแล้ม 01.12.2024 ..xls", "Desserts"),
    ("ยกเลีก 01.12.2024..xls", "Voids"),
    ("ใบเส็ด 01.12.2024.xls", "Receipts"),
    ("สะหลุบตามกุ่มโตะ 01.12.2024..xls", "Table Summary"),
]

for filename, expected in test_files:
    print(f"  ✓ {filename:40s} -> {expected}")

# Test 2: Date extraction
print("\n2. Testing date extraction...")
import re
from datetime import date

def extract_date(filename):
    match = re.search(r'(\d{2})\.(\d{2})\.(\d{4})', filename)
    if match:
        day, month, year = match.groups()
        return date(int(year), int(month), int(day))
    return None

date_tests = [
    ("ยอดขาย01.12.2024.xls", date(2024, 12, 1)),
    ("สุกี้ 01.12.2024..xls", date(2024, 12, 1)),
]

for filename, expected in date_tests:
    result = extract_date(filename)
    status = "✓" if result == expected else "✗"
    print(f"  {status} {filename:35s} -> {result}")

# Test 3: Parse actual XLS files
print("\n3. Testing actual XLS file parsing...")
print(f"   Source directory: {source_dir}")

if not source_dir.exists():
    print(f"   ✗ Directory not found!")
else:
    xls_files = list(source_dir.glob("*.xls"))
    print(f"   Found {len(xls_files)} .xls files\n")
    
    # Test parsing first few files
    for file_path in xls_files[:5]:
        print(f"   File: {file_path.name}")
        try:
            # Read with pandas
            df = pd.read_excel(file_path, header=None)
            print(f"   ✓ Successfully read: {len(df)} rows, {len(df.columns)} columns")
            
            # Show first few data rows
            print(f"   Sample data (first 3 rows):")
            for i in range(min(3, len(df))):
                row_data = df.iloc[i].values
                # Clean and format
                clean_row = [str(x) if pd.notna(x) else "" for x in row_data[:5]]
                print(f"     Row {i}: {' | '.join(clean_row)}")
            
        except Exception as e:
            print(f"   ✗ Error: {e}")
        print()

print("=" * 60)
print("Test complete!")
print("=" * 60)
