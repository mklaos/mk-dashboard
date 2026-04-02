import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/brand_selector.dart';
import '../widgets/branch_selector.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DashboardProvider>(context, listen: false);
      provider.loadTrends();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(provider.translate('trends')),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: provider.toggleLocale,
                child: Text(
                  provider.isLao ? 'EN' : 'ລາວ',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(DashboardProvider provider) {
    if (provider.isLoading && provider.dailyTrendData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandSelector(
            brands: provider.brands,
            selectedBrandId: provider.selectedBrandId,
            onBrandSelected: (id) {
              provider.switchBrand(id);
              provider.loadTrends();
            },
          ),
          BrandSelector(
            brands: provider.brands,
            selectedBrandId: provider.selectedBrandId,
            onBrandSelected: (id) {
              provider.switchBrand(id);
              provider.loadTrends();
            },
          ),
          BranchSelector(
            branches: provider.branches,
            selectedBranchCode: provider.selectedBranchCode,
            onBranchSelected: (code) {
              provider.switchBranch(code);
              provider.loadTrends();
            },
          ),
          const SizedBox(height: 20),
          _buildTrendSection(
            context,
            provider.isLao ? 'ຍອດຂາຍປະຈໍາວັນ (30 ວັນ)' : 'Daily Sales Trend (Last 30 Days)',
            provider.dailyTrendData,
            'sale_date',
          ),
          const SizedBox(height: 24),
          _buildTrendSection(
            context,
            provider.isLao ? 'ຍອດຂາຍປະຈໍາມີ (6 ເດືອນ)' : 'Monthly Sales Trend (Last 6 Months)',
            provider.monthlyTrendData,
            'month',
          ),
          const SizedBox(height: 24),
          _buildTrendSection(
            context,
            provider.isLao ? 'ຍອດຂາຍປະຈໍາປີ (3 ປີ)' : 'Yearly Sales Trend (Last 3 Years)',
            provider.yearlyTrendData,
            'year',
          ),
        ],
      ),
    );
  }

  Widget _buildTrendSection(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> data,
    String labelKey,
  ) {
    if (data.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const SizedBox(height: 200, child: Center(child: Text('No data available'))),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          height: 220,
          padding: const EdgeInsets.only(right: 16, top: 12, bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) return const SizedBox.shrink();
                      if (data.length > 7 && index % (data.length ~/ 4) != 0) return const SizedBox.shrink();
                      
                      final label = data[index][labelKey].toString();
                      final displayLabel = label.length > 5 ? label.substring(label.length - 5) : label;
                      
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(displayLabel, style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), (e.value['net_sales'] as num).toDouble());
                  }).toList(),
                  isCurved: true,
                  color: Theme.of(context).primaryColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
