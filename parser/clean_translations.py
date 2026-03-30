"""
Clean product_translations.json - remove category fields
Keeps only: thai_name (key) → {lao, en}
"""

import json
from pathlib import Path

# File paths - use parent directory's data folder
json_path = Path(__file__).parent.parent / "data" / "product_translations.json"
backup_path = Path(__file__).parent.parent / "data" / "product_translations.json.backup"

print(f"Cleaning: {json_path}")

# Load current data
with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Create backup
print(f"Creating backup: {backup_path}")
with open(backup_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

# Clean data - remove category fields
cleaned = {}
removed_count = 0

for thai_name, translations in data.items():
    cleaned_entry = {
        'lao': translations.get('lao', ''),
        'en': translations.get('en', '')
    }
    
    # Check if category existed
    if 'category' in translations:
        removed_count += 1
    
    cleaned[thai_name] = cleaned_entry

# Save cleaned data
print(f"Saving cleaned data...")
with open(json_path, 'w', encoding='utf-8') as f:
    json.dump(cleaned, f, ensure_ascii=False, indent=2)

print(f"\n✅ Cleaning complete!")
print(f"   - Removed {removed_count} category fields")
print(f"   - Total entries: {len(cleaned)}")
print(f"   - Backup saved to: {backup_path}")
