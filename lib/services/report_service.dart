import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'auth_service.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // تقرير الإيرادات الشهرية
  Future<Map<String, dynamic>> getMonthlyRevenueReport(int year) async {
    try {
      // الحصول على userId للمستخدم الحالي
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        debugPrint('❌ [ReportService] لا يوجد مستخدم مسجل دخول');
        return {
          'monthlyRevenue': <String, double>{},
          'monthlyCustomers': <String, int>{},
          'totalRevenue': 0.0,
          'totalInvoices': 0,
        };
      }

      debugPrint('📊 [ReportService] جلب تقرير الإيرادات للمستخدم: $userId');

      final invoicesQuery = await _firestore
          .collection('invoices')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'paid')
          .get();

      debugPrint(
          '📥 [ReportService] تم جلب ${invoicesQuery.docs.length} فاتورة مدفوعة');

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

          monthlyRevenue.update(monthKey, (value) => value + amount,
              ifAbsent: () => amount);
          monthlyCustomers.update(monthKey, (value) => value + 1,
              ifAbsent: () => 1);
        }
      }

      final totalRevenue =
          monthlyRevenue.values.fold(0.0, (sum, value) => sum + value);
      final totalInvoices =
          monthlyCustomers.values.fold(0, (sum, value) => sum + value);

      debugPrint(
          '✅ [ReportService] إجمالي الإيرادات: $totalRevenue، عدد الفواتير: $totalInvoices');

      return {
        'monthlyRevenue': monthlyRevenue,
        'monthlyCustomers': monthlyCustomers,
        'totalRevenue': totalRevenue,
        'totalInvoices': totalInvoices,
      };
    } catch (e) {
      debugPrint('❌ [ReportService] خطأ في تقرير الإيرادات: $e');
      throw Exception('فشل في إنشاء التقرير: $e');
    }
  }

  // تقرير استهلاك العملاء
  Future<List<Map<String, dynamic>>> getCustomerConsumptionReport() async {
    try {
      // الحصول على userId للمستخدم الحالي
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        debugPrint('❌ [ReportService] لا يوجد مستخدم مسجل دخول');
        return [];
      }

      debugPrint('📊 [ReportService] جلب تقرير الاستهلاك للمستخدم: $userId');

      final customersQuery = await _firestore
          .collection('customers')
          .where('userId', isEqualTo: userId)
          .get();

      final readingsQuery = await _firestore
          .collection('meter_readings')
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint(
          '📥 [ReportService] تم جلب ${customersQuery.docs.length} عميل و ${readingsQuery.docs.length} قراءة');

      List<Map<String, dynamic>> report = [];

      for (var customerDoc in customersQuery.docs) {
        final customer = customerDoc.data();
        final customerReadings = readingsQuery.docs
            .where((reading) => reading.data()['customerId'] == customerDoc.id)
            .toList();

        double totalConsumption = customerReadings.fold(
            0.0,
            (sum, reading) =>
                sum + (reading.data()['consumption'] ?? 0).toDouble());

        double totalAmount = customerReadings.fold(0.0,
            (sum, reading) => sum + (reading.data()['amount'] ?? 0).toDouble());

        report.add({
          'customerId': customerDoc.id,
          'customerName': customer['name'],
          'meterNumber': customer['meterNumber'],
          'totalConsumption': totalConsumption,
          'totalAmount': totalAmount,
          'readingCount': customerReadings.length,
          'lastReadingDate': customerReadings.isNotEmpty
              ? (customerReadings.first.data()['readingDate'] as Timestamp)
                  .toDate()
              : null,
        });
      }

      // ترتيب حسب الاستهلاك (تنازلي)
      report.sort(
          (a, b) => b['totalConsumption'].compareTo(a['totalConsumption']));

      debugPrint(
          '✅ [ReportService] تم إنشاء تقرير الاستهلاك لـ ${report.length} عميل');

      return report;
    } catch (e) {
      debugPrint('❌ [ReportService] خطأ في تقرير الاستهلاك: $e');
      throw Exception('فشل في إنشاء التقرير: $e');
    }
  }

  // تقرير الفواتير المتأخرة
  Future<List<Map<String, dynamic>>> getOverdueInvoicesReport() async {
    try {
      // الحصول على userId للمستخدم الحالي
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        debugPrint('❌ [ReportService] لا يوجد مستخدم مسجل دخول');
        return [];
      }

      debugPrint(
          '📊 [ReportService] جلب تقرير الفواتير المتأخرة للمستخدم: $userId');

      final invoicesQuery = await _firestore
          .collection('invoices')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      debugPrint(
          '📥 [ReportService] تم جلب ${invoicesQuery.docs.length} فاتورة معلقة');

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
      overdueInvoices
          .sort((a, b) => b['daysOverdue'].compareTo(a['daysOverdue']));

      debugPrint(
          '✅ [ReportService] تم العثور على ${overdueInvoices.length} فاتورة متأخرة');

      return overdueInvoices;
    } catch (e) {
      debugPrint('❌ [ReportService] خطأ في تقرير الفواتير المتأخرة: $e');
      throw Exception('فشل في إنشاء التقرير: $e');
    }
  }

  // إحصائيات سريعة لللوحة الرئيسية
  Future<Map<String, dynamic>> getQuickStats() async {
    try {
      // الحصول على userId للمستخدم الحالي
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        debugPrint('❌ [ReportService] لا يوجد مستخدم مسجل دخول');
        return {
          'customersCount': 0,
          'readingsCount': 0,
          'invoicesCount': 0,
          'totalRevenue': 0.0,
          'pendingInvoices': 0,
          'overdueInvoices': 0,
          'paidInvoices': 0,
        };
      }

      debugPrint('📊 [ReportService] جلب الإحصائيات السريعة للمستخدم: $userId');

      final customersCount = (await _firestore
              .collection('customers')
              .where('userId', isEqualTo: userId)
              .get())
          .size;

      final readingsCount = (await _firestore
              .collection('meter_readings')
              .where('userId', isEqualTo: userId)
              .get())
          .size;

      final invoicesQuery = await _firestore
          .collection('invoices')
          .where('userId', isEqualTo: userId)
          .get();

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

      debugPrint(
          '✅ [ReportService] الإحصائيات: عملاء=$customersCount، قراءات=$readingsCount، فواتير=${invoicesQuery.size}');

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
      debugPrint('❌ [ReportService] خطأ في جلب الإحصائيات: $e');
      throw Exception('فشل في جلب الإحصائيات: $e');
    }
  }
}
