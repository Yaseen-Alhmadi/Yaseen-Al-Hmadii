import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'repositories/customer_repository.dart';
import 'repositories/reading_repository.dart';
import 'services/sync_service.dart';
import 'services/auth_service.dart';
import 'models/customer_model.dart';
import 'models/reading_model.dart';

/// شاشة اختبار نظام المزامنة
/// يمكن الوصول إليها من القائمة الرئيسية للتطبيق
class TestSyncScreen extends StatefulWidget {
  const TestSyncScreen({Key? key}) : super(key: key);

  @override
  State<TestSyncScreen> createState() => _TestSyncScreenState();
}

class _TestSyncScreenState extends State<TestSyncScreen> {
  final _logs = <String>[];
  SyncStatus _syncStatus = SyncStatus.synced;
  int _customersCount = 0;
  int _readingsCount = 0;
  int _pendingCustomers = 0;
  int _pendingReadings = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _listenToSync();
  }

  void _loadStats() async {
    final customerRepo =
        Provider.of<CustomerRepository>(context, listen: false);
    final readingRepo = Provider.of<ReadingRepository>(context, listen: false);

    final customers = await customerRepo.getCustomers();
    final readings = await readingRepo.getReadings();

    setState(() {
      _customersCount = customers.length;
      _readingsCount = readings.length;
      _pendingCustomers = customers.where((c) => c.pendingSync == 1).length;
      _pendingReadings = readings.where((r) => r.pendingSync == 1).length;
    });
  }

  void _listenToSync() {
    final syncService = Provider.of<SyncService>(context, listen: false);
    syncService.syncStatusStream.listen((status) {
      setState(() => _syncStatus = status);
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(
          0, '${DateTime.now().toString().substring(11, 19)} - $message');
      if (_logs.length > 50) _logs.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار نظام المزامنة'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildStatusCard(),
          _buildStatsCard(),
          _buildActionsCard(),
          const Divider(height: 1),
          Expanded(child: _buildLogsList()),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    IconData icon;
    Color color;
    String text;

    switch (_syncStatus) {
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = Colors.orange;
        text = 'جاري المزامنة...';
        break;
      case SyncStatus.synced:
        icon = Icons.cloud_done;
        color = Colors.green;
        text = 'تمت المزامنة';
        break;
      case SyncStatus.offline:
        icon = Icons.cloud_off;
        color = Colors.red;
        text = 'غير متصل';
        break;
      case SyncStatus.error:
        icon = Icons.error;
        color = Colors.red;
        text = 'خطأ في المزامنة';
        break;
    }

    return Card(
      margin: const EdgeInsets.all(16),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حالة المزامنة',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الإحصائيات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'العملاء',
                    _customersCount.toString(),
                    _pendingCustomers > 0 ? '$_pendingCustomers معلق' : null,
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'القراءات',
                    _readingsCount.toString(),
                    _pendingReadings > 0 ? '$_pendingReadings معلق' : null,
                    Icons.water_drop,
                    Colors.cyan,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    String? pending,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (pending != null)
            Text(
              pending,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إجراءات الاختبار',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _testAddCustomer,
                  icon: const Icon(Icons.person_add),
                  label: const Text('إضافة عميل تجريبي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _testAddReading,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة قراءة تجريبية'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _testManualSync,
                  icon: const Icon(Icons.sync),
                  label: const Text('مزامنة يدوية'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _clearLogs,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('مسح السجل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsList() {
    return Container(
      color: Colors.grey[100],
      child: _logs.isEmpty
          ? const Center(
              child: Text(
                'لا توجد سجلات بعد\nجرب الإجراءات أعلاه',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Text(
                    _logs[index],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _testAddCustomer() async {
    _addLog('بدء إضافة عميل تجريبي...');

    try {
      final repo = Provider.of<CustomerRepository>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // الحصول على userId من المستخدم المسجل حالياً
      final userId = await authService.getCurrentUserId();
      if (userId == null) {
        _addLog('❌ لا يوجد مستخدم مسجل دخول');
        return;
      }

      final customer = Customer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        name: 'عميل تجريبي ${DateTime.now().second}',
        phone: '05${DateTime.now().millisecondsSinceEpoch % 100000000}',
        address: 'عنوان تجريبي',
        meterNumber: 'M${DateTime.now().millisecondsSinceEpoch % 10000}',
        lastReading: 0.0,
        status: 'active',
        createdAt: DateTime.now().toIso8601String(),
      );

      await repo.addCustomer(customer);
      _addLog('✅ تم إضافة العميل: ${customer.name}');
      _loadStats();
    } catch (e) {
      _addLog('❌ خطأ في إضافة العميل: $e');
    }
  }

  void _testAddReading() async {
    _addLog('بدء إضافة قراءة تجريبية...');

    try {
      final customerRepo =
          Provider.of<CustomerRepository>(context, listen: false);
      final readingRepo =
          Provider.of<ReadingRepository>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // الحصول على userId من المستخدم المسجل حالياً
      final userId = await authService.getCurrentUserId();
      if (userId == null) {
        _addLog('❌ لا يوجد مستخدم مسجل دخول');
        return;
      }

      final customers = await customerRepo.getCustomers();
      if (customers.isEmpty) {
        _addLog('⚠️ لا يوجد عملاء. أضف عميل أولاً');
        return;
      }

      final customer = customers.first;
      final reading = Reading(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        customerId: customer.id,
        reading: (DateTime.now().millisecondsSinceEpoch % 1000).toDouble(),
        date: DateTime.now().toIso8601String(),
        createdAt: DateTime.now().toIso8601String(),
      );

      await readingRepo.addReading(reading);
      _addLog(
          '✅ تم إضافة القراءة: ${reading.reading} م³ للعميل ${customer.name}');
      _loadStats();
    } catch (e) {
      _addLog('❌ خطأ في إضافة القراءة: $e');
    }
  }

  void _testManualSync() async {
    _addLog('بدء المزامنة اليدوية...');

    try {
      final syncService = Provider.of<SyncService>(context, listen: false);
      await syncService.manualSync();
      _addLog('✅ تمت المزامنة بنجاح');
      _loadStats();
    } catch (e) {
      _addLog('❌ خطأ في المزامنة: $e');
    }
  }

  void _clearLogs() {
    setState(() => _logs.clear());
  }
}
