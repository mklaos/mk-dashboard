"""
Setup Utility for MK Agent
Encrypts Supabase credentials and saves to credentials.enc
"""

import sys
import os
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from security_utils import save_secure_credentials, load_secure_credentials
from dotenv import load_dotenv

def setup_credentials_from_env():
    """Read credentials from backend/.env and save encrypted"""
    
    # Path to backend .env file
    backend_env = Path(__file__).parent.parent / "backend" / ".env"
    
    print("=" * 60)
    print("MK Agent - Credential Setup Utility")
    print("=" * 60)
    print()
    
    # Check if backend .env exists
    if not backend_env.exists():
        print(f"ERROR: Backend .env not found at: {backend_env}")
        print("Please ensure the file exists.")
        return False
    
    # Load credentials from .env
    print(f"Reading credentials from: {backend_env}")
    load_dotenv(backend_env)
    
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_KEY")
    
    if not supabase_url or not supabase_key:
        print("ERROR: Could not find SUPABASE_URL or SUPABASE_KEY in .env file")
        return False
    
    print(f"✓ Found SUPABASE_URL: {supabase_url[:20]}...")
    print(f"✓ Found SUPABASE_KEY: {supabase_key[:15]}...")
    print()
    
    # Determine where to save credentials
    # For frozen apps, save to dist folder; otherwise save to agent folder
    if getattr(sys, 'frozen', False):
        # Running as compiled executable
        target_dir = Path(sys.executable).parent
    else:
        # Running as script
        target_dir = Path(__file__).parent
    
    creds_file = target_dir / "credentials.enc"
    
    print(f"Saving encrypted credentials to: {creds_file}")
    
    # Save encrypted credentials
    save_secure_credentials(supabase_url, supabase_key)
    
    # Verify by loading back
    loaded_url, loaded_key = load_secure_credentials()
    
    if loaded_url == supabase_url and loaded_key == supabase_key:
        print()
        print("=" * 60)
        print("✓ SUCCESS! Credentials encrypted and saved.")
        print("=" * 60)
        print()
        print(f"Credentials file: {creds_file}")
        print()
        print("IMPORTANT:")
        print("  - The credentials.enc file contains encrypted data")
        print("  - It can only be decrypted on THIS computer")
        print("  - Do NOT share this file with others")
        print()
        return True
    else:
        print()
        print("ERROR: Verification failed! Credentials may not be saved correctly.")
        return False


def show_current_credentials():
    """Display currently stored credentials (for verification)"""
    print("=" * 60)
    print("Current Stored Credentials")
    print("=" * 60)
    print()
    
    url, key = load_secure_credentials()
    
    if url and key:
        print(f"SUPABASE_URL: {url}")
        print(f"SUPABASE_KEY: {key[:15]}... (hidden)")
        print()
        print("✓ Credentials found and can be decrypted")
    else:
        print("✗ No credentials found or decryption failed")
        print()
        print("Run this script again to set up credentials.")
    
    print()


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="MK Agent Credential Setup")
    parser.add_argument("--show", action="store_true", help="Show current credentials")
    parser.add_argument("--setup", action="store_true", help="Setup credentials from backend/.env")
    
    args = parser.parse_args()
    
    if args.show:
        show_current_credentials()
    elif args.setup:
        setup_credentials_from_env()
    else:
        # Default: setup credentials
        success = setup_credentials_from_env()
        if success:
            show_current_credentials()
