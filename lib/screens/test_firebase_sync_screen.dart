import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../repositories/customer_repository.dart';
import '../services/sync_service.dart';

/// شاشة اختبار المزامنة مع Firebase
class TestFirebaseSyncScreen extends StatefulWidget {
  const TestFirebaseSyncScreen({Key? key}) : super(key: key);

  @override
  State<TestFirebaseSyncScreen> createState() => _TestFirebaseSyncScreenState();
}

class _TestFirebaseSyncScreenState extends State<TestFirebaseSyncScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _connectivity = Connectivity();
  bool _isLoading = false;
  String _status = 'جاهز للاختبار';
  int _localCount = 0;
  int _firebaseCount = 0;
  String _connectionStatus = 'جاري الفحص...';

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadCounts();
  }

  /// فحص الاتصال بالإنترنت
  Future<void> _checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();

      String status;
      Color statusColor;

      if (result == ConnectivityResult.none) {
        status = '❌ غير متصل بالإنترنت';
        statusColor = Colors.red;
      } else if (result == ConnectivityResult.wifi) {
        status = '✅ متصل عبر WiFi';
        statusColor = Colors.green;
      } else if (result == ConnectivityResult.mobile) {
        status = '✅ متصل عبر Mobile Data';
        statusColor = Colors.green;
      } else {
        status = '⚠️ حالة الاتصال غير معروفة';
        statusColor = Colors.orange;
      }

      // اختبار الاتصال بـ Firebase
      try {
        await _firestore.collection('customers').limit(1).get();
        status += ' - Firebase متاح ✅';
      } catch (e) {
        status += ' - Firebase غير متاح ❌';
        statusColor = Colors.red;
      }

      setState(() => _connectionStatus = status);
    } catch (e) {
      setState(() => _connectionStatus = '❌ خطأ في فحص الاتصال: $e');
    }
  }

  Future<void> _loadCounts() async {
    setState(() => _isLoading = true);

    try {
      // عدد العملاء في القاعدة المحلية
      final repo = Provider.of<CustomerRepository>(context, listen: false);
      final localCustomers = await repo.getCustomers();

      // عدد العملاء في Firebase
      final snapshot = await _firestore.collection('customers').get();

      setState(() {
        _localCount = localCustomers.length;
        _firebaseCount = snapshot.docs.length;
        _status = 'تم التحميل بنجاح';
      });
    } catch (e) {
      setState(() => _status = 'خطأ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// إضافة عميل تجريبي في Firebase مباشرة
  Future<void> _addTestCustomerToFirebase() async {
    setState(() {
      _isLoading = true;
      _status = 'جاري إضافة عميل في Firebase...';
    });

    try {
      final now = DateTime.now();
      final testCustomer = {
        'name': 'عميل تجريبي ${now.hour}:${now.minute}:${now.second}',
        'phone':
            '0${(1000000000 + now.millisecond).toString().substring(0, 9)}',
        'address': 'عنوان تجريبي - شارع ${now.day}',
        'meterNumber': 'M${now.millisecondsSinceEpoch}',
        'lastReading': 100.0,
        'lastReadingDate': now.toIso8601String(),
        'status': 'active',
        'createdAt': now.toIso8601String(),
        'lastModified': now.toIso8601String(),
        'deleted': 0,
      };

      await _firestore.collection('customers').add(testCustomer);

      setState(
          () => _status = '✅ تم إضافة عميل في Firebase - انتظر المزامنة...');

      // انتظر قليلاً ثم أعد تحميل العدادات
      await Future.delayed(const Duration(seconds: 2));
      await _loadCounts();
    } catch (e) {
      setState(() => _status = '❌ خطأ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// مزامنة يدوية
  Future<void> _manualSync() async {
    setState(() {
      _isLoading = true;
      _status = 'جاري المزامنة اليدوية...';
    });

    try {
      final syncService = Provider.of<SyncService>(context, listen: false);
      await syncService.manualSync();

      setState(() => _status = '✅ اكتملت المزامنة');

      await Future.delayed(const Duration(seconds: 1));
      await _loadCounts();
    } catch (e) {
      setState(() => _status = '❌ خطأ في المزامنة: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// عرض العملاء من Firebase
  Future<void> _showFirebaseCustomers() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestore.collection('customers').get();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('العملاء في Firebase'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: snapshot.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.docs[index];
                final data = doc.data();
                return ListTile(
                  title: Text(data['name'] ?? 'بدون اسم'),
                  subtitle:
                      Text('ID: ${doc.id}\nالهاتف: ${data['phone'] ?? 'N/A'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await doc.reference.delete();
                      Navigator.pop(context);
                      _loadCounts();
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _status = '❌ خطأ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// عرض العملاء من القاعدة المحلية
  Future<void> _showLocalCustomers() async {
    setState(() => _isLoading = true);

    try {
      final repo = Provider.of<CustomerRepository>(context, listen: false);
      final customers = await repo.getCustomers();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('العملاء في القاعدة المحلية'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return ListTile(
                  title: Text(customer.name),
                  subtitle: Text(
                      'ID: ${customer.id}\nالهاتف: ${customer.phone ?? 'N/A'}'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _status = '❌ خطأ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار مزامنة Firebase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkConnection();
              _loadCounts();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بطاقة حالة الاتصال
            Card(
              color: _connectionStatus.contains('✅')
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      _connectionStatus.contains('✅')
                          ? Icons.wifi
                          : Icons.wifi_off,
                      color: _connectionStatus.contains('✅')
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _connectionStatus,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // بطاقة الحالة
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // الإحصائيات
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.phone_android,
                              size: 40, color: Colors.green),
                          Text(
                            '$_localCount',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('محلي (SQLite)'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.cloud,
                              size: 40, color: Colors.orange),
                          const SizedBox(height: 8),
                          Text(
                            '$_firebaseCount',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('سحابي (Firebase)'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // الأزرار
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _addTestCustomerToFirebase,
              icon: const Icon(Icons.add_circle),
              label: const Text('إضافة عميل في Firebase'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkConnection,
              icon: const Icon(Icons.network_check),
              label: const Text('فحص الاتصال'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _manualSync,
              icon: const Icon(Icons.sync),
              label: const Text('مزامنة يدوية'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _showFirebaseCustomers,
              icon: const Icon(Icons.cloud_queue),
              label: const Text('عرض عملاء Firebase'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _showLocalCustomers,
              icon: const Icon(Icons.storage),
              label: const Text('عرض العملاء المحليين'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const Spacer(),

            // تعليمات
            Card(
              color: Colors.amber.shade50,
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 تعليمات الاختبار:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. اضغط "فحص الاتصال" أولاً'),
                    Text('2. تأكد من ظهور ✅ في حالة الاتصال'),
                    Text('3. اضغط "إضافة عميل في Firebase"'),
                    Text('4. راقب Console للرسائل'),
                    Text('5. انتظر 2-3 ثواني'),
                    Text('6. تحقق من تحديث العداد المحلي'),
                    Text('7. إذا لم يتحدث، اضغط "مزامنة يدوية"'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
