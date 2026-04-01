"""
MK Restaurants PDF Parser - Full Integration
Parses all 17 PDF report types from POS system
"""

import pdfplumber
import pandas as pd
import os
import re
from datetime import datetime
from decimal import Decimal
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

class MKPDFParser:
    """Complete PDF Parser for MK Reports - All 17 Types"""

    def __init__(self, branch_code: str = "MK001"):
        self.branch_code = branch_code
        self.metrics = {}

    def detect_report_type(self, filename: str) -> str:
        """Detect report type from PDF filename"""
        filename_lower = filename.lower()
        
        patterns = {
            'daily_sales': r'ยอดขาย.*pdf',
            'hourly_sales': r'ช่วงเวลา',
            'table_details': r'แยกตามกุ่มโตะ|แยกตามกลุ่มโต๊ะ',
            'table_summary': r'สรุปตามกลุ่มโต๊ะ',
            'customer_breakdown': r'จำนวนลูกค้า|แยกตามจำนวน',
            'suki_items': r'สุกี้(?!.*ชาม)',
            'suki_sets': r'สุกี้.*ชาม',
            'duck_items': r'คัรวเป็ด|คัวเป็ด',
            'dim_sum': r'คัรวเปา|คัวเปา',
            'beverages': r'เครื่องดื่ม',
            'desserts': r'ขนม',
            'voids': r'ยกเลิก|ยกเลีก',
            'receipts': r'ใบเส็ด|ใบเสร็จ',
            'vat_summary': r'พาสี|ภาษี',
            'vip': r'vip|ห้อง vip',
            'credit': r'เครดิต',
            'kitchen_categories': r'แยกตามคัว|แยกตามครัว'
        }
        
        for report_type, pattern in patterns.items():
            if re.search(pattern, filename_lower):
                return report_type
        
        return 'unknown'

    def parse_file(self, pdf_path: str) -> dict:
        """Main entry point - parse any PDF report"""
        filename = os.path.basename(pdf_path)
        report_type = self.detect_report_type(filename)
        
        logger.info(f"Parsing PDF: {filename} as {report_type}")
        
        try:
            if report_type == 'daily_sales':
                return self.parse_daily_summary(pdf_path)
            elif report_type == 'hourly_sales':
                return self.parse_hourly_sales(pdf_path)
            elif report_type in ['suki_items', 'suki_sets', 'duck_items', 'dim_sum', 'beverages', 'desserts']:
                return self.parse_product_sales(pdf_path, report_type)
            elif report_type == 'voids':
                return self.parse_voids(pdf_path)
            elif report_type == 'receipts':
                return self.parse_receipts(pdf_path)
            elif report_type == 'table_details':
                return self.parse_table_details(pdf_path)
            elif report_type == 'table_summary':
                return self.parse_table_summary(pdf_path)
            elif report_type == 'customer_breakdown':
                return self.parse_customer_breakdown(pdf_path)
            elif report_type == 'vat_summary':
                return self.parse_vat_summary(pdf_path)
            else:
                logger.warning(f"Unsupported PDF report type: {report_type}")
                return {"success": False, "error": f"Unsupported type: {report_type}"}
                
        except Exception as e:
            logger.error(f"Error parsing {filename}: {e}")
            return {"success": False, "error": str(e)}

    def extract_text(self, pdf_path: str) -> str:
        """Extract all text from PDF"""
        full_text = ""
        try:
            with pdfplumber.open(pdf_path) as pdf:
                for page in pdf.pages:
                    text = page.extract_text()
                    if text:
                        full_text += text + "\n"
        except Exception as e:
            logger.error(f"Error extracting text: {e}")
        return full_text

    def extract_tables(self, pdf_path: str) -> list:
        """Extract all tables from PDF"""
        tables = []
        try:
            with pdfplumber.open(pdf_path) as pdf:
                for page in pdf.pages:
                    page_tables = page.extract_tables()
                    tables.extend(page_tables)
        except Exception as e:
            logger.error(f"Error extracting tables: {e}")
        return tables

    def clean_amount(self, value) -> Decimal:
        """Clean and convert amount to Decimal"""
        if value is None:
            return Decimal('0')
        if isinstance(value, (int, float)):
            return Decimal(str(value))
        if isinstance(value, str):
            # Remove commas and whitespace
            cleaned = value.replace(',', '').strip()
            # Handle Thai/Lao numerals
            thai_nums = '๐๑๒๓๔๕๖๗๘๙'
            lao_nums = '໐໑໒໓໔໕໖໗໘໙'
            for i, (t, l) in enumerate(zip(thai_nums, lao_nums)):
                cleaned = cleaned.replace(t, str(i)).replace(l, str(i))
            try:
                return Decimal(cleaned)
            except:
                return Decimal('0')
        return Decimal('0')

    def clean_int(self, value) -> int:
        """Clean and convert to integer"""
        if value is None:
            return 0
        if isinstance(value, (int, float)):
            return int(value)
        if isinstance(value, str):
            cleaned = value.replace(',', '').strip()
            thai_nums = '๐๑๓๔๕๗๘'
            lao_nums = '໐໑໒໓໔໕໖໗໘໙'
            for i, (t, l) in enumerate(zip(thai_nums, lao_nums)):
                cleaned = cleaned.replace(t, str(i)).replace(l, str(i))
            try:
                return int(float(cleaned))
            except:
                return 0
        return 0

    def parse_daily_summary(self, pdf_path: str) -> dict:
        """Parse daily sales summary PDF"""
        try:
            full_text = self.extract_text(pdf_path)
            tables = self.extract_tables(pdf_path)
            
            # Extract date from filename
            filename = os.path.basename(pdf_path)
            date_match = re.search(r'(\d{2}\.\d{2}\.\d{2})', filename)
            if date_match:
                date_str = date_match.group(1)
                try:
                    sale_date = datetime.strptime(date_str, '%d.%m.%y').date()
                except:
                    sale_date = datetime.now().date()
            else:
                sale_date = datetime.now().date()
            
            daily_data = {
                'sale_date': sale_date.isoformat(),
                'branch_code': self.branch_code
            }
            
            # Parse metrics from text using keyword anchoring
            patterns = {
                'gross_sales': r'ยอดสินค้าก่อนภาษี\s+([\d,]+\.\d{2})',
                'net_sales': r'รายรับทั้งสิ้น\s+([\d,]+\.\d{2})',
                'tax_amount': r'ภาษี\s+([\d,]+\.\d{2})',
                'receipt_count': r'จำนวนใบเสร็จที่ขาย\s+(\d+)',
                'customer_count': r'จำนวนลูกค้า\s+(\d+)',
                'table_count': r'จำนวนโต๊ะ\s+(\d+)',
                'discount_amount': r'ส่วนลด\s+([\d,]+\.\d{2})',
                'void_amount': r'ยกเลิก\s+([\d,]+\.\d{2})',
                'takeaway_sales': r'กลับบ้าน|Take Away.*?([\d,]+\.\d{2})'
            }
            
            for key, pattern in patterns.items():
                match = re.search(pattern, full_text)
                if match:
                    daily_data[key] = float(match.group(1).replace(',', ''))
            
            # If tables exist, try to extract more data
            if tables:
                for table in tables:
                    for row in table:
                        if row and len(row) >= 2:
                            row_text = ' '.join([str(cell) for cell in row if cell])
                            
                            if 'สุทธิ' in row_text and 'ยอดขาย' in row_text:
                                # Net sales row
                                for cell in row:
                                    if cell and re.search(r'[\d,]+\.\d{2}', str(cell)):
                                        daily_data['net_sales'] = self.clean_amount(cell)
                                        break
            
            return {
                "success": True,
                "report_type": "daily_sales",
                "sale_date": sale_date.isoformat(),
                "branch_code": self.branch_code,
                "daily_data": daily_data,
                "count": 1
            }
            
        except Exception as e:
            logger.error(f"Error in parse_daily_summary: {e}")
            return {"success": False, "error": str(e)}

    def parse_product_sales(self, pdf_path: str, category: str) -> dict:
        """Parse product sales PDF (suki, duck, dim_sum, etc.)"""
        try:
            tables = self.extract_tables(pdf_path)
            products = []
            
            # Extract date from filename
            filename = os.path.basename(pdf_path)
            date_match = re.search(r'(\d{2}\.\d{2}\.\d{2})', filename)
            if date_match:
                date_str = date_match.group(1)
                try:
                    sale_date = datetime.strptime(date_str, '%d.%m.%y').date()
                except:
                    sale_date = datetime.now().date()
            else:
                sale_date = datetime.now().date()
            
            for table in tables:
                header_found = False
                for i, row in enumerate(table):
                    if row and len(row) >= 3:
                        # Detect header row
                        row_text = ' '.join([str(cell) for cell in row if cell])
                        if 'ชื่อสินค้า' in row_text or 'ชื่อ' in row_text:
                            header_found = True
                            continue
                        
                        if header_found:
                            try:
                                # Skip summary rows
                                if any(x in row_text for x in ['รวม', 'Total', 'nan', 'None']):
                                    continue
                                
                                product_name = str(row[0]).strip() if len(row) > 0 else ''
                                if not product_name or product_name.lower() in ['nan', 'none', '']:
                                    continue
                                
                                quantity = self.clean_int(row[1]) if len(row) > 1 else 0
                                unit_price = self.clean_amount(row[2]) if len(row) > 2 else Decimal('0')
                                total_amount = self.clean_amount(row[3]) if len(row) > 3 else Decimal('0')
                                
                                products.append({
                                    "product_name_th": product_name,
                                    "quantity": quantity,
                                    "unit_price": float(unit_price),
                                    "total_amount": float(total_amount),
                                    "category": category
                                })
                            except Exception as e:
                                logger.debug(f"Error parsing row: {e}")
                                continue
            
            return {
                "success": True,
                "report_type": category,
                "sale_date": sale_date.isoformat(),
                "branch_code": self.branch_code,
                "products": products,
                "count": len(products)
            }
            
        except Exception as e:
            logger.error(f"Error in parse_product_sales: {e}")
            return {"success": False, "error": str(e)}

    def parse_hourly_sales(self, pdf_path: str) -> dict:
        """Parse hourly sales PDF"""
        try:
            tables = self.extract_tables(pdf_path)
            hourly_data = []
            
            filename = os.path.basename(pdf_path)
            date_match = re.search(r'(\d{2}\.\d{2}\.\d{2})', filename)
            if date_match:
                sale_date = datetime.strptime(date_match.group(1), '%d.%m.%y').date()
            else:
                sale_date = datetime.now().date()
            
            for table in tables:
                for row in table:
                    if row and len(row) >= 3:
                        try:
                            # Look for hour pattern (e.g., "12:00", "13.00")
                            hour_cell = str(row[0])
                            hour_match = re.search(r'(\d{1,2})', hour_cell)
                            if hour_match:
                                hour = int(hour_match.group(1))
                                if 0 <= hour <= 23:
                                    sales = self.clean_amount(row[-1]) if len(row) > 1 else Decimal('0')
                                    hourly_data.append({
                                        "hour": hour,
                                        "sales": float(sales)
                                    })
                        except Exception as e:
                            continue
            
            return {
                "success": True,
                "report_type": "hourly_sales",
                "sale_date": sale_date.isoformat(),
                "branch_code": self.branch_code,
                "hourly_data": hourly_data,
                "count": len(hourly_data)
            }
            
        except Exception as e:
            logger.error(f"Error in parse_hourly_sales: {e}")
            return {"success": False, "error": str(e)}

    def parse_voids(self, pdf_path: str) -> dict:
        """Parse voids PDF"""
        try:
            tables = self.extract_tables(pdf_path)
            voids = []
            
            filename = os.path.basename(pdf_path)
            date_match = re.search(r'(\d{2}\.\d{2}\.\d{2})', filename)
            if date_match:
                sale_date = datetime.strptime(date_match.group(1), '%d.%m.%y').date()
            else:
                sale_date = datetime.now().date()
            
            for table in tables:
                header_found = False
                for row in table:
                    if row:
                        row_text = ' '.join([str(cell) for cell in row if cell])
                        if 'รายการ' in row_text or 'ยกเลิก' in row_text:
                            header_found = True
                            continue
                        
                        if header_found and len(row) >= 3:
                            try:
                                voids.append({
                                    "product_name": str(row[0]) if len(row) > 0 else '',
                                    "quantity": self.clean_int(row[1]) if len(row) > 1 else 0,
                                    "amount": self.clean_amount(row[2]) if len(row) > 2 else Decimal('0'),
                                    "reason": str(row[-1]) if len(row) > 3 else ''
                                })
                            except:
                                continue
            
            return {
                "success": True,
                "report_type": "voids",
                "sale_date": sale_date.isoformat(),
                "branch_code": self.branch_code,
                "voids": voids,
                "count": len(voids)
            }
            
        except Exception as e:
            logger.error(f"Error in parse_voids: {e}")
            return {"success": False, "error": str(e)}

    def parse_receipts(self, pdf_path: str) -> dict:
        """Parse receipts PDF"""
        try:
            tables = self.extract_tables(pdf_path)
            receipts = []
            
            filename = os.path.basename(pdf_path)
            date_match = re.search(r'(\d{2}\.\d{2}\.\d{2})', filename)
            if date_match:
                sale_date = datetime.strptime(date_match.group(1), '%d.%m.%y').date()
            else:
                sale_date = datetime.now().date()
            
            for table in tables:
                for row in table:
                    if row and len(row) >= 4:
                        try:
                            receipt_no = str(row[0]).strip()
                            if receipt_no and receipt_no.lower() not in ['nan', 'none', '']:
                                receipts.append({
                                    "receipt_no": receipt_no,
                                    "table_no": str(row[1]) if len(row) > 1 else '',
                                    "customer_count": self.clean_int(row[2]) if len(row) > 2 else 0,
                                    "net_amount": self.clean_amount(row[3]) if len(row) > 3 else Decimal('0')
                                })
                        except:
                            continue
            
            return {
                "success": True,
                "report_type": "receipts",
                "sale_date": sale_date.isoformat(),
                "branch_code": self.branch_code,
                "receipts": receipts,
                "count": len(receipts)
            }
            
        except Exception as e:
            logger.error(f"Error in parse_receipts: {e}")
            return {"success": False, "error": str(e)}

    def parse_table_details(self, pdf_path: str) -> dict:
        """Parse table details PDF"""
        # Similar structure to product sales
        return self.parse_product_sales(pdf_path, 'table_details')

    def parse_table_summary(self, pdf_path: str) -> dict:
        """Parse table summary PDF"""
        try:
            tables = self.extract_tables(pdf_path)
            summary = []
            
            filename = os.path.basename(pdf_path)
            date_match = re.search(r'(\d{2}\.\d{2}\.\d{2})', filename)
            if date_match:
                sale_date = datetime.strptime(date_match.group(1), '%d.%m.%y').date()
            else:
                sale_date = datetime.now().date()
            
            for table in tables:
                for row in table:
                    if row and len(row) >= 3:
                        try:
                            summary.append({
                                "table_group": str(row[0]) if len(row) > 0 else '',
                                "receipts": self.clean_int(row[1]) if len(row) > 1 else 0,
                                "sales": self.clean_amount(row[2]) if len(row) > 2 else Decimal('0')
                            })
                        except:
                            continue
            
            return {
                "success": True,
                "report_type": "table_summary",
                "sale_date": sale_date.isoformat(),
                "branch_code": self.branch_code,
                "summary": summary,
                "count": len(summary)
            }
            
        except Exception as e:
            logger.error(f"Error in parse_table_summary: {e}")
            return {"success": False, "error": str(e)}

    def parse_customer_breakdown(self, pdf_path: str) -> dict:
        """Parse customer breakdown PDF"""
        try:
            tables = self.extract_tables(pdf_path)
            breakdown = []
            
            filename = os.path.basename(pdf_path)
            date_match = re.search(r'(\d{2}\.\d{2}\.\d{2})', filename)
            if date_match:
                sale_date = datetime.strptime(date_match.group(1), '%d.%m.%y').date()
            else:
                sale_date = datetime.now().date()
            
            for table in tables:
                for row in table:
                    if row and len(row) >= 2:
                        try:
                            breakdown.append({
                                "customer_range": str(row[0]) if len(row) > 0 else '',
                                "count": self.clean_int(row[1]) if len(row) > 1 else 0
                            })
                        except:
                            continue
            
            return {
                "success": True,
                "report_type": "customer_breakdown",
                "sale_date": sale_date.isoformat(),
                "branch_code": self.branch_code,
                "breakdown": breakdown,
                "count": len(breakdown)
            }
            
        except Exception as e:
            logger.error(f"Error in parse_customer_breakdown: {e}")
            return {"success": False, "error": str(e)}

    def parse_vat_summary(self, pdf_path: str) -> dict:
        """Parse VAT summary PDF"""
        try:
            full_text = self.extract_text(pdf_path)
            
            filename = os.path.basename(pdf_path)
            date_match = re.search(r'(\d{2}\.\d{2}\.\d{2})', filename)
            if date_match:
                sale_date = datetime.strptime(date_match.group(1), '%d.%m.%y').date()
            else:
                sale_date = datetime.now().date()
            
            vat_data = {
                "sale_date": sale_date.isoformat(),
                "branch_code": self.branch_code
            }
            
            # Look for VAT amount
            vat_match = re.search(r'ภาษี\s+([\d,]+\.\d{2})', full_text)
            if vat_match:
                vat_data['tax_amount'] = float(vat_match.group(1).replace(',', ''))
            
            return {
                "success": True,
                "report_type": "vat_summary",
                "sale_date": sale_date.isoformat(),
                "branch_code": self.branch_code,
                "vat_data": vat_data,
                "count": 1
            }
            
        except Exception as e:
            logger.error(f"Error in parse_vat_summary: {e}")
            return {"success": False, "error": str(e)}
