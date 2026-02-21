# AGENTS.md - Developer Guidelines for MK Restaurants

This file provides guidelines for AI agents working on this codebase.

---

## 1. Build, Lint, and Test Commands

### Python (Backend, Parser, Agent)

```bash
# Activate virtual environment
cd D:\mk
venv\Scripts\activate

# Run parser test
python parser/parser_complete.py

# Test single module
python -m pytest parser/tests/ -v
python -m pytest parser/tests/test_parser.py::test_function_name -v

# Run with verbose output
python -c "from parser.parser_complete import MKParserComplete; p = MKParserComplete(); print(p.parse_file('source/'))"

# Upload data to Supabase
python backend/upload_data.py

# Run tray agent
python agent/tray_app.py
```

### Flutter (Mobile Dashboard)

```bash
cd D:\mk\mobile

# Get dependencies
flutter pub get

# Run on Chrome/web
flutter run -d chrome

# Run on connected device
flutter run -d <device_id>

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Run tests
flutter test

# Run single test file
flutter test test/widget_test.dart

# Run single test
flutter test test/widget_test.dart --name="test name"

# Analyze/lint
flutter analyze

# Fix lint issues automatically
flutter analyze --fix
```

---

## 2. Code Style Guidelines

### Python

#### Imports
- Standard library first, then third-party, then local
- Use absolute imports from project root
- Group: `stdlib`, `third_party`, `local`

```python
# Correct
import os
import sys
from datetime import datetime
from decimal import Decimal

import pandas as pd
from supabase import create_client

from parser.parser_complete import MKParserComplete
from parser.translator import get_translator
```

#### Formatting
- 4 spaces for indentation (not tabs)
- Line length: 100 characters max
- Use f-strings for string formatting
- Use type hints where helpful

```python
# Correct
def upload_daily_sales(supabase: Client, branch_id: str, data: dict) -> None:
    """Upload daily sales summary."""
    try:
        record = {
            "branch_id": branch_id,
            "sale_date": data["sale_date"],
            "gross_sales": to_float(daily_data.get("gross_sales", 0)),
        }
        supabase.table("daily_sales").insert(record).execute()
    except Exception as e:
        logger.error(f"Upload failed: {e}")
```

#### Naming Conventions
- **Functions/methods**: `snake_case` (e.g., `upload_daily_sales`)
- **Classes**: `PascalCase` (e.g., `MKParserComplete`)
- **Constants**: `UPPER_SNAKE_CASE` (e.g., `SUPABASE_URL`)
- **Private methods**: Prefix with `_` (e.g., `_load_mapping`)

#### Error Handling
- Always wrap database operations in try/except
- Log errors with appropriate level
- Don't expose raw exceptions to users

```python
# Correct
try:
    supabase.table("daily_sales").insert(record).execute()
except Exception as e:
    logger.error(f"Failed to upload daily sales: {e}")
    return None
```

#### Docstrings
- Use Google-style docstrings
- Include Args, Returns, Raises sections for complex functions

```python
def translate(self, thai_name: str) -> Dict[str, str]:
    """Get Lao and English translation for a Thai product name.

    Args:
        thai_name: The Thai product name to translate.

    Returns:
        Dict with 'lao' and 'en' keys containing translations.
    """
```

---

### Flutter/Dart

#### Imports
- Package imports first, then relative imports
- Sort alphabetically within groups

```dart
// Correct
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/dashboard_screen.dart';
import 'services/sales_service.dart';
```

#### Formatting
- 2 spaces for indentation
- Line length: 80 characters max
- Use trailing commas for better formatting

```dart
// Correct
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}
```

#### Naming Conventions
- **Classes**: `PascalCase` (e.g., `DashboardScreen`)
- **Functions/methods**: `camelCase` (e.g., `fetchDailySales`)
- **Private members**: Prefix with `_` (e.g., `_salesData`)
- **Constants**: `kCamelCase` for Flutter constants (e.g., `kPrimaryColor`)

#### Widgets
- Extract reusable widgets to `lib/widgets/` directory
- Keep widgets small and focused
- Use `const` constructors where possible

```dart
// Preferred
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            Text(title),
            Text(value),
          ],
        ),
      ),
    );
  }
}
```

#### State Management
- Use `Provider` for simple state management (as configured in this project)
- Keep business logic in services

---

## 3. Database Guidelines

### Supabase

- Use service role key for admin operations (backend scripts)
- Use anon key for client-side operations (Flutter app)
- Always configure RLS policies for security
- Use UUIDs for primary keys

### Environment Variables

Store in `.env` files (never commit to git):
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=your_anon_key
SUPABASE_SERVICE_KEY=your_service_role_key
```

---

## 4. Translation Guidelines

- Product names in Thai → Lao/English via `data/product_translations.json`
- Upload script automatically translates during data upload
- Add new translations to JSON file when new products appear
- Use Lao script (Unicode) not Romanized text

```python
# Get translation
translator = get_translator()
translation = translator.translate(thai_product_name)
lao_name = translation.get('lao', '')
```

---

## 5. File Structure

```
mk/
├── backend/           # Supabase config & upload scripts
│   ├── db/            # SQL schema
│   └── upload_data.py # Data upload script
├── parser/            # XLS parsing module
│   ├── parser_complete.py
│   ├── translator.py
│   └── models.py
├── agent/             # Windows tray application
├── mobile/            # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   └── pubspec.yaml
├── data/              # Translation mappings
├── docs/              # Documentation
└── source/            # Sample XLS files
```

---

## 6. Testing Approach

### Python
- Use `pytest` for unit tests
- Test parser with sample XLS files in `source/`
- Test database operations against Supabase

### Flutter
- Use `flutter_test` package
- Widget tests for UI components
- Integration tests for API calls

---

## 7. Key Supabase Configuration

- **Project**: mk-sales-dashboard
- **URL**: https://vlrnmbydsmpdijmajamr.supabase.co
- **Anon Key**: sb_publishable_ldqWCnidvesw_18JBJ8JRA_-F4ZH79y
- **Tables**: branches, daily_sales, hourly_sales, product_sales, void_log
