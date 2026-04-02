import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/kpi_card.dart';
import '../widgets/hourly_chart.dart';
import '../widgets/sales_chart.dart';
import '../widgets/branch_selector.dart';
import '../widgets/brand_selector.dart';
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
      provider.loadInitialData();
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
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(provider.translate('dashboard')),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: provider.toggleLocale,
                child: Text(
                  provider.isLao ? 'EN' : 'ລາວ',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') provider.logout();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: Colors.black54),
                        const SizedBox(width: 8),
                        Text(provider.translate('logout')),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.isLoading ? null : provider.refresh,
              ),
            ],
          ),
          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(DashboardProvider provider) {
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
            BrandSelector(
              brands: provider.brands,
              selectedBrandId: provider.selectedBrandId,
              onBrandSelected: provider.switchBrand,
            ),
            BranchSelector(
              branches: provider.branches,
              selectedBranchCode: provider.selectedBranchCode,
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
              _buildComparisonView(provider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonView(DashboardProvider provider) {
    return Column(
      children: [
        KPIComparisonCard(
          branchData: provider.filteredBranches.map((branch) {
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
            Text(provider.error ?? 'Unknown error', textAlign: TextAlign.center),
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
              onPressed: () {}, // TODO: Implement prev day
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
                          .map((date) => SimpleDialogOption(
                                onPressed: () => Navigator.pop(context, date),
                                child: Text(_formatDisplayDate(date)),
                              ))
                          .toList(),
                    ),
                  );
                  if (selected != null) await provider.loadData(selected);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      provider.selectedDate.isNotEmpty ? _formatDisplayDate(provider.selectedDate) : 'No Data',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: () {}, // TODO: Implement next day
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
        branch != null ? '${branch.displayWithCode} - ${_formatDisplayDate(date)}' : '${provider.currentSelectionDisplay} - ${_formatDisplayDate(date)}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildNoDataView(BuildContext context, DashboardProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No Data Available', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextButton.icon(onPressed: provider.refresh, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
        ],
      ),
    );
  }

  Widget _buildKPICards(BuildContext context, DashboardProvider provider) {
    final data = provider.dailySalesData;
    final avgTicket = _calculateAvgTicket(data);
    final receiptsGrowth = provider.getGrowthFor('receipt_count');
    final customersGrowth = provider.getGrowthFor('customer_count');
    final avgTicketGrowth = provider.getGrowthFor('net_sales');

    final netSalesExTax = (data?['net_sales_ex_tax'] is num) ? data!['net_sales_ex_tax'] : 0;
    final voidAmount = (data?['void_amount'] is num) ? data!['void_amount'] : 0;
    final netSales = (data?['net_sales'] is num) ? data!['net_sales'] : 1;
    final voidPercentage = (voidAmount / (netSales > 0 ? netSales : 1)) * 100;

    Color voidColor = Colors.green;
    if (voidPercentage > 3) voidColor = Colors.red;
    else if (voidPercentage >= 1) voidColor = Colors.orange;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.8,
      children: [
        KpiCard(
          title: provider.translate('sales_ex_tax'),
          value: _formatCurrency(netSalesExTax),
          icon: Icons.attach_money,
          color: Colors.indigo,
          growthPercentage: provider.getGrowthFor('net_sales_ex_tax'),
        ),
        KpiCard(
          title: provider.translate('receipts'),
          value: '${data?['receipt_count'] ?? 0}',
          icon: Icons.receipt_long,
          color: Colors.blue,
          growthPercentage: receiptsGrowth,
        ),
        KpiCard(
          title: provider.translate('customers'),
          value: '${data?['customer_count'] ?? 0}',
          icon: Icons.people,
          color: Colors.orange,
          growthPercentage: customersGrowth,
        ),
        KpiCard(
          title: provider.translate('avg_ticket'),
          value: _formatCurrency(avgTicket),
          icon: Icons.trending_up,
          color: Colors.purple,
          growthPercentage: avgTicketGrowth,
        ),
        KpiCard(
          title: provider.translate('discounts'),
          value: _formatCurrency(data?['discount_amount'] ?? 0),
          icon: Icons.local_offer,
          color: Colors.teal,
          growthPercentage: provider.getGrowthFor('discount_amount'),
        ),
        KpiCard(
          title: '${provider.translate('voids')} (${voidPercentage.toStringAsFixed(1)}%)',
          value: _formatCurrency(voidAmount),
          icon: Icons.cancel,
          color: voidColor,
          growthPercentage: provider.getGrowthFor('void_amount'),
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
          Text(provider.isLao ? 'ຍອດຂາຍຕາມຊົ່ວໂມງ' : 'Sales by Hour', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(height: 150, child: provider.hourlyData.isNotEmpty ? HourlyChart(hourlyData: provider.hourlyData) : const Center(child: Text('No data'))),
        ],
      ),
    );
  }

  Widget _buildSalesMixChart(BuildContext context, DashboardProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.translate('food_vs_bev'), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SizedBox(height: 180, child: provider.salesMixData.isNotEmpty ? SalesMixPieChart(salesMixData: provider.salesMixData) : const Center(child: Text('No data'))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.translate('dine_in_vs_takeaway'), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SizedBox(height: 180, child: provider.dineInVsTakeawayData.isNotEmpty ? SalesMixPieChart(salesMixData: provider.dineInVsTakeawayData) : const Center(child: Text('No data'))),
              ],
            ),
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
          Text(provider.translate('top_products'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...provider.productData.take(5).map((product) {
            final name = provider.isLao && product['product_name_lao'] != null ? product['product_name_lao'] : (product['product_name_en'] ?? product['product_name_th']);
            return Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                dense: true,
                title: Text(name, style: const TextStyle(fontSize: 14)),
                trailing: Text(_formatCurrency(product['total_amount'] ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    final value = (amount is num ? amount : 0).toDouble();
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M ₭';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K ₭';
    return '$value ₭';
  }

  double _calculateAvgTicket(Map<String, dynamic>? data) {
    final receipts = data?['receipt_count'] ?? 0;
    final sales = data?['net_sales'] ?? 0;
    return receipts > 0 ? (sales / receipts).toDouble() : 0;
  }

  String _formatDisplayDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) { return dateStr; }
  }
}
