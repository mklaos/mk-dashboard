import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/kpi_card.dart';
import '../widgets/hourly_chart.dart';
import '../widgets/sales_chart.dart';
import '../widgets/branch_selector.dart';
import '../widgets/comparison_toggle.dart';
import '../widgets/kpi_comparison_card.dart';
import '../widgets/sales_mix_pie_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DashboardProvider>(
        context,
        listen: false,
      );
      provider.loadBranches();
      _loadInitialData(provider);
    });
  }

  Future<void> _loadInitialData(DashboardProvider provider) async {
    try {
      final dates = await provider.salesService.getAvailableDates();
      if (dates.isNotEmpty) {
        await provider.loadData(dates.first);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading initial data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MK Sales Dashboard'),
        centerTitle: true,
        actions: [
          Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.isLoading ? null : provider.refresh,
              );
            },
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.dailySalesData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return _buildErrorView(provider);
          }

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BranchSelector(
                    branchCodes: ['ALL', ...provider.branches.map((b) => b.code)],
                    selectedBranch: provider.selectedBranchCode,
                    onBranchSelected: provider.switchBranch,
                  ),
                  const SizedBox(height: 4),
                  _buildDateNavigation(context, provider),
                  const SizedBox(height: 12),
                  _buildSubheader(context, provider),
                  const SizedBox(height: 8),
                  if (provider.selectedBranchCode == 'ALL')
                    ComparisonToggle(
                      showComparison: provider.showComparison,
                      onToggle: provider.toggleComparisonMode,
                    ),
                  if (provider.dailySalesData == null &&
                      provider.hourlyData.isEmpty &&
                      provider.productData.isEmpty) ...[
                    _buildNoDataView(context, provider),
                  ] else if (provider.selectedBranchCode == 'ALL'
                      ? !provider.showComparison
                      : true) ...[
                    _buildKPICards(context, provider),
                    const SizedBox(height: 12),
                    _buildHourlyChart(context, provider),
                    const SizedBox(height: 12),
                    _buildSalesMixChart(context, provider),
                    const SizedBox(height: 12),
                    _buildTopProducts(context, provider),
                  ] else ...[
                    KPIComparisonCard(
                      branchData: provider.branches.map((branch) {
                        // Find the data for this specific branch in the comparison data
                        final branchStats = provider.comparisonData.firstWhere(
                          (data) => data['branch_code'] == branch.code,
                          orElse: () => null,
                        );

                        return {
                          'branch_code': branch.code,
                          'net_sales': branchStats?['net_sales'] ?? 0,
                          'receipt_count': branchStats?['receipt_count'] ?? 0,
                          'customer_count': branchStats?['customer_count'] ?? 0,
                          'void_amount': branchStats?['void_amount'] ?? 0,
                        };
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    SalesChart(
                      data: provider.comparisonData,
                      chartType: 'comparison',
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(DashboardProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              provider.error ?? 'Unknown error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                provider.clearError();
                provider.refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateNavigation(BuildContext context, DashboardProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              onPressed: () {},
            ),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final dates = await provider.salesService.getAvailableDates();
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('Select Date'),
                      children: dates
                          .map(
                            (date) => SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, date),
                              child: Text(_formatDisplayDate(date)),
                            ),
                          )
                          .toList(),
                    ),
                  );
                  if (selected != null) {
                    await provider.loadData(selected);
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      provider.selectedDate.isNotEmpty
                          ? _formatDisplayDate(provider.selectedDate)
                          : 'No Data',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 44,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubheader(BuildContext context, DashboardProvider provider) {
    final branch = provider.selectedBranch;
    final date = provider.selectedDate;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        branch != null
            ? '${branch.displayWithCode} - ${_formatDisplayDate(date)}'
            : 'All Branches - ${_formatDisplayDate(date)}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
            ),
      ),
    );
  }

  Widget _buildNoDataView(BuildContext context, DashboardProvider provider) {
    final branch = provider.selectedBranch;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Data Available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            branch != null
                ? 'No sales data found for ${branch.displayWithCode} on ${_formatDisplayDate(provider.selectedDate)}'
                : 'No sales data found for All Branches on ${_formatDisplayDate(provider.selectedDate)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: provider.refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICards(BuildContext context, DashboardProvider provider) {
    final data = provider.dailySalesData;
    final avgTicket = _calculateAvgTicket(data);
    
    // Get growth percentages
    final salesGrowth = provider.getGrowthFor('net_sales');
    final receiptsGrowth = provider.getGrowthFor('receipt_count');
    final customersGrowth = provider.getGrowthFor('customer_count');
    // For avg ticket, we need to calculate from the growth of sales and receipts
    final avgTicketGrowth = provider.getGrowthFor('net_sales'); // Approximation

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.0,
      children: [
        KpiCard(
          title: 'Total Sales',
          value: _formatCurrency(data?['net_sales'] ?? 0),
          icon: Icons.attach_money,
          color: Colors.green,
          growthPercentage: salesGrowth,
        ),
        KpiCard(
          title: 'Receipts',
          value: '${data?['receipt_count'] ?? 0}',
          icon: Icons.receipt_long,
          color: Colors.blue,
          growthPercentage: receiptsGrowth,
        ),
        KpiCard(
          title: 'Customers',
          value: '${data?['customer_count'] ?? 0}',
          icon: Icons.people,
          color: Colors.orange,
          growthPercentage: customersGrowth,
        ),
        KpiCard(
          title: 'Avg Ticket',
          value: _formatCurrency(avgTicket),
          icon: Icons.trending_up,
          color: Colors.purple,
          growthPercentage: avgTicketGrowth,
        ),
      ],
    );
  }

  Widget _buildHourlyChart(BuildContext context, DashboardProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales by Hour',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 150,
            child: provider.hourlyData.isNotEmpty
                ? HourlyChart(hourlyData: provider.hourlyData)
                : const Center(child: Text('No hourly data')),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesMixChart(BuildContext context, DashboardProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales Mix (Food vs Beverage)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 220,
            child: provider.salesMixData.isNotEmpty
                ? SalesMixPieChart(salesMixData: provider.salesMixData)
                : const Center(child: Text('No sales mix data')),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(BuildContext context, DashboardProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Products',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          ...provider.productData.take(5).map((product) {
            final name = (product['product_name_lao'] ?? '').isNotEmpty
                ? product['product_name_lao']
                : (product['product_name_en'] ??
                    product['product_name_th'] ??
                    'Unknown');
            return Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    '${provider.productData.indexOf(product) + 1}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: Text(
                  _formatCurrency(product['total_amount'] ?? 0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    final value = (amount is num ? amount : 0).toDouble();
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M ₭';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K ₭';
    }
    return '$value ₭';
  }

  double _calculateAvgTicket(Map<String, dynamic>? data) {
    final receipts = data?['receipt_count'] ?? 0;
    final sales = data?['net_sales'] ?? 0;
    if (receipts > 0) {
      return (sales / receipts).toDouble();
    }
    return 0;
  }

  String _formatDisplayDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}