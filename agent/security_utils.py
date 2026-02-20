import base64
import os
import sys
import uuid
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from pathlib import Path

def get_machine_id():
    """Generates a unique ID for the current machine to use as an encryption salt."""
    try:
        # Use the MAC address as a unique machine identifier
        node = uuid.getnode()
        return str(node).encode()
    except Exception:
        return b"MK_RESTAURANTS_LAOS_SALT"

def get_cipher():
    """Derives a encryption key from the machine ID."""
    salt = get_machine_id()
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=100000,
    )
    key = base64.urlsafe_b64encode(kdf.derive(b"MK_SECRET_KEY_v1"))
    return Fernet(key)

def encrypt_data(data: str) -> str:
    if not data: return ""
    cipher = get_cipher()
    return cipher.encrypt(data.encode()).decode()

def decrypt_data(encrypted_data: str) -> str:
    if not encrypted_data: return ""
    try:
        cipher = get_cipher()
        return cipher.decrypt(encrypted_data.encode()).decode()
    except Exception:
        return ""

def save_secure_credentials(url: str, key: str):
    """Saves encrypted credentials to a recognizable but encrypted file."""
    # Use the same directory as the executable (for frozen apps) or script
    if getattr(sys, 'frozen', False):
        creds_path = Path(sys.executable).parent / "credentials.enc"
    else:
        creds_path = Path(__file__).parent / "credentials.enc"
    
    encrypted_url = encrypt_data(url)
    encrypted_key = encrypt_data(key)

    with open(creds_path, "w") as f:
        f.write(f"{encrypted_url}\n{encrypted_key}")

def load_secure_credentials():
    """Loads and decrypts credentials."""
    # Use the same directory as the executable (for frozen apps) or script
    if getattr(sys, 'frozen', False):
        creds_path = Path(sys.executable).parent / "credentials.enc"
    else:
        creds_path = Path(__file__).parent / "credentials.enc"
    
    if not creds_path.exists():
        return "", ""

    try:
        with open(creds_path, "r") as f:
            lines = f.readlines()
            if len(lines) >= 2:
                url = decrypt_data(lines[0].strip())
                key = decrypt_data(lines[1].strip())
                return url, key
    except Exception:
        pass
    return "", ""
