import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';
import '../services/auth_service.dart';

class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  InvoiceService(this._authService);

  // إنشاء فاتورة تلقائية من قراءة العداد
  Future<String> createInvoiceFromReading(
      Map<String, dynamic> readingData) async {
    try {
      // الحصول على userId من المستخدم المسجل حالياً
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('لا يوجد مستخدم مسجل دخول');
      }

      // حساب الضريبة (5%)
      double taxRate = 0.05;
      double tax = (readingData['amount'] ?? 0) * taxRate;
      double totalAmount = (readingData['amount'] ?? 0) + tax;

      // تاريخ الاستحقاق (شهر من تاريخ الإصدار)
      DateTime dueDate = DateTime.now().add(Duration(days: 30));

      final invoiceData = {
        'customerId': readingData['customerId'],
        'customerName': readingData['customerName'],
        'meterReadingId': readingData['id'],
        'userId': userId,
        'consumption': readingData['consumption'],
        'rate': readingData['rate'],
        'amount': readingData['amount'],
        'tax': tax,
        'totalAmount': totalAmount,
        'issueDate': Timestamp.now(),
        'dueDate': Timestamp.fromDate(dueDate),
        'status': 'pending',
        'createdAt': Timestamp.now(),
      };

      DocumentReference docRef =
          await _firestore.collection('invoices').add(invoiceData);
      return docRef.id;
    } catch (e) {
      throw Exception('فشل في إنشاء الفاتورة: $e');
    }
  }

  // جلب فواتير العميل
  Stream<List<Invoice>> getCustomerInvoices(String customerId) async* {
    // الحصول على userId من المستخدم المسجل حالياً
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      yield [];
      return;
    }

    await for (var snapshot in _firestore
        .collection('invoices')
        .where('customerId', isEqualTo: customerId)
        .where('userId', isEqualTo: userId)
        .orderBy('issueDate', descending: true)
        .snapshots()) {
      yield snapshot.docs
          .map((doc) => Invoice.fromMap(doc.data(), doc.id))
          .toList();
    }
  }

  // جلب جميع الفواتير
  Stream<List<Invoice>> getAllInvoices() async* {
    // الحصول على userId من المستخدم المسجل حالياً
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      yield [];
      return;
    }

    await for (var snapshot in _firestore
        .collection('invoices')
        .where('userId', isEqualTo: userId)
        .orderBy('issueDate', descending: true)
        .snapshots()) {
      yield snapshot.docs
          .map((doc) => Invoice.fromMap(doc.data(), doc.id))
          .toList();
    }
  }

  // تحديث حالة الفاتورة
  Future<void> updateInvoiceStatus(String invoiceId, String status,
      {String? paymentMethod}) async {
    try {
      Map<String, dynamic> updates = {
        'status': status,
      };

      if (status == 'paid') {
        updates['paymentDate'] = Timestamp.now();
        updates['paymentMethod'] = paymentMethod ?? 'نقدي';
      }

      await _firestore.collection('invoices').doc(invoiceId).update(updates);
    } catch (e) {
      throw Exception('فشل في تحديث الفاتورة: $e');
    }
  }

  // جلب إحصائيات الفواتير
  Future<Map<String, dynamic>> getInvoiceStats() async {
    try {
      // الحصول على userId من المستخدم المسجل حالياً
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('لا يوجد مستخدم مسجل دخول');
      }

      final query = await _firestore
          .collection('invoices')
          .where('userId', isEqualTo: userId)
          .get();
      final invoices =
          query.docs.map((doc) => Invoice.fromMap(doc.data(), doc.id)).toList();

      double totalRevenue = 0;
      double pendingAmount = 0;
      int pendingCount = 0;
      int paidCount = 0;
      int overdueCount = 0;

      for (var invoice in invoices) {
        if (invoice.status == 'paid') {
          totalRevenue += invoice.totalAmount;
          paidCount++;
        } else if (invoice.status == 'pending') {
          pendingAmount += invoice.totalAmount;
          pendingCount++;
          if (invoice.isOverdue) {
            overdueCount++;
          }
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'pendingAmount': pendingAmount,
        'pendingCount': pendingCount,
        'paidCount': paidCount,
        'overdueCount': overdueCount,
        'totalCount': invoices.length,
      };
    } catch (e) {
      throw Exception('فشل في جلب الإحصائيات: $e');
    }
  }
}
