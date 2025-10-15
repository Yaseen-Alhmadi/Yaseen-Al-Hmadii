import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../repositories/reading_repository.dart';
import '../repositories/customer_repository.dart';
import '../services/sync_service.dart';
import '../models/reading_model.dart';
import '../models/customer_model.dart';
import 'add_reading_screen.dart';

class ReadingsScreenNew extends StatefulWidget {
  const ReadingsScreenNew({Key? key}) : super(key: key);

  @override
  State<ReadingsScreenNew> createState() => _ReadingsScreenNewState();
}

class _ReadingsScreenNewState extends State<ReadingsScreenNew> {
  List<Reading> _readings = [];
  Map<String, Customer> _customersMap = {};
  bool _isLoading = true;
  SyncStatus _syncStatus = SyncStatus.synced;
  String? _selectedCustomerId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenToSync();
  }

  void _loadData() async {
    setState(() => _isLoading = true);

    final readingRepo = Provider.of<ReadingRepository>(context, listen: false);
    final customerRepo =
        Provider.of<CustomerRepository>(context, listen: false);

    // تحميل القراءات
    final readings = await readingRepo.getReadings();

    // تحميل العملاء لعرض أسمائهم
    final customers = await customerRepo.getCustomers();
    final customersMap = <String, Customer>{};
    for (var customer in customers) {
      customersMap[customer.id] = customer;
    }

    setState(() {
      _readings = readings;
      _customersMap = customersMap;
      _isLoading = false;
    });
  }

  void _listenToSync() {
    final readingRepo = Provider.of<ReadingRepository>(context, listen: false);
    final customerRepo =
        Provider.of<CustomerRepository>(context, listen: false);
    final syncService = Provider.of<SyncService>(context, listen: false);

    // الاستماع لتغييرات القراءات
    readingRepo.syncStream.listen((_) => _loadData());

    // الاستماع لتغييرات العملاء
    customerRepo.syncStream.listen((_) => _loadData());

    // الاستماع لحالة المزامنة
    syncService.syncStatusStream.listen((status) {
      setState(() => _syncStatus = status);
    });
  }

  List<Reading> get _filteredReadings {
    if (_selectedCustomerId == null) return _readings;
    return _readings.where((r) => r.customerId == _selectedCustomerId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة القراءات'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          _buildSyncIndicator(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _manualSync,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredReadings.isEmpty
              ? _buildEmptyState()
              : _buildReadingsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReading,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSyncIndicator() {
    IconData icon;
    Color color;
    String tooltip;

    switch (_syncStatus) {
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = Colors.orange;
        tooltip = 'جاري المزامنة...';
        break;
      case SyncStatus.synced:
        icon = Icons.cloud_done;
        color = Colors.green;
        tooltip = 'تمت المزامنة';
        break;
      case SyncStatus.offline:
        icon = Icons.cloud_off;
        color = Colors.red;
        tooltip = 'غير متصل';
        break;
      case SyncStatus.error:
        icon = Icons.error;
        color = Colors.red;
        tooltip = 'خطأ في المزامنة';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Tooltip(
        message: tooltip,
        child: Icon(icon, color: color),
      ),
    );
  }

  Future<void> _manualSync() async {
    final syncService = Provider.of<SyncService>(context, listen: false);

    try {
      await syncService.manualSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت المزامنة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في المزامنة: $e')),
        );
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفية حسب العميل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('جميع العملاء'),
              leading: Radio<String?>(
                value: null,
                groupValue: _selectedCustomerId,
                onChanged: (value) {
                  setState(() => _selectedCustomerId = value);
                  Navigator.pop(context);
                },
              ),
            ),
            ..._customersMap.values.map((customer) {
              return ListTile(
                title: Text(customer.name),
                leading: Radio<String?>(
                  value: customer.id,
                  groupValue: _selectedCustomerId,
                  onChanged: (value) {
                    setState(() => _selectedCustomerId = value);
                    Navigator.pop(context);
                  },
                ),
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.water_drop_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _selectedCustomerId != null
                ? 'لا توجد قراءات لهذا العميل'
                : 'لا توجد قراءات مسجلة بعد',
          ),
          const SizedBox(height: 8),
          const Text('اضغط على زر + لإضافة قراءة جديدة'),
        ],
      ),
    );
  }

  Widget _buildReadingsList() {
    // ترتيب القراءات حسب التاريخ (الأحدث أولاً)
    final sortedReadings = List<Reading>.from(_filteredReadings)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      itemCount: sortedReadings.length,
      itemBuilder: (context, index) {
        return _buildReadingCard(sortedReadings[index]);
      },
    );
  }

  Widget _buildReadingCard(Reading reading) {
    final customer = _customersMap[reading.customerId];
    final dateFormat = DateFormat('yyyy-MM-dd');
    final date = DateTime.tryParse(reading.date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: const Icon(Icons.water_drop, color: Colors.white),
        ),
        title: Text(
          customer?.name ?? 'عميل غير معروف',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('القراءة: ${reading.reading} م³'),
            Text(
              'التاريخ: ${date != null ? dateFormat.format(date) : reading.date}',
            ),
            if (reading.pendingSync == 1)
              Row(
                children: const [
                  Icon(Icons.sync, size: 14, color: Colors.orange),
                  SizedBox(width: 4),
                  Text(
                    'في انتظار المزامنة',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuSelection(value, reading),
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: 'view_details',
              child: Text('عرض التفاصيل'),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Text('تعديل'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuSelection(String value, Reading reading) {
    switch (value) {
      case 'view_details':
        _showReadingDetails(reading);
        break;
      case 'edit':
        _editReading(reading);
        break;
      case 'delete':
        _deleteReading(reading);
        break;
    }
  }

  void _showReadingDetails(Reading reading) {
    final customer = _customersMap[reading.customerId];
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final date = DateTime.tryParse(reading.date);
    final createdAt = reading.createdAt != null
        ? DateTime.tryParse(reading.createdAt!)
        : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل القراءة'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('العميل: ${customer?.name ?? 'غير معروف'}'),
              Text('رقم العداد: ${customer?.meterNumber ?? 'غير محدد'}'),
              const Divider(),
              Text('القراءة: ${reading.reading} م³'),
              Text(
                'التاريخ: ${date != null ? dateFormat.format(date) : reading.date}',
              ),
              if (createdAt != null)
                Text('تاريخ الإنشاء: ${dateFormat.format(createdAt)}'),
              const Divider(),
              Text(
                'الحالة: ${reading.pendingSync == 1 ? 'في انتظار المزامنة' : 'تمت المزامنة'}',
                style: TextStyle(
                  color:
                      reading.pendingSync == 1 ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
  }

  void _editReading(Reading reading) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة التعديل قريباً')),
    );
  }

  void _deleteReading(Reading reading) {
    final customer = _customersMap[reading.customerId];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف القراءة'),
        content: Text(
          'هل أنت متأكد من حذف قراءة ${customer?.name ?? 'العميل'} بتاريخ ${reading.date}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final repository = Provider.of<ReadingRepository>(
                context,
                listen: false,
              );

              await repository.deleteReading(reading.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف القراءة بنجاح')),
                );
              }
            },
            child: const Text(
              'حذف',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _addReading() async {
    if (_customersMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب إضافة عميل أولاً قبل إضافة قراءة'),
        ),
      );
      return;
    }

    // يمكن تحديث AddReadingScreen لاستخدام Repository أيضاً
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddReadingScreen(
          customer: _customersMap.values.first.toMap(),
        ),
      ),
    ).then((_) => _loadData());
  }
}
