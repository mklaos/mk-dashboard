"""
Data models for parsed POS records
"""

from dataclasses import dataclass, field
from datetime import date, time
from decimal import Decimal
from typing import Optional, List
from enum import Enum


class ReportType(Enum):
    DAILY_SALES = "daily_sales"
    HOURLY_SALES = "hourly_sales"
    TABLE_DETAILS = "table_details"
    TABLE_SUMMARY = "table_summary"
    CUSTOMER_BREAKDOWN = "customer_breakdown"
    KITCHEN_CATEGORIES = "kitchen_categories"
    RECEIPTS = "receipts"
    SUKI_ITEMS = "suki_items"
    SUKI_SETS = "suki_sets"
    DUCK_ITEMS = "duck_items"
    DIM_SUM = "dim_sum"
    BEVERAGES = "beverages"
    DESSERTS = "desserts"
    VOIDS = "voids"
    VIP = "vip"
    CREDIT = "credit"
    VAT_SUMMARY = "vat_summary"
    UNKNOWN = "unknown"


@dataclass
class DailySales:
    branch_code: str
    sale_date: date
    gross_sales: Decimal = Decimal("0")
    net_sales: Decimal = Decimal("0")
    tax_amount: Decimal = Decimal("0")
    discount_amount: Decimal = Decimal("0")
    rounding_amount: Decimal = Decimal("0")
    receipt_count: int = 0
    customer_count: int = 0
    table_count: int = 0
    void_count: int = 0
    void_amount: Decimal = Decimal("0")
    takeaway_receipts: int = 0
    takeaway_sales: Decimal = Decimal("0")
    receipt_start: str = ""
    receipt_end: str = ""


@dataclass
class HourlySales:
    branch_code: str
    sale_date: date
    hour: int
    table_count: int = 0
    customer_count: int = 0
    sales: Decimal = Decimal("0")


@dataclass
class ProductSale:
    branch_code: str
    sale_date: date
    product_name_th: str
    product_name_lao: str = ""
    product_name_en: str = ""
    category: str = ""
    quantity: int = 0
    unit_price: Decimal = Decimal("0")
    total_amount: Decimal = Decimal("0")


@dataclass
class Transaction:
    branch_code: str
    sale_date: date
    receipt_no: str
    table_no: str = ""
    time_in: Optional[time] = None
    time_out: Optional[time] = None
    customer_count: int = 0
    gross_amount: Decimal = Decimal("0")
    discount_amount: Decimal = Decimal("0")
    net_amount: Decimal = Decimal("0")
    tax_amount: Decimal = Decimal("0")
    rounding_amount: Decimal = Decimal("0")
    discount_card: str = ""
    payment_method: str = "cash"
    receipt_type: str = "dine_in"


@dataclass
class VoidRecord:
    branch_code: str
    sale_date: date
    original_receipt_no: str
    table_no: str = ""
    time_voided: Optional[time] = None
    product_name_th: str = ""
    quantity: int = 0
    unit_price: Decimal = Decimal("0")
    amount: Decimal = Decimal("0")
    reason_th: str = ""
    approved_by: str = ""
    recorded_by: str = ""


@dataclass
class TableSummary:
    branch_code: str
    sale_date: date
    table_type: str
    receipt_count: int = 0
    customer_count: int = 0
    gross_sales: Decimal = Decimal("0")
    discount_amount: Decimal = Decimal("0")
    net_sales: Decimal = Decimal("0")
    tax_amount: Decimal = Decimal("0")


@dataclass
class CustomerBreakdown:
    branch_code: str
    sale_date: date
    customer_group: str
    table_count: int = 0
    customer_count: int = 0
    total_sales: Decimal = Decimal("0")
    sales_percentage: Decimal = Decimal("0")
    avg_per_customer: Decimal = Decimal("0")


@dataclass
class VATSummary:
    branch_code: str
    sale_date: date
    gross_sales: Decimal = Decimal("0")
    net_sales: Decimal = Decimal("0")
    tax_amount: Decimal = Decimal("0")
    receipt_start: str = ""
    receipt_end: str = ""


@dataclass
class ParseResult:
    report_type: ReportType
    file_name: str
    sale_date: Optional[date] = None
    branch_code: str = ""
    success: bool = True
    error_message: str = ""
    records: List = field(default_factory=list)
    raw_row_count: int = 0
    parsed_row_count: int = 0
