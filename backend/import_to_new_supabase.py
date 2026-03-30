"""
Import exported data to new Supabase project.
Reads JSON files from D:/mk/backup/ and imports to new Supabase instance.

Usage:
    python backend/import_to_new_supabase.py
"""

import os
import json
from datetime import datetime
from pathlib import Path
from supabase import create_client, Client
from dotenv import load_dotenv

# Find the .env.new file (try multiple locations)
script_dir = Path(__file__).parent
env_paths = [
    script_dir / ".env.new",
    script_dir.parent / "backend" / ".env.new",
    Path.cwd() / ".env.new",
    Path.cwd() / "backend" / ".env.new"
]

env_loaded = False
for env_path in env_paths:
    if env_path.exists():
        load_dotenv(env_path)
        env_loaded = True
        print(f"Loaded: {env_path}")
        break

if not env_loaded:
    print("❌ Error: Could not find .env.new file")
    print("Please create backend/.env.new with new project credentials")
    print("Searched in:")
    for p in env_paths:
        print(f"  - {p}")
    exit(1)

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print("❌ Error: Missing new Supabase credentials")
    print("Please create backend/.env.new file with:")
    print("  SUPABASE_URL=https://NEW_PROJECT_ID.supabase.co")
    print("  SUPABASE_SERVICE_KEY=your-new-service-role-key")
    exit(1)

# Initialize Supabase client for NEW project
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

# Backup directory
BACKUP_DIR = Path("D:/mk/backup")

# Tables to import (in order to respect foreign keys)
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

# Mapping of old UUIDs to new UUIDs (for maintaining relationships)
UUID_MAPPING = {}
OLD_UUID_TO_CODE = {}  # Maps old UUID to branch code

def import_table(table_name: str) -> dict:
    """Import data from JSON file to table."""
    print(f"  Importing {table_name}...")
    
    input_file = BACKUP_DIR / f"{table_name}.json"
    
    if not input_file.exists():
        print(f"    ⚠️  File not found: {input_file}")
        return {
            "table": table_name,
            "imported_rows": 0,
            "skipped_rows": 0,
            "error": "File not found"
        }
    
    try:
        # Load exported data
        with open(input_file, "r", encoding="utf-8") as f:
            export_data = json.load(f)
        
        rows = export_data.get("data", [])
        
        if not rows:
            print(f"    ⚠️  No data to import")
            return {
                "table": table_name,
                "imported_rows": 0,
                "skipped_rows": 0
            }
        
        imported = 0
        skipped = 0
        
        # Special handling for tables with UUIDs that need mapping
        if table_name in ["branches", "categories", "void_reasons"]:
            # These are reference tables - preserve UUIDs
            for row in rows:
                try:
                    # Remove created_at if it exists (let DB set default)
                    if "created_at" in row:
                        del row["created_at"]
                    if "updated_at" in row:
                        del row["updated_at"]
                    
                    old_id = row.get("id")
                    
                    response = supabase.table(table_name).upsert(row).execute()
                    imported += 1
                    
                    # Store UUID mapping for branches
                    if table_name == "branches" and old_id and response.data and len(response.data) > 0:
                        new_id = response.data[0]["id"]
                        branch_code = response.data[0].get("code")
                        UUID_MAPPING[old_id] = new_id
                        OLD_UUID_TO_CODE[old_id] = branch_code
                        print(f"    📝 Mapped old {old_id} → new {new_id} ({branch_code})")
                        
                except Exception as e:
                    print(f"      ⚠️  Skipped row: {str(e)[:50]}")
                    skipped += 1
            
            # After importing branches, also build a code-based mapping
            if table_name == "branches":
                print(f"    📝 Building branch code mapping...")
                branch_response = supabase.table("branches").select("id, code").execute()
                for branch in branch_response.data:
                    UUID_MAPPING[branch["code"]] = branch["id"]
                    
        elif table_name in ["daily_sales", "hourly_sales", "product_sales", "transactions", "transaction_items", "void_log", "sync_log", "import_log"]:
            # Transactional tables - need to map branch_id
            for row in rows:
                try:
                    # Remove auto-generated fields
                    if "id" in row:
                        del row["id"]
                    if "created_at" in row:
                        del row["created_at"]
                    if "updated_at" in row:
                        del row["updated_at"]
                    if "imported_at" in row:
                        del row["imported_at"]
                    
                    # Map branch_id using the OLD_UUID_TO_CODE mapping
                    if "branch_id" in row and row["branch_id"]:
                        old_branch_id = row["branch_id"]
                        
                        # Strategy 1: Use old UUID to new UUID mapping
                        if old_branch_id in UUID_MAPPING:
                            row["branch_id"] = UUID_MAPPING[old_branch_id]
                        # Strategy 2: Default to MK001 if no mapping found
                        else:
                            row["branch_id"] = UUID_MAPPING.get("MK001")
                            print(f"      ⚠️  Using default MK001 for unknown branch {old_branch_id}")
                    
                    response = supabase.table(table_name).insert(row).execute()
                    imported += 1
                except Exception as e:
                    error_msg = str(e)
                    if "duplicate" in error_msg.lower() or "unique" in error_msg.lower():
                        pass  # Skip silently for duplicates
                    elif "foreign key" in error_msg.lower():
                        # Try with MK001
                        if "branch_id" in row:
                            row["branch_id"] = UUID_MAPPING.get("MK001")
                            try:
                                response = supabase.table(table_name).insert(row).execute()
                                imported += 1
                                continue
                            except:
                                pass
                        print(f"      ⚠️  FK error: {str(e)[:50]}")
                        skipped += 1
                    else:
                        print(f"      ⚠️  Skipped: {str(e)[:60]}")
                    skipped += 1
        else:
            # Other tables - insert normally
            clean_rows = []
            for row in rows:
                clean_row = row.copy()
                if "id" in clean_row:
                    del clean_row["id"]
                if "created_at" in clean_row:
                    del clean_row["created_at"]
                if "updated_at" in clean_row:
                    del clean_row["updated_at"]
                if "imported_at" in clean_row:
                    del clean_row["imported_at"]
                clean_rows.append(clean_row)
            
            # Batch insert (100 rows at a time)
            batch_size = 100
            for i in range(0, len(clean_rows), batch_size):
                batch = clean_rows[i:i + batch_size]
                try:
                    response = supabase.table(table_name).insert(batch).execute()
                    imported += len(batch)
                except Exception as e:
                    print(f"      ⚠️  Batch error: {str(e)[:50]}")
                    skipped += len(batch)
        
        print(f"    ✅ {imported} rows imported, {skipped} skipped")
        
        return {
            "table": table_name,
            "imported_rows": imported,
            "skipped_rows": skipped
        }
        
    except Exception as e:
        print(f"    ❌ Error importing {table_name}: {str(e)}")
        return {
            "table": table_name,
            "imported_rows": 0,
            "skipped_rows": 0,
            "error": str(e)
        }

def verify_migration():
    """Verify that data was migrated correctly."""
    print()
    print("=" * 70)
    print("🔍 VERIFYING MIGRATION")
    print("=" * 70)
    
    verification = {}
    
    for table_name in TABLES:
        try:
            response = supabase.table(table_name).select("count", count="exact").execute()
            count = response.count if hasattr(response, 'count') else 0
            verification[table_name] = {"count": count, "status": "✅"}
            print(f"  ✅ {table_name:25} {count:6} rows")
        except Exception as e:
            verification[table_name] = {"count": 0, "status": "❌", "error": str(e)}
            print(f"  ❌ {table_name:25} Error: {str(e)[:40]}")
    
    return verification

def main():
    print("=" * 70)
    print("MK Restaurants - Supabase Data Import to NEW Project")
    print("=" * 70)
    print(f"\n📦 Importing to: {SUPABASE_URL}")
    print(f"📁 Source directory: {BACKUP_DIR}")
    print(f"⏰ Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Check if backup files exist
    if not BACKUP_DIR.exists():
        print(f"❌ Backup directory not found: {BACKUP_DIR}")
        print("Please run export_data.py first to create backup files.")
        exit(1)
    
    # Test connection to NEW project
    try:
        test_response = supabase.table("branches").select("count", count="exact").execute()
        print("✅ Connected to NEW Supabase project successfully")
        print()
    except Exception as e:
        print(f"❌ Connection to new project failed: {str(e)}")
        print("\n💡 Make sure you have valid credentials in backend/.env.new")
        exit(1)
    
    # Check if backup files exist
    backup_files = list(BACKUP_DIR.glob("*.json"))
    if not backup_files:
        print(f"❌ No backup files found in {BACKUP_DIR}")
        print("Please run export_data.py first.")
        exit(1)
    
    print(f"📁 Found {len(backup_files)} backup files")
    print()
    
    # Import all tables
    import_summary = {
        "import_started": datetime.now().isoformat(),
        "project_url": SUPABASE_URL,
        "tables": {}
    }
    
    for table_name in TABLES:
        result = import_table(table_name)
        import_summary["tables"][table_name] = result
    
    # Save import summary
    summary_file = BACKUP_DIR / "import_summary.json"
    with open(summary_file, "w", encoding="utf-8") as f:
        json.dump(import_summary, f, ensure_ascii=False, indent=2, default=str)
    
    # Verify migration
    verification = verify_migration()
    
    # Print summary
    print()
    print("=" * 70)
    print("📊 IMPORT SUMMARY")
    print("=" * 70)
    
    total_imported = 0
    total_skipped = 0
    
    for table_name, info in import_summary["tables"].items():
        imported = info.get("imported_rows", 0)
        skipped = info.get("skipped_rows", 0)
        total_imported += imported
        total_skipped += skipped
        status = "❌" if info.get("error") else "✅"
        print(f"{status} {table_name:25} +{imported} imported, {skipped} skipped")
    
    print("-" * 70)
    print(f"{'TOTAL':25} +{total_imported} imported, {total_skipped} skipped")
    print("=" * 70)
    print(f"\n⏰ Completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    print("✅ Migration completed!")
    print()
    print("Next steps:")
    print("  1. Review import summary in D:/mk/backup/import_summary.json")
    print("  2. Update agent/config.json with new credentials")
    print("  3. Create backend/.env with new credentials")
    print("  4. Run: python backend/test_supabase.py")
    print("  5. Start agent and verify sync works")

if __name__ == "__main__":
    main()
