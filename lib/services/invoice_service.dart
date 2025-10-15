import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';
import 'auth_service.dart';

class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  InvoiceService(this._authService);

  /// إنشاء فاتورة تلقائية من قراءة العداد
  Future<String> createInvoiceFromReading(
      Map<String, dynamic> readingData) async {
    try {
      // الحصول على userId من المستخدم المسجل حالياً
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('لا يوجد مستخدم مسجل دخول');
      }

      // حساب الضريبة (5%)
      const double taxRate = 0.05;
      final double tax = (readingData['amount'] ?? 0) * taxRate;
      final double totalAmount = (readingData['amount'] ?? 0) + tax;

      // تاريخ الاستحقاق (شهر من تاريخ الإصدار)
      final DateTime dueDate = DateTime.now().add(const Duration(days: 30));

      final Map<String, dynamic> invoiceData = {
        'userId': userId,
        'customerId': readingData['customerId'],
        'customerName': readingData['customerName'],
        'meterReadingId': readingData['id'],
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

      final DocumentReference<Object?> docRef =
          await _firestore.collection('invoices').add(invoiceData);
      return docRef.id;
    } catch (e) {
      throw Exception('فشل في إنشاء الفاتورة: $e');
    }
  }

  /// جلب فواتير العميل (فقط إذا كان العميل غير محذوف)
  Stream<List<Invoice>> getCustomerInvoices(String customerId) async* {
    // الحصول على userId من المستخدم المسجل حالياً
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      yield [];
      return;
    }

    await for (final invoiceSnapshot in _firestore
        .collection('invoices')
        .where('customerId', isEqualTo: customerId)
        .where('userId', isEqualTo: userId)
        .orderBy('issueDate', descending: true)
        .snapshots()) {
      // التحقق من أن العميل غير محذوف
      final customerDoc =
          await _firestore.collection('customers').doc(customerId).get();

      if (!customerDoc.exists) {
        yield [];
        continue;
      }

      final customerData = customerDoc.data();
      final deleted = customerData?['deleted'] ?? 0;

      // إذا كان العميل محذوفاً، لا نعرض فواتيره
      if (deleted != 0) {
        yield [];
        continue;
      }

      // إذا كان العميل نشطاً، نعرض فواتيره
      final invoices = invoiceSnapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              Invoice.fromMap(doc.data(), doc.id))
          .toList();

      yield invoices;
    }
  }

  /// جلب جميع الفواتير (فقط للعملاء غير المحذوفين)
  Stream<List<Invoice>> getAllInvoices() async* {
    // الحصول على userId من المستخدم المسجل حالياً
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      yield [];
      return;
    }

    await for (final invoiceSnapshot in _firestore
        .collection('invoices')
        .where('userId', isEqualTo: userId)
        .orderBy('issueDate', descending: true)
        .snapshots()) {
      // جلب جميع الفواتير
      final allInvoices = invoiceSnapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              Invoice.fromMap(doc.data(), doc.id))
          .toList();

      // جلب معلومات العملاء للتحقق من حالة الحذف
      final customerIds =
          allInvoices.map((invoice) => invoice.customerId).toSet().toList();

      if (customerIds.isEmpty) {
        yield [];
        continue;
      }

      // جلب العملاء من Firebase (بحد أقصى 10 في كل استعلام)
      final Set<String> activeCustomerIds = {};

      // تقسيم الاستعلامات إلى مجموعات من 10 (حد Firebase)
      for (int i = 0; i < customerIds.length; i += 10) {
        final batch = customerIds.skip(i).take(10).toList();
        final customersSnapshot = await _firestore
            .collection('customers')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        // إضافة IDs العملاء غير المحذوفين
        for (final doc in customersSnapshot.docs) {
          final data = doc.data();
          final deleted = data['deleted'] ?? 0;
          if (deleted == 0) {
            activeCustomerIds.add(doc.id);
          }
        }
      }

      // تصفية الفواتير لإظهار فقط فواتير العملاء غير المحذوفين
      final filteredInvoices = allInvoices
          .where((invoice) => activeCustomerIds.contains(invoice.customerId))
          .toList();

      yield filteredInvoices;
    }
  }

  /// تحديث حالة الفاتورة
  Future<void> updateInvoiceStatus(
    String invoiceId,
    String status, {
    String? paymentMethod,
  }) async {
    try {
      final Map<String, dynamic> updates = {
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

  /// جلب إحصائيات الفواتير (فقط للعملاء غير المحذوفين)
  Future<Map<String, dynamic>> getInvoiceStats() async {
    try {
      // الحصول على userId من المستخدم المسجل حالياً
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('لا يوجد مستخدم مسجل دخول');
      }

      // جلب جميع الفواتير
      final QuerySnapshot<Map<String, dynamic>> invoicesQuery = await _firestore
          .collection('invoices')
          .where('userId', isEqualTo: userId)
          .get();
      final List<Invoice> allInvoices = invoicesQuery.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              Invoice.fromMap(doc.data(), doc.id))
          .toList();

      // جلب معلومات العملاء للتحقق من حالة الحذف
      final customerIds =
          allInvoices.map((invoice) => invoice.customerId).toSet().toList();

      if (customerIds.isEmpty) {
        return <String, dynamic>{
          'totalRevenue': 0.0,
          'pendingAmount': 0.0,
          'pendingCount': 0,
          'paidCount': 0,
          'overdueCount': 0,
          'totalCount': 0,
        };
      }

      // جلب العملاء من Firebase (بحد أقصى 10 في كل استعلام)
      final Set<String> activeCustomerIds = {};

      // تقسيم الاستعلامات إلى مجموعات من 10 (حد Firebase)
      for (int i = 0; i < customerIds.length; i += 10) {
        final batch = customerIds.skip(i).take(10).toList();
        final customersSnapshot = await _firestore
            .collection('customers')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        // إضافة IDs العملاء غير المحذوفين
        for (final doc in customersSnapshot.docs) {
          final data = doc.data();
          final deleted = data['deleted'] ?? 0;
          if (deleted == 0) {
            activeCustomerIds.add(doc.id);
          }
        }
      }

      // تصفية الفواتير لإظهار فقط فواتير العملاء غير المحذوفين
      final invoices = allInvoices
          .where((invoice) => activeCustomerIds.contains(invoice.customerId))
          .toList();

      double totalRevenue = 0;
      double pendingAmount = 0;
      int pendingCount = 0;
      int paidCount = 0;
      int overdueCount = 0;

      for (final Invoice invoice in invoices) {
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

      return <String, dynamic>{
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
