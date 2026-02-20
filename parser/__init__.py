"""
MK Restaurants XLS Parser Module
Parses POS report files and returns structured data
"""

from .models import (
    ReportType,
    DailySales,
    HourlySales,
    ProductSale,
    Transaction,
    VoidRecord,
    TableSummary,
    CustomerBreakdown,
    VATSummary,
    ParseResult
)

from .parser import MKParser, parse_file, parse_directory

__version__ = "1.0.0"
__all__ = [
    "MKParser",
    "parse_file",
    "parse_directory",
    "ReportType",
    "DailySales",
    "HourlySales", 
    "ProductSale",
    "Transaction",
    "VoidRecord",
    "TableSummary",
    "CustomerBreakdown",
    "VATSummary",
    "ParseResult"
]
