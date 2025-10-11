import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إضافة عميل جديد
  Future<String> addCustomer(Map<String, dynamic> customerData) async {
    try {
      DocumentReference docRef = await _firestore.collection('customers').add({
        ...customerData,
        'createdAt': Timestamp.now(),
        'lastReading': 0.0,
        'lastReadingDate': null,
        'status': 'active',
      });
      return docRef.id;
    } catch (e) {
      throw Exception('فشل في إضافة العميل: $e');
    }
  }

  // جلب جميع العملاء
  Stream<List<Map<String, dynamic>>> getCustomers() {
    return _firestore
        .collection('customers')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // تحديث قراءة العميل الأخيرة
  Future<void> updateCustomerReading(String customerId, double newReading) async {
    try {
      await _firestore.collection('customers').doc(customerId).update({
        'lastReading': newReading,
        'lastReadingDate': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('فشل في تحديث القراءة: $e');
    }
  }
}