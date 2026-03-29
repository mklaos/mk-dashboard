import json
import csv
import os

def generate_csv():
    json_path = 'data/product_translations.json'
    csv_path = 'data/product_translations_review.csv'
    
    if not os.path.exists(json_path):
        print(f"Error: {json_path} not found.")
        return

    with open(json_path, 'r', encoding='utf-8') as f:
        translations = json.load(f)

    with open(csv_path, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        # Header
        writer.writerow(['Thai Name', 'English Name', 'Current Lao Name', 'New Lao Name (Fill here)', 'Category'])
        
        for thai_name, details in sorted(translations.items()):
            lao = details.get('lao', '')
            en = details.get('en', '')
            cat = details.get('category', 'unknown')
            
            # Write row, leaving "New Lao Name" empty for user to fill
            writer.writerow([thai_name, en, lao, '', cat])

    print(f"Successfully generated {csv_path}")

if __name__ == "__main__":
    generate_csv()
