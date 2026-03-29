"""
Supabase Data Upload Script
Parses XLS files and uploads to mk-sales-dashboard
"""

import os
import sys
from pathlib import Path
from datetime import datetime
from decimal import Decimal
from dotenv import load_dotenv

# Load environment
load_dotenv()

# Setup paths
sys.path.insert(0, str(Path(__file__).parent.parent))

from supabase import create_client, Client
from parser.parser_complete import MKParserComplete
from parser.translator import get_translator

def to_float(value):
    """Convert Decimal or other types to float for JSON serialization"""
    if isinstance(value, Decimal):
        return float(value)
    return value

# Configuration
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")
BRANCH_CODE = os.getenv("BRANCH_CODE", "MK001")

# Initialize translator
translator = get_translator()

def get_branch_uuid(supabase: Client, branch_code: str) -> str:
    """Get branch UUID from code"""
    try:
        response = supabase.table("branches").select("id").eq("code", branch_code).execute()
        if response.data:
            return response.data[0]["id"]
        return None
    except Exception as e:
        print(f"Error getting branch: {e}")
        return None

def upload_daily_sales(supabase: Client, branch_id: str, data: dict):
    """Upload daily sales summary"""
    try:
        daily_data = data.get("daily_data", {})
        if daily_data:
            record = {
                "branch_id": branch_id,
                "sale_date": data["sale_date"],
                "gross_sales": to_float(daily_data.get("gross_sales", 0)),
                "net_sales": to_float(daily_data.get("net_sales", 0)),
                "tax_amount": to_float(daily_data.get("tax_amount", 0)),
                "discount_amount": to_float(daily_data.get("discount_amount", 0)),
                "takeaway_sales": to_float(daily_data.get("takeaway_sales", 0)),
                "receipt_count": int(daily_data.get("receipt_count", 0)),
                "customer_count": int(daily_data.get("customer_count", 0)),
                "table_count": int(daily_data.get("table_count", 0)),
                "void_count": int(daily_data.get("void_count", 0)),
                "void_amount": to_float(daily_data.get("void_amount", 0)),
            }
            
            # Check if record exists
            check = supabase.table("daily_sales").select("id").eq("branch_id", branch_id).eq("sale_date", data["sale_date"]).execute()
            
            if check.data:
                # Update existing
                supabase.table("daily_sales").update(record).eq("id", check.data[0]["id"]).execute()
                print(f"  Updated daily sales for {data['sale_date']}")
            else:
                # Insert new
                supabase.table("daily_sales").insert(record).execute()
                print(f"  Inserted daily sales for {data['sale_date']}")
                
    except Exception as e:
        print(f"  Error uploading daily sales: {e}")

def upload_hourly_sales(supabase: Client, branch_id: str, data: dict):
    """Upload hourly sales"""
    try:
        hourly_data = data.get("hourly_data", [])
        count = 0
        
        for hour_record in hourly_data:
            record = {
                "branch_id": branch_id,
                "sale_date": data["sale_date"],
                "hour": int(hour_record["hour"]),
                "table_count": int(hour_record.get("table_count", 0)),
                "customer_count": int(hour_record.get("customer_count", 0)),
                "sales": to_float(hour_record.get("sales", 0)),
            }
            
            # Upsert (insert or update)
            supabase.table("hourly_sales").upsert(record).execute()
            count += 1
            
        print(f"  Uploaded {count} hourly records")
        
    except Exception as e:
        print(f"  Error uploading hourly sales: {e}")

def upload_product_sales(supabase: Client, branch_id: str, data: dict):
    """Upload product sales"""
    try:
        products = data.get("products", [])
        count = 0
        
        for product in products:
            thai_name = product.get("product_name_th", "")
            # Get translation from mapping file
            translation = translator.translate(thai_name)
            
            record = {
                "branch_id": branch_id,
                "sale_date": data["sale_date"],
                "product_name_th": thai_name,
                "product_name_lao": translation.get("lao", ""),
                "category_name": product.get("category", ""),
                "quantity": int(product.get("quantity", 0)),
                "unit_price": to_float(product.get("unit_price", 0)),
                "total_amount": to_float(product.get("total_amount", 0)),
            }
            
            # Get or create product
            # For now, just insert without product_id reference
            supabase.table("product_sales").upsert(record).execute()
            count += 1
            
        print(f"  Uploaded {count} product sales")
        
    except Exception as e:
        print(f"  Error uploading product sales: {e}")

def upload_voids(supabase: Client, branch_id: str, data: dict):
    """Upload void log"""
    try:
        voids = data.get("voids", [])
        count = 0
        
        for void_record in voids:
            product_name = void_record.get("product_name", "")
            translation = translator.translate(product_name)
            
            record = {
                "branch_id": branch_id,
                "sale_date": data["sale_date"],
                "original_receipt_no": void_record.get("receipt_no", ""),
                "table_no": void_record.get("table_no", ""),
                "product_name_th": product_name,
                "product_name_lao": translation.get("lao", ""),
                "quantity": int(void_record.get("quantity", 0)),
                "amount": abs(to_float(void_record.get("amount", 0))),
                "reason_text": void_record.get("reason", ""),
            }
            
            supabase.table("void_log").insert(record).execute()
            count += 1
        
        print(f"  Uploaded {count} void records")
        
    except Exception as e:
        print(f"  Error uploading voids: {e}")

def upload_file_data(supabase: Client, branch_id: str, result: dict):
    """Route to appropriate upload function"""
    report_type = result.get("report_type", "")
    
    if report_type == "daily_sales":
        upload_daily_sales(supabase, branch_id, result)
    elif report_type == "hourly_sales":
        upload_hourly_sales(supabase, branch_id, result)
    elif report_type in ["suki_items", "suki_sets", "duck_items", "dim_sum", "beverages", "desserts"]:
        upload_product_sales(supabase, branch_id, result)
    elif report_type == "voids":
        upload_voids(supabase, branch_id, result)
    else:
        print(f"  Skipped {report_type} (not yet implemented)")

def main():
    """Main upload function"""
    print("=" * 70)
    print("MK Restaurants - Supabase Data Upload")
    print("=" * 70)
    print(f"Project: {SUPABASE_URL}")
    print(f"Branch: {BRANCH_CODE}")
    print()
    
    # Validate config
    if not SUPABASE_URL or not SUPABASE_KEY:
        print("❌ Error: SUPABASE_URL and SUPABASE_KEY must be set in .env")
        print("   Check backend/.env file")
        return
    
    try:
        # Connect to Supabase
        print("Connecting to Supabase...")
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        # Get branch UUID
        print(f"Getting branch ID for {BRANCH_CODE}...")
        branch_id = get_branch_uuid(supabase, BRANCH_CODE)
        
        if not branch_id:
            print(f"❌ Error: Branch {BRANCH_CODE} not found in database")
            print("   Make sure schema.sql was run and branches seeded")
            return
            
        print(f"✓ Connected! Branch ID: {branch_id}")
        print()
        
        # Parse and upload all files
        source_dir = Path(__file__).parent.parent / "source"
        parser = MKParserComplete(branch_code=BRANCH_CODE)
        
        print(f"Processing files from: {source_dir}")
        print("=" * 70)
        
        results = parser.parse_directory(str(source_dir))
        
        print()
        print("=" * 70)
        print("Uploading to Supabase...")
        print("=" * 70)
        
        uploaded = 0
        failed = 0
        
        for result in results:
            if result.get("success") and result.get("count", 0) > 0:
                print(f"\n{result['report_type']}: {result['filename']}")
                try:
                    upload_file_data(supabase, branch_id, result)
                    uploaded += 1
                except Exception as e:
                    print(f"  ❌ Failed: {e}")
                    failed += 1
        
        # Summary
        print()
        print("=" * 70)
        print("UPLOAD SUMMARY")
        print("=" * 70)
        print(f"Files processed: {len(results)}")
        print(f"Successfully uploaded: {uploaded}")
        print(f"Failed: {failed}")
        
        # Show sample data from database
        print()
        print("=" * 70)
        print("VERIFICATION - Data in Database")
        print("=" * 70)
        
        # Check daily_sales
        daily = supabase.table("daily_sales").select("*").execute()
        print(f"Daily Sales records: {len(daily.data)}")
        
        # Check hourly_sales
        hourly = supabase.table("hourly_sales").select("*").execute()
        print(f"Hourly Sales records: {len(hourly.data)}")
        
        # Check product_sales
        products = supabase.table("product_sales").select("*").execute()
        print(f"Product Sales records: {len(products.data)}")
        
        # Check void_log
        voids = supabase.table("void_log").select("*").execute()
        print(f"Void Log records: {len(voids.data)}")
        
        print()
        print("✓ Upload complete!")
        print("=" * 70)
        
    except Exception as e:
        print(f"❌ Fatal error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
