import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // تقرير الإيرادات الشهرية
  Future<Map<String, dynamic>> getMonthlyRevenueReport(int year) async {
    try {
      final invoicesQuery = await _firestore
          .collection('invoices')
          .where('status', isEqualTo: 'paid')
          .get();

      Map<String, double> monthlyRevenue = {};
      Map<String, int> monthlyCustomers = {};
      
      // تهيئة جميع الأشهر
      for (int month = 1; month <= 12; month++) {
        String monthKey = '$year-${month.toString().padLeft(2, '0')}';
        monthlyRevenue[monthKey] = 0.0;
        monthlyCustomers[monthKey] = 0;
      }

      for (var doc in invoicesQuery.docs) {
        final invoice = doc.data();
        final issueDate = (invoice['issueDate'] as Timestamp).toDate();
        
        if (issueDate.year == year) {
          String monthKey = DateFormat('yyyy-MM').format(issueDate);
          double amount = (invoice['totalAmount'] ?? 0).toDouble();
          
          monthlyRevenue.update(monthKey, (value) => value + amount, ifAbsent: () => amount);
          monthlyCustomers.update(monthKey, (value) => value + 1, ifAbsent: () => 1);
        }
      }

      return {
        'monthlyRevenue': monthlyRevenue,
        'monthlyCustomers': monthlyCustomers,
        'totalRevenue': monthlyRevenue.values.fold(0.0, (sum, value) => sum + value),
        'totalInvoices': monthlyCustomers.values.fold(0, (sum, value) => sum + value),
      };
    } catch (e) {
      throw Exception('فشل في生成 التقرير: $e');
    }
  }

  // تقرير استهلاك العملاء
  Future<List<Map<String, dynamic>>> getCustomerConsumptionReport() async {
    try {
      final customersQuery = await _firestore.collection('customers').get();
      final readingsQuery = await _firestore.collection('meter_readings').get();

      List<Map<String, dynamic>> report = [];
      
      for (var customerDoc in customersQuery.docs) {
        final customer = customerDoc.data();
        final customerReadings = readingsQuery.docs
            .where((reading) => reading.data()['customerId'] == customerDoc.id)
            .toList();

        double totalConsumption = customerReadings
            .fold(0.0, (sum, reading) => sum + (reading.data()['consumption'] ?? 0).toDouble());

        double totalAmount = customerReadings
            .fold(0.0, (sum, reading) => sum + (reading.data()['amount'] ?? 0).toDouble());

        report.add({
          'customerId': customerDoc.id,
          'customerName': customer['name'],
          'meterNumber': customer['meterNumber'],
          'totalConsumption': totalConsumption,
          'totalAmount': totalAmount,
          'readingCount': customerReadings.length,
          'lastReadingDate': customerReadings.isNotEmpty 
              ? (customerReadings.first.data()['readingDate'] as Timestamp).toDate()
              : null,
        });
      }

      // ترتيب حسب الاستهلاك (تنازلي)
      report.sort((a, b) => b['totalConsumption'].compareTo(a['totalConsumption']));
      
      return report;
    } catch (e) {
      throw Exception('فشل في生成 التقرير: $e');
    }
  }

  // تقرير الفواتير المتأخرة
  Future<List<Map<String, dynamic>>> getOverdueInvoicesReport() async {
    try {
      final invoicesQuery = await _firestore
          .collection('invoices')
          .where('status', isEqualTo: 'pending')
          .get();

      final now = DateTime.now();
      List<Map<String, dynamic>> overdueInvoices = [];

      for (var doc in invoicesQuery.docs) {
        final invoice = doc.data();
        final dueDate = (invoice['dueDate'] as Timestamp).toDate();
        
        if (dueDate.isBefore(now)) {
          final daysOverdue = now.difference(dueDate).inDays;
          
          overdueInvoices.add({
            'id': doc.id,
            'customerName': invoice['customerName'],
            'totalAmount': invoice['totalAmount'],
            'dueDate': dueDate,
            'daysOverdue': daysOverdue,
            'amount': invoice['totalAmount'],
          });
        }
      }

      // ترتيب حسب مدة التأخير (تنازلي)
      overdueInvoices.sort((a, b) => b['daysOverdue'].compareTo(a['daysOverdue']));
      
      return overdueInvoices;
    } catch (e) {
      throw Exception('فشل في生成 التقرير: $e');
    }
  }

  // إحصائيات سريعة لللوحة الرئيسية
  Future<Map<String, dynamic>> getQuickStats() async {
    try {
      final customersCount = (await _firestore.collection('customers').get()).size;
      final readingsCount = (await _firestore.collection('meter_readings').get()).size;
      final invoicesQuery = await _firestore.collection('invoices').get();

      double totalRevenue = 0;
      int pendingInvoices = 0;
      int overdueInvoices = 0;
      final now = DateTime.now();

      for (var doc in invoicesQuery.docs) {
        final invoice = doc.data();
        if (invoice['status'] == 'paid') {
          totalRevenue += (invoice['totalAmount'] ?? 0).toDouble();
        } else if (invoice['status'] == 'pending') {
          pendingInvoices++;
          final dueDate = (invoice['dueDate'] as Timestamp).toDate();
          if (dueDate.isBefore(now)) {
            overdueInvoices++;
          }
        }
      }

      return {
        'customersCount': customersCount,
        'readingsCount': readingsCount,
        'invoicesCount': invoicesQuery.size,
        'totalRevenue': totalRevenue,
        'pendingInvoices': pendingInvoices,
        'overdueInvoices': overdueInvoices,
        'paidInvoices': invoicesQuery.size - pendingInvoices,
      };
    } catch (e) {
      throw Exception('فشل في جلب الإحصائيات: $e');
    }
  }
}