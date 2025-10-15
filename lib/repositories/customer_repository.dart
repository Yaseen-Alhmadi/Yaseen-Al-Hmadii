import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';

class CustomerRepository {
  CustomerRepository({
    DatabaseHelper? dbHelper,
    FirebaseFirestore? firestore,
    Connectivity? connectivity,
    AuthService? authService,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity ?? Connectivity(),
        _authService = authService ?? AuthService();

  final DatabaseHelper _dbHelper;
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;
  final AuthService _authService;

  final _syncController = StreamController<void>.broadcast();
  final _customersController = StreamController<List<Customer>>.broadcast();
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;

  Stream<void> get syncStream => _syncController.stream;

  /// Stream للاستماع لتحديثات العملاء من القاعدة المحلية
  Stream<List<Customer>> get customersStream async* {
    // إرسال البيانات الأولية
    yield await getCustomers();

    // الاستماع للتحديثات
    await for (final _ in _syncController.stream) {
      yield await getCustomers();
    }
  }

  /// الحصول على جميع العملاء من القاعدة المحلية (للمستخدم الحالي فقط)
  Future<List<Customer>> getCustomers() async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) return [];

    final rows = await _dbHelper.queryRows(
      'customers',
      'userId = ? AND deleted = ?',
      [userId, 0],
    );
    return rows.map((row) => Customer.fromMap(row)).toList();
  }

  /// الحصول على عميل واحد بواسطة ID (للمستخدم الحالي فقط)
  Future<Customer?> getCustomerById(String id) async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) return null;

    final rows = await _dbHelper.queryRows(
      'customers',
      'id = ? AND userId = ? AND deleted = ?',
      [id, userId, 0],
    );
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  /// إضافة عميل جديد
  Future<void> addCustomer(Customer customer) async {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      throw Exception('لا يوجد مستخدم مسجل دخول');
    }

    final now = DateTime.now().toIso8601String();
    final data = customer.toMap()
      ..addAll({
        'userId': userId,
        'pendingSync': 1,
        'lastModified': now,
        'createdAt': customer.createdAt ?? now,
        'deleted': 0,
      });

    await _dbHelper.insert('customers', data);
    _syncController.add(null);
    await _trySync();
  }

  /// تحديث عميل موجود
  Future<void> updateCustomer(Customer customer) async {
    final now = DateTime.now().toIso8601String();
    final data = customer.toMap()
      ..addAll({
        'pendingSync': 1,
        'lastModified': now,
      });

    await _dbHelper.update(
      'customers',
      data,
      'id = ?',
      [customer.id],
    );
    _syncController.add(null);
    await _trySync();
  }

  /// حذف عميل (حذف منطقي)
  Future<void> deleteCustomer(String id) async {
    final now = DateTime.now().toIso8601String();

    await _dbHelper.update(
      'customers',
      {
        'pendingSync': 1,
        'lastModified': now,
        'deleted': 1,
      },
      'id = ?',
      [id],
    );
    _syncController.add(null);
    await _trySync();
  }

  /// محاولة المزامنة إذا كان هناك اتصال
  Future<void> _trySync() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final hasNetwork = connectivityResult != ConnectivityResult.none;

    if (!hasNetwork) return;

    await _pushLocalChanges();
  }

  /// رفع التغييرات المحلية إلى Firestore
  Future<void> _pushLocalChanges() async {
    try {
      final pendingRows = await _dbHelper.queryRows(
        'customers',
        'pendingSync = ?',
        [1],
      );

      for (final row in pendingRows) {
        final customer = Customer.fromMap(row);
        final docRef = _firestore.collection('customers').doc(customer.id);

        if (customer.deleted == 1) {
          // حذف من Firestore
          await docRef.delete();
        } else {
          // تحديث أو إضافة في Firestore
          await docRef.set(customer.toFirestore(), SetOptions(merge: true));
        }

        // تحديث حالة المزامنة محلياً
        await _dbHelper.update(
          'customers',
          {
            ...row,
            'pendingSync': 0,
            'lastSyncedAt': DateTime.now().toIso8601String(),
          },
          'id = ?',
          [customer.id],
        );
      }

      _syncController.add(null);
    } catch (e) {
      debugPrint('خطأ في رفع التغييرات: $e');
    }
  }

  /// سحب التغييرات من Firestore (مزامنة أولية)
  Future<void> pullRemoteChanges() async {
    try {
      debugPrint('🔄 [CustomerRepo] بدء سحب العملاء من Firestore...');

      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        debugPrint('❌ [CustomerRepo] لا يوجد مستخدم مسجل دخول');
        return;
      }

      final snapshot = await _firestore
          .collection('customers')
          .where('userId', isEqualTo: userId)
          .get();
      debugPrint(
          '📥 [CustomerRepo] تم جلب ${snapshot.docs.length} عميل من Firestore');

      for (final doc in snapshot.docs) {
        final remote = doc.data();
        remote['id'] = doc.id;

        // تحويل Timestamp إلى String
        remote['createdAt'] = _convertTimestampToString(remote['createdAt']);
        remote['lastModified'] =
            _convertTimestampToString(remote['lastModified']);
        remote['lastReadingDate'] =
            _convertTimestampToString(remote['lastReadingDate']);

        // التأكد من وجود userId
        if (remote['userId'] == null) {
          remote['userId'] = userId;
        }

        final localRows = await _dbHelper.queryRows(
          'customers',
          'id = ?',
          [doc.id],
        );

        if (localRows.isEmpty) {
          // إضافة سجل جديد من السحابة
          debugPrint(
              '➕ [CustomerRepo] إضافة عميل جديد: ${remote['name']} (${doc.id})');
          final cleanData = _cleanCustomerData({
            ...remote,
            'pendingSync': 0,
            'lastSyncedAt': DateTime.now().toIso8601String(),
            'deleted': remote['deleted'] ?? 0,
          });
          await _dbHelper.insert('customers', cleanData);
          continue;
        }

        final local = localRows.first;
        final isPending = local['pendingSync'] == 1;

        // إذا كان السجل المحلي في انتظار المزامنة، لا نستبدله
        if (isPending) continue;

        final localModified = local['lastModified'] != null
            ? DateTime.parse(local['lastModified'] as String)
            : DateTime(2000);

        final remoteModified = remote['lastModified'] != null
            ? DateTime.parse(remote['lastModified'] as String)
            : DateTime(2000);

        // تحديث إذا كان السجل السحابي أحدث
        if (remoteModified.isAfter(localModified)) {
          debugPrint(
              '🔄 [CustomerRepo] تحديث عميل: ${remote['name']} (${doc.id})');
          final cleanData = _cleanCustomerData({
            ...remote,
            'pendingSync': 0,
            'lastSyncedAt': DateTime.now().toIso8601String(),
          });
          await _dbHelper.update(
            'customers',
            cleanData,
            'id = ?',
            [doc.id],
          );
        } else {
          debugPrint(
              '⏭️ [CustomerRepo] تخطي عميل (محلي أحدث): ${remote['name']}');
        }
      }

      debugPrint('✅ [CustomerRepo] اكتملت مزامنة العملاء من Firestore');
      _syncController.add(null);
    } catch (e) {
      debugPrint('❌ [CustomerRepo] خطأ في سحب التغييرات: $e');
      rethrow;
    }
  }

  /// تحويل Timestamp إلى String
  String? _convertTimestampToString(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is String) return value;
    return null;
  }

  /// تنظيف البيانات من الحقول غير المدعومة
  Map<String, dynamic> _cleanCustomerData(Map<String, dynamic> data) {
    // قائمة الحقول المدعومة في جدول customers
    const supportedFields = {
      'id',
      'userId',
      'name',
      'phone',
      'address',
      'meterNumber',
      'lastReading',
      'lastReadingDate',
      'status',
      'createdAt',
      'lastModified',
      'lastSyncedAt',
      'pendingSync',
      'deleted',
    };

    // إزالة الحقول غير المدعومة
    final cleaned = <String, dynamic>{};
    data.forEach((key, value) {
      if (supportedFields.contains(key)) {
        cleaned[key] = value;
      }
    });

    return cleaned;
  }

  /// الاستماع للتغييرات في الوقت الفعلي من Firestore
  void listenForRemoteUpdates() async {
    debugPrint('👂 [CustomerRepo] بدء الاستماع للتحديثات من Firestore...');

    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      debugPrint('❌ [CustomerRepo] لا يوجد مستخدم مسجل دخول للاستماع');
      return;
    }

    _firestoreSubscription?.cancel();
    _firestoreSubscription = _firestore
        .collection('customers')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((querySnapshot) async {
      debugPrint(
          '🔔 [CustomerRepo] تلقي تحديث: ${querySnapshot.docChanges.length} تغيير');
      for (final change in querySnapshot.docChanges) {
        final doc = change.doc;
        final data = doc.data();

        if (data == null) continue;

        data['id'] = doc.id;

        // تحويل Timestamp إلى String
        data['createdAt'] = _convertTimestampToString(data['createdAt']);
        data['lastModified'] = _convertTimestampToString(data['lastModified']);
        data['lastReadingDate'] =
            _convertTimestampToString(data['lastReadingDate']);

        // التأكد من وجود userId
        if (data['userId'] == null) {
          data['userId'] = userId;
        }

        if (change.type == DocumentChangeType.removed) {
          // حذف من المحلي
          debugPrint('🗑️ [CustomerRepo] حذف عميل: ${doc.id}');
          await _dbHelper.update(
            'customers',
            {
              'deleted': 1,
              'lastModified': DateTime.now().toIso8601String(),
              'pendingSync': 0,
            },
            'id = ?',
            [doc.id],
          );
          _syncController.add(null);
          continue;
        }

        final rows = await _dbHelper.queryRows('customers', 'id = ?', [doc.id]);

        if (rows.isEmpty) {
          // إضافة سجل جديد
          debugPrint(
              '➕ [CustomerRepo] إضافة عميل جديد (realtime): ${data['name']}');
          final cleanData = _cleanCustomerData({
            ...data,
            'pendingSync': 0,
            'lastSyncedAt': DateTime.now().toIso8601String(),
            'deleted': data['deleted'] ?? 0,
          });
          await _dbHelper.insert('customers', cleanData);
          _syncController.add(null);
          continue;
        }

        final local = rows.first;
        final isPending = local['pendingSync'] == 1;

        // لا نستبدل السجلات المحلية في انتظار المزامنة
        if (isPending) continue;

        final localModified = local['lastModified'] != null
            ? DateTime.parse(local['lastModified'] as String)
            : DateTime(2000);

        final remoteModified = data['lastModified'] != null
            ? DateTime.parse(data['lastModified'] as String)
            : DateTime(2000);

        if (remoteModified.isAfter(localModified)) {
          final cleanData = _cleanCustomerData({
            ...data,
            'pendingSync': 0,
            'lastSyncedAt': DateTime.now().toIso8601String(),
          });
          await _dbHelper.update(
            'customers',
            cleanData,
            'id = ?',
            [doc.id],
          );
          _syncController.add(null);
        }
      }
    });
  }

  /// إيقاف الاستماع
  void dispose() {
    _firestoreSubscription?.cancel();
    _syncController.close();
    _customersController.close();
  }
}
