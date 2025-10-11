import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addReading(Map<String, dynamic> readingData) async {
    try {
      DocumentReference docRef = await _firestore.collection('meter_readings').add({
        ...readingData,
        'createdAt': Timestamp.now(),
      });

      // إنشاء فاتورة تلقائية بعد إضافة القراءة
      await _createInvoiceForReading({
        ...readingData,
        'id': docRef.id,
      });

    } catch (e) {
      throw Exception('فشل في إضافة القراءة: $e');
    }
  }

  // دالة مساعدة لإنشاء فاتورة
  Future<void> _createInvoiceForReading(Map<String, dynamic> readingData) async {
    try {
      await _firestore.collection('invoices').add({
        'customerId': readingData['customerId'],
        'customerName': readingData['customerName'],
        'meterReadingId': readingData['id'],
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

  Stream<List<Map<String, dynamic>>> getCustomerReadings(String customerId) {
    return _firestore
        .collection('meter_readings')
        .where('customerId', isEqualTo: customerId)
        .orderBy('readingDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  Stream<List<Map<String, dynamic>>> getAllReadings() {
    return _firestore
        .collection('meter_readings')
        .orderBy('readingDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }
}