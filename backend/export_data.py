"""
Export all data from current Supabase project for migration.
Creates JSON backup files in D:/mk/backup/ directory.

Usage:
    python backend/export_data.py
"""

import os
import json
from datetime import datetime
from pathlib import Path
from supabase import create_client, Client
from dotenv import load_dotenv

# Find the .env file (try multiple locations)
script_dir = Path(__file__).parent
env_paths = [
    script_dir / ".env",
    script_dir.parent / "backend" / ".env",
    Path.cwd() / ".env",
    Path.cwd() / "backend" / ".env"
]

env_loaded = False
for env_path in env_paths:
    if env_path.exists():
        load_dotenv(env_path)
        env_loaded = True
        print(f"Loaded: {env_path}")
        break

if not env_loaded:
    print("❌ Error: Could not find .env file")
    print("Searched in:")
    for p in env_paths:
        print(f"  - {p}")
    exit(1)

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print("❌ Error: Missing Supabase credentials")
    print("Please create backend/.env file with:")
    print("  SUPABASE_URL=https://your-project.supabase.co")
    print("  SUPABASE_SERVICE_KEY=your-service-role-key")
    exit(1)

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

# Backup directory
BACKUP_DIR = Path("D:/mk/backup")
BACKUP_DIR.mkdir(parents=True, exist_ok=True)

# Tables to export (in order to respect foreign keys)
TABLES = [
    "branches",
    "categories",
    "void_reasons",
    "products",
    "daily_sales",
    "hourly_sales",
    "product_sales",
    "transactions",
    "transaction_items",
    "void_log",
    "sync_log",
    "import_log",
]

def export_table(table_name: str) -> dict:
    """Export all rows from a table."""
    print(f"  Exporting {table_name}...")
    
    try:
        # Fetch all records
        response = supabase.table(table_name).select("*").execute()
        
        data = {
            "table": table_name,
            "row_count": len(response.data),
            "exported_at": datetime.now().isoformat(),
            "data": response.data
        }
        
        # Save to file
        output_file = BACKUP_DIR / f"{table_name}.json"
        with open(output_file, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2, default=str)
        
        print(f"    ✅ {response.data} rows exported to {output_file}")
        return data
        
    except Exception as e:
        print(f"    ❌ Error exporting {table_name}: {str(e)}")
        return {
            "table": table_name,
            "row_count": 0,
            "error": str(e),
            "data": []
        }

def main():
    print("=" * 70)
    print("MK Restaurants - Supabase Data Export")
    print("=" * 70)
    print(f"\n📦 Exporting from: {SUPABASE_URL}")
    print(f"📁 Backup directory: {BACKUP_DIR}")
    print(f"⏰ Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Test connection first
    try:
        test_response = supabase.table("branches").select("count", count="exact").execute()
        print("✅ Connected to Supabase successfully")
        print()
    except Exception as e:
        print(f"❌ Connection failed: {str(e)}")
        print("\n💡 Make sure you have valid credentials in backend/.env")
        exit(1)
    
    # Export all tables
    export_summary = {
        "export_started": datetime.now().isoformat(),
        "project_url": SUPABASE_URL,
        "tables": {}
    }
    
    for table_name in TABLES:
        result = export_table(table_name)
        export_summary["tables"][table_name] = {
            "row_count": result["row_count"],
            "error": result.get("error")
        }
    
    # Save export summary
    summary_file = BACKUP_DIR / "export_summary.json"
    with open(summary_file, "w", encoding="utf-8") as f:
        json.dump(export_summary, f, ensure_ascii=False, indent=2, default=str)
    
    # Print summary
    print()
    print("=" * 70)
    print("📊 EXPORT SUMMARY")
    print("=" * 70)
    
    total_rows = 0
    for table_name, info in export_summary["tables"].items():
        rows = info["row_count"]
        total_rows += rows
        status = "❌" if info.get("error") else "✅"
        print(f"{status} {table_name:25} {rows:6} rows")
    
    print("-" * 70)
    print(f"{'TOTAL':25} {total_rows:6} rows")
    print("=" * 70)
    print(f"\n💾 Backup saved to: {BACKUP_DIR}")
    print(f"⏰ Completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    print("Next steps:")
    print("  1. Review exported files in D:/mk/backup/")
    print("  2. Set up new Supabase project")
    print("  3. Run: python backend/import_to_new_supabase.py")

if __name__ == "__main__":
    main()
