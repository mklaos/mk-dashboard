import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/branch.dart';
import '../models/brand.dart';
import '../models/user.dart';

class SalesService {
  final _supabase = Supabase.instance.client;

  /// Authenticate user
  Future<AppUser?> login(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      return getCurrentUser();
    }
    return null;
  }

  /// Get profile data for currently logged in user
  Future<AppUser?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('app_users')
        .select('*')
        .eq('auth_id', user.id)
        .maybeSingle();

    if (response != null) {
      return AppUser.fromJson(response);
    }
    return null;
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get all available brands
  Future<List<Brand>> getAvailableBrands() async {
    final response = await _supabase
        .from('brands')
        .select('*')
        .order('name', ascending: true);

    return response.map<Brand>((json) => Brand.fromJson(json)).toList();
  }

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

    // Get unique dates
    final dates = response.map<String>((row) => row['sale_date'] as String).toSet().toList();
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  /// Get sales summary for a specific date (optionally filtered by branch or brand)
  Future<Map<String, dynamic>?> getSalesByDate(
    String date, {
    String? branchCode,
    String? brandId,
  }) async {
    // 1. Specific Branch
    if (branchCode != null && branchCode != 'ALL') {
      final branchResponse = await _supabase
          .from('branches')
          .select('id, code, name, name_lao, name_en')
          .eq('code', branchCode)
          .maybeSingle();

      if (branchResponse == null) return null;

      final response = await _supabase
          .from('daily_sales')
          .select('*')
          .eq('sale_date', date)
          .eq('branch_id', branchResponse['id'])
          .maybeSingle();

      if (response == null) return null;
      
      return {
        ...response,
        'branches': branchResponse,
        'net_sales_ex_tax': (response['net_sales'] as num? ?? 0).toDouble() - (response['tax_amount'] as num? ?? 0).toDouble(),
      };
    }

    // 2. All Branches (optionally within a Brand)
    var query = _supabase
        .from('daily_sales')
        .select('net_sales, receipt_count, customer_count, void_amount, discount_amount, tax_amount')
        .eq('sale_date', date);

    if (brandId != null && brandId != 'ALL') {
      final branchesResponse = await _supabase
          .from('branches')
          .select('id')
          .eq('brand_id', brandId);
      
      final List<String> branchIds = (branchesResponse as List).map((b) => b['id'] as String).toList();
      if (branchIds.isEmpty) return null;
      query = query.inFilter('branch_id', branchIds);
    }

    final response = await query;

    if (response == null || (response as List).isEmpty) {
      return null;
    }

    final List<dynamic> records = response as List;
    double netSales = 0;
    int receipts = 0;
    int customers = 0;
    double voids = 0;
    double discounts = 0;
    double taxes = 0;

    for (var record in records) {
      netSales += (record['net_sales'] as num?)?.toDouble() ?? 0;
      receipts += (record['receipt_count'] as num?)?.toInt() ?? 0;
      customers += (record['customer_count'] as num?)?.toInt() ?? 0;
      voids += (record['void_amount'] as num?)?.toDouble() ?? 0;
      discounts += (record['discount_amount'] as num?)?.toDouble() ?? 0;
      taxes += (record['tax_amount'] as num?)?.toDouble() ?? 0;
    }

    return {
      'sale_date': date,
      'net_sales': netSales,
      'receipt_count': receipts,
      'customer_count': customers,
      'void_amount': voids,
      'discount_amount': discounts,
      'tax_amount': taxes,
      'net_sales_ex_tax': netSales - taxes,
    };
  }

  Future<List<dynamic>> getHourlySalesByDate(
    String date, {
    String? branchCode,
    String? brandId,
  }) async {
    var query = _supabase
        .from('hourly_sales')
        .select('hour, sales, customer_count, table_count')
        .eq('sale_date', date);

    if (branchCode != null && branchCode != 'ALL') {
      final branchResponse = await _supabase
          .from('branches')
          .select('id')
          .eq('code', branchCode)
          .maybeSingle();

      if (branchResponse != null) {
        query = query.eq('branch_id', branchResponse['id']);
      } else {
        return [];
      }
    } else if (brandId != null && brandId != 'ALL') {
      final branchesResponse = await _supabase
          .from('branches')
          .select('id')
          .eq('brand_id', brandId);
      
      final List<String> branchIds = (branchesResponse as List).map((b) => b['id'] as String).toList();
      if (branchIds.isEmpty) return [];
      query = query.inFilter('branch_id', branchIds);
    }

    final response = await query.order('hour', ascending: true);
    
    // If it's multiple branches, we need to aggregate by hour
    if (branchCode == null || branchCode == 'ALL') {
      final Map<int, Map<String, dynamic>> hourlyMap = {};
      for (var row in response) {
        final h = row['hour'] as int;
        if (!hourlyMap.containsKey(h)) {
          hourlyMap[h] = {'hour': h, 'sales': 0.0, 'customer_count': 0, 'table_count': 0};
        }
        hourlyMap[h]!['sales'] += (row['sales'] as num?)?.toDouble() ?? 0;
        hourlyMap[h]!['customer_count'] += (row['customer_count'] as num?)?.toInt() ?? 0;
        hourlyMap[h]!['table_count'] += (row['table_count'] as num?)?.toInt() ?? 0;
      }
      final sortedKeys = hourlyMap.keys.toList()..sort();
      return sortedKeys.map((k) => hourlyMap[k]!).toList();
    }

    return response;
  }

  Future<List<dynamic>> getTopProductsByDate(
    String date, {
    int limit = 10,
    String? branchCode,
    String? brandId,
  }) async {
    var query = _supabase
        .from('product_sales')
        .select('product_name_th, product_name_lao, quantity, total_amount, category_name')
        .eq('sale_date', date);

    if (branchCode != null && branchCode != 'ALL') {
      final branchResponse = await _supabase
          .from('branches')
          .select('id')
          .eq('code', branchCode)
          .maybeSingle();

      if (branchResponse != null) {
        query = query.eq('branch_id', branchResponse['id']);
      } else {
        return [];
      }
    } else if (brandId != null && brandId != 'ALL') {
      final branchesResponse = await _supabase
          .from('branches')
          .select('id')
          .eq('brand_id', brandId);
      
      final List<String> branchIds = (branchesResponse as List).map((b) => b['id'] as String).toList();
      if (branchIds.isEmpty) return [];
      query = query.inFilter('branch_id', branchIds);
    }

    final response = await query;
    
    // Aggregate by product name (since same product might be in multiple branches)
    final Map<String, Map<String, dynamic>> productMap = {};
    for (var row in response) {
      final name = row['product_name_th'] as String;
      if (!productMap.containsKey(name)) {
        productMap[name] = {
          'product_name_th': name,
          'product_name_lao': row['product_name_lao'],
          'quantity': 0,
          'total_amount': 0.0,
          'category_name': row['category_name'],
        };
      }
      productMap[name]!['quantity'] += (row['quantity'] as num?)?.toInt() ?? 0;
      productMap[name]!['total_amount'] += (row['total_amount'] as num?)?.toDouble() ?? 0;
    }

    final sortedProducts = productMap.values.toList()
      ..sort((a, b) => (b['total_amount'] as double).compareTo(a['total_amount'] as double));

    return sortedProducts.take(limit).toList();
  }

  Future<List<dynamic>> getBranchComparison(String date, {String? brandId}) async {
    var query = _supabase
        .from('v_branch_performance')
        .select('*')
        .eq('sale_date', date);
    
    if (brandId != null && brandId != 'ALL') {
      query = query.eq('brand_id', brandId);
    }

    final response = await query.order('branch_code', ascending: true);
    return response;
  }

  Future<Map<String, dynamic>?> getPreviousWeekAverage(
    String currentDate, {
    String? branchCode,
    String? brandId,
  }) async {
    try {
      final current = DateTime.parse(currentDate);
      final previousWeekStart = current.subtract(const Duration(days: 7));
      final previousWeekEnd = current.subtract(const Duration(days: 1));

      final startDate =
          '${previousWeekStart.year}-${previousWeekStart.month.toString().padLeft(2, '0')}-${previousWeekStart.day.toString().padLeft(2, '0')}';
      final endDate =
          '${previousWeekEnd.year}-${previousWeekEnd.month.toString().padLeft(2, '0')}-${previousWeekEnd.day.toString().padLeft(2, '0')}';

      var query = _supabase
          .from('daily_sales')
          .select('sale_date, net_sales, receipt_count, customer_count, void_amount, discount_amount, tax_amount')
          .gte('sale_date', startDate)
          .lte('sale_date', endDate);

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
      } else if (brandId != null && brandId != 'ALL') {
        final branchesResponse = await _supabase
            .from('branches')
            .select('id')
            .eq('brand_id', brandId);
        final List<String> branchIds = (branchesResponse as List).map((b) => b['id'] as String).toList();
        if (branchIds.isEmpty) return null;
        query = query.inFilter('branch_id', branchIds);
      }

      final response = await query;
      if (response == null || (response as List).isEmpty) return null;

      double totalSales = 0;
      int totalReceipts = 0;
      int totalCustomers = 0;
      double totalVoids = 0;
      double totalTaxes = 0;
      int daysWithData = 0;

      for (var record in response) {
        totalSales += (record['net_sales'] as num?)?.toDouble() ?? 0;
        totalReceipts += (record['receipt_count'] as num?)?.toInt() ?? 0;
        totalCustomers += (record['customer_count'] as num?)?.toInt() ?? 0;
        totalVoids += (record['void_amount'] as num?)?.toDouble() ?? 0;
        totalTaxes += (record['tax_amount'] as num?)?.toDouble() ?? 0;
        daysWithData++;
      }

      final avgDays = daysWithData > 0 ? daysWithData.toDouble() : 1;

      return {
        'net_sales': totalSales / avgDays,
        'receipt_count': (totalReceipts / avgDays).round(),
        'customer_count': (totalCustomers / avgDays).round(),
        'void_amount': totalVoids / avgDays,
        'net_sales_ex_tax': (totalSales - totalTaxes) / avgDays,
        'days_with_data': daysWithData,
      };
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getSalesMixByCategory(
    String date, {
    String? branchCode,
    String? brandId,
  }) async {
    try {
      var query = _supabase
          .from('product_sales')
          .select('product_name_th, product_name_lao, category_name, quantity, total_amount')
          .eq('sale_date', date);

      if (branchCode != null && branchCode != 'ALL') {
        final branchResponse = await _supabase.from('branches').select('id').eq('code', branchCode).maybeSingle();
        if (branchResponse != null) query = query.eq('branch_id', branchResponse['id']);
      } else if (brandId != null && brandId != 'ALL') {
        final branchesResponse = await _supabase.from('branches').select('id').eq('brand_id', brandId);
        final List<String> branchIds = (branchesResponse as List).map((b) => b['id'] as String).toList();
        if (branchIds.isNotEmpty) query = query.inFilter('branch_id', branchIds);
      }

      final response = await query;
      if (response == null || (response as List).isEmpty) return [];

      double foodSales = 0;
      double beverageSales = 0;
      final beverageKeywords = ['drink', 'beverage', 'water', 'juice', 'soda', 'beer', 'wine', 'cocktail', 'ទឹក', 'ស្រា', 'ភេសជ្ជៈ', 'ນ້ຳ', 'ເບຍ', 'ເຫຼົ້າ'];

      for (var product in response) {
        final categoryName = (product['category_name'] ?? '').toString().toLowerCase();
        final nameTh = (product['product_name_th'] ?? '').toString().toLowerCase();
        final amount = (product['total_amount'] as num?)?.toDouble() ?? 0;
        bool isBeverage = categoryName.contains('beverage') || categoryName.contains('drink') || beverageKeywords.any((kw) => nameTh.contains(kw));
        if (isBeverage) beverageSales += amount; else foodSales += amount;
      }

      final total = foodSales + beverageSales;
      return [
        {'category': 'Food', 'category_lao': 'ອາຫານ', 'amount': foodSales, 'percentage': total > 0 ? (foodSales / total * 100) : 0},
        {'category': 'Beverage', 'category_lao': 'ເຄື່ອງດື່ມ', 'amount': beverageSales, 'percentage': total > 0 ? (beverageSales / total * 100) : 0},
      ];
  Future<List<Map<String, dynamic>>> getDailyTrends(
    String startDate,
    String endDate, {
    String? branchCode,
    String? brandId,
  }) async {
    try {
      var query = _supabase
          .from('daily_sales')
          .select('sale_date, net_sales, receipt_count, customer_count')
          .gte('sale_date', startDate)
          .lte('sale_date', endDate);

      if (branchCode != null && branchCode != 'ALL') {
        final branchResponse = await _supabase.from('branches').select('id').eq('code', branchCode).maybeSingle();
        if (branchResponse != null) query = query.eq('branch_id', branchResponse['id']);
      } else if (brandId != null && brandId != 'ALL') {
        final branchesResponse = await _supabase.from('branches').select('id').eq('brand_id', brandId);
        final List<String> branchIds = (branchesResponse as List).map((b) => b['id'] as String).toList();
        if (branchIds.isNotEmpty) query = query.inFilter('branch_id', branchIds);
      }

      final response = await query.order('sale_date', ascending: true);
      if (response == null || (response as List).isEmpty) return [];

      // Aggregate by date
      final Map<String, Map<String, dynamic>> trendMap = {};
      for (var row in response) {
        final date = row['sale_date'] as String;
        if (!trendMap.containsKey(date)) {
          trendMap[date] = {'sale_date': date, 'net_sales': 0.0, 'receipt_count': 0, 'customer_count': 0};
        }
        trendMap[date]!['net_sales'] += (row['net_sales'] as num?)?.toDouble() ?? 0;
        trendMap[date]!['receipt_count'] += (row['receipt_count'] as num?)?.toInt() ?? 0;
        trendMap[date]!['customer_count'] += (row['customer_count'] as num?)?.toInt() ?? 0;
      }

      return trendMap.values.toList()..sort((a, b) => (a['sale_date'] as String).compareTo(b['sale_date'] as String));
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyTrends(
    String startMonth, // YYYY-MM
    String endMonth,   // YYYY-MM
    {
    String? branchCode,
    String? brandId,
  }) async {
    try {
      // Fetch all daily sales for the period and aggregate by month
      final startDate = '$startMonth-01';
      final endMonthObj = DateTime.parse('$endMonth-01');
      final endDate = DateTime(endMonthObj.year, endMonthObj.month + 1, 0).toString().split(' ')[0];

      var query = _supabase
          .from('daily_sales')
          .select('sale_date, net_sales, receipt_count, customer_count')
          .gte('sale_date', startDate)
          .lte('sale_date', endDate);

      if (branchCode != null && branchCode != 'ALL') {
        final branchResponse = await _supabase.from('branches').select('id').eq('code', branchCode).maybeSingle();
        if (branchResponse != null) query = query.eq('branch_id', branchResponse['id']);
      } else if (brandId != null && brandId != 'ALL') {
        final branchesResponse = await _supabase.from('branches').select('id').eq('brand_id', brandId);
        final List<String> branchIds = (branchesResponse as List).map((b) => b['id'] as String).toList();
        if (branchIds.isNotEmpty) query = query.inFilter('branch_id', branchIds);
      }

      final response = await query;
      if (response == null || (response as List).isEmpty) return [];

      final Map<String, Map<String, dynamic>> trendMap = {};
      for (var row in response) {
        final date = row['sale_date'] as String;
        final month = date.substring(0, 7); // YYYY-MM
        if (!trendMap.containsKey(month)) {
          trendMap[month] = {'month': month, 'net_sales': 0.0, 'receipt_count': 0, 'customer_count': 0};
        }
        trendMap[month]!['net_sales'] += (row['net_sales'] as num?)?.toDouble() ?? 0;
        trendMap[month]!['receipt_count'] += (row['receipt_count'] as num?)?.toInt() ?? 0;
        trendMap[month]!['customer_count'] += (row['customer_count'] as num?)?.toInt() ?? 0;
      }

      return trendMap.values.toList()..sort((a, b) => (a['month'] as String).compareTo(b['month'] as String));
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getYearlyTrends(
    int startYear,
    int endYear,
    {
    String? branchCode,
    String? brandId,
  }) async {
    try {
      final startDate = '$startYear-01-01';
      final endDate = '$endYear-12-31';

      var query = _supabase
          .from('daily_sales')
          .select('sale_date, net_sales, receipt_count, customer_count')
          .gte('sale_date', startDate)
          .lte('sale_date', endDate);

      if (branchCode != null && branchCode != 'ALL') {
        final branchResponse = await _supabase.from('branches').select('id').eq('code', branchCode).maybeSingle();
        if (branchResponse != null) query = query.eq('branch_id', branchResponse['id']);
      } else if (brandId != null && brandId != 'ALL') {
        final branchesResponse = await _supabase.from('branches').select('id').eq('brand_id', brandId);
        final List<String> branchIds = (branchesResponse as List).map((b) => b['id'] as String).toList();
        if (branchIds.isNotEmpty) query = query.inFilter('branch_id', branchIds);
      }

      final response = await query;
      if (response == null || (response as List).isEmpty) return [];

      final Map<int, Map<String, dynamic>> trendMap = {};
      for (var row in response) {
        final date = row['sale_date'] as String;
        final year = int.parse(date.substring(0, 4));
        if (!trendMap.containsKey(year)) {
          trendMap[year] = {'year': year, 'net_sales': 0.0, 'receipt_count': 0, 'customer_count': 0};
        }
        trendMap[year]!['net_sales'] += (row['net_sales'] as num?)?.toDouble() ?? 0;
        trendMap[year]!['receipt_count'] += (row['receipt_count'] as num?)?.toInt() ?? 0;
        trendMap[year]!['customer_count'] += (row['customer_count'] as num?)?.toInt() ?? 0;
      }

      return trendMap.values.toList()..sort((a, b) => (a['year'] as int).compareTo(b['year'] as int));
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDineInVsTakeaway(
    String date, {
    String? branchCode,
    String? brandId,
  }) async {
    try {
      var query = _supabase
          .from('daily_sales')
          .select('net_sales, takeaway_sales')
          .eq('sale_date', date);

      if (branchCode != null && branchCode != 'ALL') {
        final branchResponse = await _supabase.from('branches').select('id').eq('code', branchCode).maybeSingle();
        if (branchResponse != null) query = query.eq('branch_id', branchResponse['id']);
      } else if (brandId != null && brandId != 'ALL') {
        final branchesResponse = await _supabase.from('branches').select('id').eq('brand_id', brandId);
        final List<String> branchIds = (branchesResponse as List).map((b) => b['id'] as String).toList();
        if (branchIds.isNotEmpty) query = query.inFilter('branch_id', branchIds);
      }

      final response = await query;
      if (response == null || (response as List).isEmpty) return [];

      double totalNetSales = 0;
      double totalTakeawaySales = 0;

      for (var record in response) {
        totalNetSales += (record['net_sales'] as num?)?.toDouble() ?? 0;
        totalTakeawaySales += (record['takeaway_sales'] as num?)?.toDouble() ?? 0;
      }

      final dineInSales = totalNetSales - totalTakeawaySales;
      final total = totalNetSales > 0 ? totalNetSales : 1;

      return [
        {
          'category': 'Dine-In',
          'category_lao': 'ກິນຢູ່ຮ້ານ',
          'amount': dineInSales,
          'percentage': (dineInSales / total) * 100,
        },
        {
          'category': 'Takeaway',
          'category_lao': 'ຊື້ກັບບ້ານ',
          'amount': totalTakeawaySales,
          'percentage': (totalTakeawaySales / total) * 100,
        },
      ];
    } catch (e) {
      return [];
    }
  }
}
