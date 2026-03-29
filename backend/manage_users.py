"""
Supabase User Management Script
Allows managing roles, allowed brands, and passwords for app users.
Requires SUPABASE_SERVICE_KEY in backend/.env
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
from supabase import create_client, Client

# Load environment
env_path = Path(__file__).parent / ".env"
load_dotenv(dotenv_path=env_path)

SUPABASE_URL = os.getenv("SUPABASE_URL")
SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

VALID_ROLES = ["president", "shareholder", "brand_manager", "branch_manager", "viewer"]

def get_client() -> Client:
    if not SUPABASE_URL or not SERVICE_KEY:
        print("❌ Error: SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in backend/.env")
        sys.exit(1)
    return create_client(SUPABASE_URL, SERVICE_KEY)

def list_users(supabase: Client):
    print("\n--- Current App Users ---")
    try:
        response = supabase.table("app_users").select("id, name, email, role, allowed_brands, allowed_branches").execute()
        if not response.data:
            print("No users found.")
            return
        
        for i, user in enumerate(response.data):
            brands = ", ".join(user.get("allowed_brands") or [])
            print(f"{i+1}. {user['name']} ({user['email']})")
            print(f"   Role: {user['role']} | Brands: {brands if brands else 'All (President) or Specific'}")
    except Exception as e:
        print(f"Error listing users: {e}")

def list_brands(supabase: Client):
    try:
        response = supabase.table("brands").select("id, name").execute()
        return response.data or []
    except Exception as e:
        print(f"Error listing brands: {e}")
        return []

def list_branches(supabase: Client):
    try:
        response = supabase.table("branches").select("id, code, name").execute()
        return response.data or []
    except Exception as e:
        print(f"Error listing branches: {e}")
        return []

def create_user(supabase: Client):
    print("\n--- Create New User ---")
    email = input("Email: ").strip()
    password = input("Password (min 6 chars): ").strip()
    name = input("Display Name: ").strip()
    
    print(f"\nAvailable Roles: {', '.join(VALID_ROLES)}")
    role = input("Role: ").strip()
    
    if role not in VALID_ROLES:
        print("Invalid role. Defaulting to viewer.")
        role = "viewer"

    try:
        auth_res = supabase.auth.admin.create_user({
            "email": email,
            "password": password,
            "email_confirm": True
        })
        auth_id = auth_res.user.id
        supabase.table("app_users").update({"name": name, "role": role, "auth_id": auth_id}).eq("email", email).execute()
        print(f"✅ Successfully created user {email} with role {role}")
    except Exception as e:
        print(f"Error creating user: {e}")

def update_user_role(supabase: Client):
    email = input("\nEnter user email to update: ").strip()
    print(f"\nAvailable Roles: {', '.join(VALID_ROLES)}")
    new_role = input("Enter new role: ").strip()
    if new_role not in VALID_ROLES:
        print("Invalid role.")
        return
    try:
        supabase.table("app_users").update({"role": new_role}).eq("email", email).execute()
        print(f"✅ Successfully updated {email} to {new_role}")
    except Exception as e:
        print(f"Error updating user: {e}")

def update_allowed_brands(supabase: Client):
    email = input("\nEnter user email to update brands: ").strip()
    brands = list_brands(supabase)
    print("\nAvailable Brands:")
    for b in brands: print(f" - {b['id']}: {b['name']}")
    brand_ids_str = input("\nEnter Brand UUIDs (comma separated): ").strip()
    brand_ids = [b.strip() for b in brand_ids_str.split(",") if b.strip()]
    try:
        supabase.table("app_users").update({"allowed_brands": brand_ids}).eq("email", email).execute()
        print(f"✅ Successfully updated allowed brands for {email}")
    except Exception as e:
        print(f"Error updating brands: {e}")

def update_allowed_branches(supabase: Client):
    email = input("\nEnter user email to update branches: ").strip()
    branches = list_branches(supabase)
    print("\nAvailable Branches:")
    for b in branches: print(f" - {b['id']}: {b['code']} ({b['name']})")
    branch_ids_str = input("\nEnter Branch UUIDs (comma separated): ").strip()
    branch_ids = [b.strip() for b in branch_ids_str.split(",") if b.strip()]
    try:
        supabase.table("app_users").update({"allowed_branches": branch_ids}).eq("email", email).execute()
        print(f"✅ Successfully updated allowed branches for {email}")
    except Exception as e:
        print(f"Error updating branches: {e}")

def reset_password(supabase: Client):
    email = input("\nEnter user email to reset password: ").strip()
    new_password = input("Enter new password: ").strip()
    if len(new_password) < 6:
        print("Password must be at least 6 characters.")
        return
    try:
        user_data = supabase.table("app_users").select("auth_id").eq("email", email).single().execute()
        if not user_data.data:
            print("User not found.")
            return
        supabase.auth.admin.update_user_by_id(user_data.data["auth_id"], attributes={'password': new_password})
        print(f"✅ Successfully reset password for {email}")
    except Exception as e:
        print(f"Error resetting password: {e}")

def main():
    supabase = get_client()
    while True:
        print("\n" + "="*40)
        print(" MK SALES - USER MANAGEMENT ADMIN ")
        print("="*40)
        print("1. List Users")
        print("2. Create New User")
        print("3. Update User Role")
        print("4. Update Allowed Brands (Shareholders/Brand Mgrs)")
        print("5. Update Allowed Branches (Branch Mgrs)")
        print("6. Reset User Password")
        print("7. Exit")
        choice = input("\nSelect an option: ").strip()
        if choice == "1": list_users(supabase)
        elif choice == "2": create_user(supabase)
        elif choice == "3": update_user_role(supabase)
        elif choice == "4": update_allowed_brands(supabase)
        elif choice == "5": update_allowed_branches(supabase)
        elif choice == "6": reset_password(supabase)
        elif choice == "7": break
        else: print("Invalid choice.")

if __name__ == "__main__":
    main()
