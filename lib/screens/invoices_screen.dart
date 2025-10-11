import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
//import '../models/invoice_model.dart';
import '../models/invoice_model.dart';
import 'invoice_details_screen.dart';
import '../services/invoice_service.dart';

class InvoicesScreen extends StatefulWidget {
  @override
  _InvoicesScreenState createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  String _filterStatus = 'all'; // all, pending, paid, overdue

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة الفواتير'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          _buildFilterDropdown(),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(),
          Expanded(
            child: _buildInvoicesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          _filterStatus = value;
        });
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(value: 'all', child: Text('جميع الفواتير')),
        PopupMenuItem(value: 'pending', child: Text('قيد الانتظار')),
        PopupMenuItem(value: 'paid', child: Text('مدفوعة')),
        PopupMenuItem(value: 'overdue', child: Text('متأخرة')),
      ],
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(Icons.filter_list),
            SizedBox(width: 4),
            Text('تصفية'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: Provider.of<InvoiceService>(context).getInvoiceStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final stats = snapshot.data!;
        return Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                    'الإيرادات',
                    '${stats['totalRevenue']?.toStringAsFixed(2) ?? '0'} ريال',
                    Colors.green),
                _buildStatItem(
                    'المعلقة', '${stats['pendingCount']}', Colors.orange),
                _buildStatItem(
                    'المدفوعة', '${stats['paidCount']}', Colors.blue),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInvoicesList() {
    return StreamBuilder<List<Invoice>>(
      stream: Provider.of<InvoiceService>(context).getAllInvoices(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('خطأ في تحميل الفواتير'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final invoices = snapshot.data ?? [];
        final filteredInvoices = _filterInvoices(invoices);

        if (filteredInvoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا توجد فواتير'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredInvoices.length,
          itemBuilder: (context, index) {
            return _buildInvoiceCard(filteredInvoices[index]);
          },
        );
      },
    );
  }

  List<Invoice> _filterInvoices(List<Invoice> invoices) {
    switch (_filterStatus) {
      case 'pending':
        return invoices
            .where((invoice) => invoice.status == 'pending')
            .toList();
      case 'paid':
        return invoices.where((invoice) => invoice.status == 'paid').toList();
      case 'overdue':
        return invoices.where((invoice) => invoice.isOverdue).toList();
      default:
        return invoices;
    }
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _buildStatusIcon(invoice),
        title: Text(
          invoice.customerName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المبلغ: ${invoice.totalAmount.toStringAsFixed(2)} ريال'),
            Text('الاستهلاك: ${invoice.consumption.toStringAsFixed(2)} وحدة'),
            Text('تاريخ الإصدار: ${_formatDate(invoice.issueDate)}'),
            if (invoice.status == 'pending')
              Text(
                'موعد الاستحقاق: ${invoice.daysUntilDue} أيام',
                style: TextStyle(
                  color: invoice.isOverdue ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${invoice.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'ريال',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceDetailsScreen(invoice: invoice),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon(Invoice invoice) {
    Color color;
    IconData icon;

    switch (invoice.status) {
      case 'paid':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'pending':
        if (invoice.isOverdue) {
          color = Colors.red;
          icon = Icons.warning;
        } else {
          color = Colors.orange;
          icon = Icons.pending;
        }
        break;
      default:
        color = Colors.grey;
        icon = Icons.receipt;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }
}
