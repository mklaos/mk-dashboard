"""
Uploader module for MK Agent
Handles data transfer to Supabase with proper error handling and logging.
"""

import logging
from decimal import Decimal
from supabase import create_client, Client

logger = logging.getLogger(__name__)

def to_float(value):
    """Convert Decimal to float for JSON compatibility."""
    if isinstance(value, Decimal):
        return float(value)
    return value

class MKUploader:
    def __init__(self, url: str, key: str):
        self.url = url
        self.key = key
        self.client: Client = None
        if url and key:
            try:
                self.client = create_client(url, key)
            except Exception as e:
                logger.error(f"Failed to initialize Supabase client: {e}")

    def get_branch_id(self, branch_code: str) -> str:
        if not self.client: return None
        try:
            response = self.client.table("branches").select("id").eq("code", branch_code).execute()
            if response.data:
                return response.data[0]["id"]
            return None
        except Exception as e:
            logger.error(f"Error getting branch ID: {e}")
            return None

    def upload_result(self, branch_id: str, result: dict) -> bool:
        if not self.client or not branch_id:
            return False
            
        report_type = result.get("report_type", "")
        sale_date = result.get("sale_date")
        
        try:
            if report_type == "daily_sales":
                return self._upload_daily(branch_id, sale_date, result.get("daily_data", {}))
            elif report_type == "hourly_sales":
                return self._upload_hourly(branch_id, sale_date, result.get("hourly_data", []))
            elif report_type in ["suki_items", "suki_sets", "duck_items", "dim_sum", "beverages", "desserts"]:
                return self._upload_products(branch_id, sale_date, result.get("products", []))
            elif report_type == "voids":
                return self._upload_voids(branch_id, sale_date, result.get("voids", []))
            else:
                logger.info(f"Skipping upload for report type: {report_type}")
                return True # Consider successful if we just chose to skip
        except Exception as e:
            logger.error(f"Upload error for {report_type}: {e}")
            return False

    def _upload_daily(self, branch_id, sale_date, data):
        record = {
            "branch_id": branch_id,
            "sale_date": sale_date,
            "gross_sales": to_float(data.get("gross_sales", 0)),
            "net_sales": to_float(data.get("net_sales", 0)),
            "tax_amount": to_float(data.get("tax_amount", 0)),
            "receipt_count": int(data.get("receipt_count", 0)),
            "customer_count": int(data.get("customer_count", 0)),
            "table_count": int(data.get("table_count", 0)),
            "void_count": int(data.get("void_count", 0)),
            "void_amount": to_float(data.get("void_amount", 0)),
        }
        self.client.table("daily_sales").upsert(record).execute()
        return True

    def _upload_hourly(self, branch_id, sale_date, data_list):
        records = []
        for row in data_list:
            records.append({
                "branch_id": branch_id,
                "sale_date": sale_date,
                "hour": int(row["hour"]),
                "table_count": int(row.get("table_count", 0)),
                "customer_count": int(row.get("customer_count", 0)),
                "sales": to_float(row.get("sales", 0)),
            })
        if records:
            self.client.table("hourly_sales").upsert(records).execute()
        return True

    def _upload_products(self, branch_id, sale_date, products):
        records = []
        for p in products:
            record = {
                "branch_id": branch_id,
                "sale_date": sale_date,
                "product_name_th": p.get("product_name_th", ""),
                "category_name": p.get("category", ""),
                "quantity": int(p.get("quantity", 0)),
                "unit_price": to_float(p.get("unit_price", 0)),
                "total_amount": to_float(p.get("total_amount", 0)),
            }
            # Add Lao name if available
            if "product_name_lao" in p and p["product_name_lao"]:
                record["product_name_lao"] = p["product_name_lao"]
            records.append(record)
        if records:
            # Note: Using upsert requires a unique constraint in DB (branch_id, sale_date, product_name_th)
            self.client.table("product_sales").upsert(records).execute()
        return True

    def _upload_voids(self, branch_id, sale_date, voids):
        records = []
        for v in voids:
            records.append({
                "branch_id": branch_id,
                "sale_date": sale_date,
                "original_receipt_no": v.get("receipt_no", ""),
                "table_no": v.get("table_no", ""),
                "product_name_th": v.get("product_name", ""),
                "quantity": int(v.get("quantity", 0)),
                "amount": abs(to_float(v.get("amount", 0))),
                "reason_text": v.get("reason", ""),
            })
        if records:
            self.client.table("void_log").insert(records).execute()
        return True
