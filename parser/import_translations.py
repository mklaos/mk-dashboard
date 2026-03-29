import json
import csv
import os
from pathlib import Path

def import_translations_from_csv():
    json_path = 'data/product_translations.json'
    csv_path = 'data/product_translations_review.csv'
    
    if not os.path.exists(csv_path):
        print(f"Error: {csv_path} not found. Please generate it first.")
        return

    # Load existing JSON
    if os.path.exists(json_path):
        with open(json_path, 'r', encoding='utf-8') as f:
            translations = json.load(f)
    else:
        translations = {}

    updated_count = 0
    
    # Read CSV
    try:
        with open(csv_path, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            for row in reader:
                thai_name = row['Thai Name']
                new_lao = row.get('New Lao Name (Fill here)', '').strip()
                english = row.get('English Name', '').strip()
                category = row.get('Category', 'unknown').strip()
                
                if thai_name:
                    # Update if new Lao name is provided
                    if new_lao:
                        if thai_name not in translations:
                            translations[thai_name] = {}
                        
                        translations[thai_name]['lao'] = new_lao
                        translations[thai_name]['en'] = english if english else thai_name
                        translations[thai_name]['category'] = category
                        updated_count += 1
                    elif thai_name not in translations:
                        # Add as placeholder if not exists
                        translations[thai_name] = {
                            'lao': row.get('Current Lao Name', '').strip(),
                            'en': english if english else thai_name,
                            'category': category
                        }

        # Save updated JSON
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(translations, f, ensure_ascii=False, indent=2)
        
        print(f"Successfully imported {updated_count} new translations into {json_path}")
        
    except Exception as e:
        print(f"Error during import: {e}")

if __name__ == "__main__":
    import_translations_from_csv()
