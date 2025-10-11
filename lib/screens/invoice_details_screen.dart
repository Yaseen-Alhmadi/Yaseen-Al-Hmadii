import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';
import '../services/invoice_service.dart';
//import '../services/invoice_service.dart';

class InvoiceDetailsScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailsScreen({Key? key, required this.invoice})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل الفاتورة'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInvoiceHeader(),
            SizedBox(height: 20),
            _buildInvoiceDetails(),
            Spacer(),
            if (invoice.status == 'pending') _buildPaymentButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'فاتورة استهلاك المياه',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'العميل: ${invoice.customerName}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 5),
            Text(
              'رقم الفاتورة: ${invoice.id.substring(0, 8)}',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceDetails() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Table(
          columnWidths: {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
          },
          children: [
            _buildTableRow(
                'الاستهلاك (وحدة)', invoice.consumption.toStringAsFixed(2)),
            _buildTableRow(
                'سعر الوحدة (ريال)', invoice.rate.toStringAsFixed(2)),
            _buildTableRow(
                'المبلغ الإجمالي', invoice.amount.toStringAsFixed(2)),
            _buildTableRow('الضريبة (5%)', invoice.tax.toStringAsFixed(2)),
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'المبلغ النهائي',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '${invoice.totalAmount.toStringAsFixed(2)} ريال',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue),
                  ),
                ),
              ],
            ),
            _buildTableRow('تاريخ الإصدار', _formatDate(invoice.issueDate)),
            _buildTableRow('موعد الاستحقاق', _formatDate(invoice.dueDate)),
            _buildTableRow('الحالة', _getStatusText(invoice.status)),
            if (invoice.paymentDate != null)
              _buildTableRow('تاريخ الدفع', _formatDate(invoice.paymentDate!)),
            if (invoice.paymentMethod != null)
              _buildTableRow('طريقة الدفع', invoice.paymentMethod!),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(label),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildPaymentButtons() {
    return Builder(
      builder: (context) => Column(
        children: [
          Divider(),
          SizedBox(height: 10),
          Text(
            'دفع الفاتورة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _processPayment(context, 'نقدي'),
                  icon: Icon(Icons.money),
                  label: Text('دفع نقدي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _processPayment(context, 'بطاقة ائتمان'),
                  icon: Icon(Icons.credit_card),
                  label: Text('بطاقة ائتمان'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => _processPayment(context, 'محفظة إلكترونية'),
            icon: Icon(Icons.wallet),
            label: Text('محفظة إلكترونية'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment(BuildContext context, String paymentMethod) async {
    try {
      await Provider.of<InvoiceService>(context, listen: false)
          .updateInvoiceStatus(invoice.id, 'paid',
              paymentMethod: paymentMethod);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم دفع الفاتورة بنجاح باستخدام $paymentMethod'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في عملية الدفع: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'paid':
        return 'مدفوعة';
      case 'overdue':
        return 'متأخرة';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }
}
