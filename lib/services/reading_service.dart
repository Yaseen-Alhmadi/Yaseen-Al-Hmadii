import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ReadingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  ReadingService(this._authService);

  Future<void> addReading(Map<String, dynamic> readingData) async {
    try {
      // الحصول على userId من المستخدم المسجل حالياً
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('لا يوجد مستخدم مسجل دخول');
      }

      DocumentReference docRef =
          await _firestore.collection('meter_readings').add({
        ...readingData,
        'userId': userId,
        'createdAt': Timestamp.now(),
      });

      // إنشاء فاتورة تلقائية بعد إضافة القراءة
      await _createInvoiceForReading({
        ...readingData,
        'id': docRef.id,
        'userId': userId,
      });
    } catch (e) {
      throw Exception('فشل في إضافة القراءة: $e');
    }
  }

  // دالة مساعدة لإنشاء فاتورة
  Future<void> _createInvoiceForReading(
      Map<String, dynamic> readingData) async {
    try {
      await _firestore.collection('invoices').add({
        'customerId': readingData['customerId'],
        'customerName': readingData['customerName'],
        'meterReadingId': readingData['id'],
        'userId': readingData['userId'],
        'consumption': readingData['consumption'],
        'rate': readingData['rate'],
        'amount': readingData['amount'],
        'tax': (readingData['amount'] ?? 0) * 0.05, // ضريبة 5%
        'totalAmount': (readingData['amount'] ?? 0) * 1.05,
        'issueDate': Timestamp.now(),
        'dueDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 30))),
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      print('فشل في إنشاء الفاتورة: $e');
    }
  }

  /// جلب قراءات عميل معين - فقط إذا كان العميل نشط (غير محذوف)
  Stream<List<Map<String, dynamic>>> getCustomerReadings(
      String customerId) async* {
    // الحصول على userId من المستخدم المسجل حالياً
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      yield [];
      return;
    }

    await for (var snapshot in _firestore
        .collection('meter_readings')
        .where('customerId', isEqualTo: customerId)
        .where('userId', isEqualTo: userId)
        .orderBy('readingDate', descending: true)
        .snapshots()) {
      // التحقق من أن العميل نشط (غير محذوف)
      try {
        final customerDoc =
            await _firestore.collection('customers').doc(customerId).get();

        // إذا كان العميل محذوف أو غير موجود، نرجع قائمة فارغة
        if (!customerDoc.exists || (customerDoc.data()?['deleted'] ?? 0) == 1) {
          yield [];
          continue;
        }

        // العميل نشط، نرجع قراءاته
        yield snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
      } catch (e) {
        print('خطأ في التحقق من حالة العميل: $e');
        yield [];
      }
    }
  }

  /// جلب جميع القراءات - فقط للعملاء النشطين (غير المحذوفين)
  Stream<List<Map<String, dynamic>>> getAllReadings() async* {
    // الحصول على userId من المستخدم المسجل حالياً
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      yield [];
      return;
    }

    await for (var snapshot in _firestore
        .collection('meter_readings')
        .where('userId', isEqualTo: userId)
        .orderBy('readingDate', descending: true)
        .snapshots()) {
      try {
        // جلب جميع القراءات
        final allReadings = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();

        if (allReadings.isEmpty) {
          yield [];
          continue;
        }

        // استخراج معرفات العملاء الفريدة
        final customerIds = allReadings
            .map((reading) => reading['customerId'] as String?)
            .where((id) => id != null)
            .toSet()
            .cast<String>()
            .toList();

        if (customerIds.isEmpty) {
          yield [];
          continue;
        }

        // جلب حالة العملاء على دفعات (Firebase limit: 10 items per whereIn)
        final activeCustomerIds = <String>{};

        for (int i = 0; i < customerIds.length; i += 10) {
          final batch = customerIds.skip(i).take(10).toList();

          final customersSnapshot = await _firestore
              .collection('customers')
              .where(FieldPath.documentId, whereIn: batch)
              .get();

          // إضافة معرفات العملاء النشطين فقط
          for (var doc in customersSnapshot.docs) {
            final data = doc.data();
            if ((data['deleted'] ?? 0) == 0) {
              activeCustomerIds.add(doc.id);
            }
          }
        }

        // تصفية القراءات لتشمل فقط العملاء النشطين
        final filteredReadings = allReadings
            .where((reading) =>
                reading['customerId'] != null &&
                activeCustomerIds.contains(reading['customerId']))
            .toList();

        yield filteredReadings;
      } catch (e) {
        print('خطأ في تصفية القراءات: $e');
        yield [];
      }
    }
  }
}
