import 'package:flutter/foundation.dart';
import '../models/branch.dart';
import '../models/brand.dart';
import '../models/user.dart';
import '../services/sales_service.dart';

class DashboardProvider extends ChangeNotifier {
  final SalesService _salesService = SalesService();

  /// Expose SalesService for direct access (used by DashboardScreen)
  SalesService get salesService => _salesService;

  // State variables
  AppUser? _currentUser;
  List<Brand> _brands = [];
  String _selectedBrandId = 'ALL';
  List<Branch> _branches = [];
  String _selectedBranchCode = 'ALL'; // Default: show all branches
  String _selectedDate = '';
  String _locale = 'lo'; // Default to Lao
  Map<String, dynamic>? _dailySalesData;
  Map<String, dynamic>? _previousWeekData; // Historical data for comparison

  // Getters
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String get locale => _locale;
  bool get isLao => _locale == 'lo';

  /// Authenticate and load initial data
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _salesService.login(email, password);
      if (user != null) {
        _currentUser = user;
        await loadInitialData();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = 'Invalid credentials';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Login error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout and reset
  Future<void> logout() async {
    await _salesService.signOut();
    _currentUser = null;
    reset();
    notifyListeners();
  }

  void setLocale(String locale) {
    _locale = locale;
    notifyListeners();
  }

  void toggleLocale() {
    _locale = _locale == 'lo' ? 'en' : 'lo';
    notifyListeners();
  }

  /// Get translated text
  String translate(String key) {
    final translations = {
      'lo': {
        'total_sales': 'ຍອດຂາຍທັງໝົດ',
        'sales_ex_tax': 'ຍອດຂາຍ (ບໍ່ລວມພາສີ)',
        'receipts': 'ໃບບິນ',
        'customers': 'ລູກຄ້າ',
        'avg_ticket': 'ສະເລ່ຍ/ບິນ',
        'discounts': 'ສ່ວນຫຼຸດ',
        'voids': 'ຍົກເລີກ',
        'food_vs_bev': 'ອາຫານ vs ເຄື່ອງດື່ມ',
        'dine_in_vs_takeaway': 'ກິນຢູ່ຮ້ານ vs ກັບບ້ານ',
        'top_products': 'ລາຍການຂາຍດີ',
        'trends': 'ແນວໂນ້ມການຂາຍ',
        'dashboard': 'ໜ້າຫຼັກ',
        'select_brand': 'ເລືອກຍີ່ຫໍ້',
        'select_branch': 'ເລືອກສາຂາ',
        'login': 'ເຂົ້າສູ່ລະບົບ',
        'email': 'ອີເມວ',
        'password': 'ລະຫັດຜ່ານ',
        'logout': 'ອອກຈາກລະບົບ',
      },
      'en': {
        'total_sales': 'Total Sales',
        'sales_ex_tax': 'Sales (Ex Tax)',
        'receipts': 'Receipts',
        'customers': 'Customers',
        'avg_ticket': 'Avg Ticket',
        'discounts': 'Discounts',
        'voids': 'Voids',
        'food_vs_bev': 'Food vs Beverage',
        'dine_in_vs_takeaway': 'Dine-In vs Takeaway',
        'top_products': 'Top Products',
        'trends': 'Sales Trends',
        'dashboard': 'Dashboard',
        'select_brand': 'Select Brand',
        'select_branch': 'Select Branch',
        'login': 'Login',
        'email': 'Email',
        'password': 'Password',
        'logout': 'Logout',
      }
    };
    return translations[_locale]?[key] ?? key;
  }
  List<dynamic> _comparisonData = [];
  List<dynamic> _hourlyData = [];
  List<dynamic> _productData = [];
  List<Map<String, dynamic>> _salesMixData = []; // Food vs Beverage
  List<Map<String, dynamic>> _dineInVsTakeawayData = [];
  
  // Trend data
  List<Map<String, dynamic>> _dailyTrendData = [];
  List<Map<String, dynamic>> _monthlyTrendData = [];
  List<Map<String, dynamic>> _yearlyTrendData = [];
  
  bool _showComparison = false; // Toggle between totals and comparison
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Brand> get brands {
    if (_currentUser?.role == 'owner') {
      return _brands;
    }
    // Filter brands based on user's allowed_brands
    return _brands.where((b) => _currentUser?.allowedBrands.contains(b.id) ?? false).toList();
  }

  String get selectedBrandId => _selectedBrandId;
  List<Branch> get branches => _branches;
  
  /// Filtered branches based on selected brand and user permissions
  List<Branch> get filteredBranches {
    List<Branch> list = _branches;
    
    // Filter by brand selection
    if (_selectedBrandId != 'ALL') {
      list = list.where((b) => b.brandId == _selectedBrandId).toList();
    } else if (_currentUser?.role != 'owner') {
      // If ALL is selected but user is not owner, show only their allowed brands' branches
      list = list.where((b) => _currentUser?.allowedBrands.contains(b.brandId) ?? false).toList();
    }

    // Filter by branch permissions (for managers/viewers)
    if (_currentUser?.role != 'owner' && (_currentUser?.allowedBranches.isNotEmpty ?? false)) {
      list = list.where((b) => _currentUser?.allowedBranches.contains(b.id) ?? false).toList();
    }

    return list;
  }

  String get selectedBranchCode => _selectedBranchCode;
  String get selectedDate => _selectedDate;
  Map<String, dynamic>? get dailySalesData => _dailySalesData;
  Map<String, dynamic>? get previousWeekData => _previousWeekData;
  List<dynamic> get comparisonData => _comparisonData;
  List<dynamic> get hourlyData => _hourlyData;
  List<dynamic> get productData => _productData;
  List<Map<String, dynamic>> get salesMixData => _salesMixData;
  List<Map<String, dynamic>> get dineInVsTakeawayData => _dineInVsTakeawayData;
  
  // Trend Getters
  List<Map<String, dynamic>> get dailyTrendData => _dailyTrendData;
  List<Map<String, dynamic>> get monthlyTrendData => _monthlyTrendData;
  List<Map<String, dynamic>> get yearlyTrendData => _yearlyTrendData;

  bool get showComparison => _showComparison;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Check if user is already logged in
  Future<void> checkSession() async {
    _currentUser = await _salesService.getCurrentUser();
    if (_currentUser != null) {
      await loadInitialData();
    }
    notifyListeners();
  }

  /// Load trend data
  Future<void> loadTrends() async {
    try {
      _isLoading = true;
      notifyListeners();

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30)).toString().split(' ')[0];
      final endDate = now.toString().split(' ')[0];

      final startMonth = DateTime(now.year, now.month - 5, 1).toString().substring(0, 7);
      final endMonth = now.toString().substring(0, 7);

      final startYear = now.year - 2;
      final endYear = now.year;

      final results = await Future.wait([
        _salesService.getDailyTrends(startDate, endDate, branchCode: _selectedBranchCode, brandId: _selectedBrandId),
        _salesService.getMonthlyTrends(startMonth, endMonth, branchCode: _selectedBranchCode, brandId: _selectedBrandId),
        _salesService.getYearlyTrends(startYear, endYear, branchCode: _selectedBranchCode, brandId: _selectedBrandId),
      ]);

      _dailyTrendData = results[0];
      _monthlyTrendData = results[1];
      _yearlyTrendData = results[2];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading trends: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculate growth percentage between current and previous value
  /// Returns null if previous value is null or zero
  double? calculateGrowth(double? current, double? previous) {
    if (current == null || previous == null || previous == 0) {
      return null;
    }
    return ((current - previous) / previous) * 100;
  }

  /// Get growth indicator for a metric
  /// Returns positive number for growth, negative for decline
  double? getGrowthFor(String metric) {
    if (_dailySalesData == null || _previousWeekData == null) {
      return null;
    }

    final current = _dailySalesData![metric];
    final previous = _previousWeekData![metric];

    if (current == null || previous == null) {
      return null;
    }

    if (previous == 0) {
      return null;
    }

    return ((current - previous) / previous) * 100;
  }

  /// Returns the currently selected branch or null for ALL
  Branch? get selectedBranch {
    if (_selectedBranchCode == 'ALL' || _selectedBranchCode.isEmpty) {
      return null;
    }
    try {
      return _branches.firstWhere(
        (branch) => branch.code == _selectedBranchCode,
      );
    } catch (e) {
      return null;
    }
  }

  /// Returns the currently selected brand or null for ALL
  Brand? get selectedBrand {
    if (_selectedBrandId == 'ALL') return null;
    try {
      return _brands.firstWhere((b) => b.id == _selectedBrandId);
    } catch (e) {
      return null;
    }
  }

  /// Get display name for the current selection
  String get currentSelectionDisplay {
    if (_selectedBranchCode == 'ALL') {
      if (_selectedBrandId == 'ALL') {
         if (_currentUser?.role == 'owner') return 'All Brands';
         final userBrands = brands;
         if (userBrands.length == 1) return userBrands.first.displayName;
         return 'Allowed Brands';
      }
      return selectedBrand?.displayName ?? 'Selected Brand';
    }
    final branch = selectedBranch;
    return branch?.displayWithCode ?? _selectedBranchCode;
  }

  /// Load all available brands and branches from the database
  Future<void> loadInitialData() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _brands = await _salesService.getAvailableBrands();
      _branches = await _salesService.getAvailableBranches();
      
      // Auto-select if user only has access to one brand/branch
      final allowedBrands = brands;
      if (allowedBrands.length == 1 && _selectedBrandId == 'ALL') {
        _selectedBrandId = allowedBrands.first.id;
      }
      
      final allowedBranches = filteredBranches;
      if (allowedBranches.length == 1 && _selectedBranchCode == 'ALL') {
        _selectedBranchCode = allowedBranches.first.code;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      _error = 'Failed to load metadata';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Switch brand and reset branch selection
  Future<void> switchBrand(String brandId) async {
    if (_selectedBrandId == brandId) return;
    
    _selectedBrandId = brandId;
    _selectedBranchCode = 'ALL'; // Reset branch selection when brand changes
    notifyListeners();
    
    if (_selectedDate.isNotEmpty) {
      await loadData(_selectedDate);
    }
  }

  /// Load data for a specific date and branch/brand
  Future<void> loadData(String date, {String? branchCode, String? brandId}) async {
    if (date.isEmpty) return;

    try {
      _isLoading = true;
      _error = null;
      // Clear previous data immediately to prevent showing stale data
      _dailySalesData = null;
      _previousWeekData = null;
      _comparisonData = [];
      _hourlyData = [];
      _productData = [];
      _salesMixData = [];
      notifyListeners();

      // Use selected values if not provided
      final activeBranch = branchCode ?? _selectedBranchCode;
      final activeBrand = brandId ?? _selectedBrandId;

      // Filter for brand/branch permissions if not owner
      String? filterBrand = activeBrand;
      if (_currentUser?.role != 'owner' && filterBrand == 'ALL') {
         // Should we aggregate all allowed brands? Yes, getSalesByDate handles it if null
      }

      // Load all data in parallel for speed
      final results = await Future.wait([
        _salesService.getSalesByDate(date, branchCode: activeBranch, brandId: filterBrand),
        _salesService.getHourlySalesByDate(date, branchCode: activeBranch, brandId: filterBrand),
        _salesService.getTopProductsByDate(date, limit: 10, branchCode: activeBranch, brandId: filterBrand),
        _salesService.getPreviousWeekAverage(date, branchCode: activeBranch, brandId: filterBrand),
        _salesService.getSalesMixByCategory(date, branchCode: activeBranch, brandId: filterBrand),
        _salesService.getDineInVsTakeaway(date, branchCode: activeBranch, brandId: filterBrand),
        activeBranch == 'ALL' 
            ? _salesService.getBranchComparison(date, brandId: filterBrand)
            : Future.value([]),
      ]);

      _dailySalesData = results[0] as Map<String, dynamic>?;
      _hourlyData = results[1] as List<dynamic>;
      _productData = results[2] as List<dynamic>;
      _previousWeekData = results[3] as Map<String, dynamic>?;
      _salesMixData = results[4] as List<Map<String, dynamic>>;
      _dineInVsTakeawayData = results[5] as List<Map<String, dynamic>>;
      _comparisonData = results[6] as List<dynamic>;

      _selectedDate = date;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading data: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Switch to a different branch
  Future<void> switchBranch(String branchCode) async {
    if (_selectedBranchCode == branchCode) return;

    _selectedBranchCode = branchCode;
    notifyListeners();

    // Reload data with new branch if we have a date
    if (_selectedDate.isNotEmpty) {
      await loadData(_selectedDate);
    }
  }

  /// Toggle between totals view and comparison view
  void toggleComparisonMode() {
    _showComparison = !_showComparison;
    notifyListeners();
  }

  /// Refresh current data
  Future<void> refresh() async {
    if (_selectedDate.isNotEmpty) {
      await loadData(_selectedDate);
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _selectedBrandId = 'ALL';
    _selectedBranchCode = 'ALL';
    _selectedDate = '';
    _dailySalesData = null;
    _previousWeekData = null;
    _comparisonData = [];
    _hourlyData = [];
    _productData = [];
    _salesMixData = [];
    _showComparison = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}

  /// Switch to a different branch
  Future<void> switchBranch(String branchCode) async {
    if (_selectedBranchCode == branchCode) return;

    _selectedBranchCode = branchCode;
    notifyListeners();

    // Reload data with new branch if we have a date
    if (_selectedDate.isNotEmpty) {
      await loadData(_selectedDate);
    }
  }

  /// Toggle between totals view and comparison view
  void toggleComparisonMode() {
    _showComparison = !_showComparison;
    notifyListeners();
  }

  /// Refresh current data
  Future<void> refresh() async {
    if (_selectedDate.isNotEmpty) {
      await loadData(_selectedDate);
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _selectedBranchCode = 'ALL';
    _selectedDate = '';
    _dailySalesData = null;
    _previousWeekData = null;
    _comparisonData = [];
    _hourlyData = [];
    _productData = [];
    _salesMixData = [];
    _showComparison = false;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}