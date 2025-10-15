import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_helper.dart';
import 'auth_service.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AuthService _authService;

  CustomerService(this._authService);

  // إضافة عميل جديد
  Future<String> addCustomer(Map<String, dynamic> customerData) async {
    try {
      // الحصول على userId من المستخدم المسجل حالياً
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('لا يوجد مستخدم مسجل دخول');
      }

      DocumentReference docRef = await _firestore.collection('customers').add({
        ...customerData,
        'userId': userId,
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
  Stream<List<Map<String, dynamic>>> getCustomers() async* {
    // الحصول على userId من المستخدم المسجل حالياً
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      yield [];
      return;
    }

    await for (var snapshot in _firestore
        .collection('customers')
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .snapshots()) {
      yield snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    }
  }

  // تحديث قراءة العميل الأخيرة
  Future<void> updateCustomerReading(
      String customerId, double newReading) async {
    try {
      await _firestore.collection('customers').doc(customerId).update({
        'lastReading': newReading,
        'lastReadingDate': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('فشل في تحديث القراءة: $e');
    }
  }

  // ===== دوال قاعدة البيانات المحلية =====

  // إضافة عميل جديد محليًا
  Future<String> addCustomerLocal(Map<String, dynamic> customerData) async {
    try {
      String id = DateTime.now().millisecondsSinceEpoch.toString(); // ID بسيط
      Map<String, dynamic> data = {
        'id': id,
        ...customerData,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _dbHelper.insert('customers', data);
      return id;
    } catch (e) {
      throw Exception('فشل في إضافة العميل محليًا: $e');
    }
  }

  // جلب جميع العملاء محليًا
  Future<List<Map<String, dynamic>>> getCustomersLocal() async {
    try {
      return await _dbHelper.queryAllRows('customers');
    } catch (e) {
      throw Exception('فشل في جلب العملاء محليًا: $e');
    }
  }

  // تحديث قراءة العميل محليًا
  Future<void> updateCustomerReadingLocal(
      String customerId, double newReading) async {
    try {
      await _dbHelper.update(
        'customers',
        {
          'lastReading': newReading,
          'lastReadingDate': DateTime.now().toIso8601String()
        },
        'id = ?',
        [customerId],
      );
    } catch (e) {
      throw Exception('فشل في تحديث القراءة محليًا: $e');
    }
  }
}
