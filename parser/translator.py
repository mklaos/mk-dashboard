"""
Product Translation Utility
Loads Thai → Lao/English translations from JSON mapping file
"""

import json
from pathlib import Path
from typing import Dict, Optional

class ProductTranslator:
    """Handles translation of product names from Thai to Lao/English"""
    
    def __init__(self, mapping_file: str = None):
        if mapping_file is None:
            mapping_file = Path(__file__).parent.parent / "data" / "product_translations.json"
        
        self.mapping: Dict[str, Dict[str, str]] = {}
        self._load_mapping(mapping_file)
    
    def _load_mapping(self, filepath: str):
        """Load translation mapping from JSON file"""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                self.mapping = json.load(f)
        except FileNotFoundError:
            print(f"Warning: Translation file not found: {filepath}")
        except json.JSONDecodeError as e:
            print(f"Warning: Error parsing translation file: {e}")
    
    def translate(self, thai_name: str) -> Dict[str, str]:
        """
        Get Lao and English translation for a Thai product name.
        
        Returns:
            Dict with 'lao' and 'en' keys. Falls back to Thai name if not found.
        """
        if thai_name in self.mapping:
            return self.mapping[thai_name]
        
        # Try partial match (sometimes names have slight variations)
        for thai_key, translations in self.mapping.items():
            if thai_key in thai_name or thai_name in thai_key:
                return translations
        
        # Return Thai name as fallback for both
        return {'lao': '', 'en': thai_name}
    
    def get_lao(self, thai_name: str) -> str:
        """Get Lao translation for a Thai product name"""
        return self.translate(thai_name).get('lao', '')
    
    def get_en(self, thai_name: str) -> str:
        """Get English translation for a Thai product name"""
        return self.translate(thai_name).get('en', thai_name)
    
    def add_translation(self, thai_name: str, lao_name: str, en_name: str):
        """Add a new translation to the mapping"""
        self.mapping[thai_name] = {'lao': lao_name, 'en': en_name}
    
    def save(self, filepath: str = None):
        """Save current mapping to JSON file"""
        if filepath is None:
            filepath = Path(__file__).parent.parent / "data" / "product_translations.json"
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(self.mapping, f, ensure_ascii=False, indent=2)


# Global instance for convenience
_translator = None

def get_translator() -> ProductTranslator:
    """Get global translator instance"""
    global _translator
    if _translator is None:
        _translator = ProductTranslator()
    return _translator


def translate_product(thai_name: str) -> Dict[str, str]:
    """Convenience function to translate a product name"""
    return get_translator().translate(thai_name)


def get_lao_name(thai_name: str) -> str:
    """Convenience function to get Lao name"""
    return get_translator().get_lao(thai_name)


def get_en_name(thai_name: str) -> str:
    """Convenience function to get English name"""
    return get_translator().get_en(thai_name)
