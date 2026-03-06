import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/branch.dart';

class SalesService {
  final _supabase = Supabase.instance.client;

  /// Get all available branches from the database
  Future<List<Branch>> getAvailableBranches() async {
    final response = await _supabase
        .from('branches')
        .select('*')
        .eq('is_active', true)
        .order('code', ascending: true);

    return response.map<Branch>((json) => Branch.fromJson(json)).toList();
  }

  Future<List<String>> getAvailableDates() async {
    final response = await _supabase
        .from('daily_sales')
        .select('sale_date')
        .order('sale_date', ascending: false);

    return response.map<String>((row) => row['sale_date'] as String).toList();
  }

  Future<Map<String, dynamic>?> getDailySales() async {
    final response = await _supabase
        .from('daily_sales')
        .select('''
          *,
          branches!inner(code, name, name_lao)
        ''')
        .order('sale_date', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  }

  Future<Map<String, dynamic>?> getSalesByDate(
    String date, {
    String? branchCode,
  }) async {
    // If ALL, don't filter by branch
    if (branchCode == null || branchCode == 'ALL') {
      final response = await _supabase
          .from('daily_sales')
          .select('''
            *,
            branches!inner(code, name, name_lao, name_en)
          ''')
          .eq('sale_date', date)
          .maybeSingle();
      return response;
    }

    // For specific branch, first get the branch ID
    final branchResponse = await _supabase
        .from('branches')
        .select('id')
        .eq('code', branchCode)
        .maybeSingle();

    if (branchResponse == null) {
      return null;
    }

    final branchId = branchResponse['id'];

    // Then query daily_sales with the branch_id
    final response = await _supabase
        .from('daily_sales')
        .select('''
          *,
          branches!inner(code, name, name_lao, name_en)
        ''')
        .eq('sale_date', date)
        .eq('branch_id', branchId)
        .maybeSingle();

    return response;
  }

  Future<List<dynamic>> getHourlySales() async {
    final dailySales = await getDailySales();
    if (dailySales == null) return [];

    final saleDate = dailySales['sale_date'];

    final response = await _supabase
        .from('hourly_sales')
        .select('*')
        .eq('sale_date', saleDate)
        .order('hour', ascending: true);

    return response;
  }

  Future<List<dynamic>> getHourlySalesByDate(
    String date, {
    String? branchCode,
  }) async {
    // If ALL, use the aggregated view
    if (branchCode == null || branchCode == 'ALL') {
      final response = await _supabase
          .from('v_peak_hours')
          .select('hour, total_sales, total_customers, total_tables')
          .eq('sale_date', date)
          .order('hour', ascending: true);
      
      // Map total_sales to sales for compatibility
      return response.map((e) => {
        ...e,
        'sales': e['total_sales'],
      }).toList();
    }

    // For specific branch, query hourly_sales table
    var query = _supabase
        .from('hourly_sales')
        .select('*')
        .eq('sale_date', date);

    // Filter by branch
    final branchResponse = await _supabase
        .from('branches')
        .select('id')
        .eq('code', branchCode)
        .maybeSingle();

    if (branchResponse != null) {
      query = query.eq('branch_id', branchResponse['id']);
    } else {
      return []; // Branch not found
    }

    final response = await query.order('hour', ascending: true);
    return response;
  }

  Future<List<dynamic>> getTopProducts({int limit = 10}) async {
    final dailySales = await getDailySales();
    if (dailySales == null) return [];

    final saleDate = dailySales['sale_date'];

    final response = await _supabase
        .from('product_sales')
        .select('*')
        .eq('sale_date', saleDate)
        .order('total_amount', ascending: false)
        .limit(limit);

    return response;
  }

  Future<List<dynamic>> getTopProductsByDate(
    String date, {
    int limit = 10,
    String? branchCode,
  }) async {
    // If ALL, use the aggregated view
    if (branchCode == null || branchCode == 'ALL') {
      final response = await _supabase
          .from('v_product_performance')
          .select('*')
          .eq('sale_date', date)
          .order('total_sales', ascending: false)
          .limit(limit);
      
      // Map total_sales back to total_amount for UI compatibility
      return response.map((e) => {
        ...e,
        'total_amount': e['total_sales'],
        'quantity': e['total_qty'],
      }).toList();
    }

    // For specific branch, query product_sales table
    var query = _supabase
        .from('product_sales')
        .select('*')
        .eq('sale_date', date);

    // Filter by branch
    final branchResponse = await _supabase
        .from('branches')
        .select('id')
        .eq('code', branchCode)
        .maybeSingle();

    if (branchResponse != null) {
      query = query.eq('branch_id', branchResponse['id']);
    } else {
      return []; // Branch not found
    }

    final response = await query
        .order('total_amount', ascending: false)
        .limit(limit);

    return response;
  }

  Future<List<dynamic>> getBranchPerformance() async {
    final response = await _supabase
        .from('v_branch_performance')
        .select('*')
        .order('sale_date', ascending: false)
        .limit(10);

    return response;
  }

  Future<List<dynamic>> getVoids() async {
    final response = await _supabase
        .from('void_log')
        .select('*')
        .order('sale_date', ascending: false)
        .limit(20);

    return response;
  }

  /// Get consolidated totals across all branches for a specific date
  Future<Map<String, dynamic>?> getAllBranchesTotals(String date) async {
    // We query daily_sales directly and sum the values for the given date
    // to ensure it works for historical dates and uses matching keys.
    final response = await _supabase
        .from('daily_sales')
        .select('net_sales, receipt_count, customer_count, void_amount')
        .eq('sale_date', date);

    if (response == null || (response as List).isEmpty) {
      return null;
    }

    final List<dynamic> records = response as List;
    double netSales = 0;
    int receipts = 0;
    int customers = 0;
    double voids = 0;

    for (var record in records) {
      netSales += (record['net_sales'] as num?)?.toDouble() ?? 0;
      receipts += (record['receipt_count'] as num?)?.toInt() ?? 0;
      customers += (record['customer_count'] as num?)?.toInt() ?? 0;
      voids += (record['void_amount'] as num?)?.toDouble() ?? 0;
    }

    return {
      'sale_date': date,
      'net_sales': netSales,
      'receipt_count': receipts,
      'customer_count': customers,
      'void_amount': voids,
    };
  }

  /// Get side-by-side comparison of all branches for a specific date
  /// Uses the v_branch_performance view
  Future<List<dynamic>> getBranchComparison(String date) async {
    final response = await _supabase
        .from('v_branch_performance')
        .select('*')
        .eq('sale_date', date)
        .order('branch_code', ascending: true);

    return response;
  }

  /// Get historical data for comparison (previous 7 days average)
  /// Returns average of previous week for growth indicator calculation
  Future<Map<String, dynamic>?> getPreviousWeekAverage(
    String currentDate, {
    String? branchCode,
  }) async {
    try {
      final current = DateTime.parse(currentDate);
      // Calculate previous week (7 days before the current date)
      final previousWeekStart = current.subtract(const Duration(days: 7));
      final previousWeekEnd = current.subtract(const Duration(days: 1));

      final startDate =
          '${previousWeekStart.year}-${previousWeekStart.month.toString().padLeft(2, '0')}-${previousWeekStart.day.toString().padLeft(2, '0')}';
      final endDate =
          '${previousWeekEnd.year}-${previousWeekEnd.month.toString().padLeft(2, '0')}-${previousWeekEnd.day.toString().padLeft(2, '0')}';

      var query = _supabase
          .from('daily_sales')
          .select('sale_date, net_sales, receipt_count, customer_count, void_amount')
          .gte('sale_date', startDate)
          .lte('sale_date', endDate);

      // Filter by branch if specified
      if (branchCode != null && branchCode != 'ALL') {
        final branchResponse = await _supabase
            .from('branches')
            .select('id')
            .eq('code', branchCode)
            .maybeSingle();

        if (branchResponse != null) {
          query = query.eq('branch_id', branchResponse['id']);
        } else {
          return null;
        }
      }

      final response = await query;

      if (response == null || (response as List).isEmpty) {
        // No data for previous week, return zeros
        return {
          'net_sales': 0.0,
          'receipt_count': 0,
          'customer_count': 0,
          'void_amount': 0.0,
          'days_with_data': 0,
        };
      }

      // Calculate averages
      double totalSales = 0;
      int totalReceipts = 0;
      int totalCustomers = 0;
      double totalVoids = 0;
      int daysWithData = 0;

      for (var record in response) {
        totalSales += (record['net_sales'] as num?)?.toDouble() ?? 0;
        totalReceipts += (record['receipt_count'] as num?)?.toInt() ?? 0;
        totalCustomers += (record['customer_count'] as num?)?.toInt() ?? 0;
        totalVoids += (record['void_amount'] as num?)?.toDouble() ?? 0;
        daysWithData++;
      }

      // Calculate daily average
      final avgDays = daysWithData > 0 ? daysWithData.toDouble() : 1;

      return {
        'net_sales': totalSales / avgDays,
        'receipt_count': (totalReceipts / avgDays).round(),
        'customer_count': (totalCustomers / avgDays).round(),
        'void_amount': totalVoids / avgDays,
        'days_with_data': daysWithData,
      };
    } catch (e) {
      print('Error getting previous week average: $e');
      return null;
    }
  }

  /// Get sales mix by category (Food vs Beverage vs Other)
  /// Categories are determined by product category_name or product name patterns
  Future<List<Map<String, dynamic>>> getSalesMixByCategory(
    String date, {
    String? branchCode,
  }) async {
    try {
      var query = _supabase
          .from('product_sales')
          .select('product_name_th, product_name_lao, category_name, quantity, total_amount')
          .eq('sale_date', date);

      // Filter by branch if specified
      if (branchCode != null && branchCode != 'ALL') {
        final branchResponse = await _supabase
            .from('branches')
            .select('id')
            .eq('code', branchCode)
            .maybeSingle();

        if (branchResponse != null) {
          query = query.eq('branch_id', branchResponse['id']);
        }
      }

      final response = await query;

      if (response == null || (response as List).isEmpty) {
        return [];
      }

      // Categorize products
      double foodSales = 0;
      double beverageSales = 0;

      // Report types that are beverages
      final beverageCategories = [
        'beverages', 'beverage', 'drinks', 'drink',
      ];

      // Report types that are food
      final foodCategories = [
        'suki_items', 'suki_sets', 'duck_items', 'dim_sum', 'desserts',
        'food', 'kitchen_categories', 'dessert',
      ];

      // Keywords for categorization (English, Thai, Lao)
      final beverageKeywords = [
        'drink', 'beverage', 'water', 'juice', 'soda', 'beer', 'wine', 'cocktail',
        'ទឹក', 'ស្រា', 'ភេសជ្ជៈ', // Thai
        'ນ້ຳ', 'ເບຍ', 'ເຫຼົ້າ', // Lao
      ];

      for (var product in response) {
        final categoryName = (product['category_name'] ?? '').toString().toLowerCase();
        final nameTh = (product['product_name_th'] ?? '').toString().toLowerCase();
        final nameLao = (product['product_name_lao'] ?? '').toString().toLowerCase();
        final amount = (product['total_amount'] as num?)?.toDouble() ?? 0;

        // First check category_name from parser
        bool isBeverage = false;

        if (beverageCategories.any((cat) => categoryName.contains(cat))) {
          isBeverage = true;
        } else if (foodCategories.any((cat) => categoryName.contains(cat))) {
          isBeverage = false;
        } else {
          // Fallback to keyword matching on product name
          for (var keyword in beverageKeywords) {
            if (nameTh.contains(keyword) ||
                nameLao.contains(keyword)) {
              isBeverage = true;
              break;
            }
          }
        }
        if (isBeverage) {
          beverageSales += amount;
        } else {
          // Everything else is food (main dishes, sides, desserts)
          foodSales += amount;
        }
      }

      final total = foodSales + beverageSales;

      return [
        {
          'category': 'Food',
          'category_kh': 'អាហារ',
          'category_lao': 'ອາຫານ',
          'amount': foodSales,
          'percentage': total > 0 ? (foodSales / total * 100) : 0,
        },
        {
          'category': 'Beverage',
          'category_kh': 'ភេសជ្ជៈ',
          'category_lao': 'ເຄື່ອງດື່ມ',
          'amount': beverageSales,
          'percentage': total > 0 ? (beverageSales / total * 100) : 0,
        },
      ];
    } catch (e) {
      print('Error getting sales mix: $e');
      return [];
    }
  }
}