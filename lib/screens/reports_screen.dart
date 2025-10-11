import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/report_service.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedYear = DateTime.now().year;
  String _selectedReport = 'revenue';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('التقارير والإحصائيات'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildReportSelector(),
            SizedBox(height: 20),
            Expanded(
              child: _buildSelectedReport(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedReport,
                    items: [
                      DropdownMenuItem(value: 'revenue', child: Text('تقرير الإيرادات')),
                      DropdownMenuItem(value: 'consumption', child: Text('تقرير الاستهلاك')),
                      DropdownMenuItem(value: 'overdue', child: Text('الفواتير المتأخرة')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedReport = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'نوع التقرير',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  width: 120,
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    items: List.generate(5, (index) {
                      int year = DateTime.now().year - index;
                      return DropdownMenuItem(value: year, child: Text(year.toString()));
                    }),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'السنة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedReport() {
    switch (_selectedReport) {
      case 'revenue':
        return _buildRevenueReport();
      case 'consumption':
        return _buildConsumptionReport();
      case 'overdue':
        return _buildOverdueReport();
      default:
        return _buildRevenueReport();
    }
  }

  Widget _buildRevenueReport() {
    return FutureBuilder<Map<String, dynamic>>(
      future: Provider.of<ReportService>(context).getMonthlyRevenueReport(_selectedYear),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('خطأ في تحميل التقرير: ${snapshot.error}'));
        }

        final reportData = snapshot.data!;
        final monthlyRevenue = reportData['monthlyRevenue'] as Map<String, double>;

        // تحويل البيانات للرسم البياني
        List<ChartData> chartData = [];
        monthlyRevenue.forEach((month, revenue) {
          chartData.add(ChartData(month, revenue));
        });

        return SingleChildScrollView(
          child: Column(
            children: [
              Card(
                child: Container(
                  height: 300,
                  padding: EdgeInsets.all(16),
                  child: SfCartesianChart(
                    primaryXAxis: CategoryAxis(),
                    title: ChartTitle(text: 'الإيرادات الشهرية - $_selectedYear'),
                    legend: Legend(isVisible: true),
                    series: <ChartSeries<ChartData, String>>[
                      ColumnSeries<ChartData, String>(
                        dataSource: chartData,
                        xValueMapper: (ChartData data, _) => data.month,
                        yValueMapper: (ChartData data, _) => data.value,
                        name: 'الإيرادات',
                        color: Colors.blue,
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              _buildStatsGrid(reportData),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConsumptionReport() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Provider.of<ReportService>(context).getCustomerConsumptionReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('خطأ في تحميل التقرير'));
        }

        final reportData = snapshot.data!;

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أعلى 10 عملاء استهلاكاً',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: reportData.take(10).length,
                    itemBuilder: (context, index) {
                      final customer = reportData[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(customer['customerName']),
                        subtitle: Text('الاستهلاك: ${customer['totalConsumption']?.toStringAsFixed(2)} وحدة'),
                        trailing: Text('${customer['totalAmount']?.toStringAsFixed(2)} ريال'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverdueReport() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Provider.of<ReportService>(context).getOverdueInvoicesReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('خطأ في تحميل التقرير'));
        }

        final overdueInvoices = snapshot.data!;

        if (overdueInvoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 60, color: Colors.green),
                SizedBox(height: 16),
                Text('لا توجد فواتير متأخرة'),
              ],
            ),
          );
        }

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الفواتير المتأخرة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: overdueInvoices.length,
                    itemBuilder: (context, index) {
                      final invoice = overdueInvoices[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(Icons.warning, color: Colors.white),
                        ),
                        title: Text(invoice['customerName']),
                        subtitle: Text('متأخرة ${invoice['daysOverdue']} أيام'),
                        trailing: Text('${invoice['amount']?.toStringAsFixed(2)} ريال'),
                        tileColor: Colors.red[50],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard('إجمالي الإيرادات', '${stats['totalRevenue']?.toStringAsFixed(2)} ريال', Icons.attach_money, Colors.green),
        _buildStatCard('عدد الفواتير', '${stats['totalInvoices']}', Icons.receipt, Colors.blue),
        _buildStatCard('متوسط الفاتورة', '${(stats['totalRevenue'] / stats['totalInvoices']).toStringAsFixed(2)} ريال', Icons.analytics, Colors.orange),
        _buildStatCard('أعلى شهر', _getHighestMonth(stats['monthlyRevenue']), Icons.trending_up, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getHighestMonth(Map<String, double> monthlyRevenue) {
    if (monthlyRevenue.isEmpty) return '-';
    var highest = monthlyRevenue.entries.reduce((a, b) => a.value > b.value ? a : b);
    return highest.key;
  }
}

// نموذج بيانات الرسم البياني
class ChartData {
  final String month;
  final double value;

  ChartData(this.month, this.value);
}