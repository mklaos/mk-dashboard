import 'package:flutter/foundation.dart';
import '../models/branch.dart';
import '../services/sales_service.dart';

class DashboardProvider extends ChangeNotifier {
  final SalesService _salesService = SalesService();

  /// Expose SalesService for direct access (used by DashboardScreen)
  SalesService get salesService => _salesService;

  // State variables
  List<Branch> _branches = [];
  String _selectedBranchCode = 'ALL'; // Default: show all branches
  String _selectedDate = '';
  Map<String, dynamic>? _dailySalesData;
  Map<String, dynamic>? _previousWeekData; // Historical data for comparison
  List<dynamic> _comparisonData = [];
  List<dynamic> _hourlyData = [];
  List<dynamic> _productData = [];
  List<Map<String, dynamic>> _salesMixData = []; // Food vs Beverage
  bool _showComparison = false; // Toggle between totals and comparison
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Branch> get branches => _branches;
  String get selectedBranchCode => _selectedBranchCode;
  String get selectedDate => _selectedDate;
  Map<String, dynamic>? get dailySalesData => _dailySalesData;
  Map<String, dynamic>? get previousWeekData => _previousWeekData;
  List<dynamic> get comparisonData => _comparisonData;
  List<dynamic> get hourlyData => _hourlyData;
  List<dynamic> get productData => _productData;
  List<Map<String, dynamic>> get salesMixData => _salesMixData;
  bool get showComparison => _showComparison;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  /// Get display name for the current selection
  String get currentSelectionDisplay {
    if (_selectedBranchCode == 'ALL') {
      return 'All Branches';
    }
    final branch = selectedBranch;
    return branch?.displayWithCode ?? _selectedBranchCode;
  }

  /// Load all available branches from the database
  Future<void> loadBranches() async {
    try {
      _branches = await _salesService.getAvailableBranches();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading branches: $e');
    }
  }

  /// Load data for a specific date and branch
  Future<void> loadData(String date, {String? branchCode}) async {
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

      // Use 'ALL' as default if no branch specified
      final branch = branchCode ?? _selectedBranchCode;

      // Load data based on branch selection
      if (branch == 'ALL') {
        // Load consolidated data
        final totals = await _salesService.getAllBranchesTotals(date);
        final comparison = await _salesService.getBranchComparison(date);
        final hourly = await _salesService.getHourlySalesByDate(date);
        final products = await _salesService.getTopProductsByDate(
          date,
          limit: 10,
        );
        final previousWeek = await _salesService.getPreviousWeekAverage(
          date,
          branchCode: branch,
        );
        final salesMix = await _salesService.getSalesMixByCategory(
          date,
          branchCode: branch,
        );

        _dailySalesData = totals;
        _previousWeekData = previousWeek;
        _comparisonData = comparison;
        _hourlyData = hourly;
        _productData = products;
        _salesMixData = salesMix;
      } else {
        // Load branch-specific data
        final sales = await _salesService.getSalesByDate(
          date,
          branchCode: branch,
        );
        final hourly = await _salesService.getHourlySalesByDate(
          date,
          branchCode: branch,
        );
        final products = await _salesService.getTopProductsByDate(
          date,
          limit: 10,
          branchCode: branch,
        );
        final previousWeek = await _salesService.getPreviousWeekAverage(
          date,
          branchCode: branch,
        );
        final salesMix = await _salesService.getSalesMixByCategory(
          date,
          branchCode: branch,
        );

        _dailySalesData = sales;
        _previousWeekData = previousWeek;
        _comparisonData = []; // No comparison for single branch
        _hourlyData = hourly;
        _productData = products;
        _salesMixData = salesMix;
      }

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