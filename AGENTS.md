# AGENTS.md - Developer Guidelines for MK Restaurants

Guidelines for AI agents working in this codebase.

---

## 1. Build, Lint, and Test Commands

### Python (Backend, Parser)

```bash
# Activate virtual environment
cd D:\mk
venv\Scripts\activate

# Run parser
python parser/parser_complete.py

# Run tests
python -m pytest parser/tests/ -v

# Run single test
python -m pytest parser/tests/test_parser.py::test_function_name -v

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

# Run on device
flutter run -d <device_id>

# Build APK
flutter build apk --debug
flutter build apk --release

# Run tests
flutter test
flutter test test/widget_test.dart                    # single file
flutter test test/widget_test.dart --name="test name"  # single test

# Lint
flutter analyze
flutter analyze --fix
```

---

## 2. Code Style Guidelines

### Python

**Imports**: stdlib → third-party → local, use absolute imports

```python
import os
import pandas as pd
from supabase import Client
from parser.parser_complete import MKParserComplete
```

**Formatting**: 4 spaces, 100 char max line, f-strings, type hints

**Naming**: 
- Functions/methods: `snake_case`
- Classes: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`
- Private methods: `_prefix`

**Error Handling**: Wrap DB operations in try/except, log errors, return None on failure

**Docstrings**: Google-style

---

### Flutter/Dart

**Imports**: package → relative, alphabetical within groups

**Formatting**: 2 spaces, 80 char max, trailing commas

**Naming**:
- Classes: `PascalCase`
- Functions/methods: `camelCase`
- Private members: `_prefix`
- Constants: `kCamelCase`

**Widgets**: Extract to `lib/widgets/`, use `const` constructors

**State**: Use Provider, keep logic in services

---

## 3. Database

- Service role key for backend/admin
- Anon key for client-side (Flutter)
- Configure RLS policies
- Use UUIDs for primary keys

**Env vars** (`.env`, never commit):
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=your_anon_key
SUPABASE_SERVICE_KEY=your_service_role_key
```

---

## 4. Translation

- Thai → Lao/English via `data/product_translations.json`
- Add new translations to JSON when products appear
- Use Lao script (Unicode), not Romanized

---

## 5. File Structure

```
mk/
├── backend/           # Supabase config & upload scripts
├── parser/            # XLS parsing (parser_complete.py, translator.py, models.py)
├── agent/             # Windows tray application
├── mobile/            # Flutter app (lib/screens/, services/, widgets/)
├── data/              # Translation mappings
└── source/            # Sample XLS files
```

---

## 6. Key Supabase Config

- **Project**: mk-sales-dashboard
- **URL**: https://vlrnmbydsmpdijmajamr.supabase.co
- **Tables**: branches, daily_sales, hourly_sales, product_sales, void_log
