import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/customer_repository.dart';
import '../services/sync_service.dart';
import '../models/customer_model.dart';
import 'add_customer_screen.dart';
import 'add_reading_screen.dart';

class CustomersScreenNew extends StatefulWidget {
  const CustomersScreenNew({Key? key}) : super(key: key);

  @override
  State<CustomersScreenNew> createState() => _CustomersScreenNewState();
}

class _CustomersScreenNewState extends State<CustomersScreenNew> {
  List<Customer> _customers = [];
  bool _isLoading = true;
  SyncStatus _syncStatus = SyncStatus.synced;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _listenToSync();
  }

  void _loadCustomers() async {
    setState(() => _isLoading = true);

    final repository = Provider.of<CustomerRepository>(context, listen: false);
    final customers = await repository.getCustomers();

    setState(() {
      _customers = customers;
      _isLoading = false;
    });
  }

  void _listenToSync() {
    final repository = Provider.of<CustomerRepository>(context, listen: false);
    final syncService = Provider.of<SyncService>(context, listen: false);

    // الاستماع لتغييرات البيانات
    repository.syncStream.listen((_) {
      _loadCustomers();
    });

    // الاستماع لحالة المزامنة
    syncService.syncStatusStream.listen((status) {
      setState(() => _syncStatus = status);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العملاء'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // مؤشر حالة المزامنة
          _buildSyncIndicator(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _manualSync,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ميزة البحث قريباً')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _customers.isEmpty
              ? _buildEmptyState()
              : _buildCustomersList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddCustomerScreen()),
          ).then((_) => _loadCustomers());
        },
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('لا يوجد عملاء مسجلين بعد'),
          const SizedBox(height: 8),
          const Text('اضغط على زر + لإضافة عميل جديد'),
        ],
      ),
    );
  }

  Widget _buildCustomersList() {
    return ListView.builder(
      itemCount: _customers.length,
      itemBuilder: (context, index) {
        return _buildCustomerCard(_customers[index]);
      },
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            customer.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('العنوان: ${customer.address ?? 'غير محدد'}'),
            Text('الهاتف: ${customer.phone ?? 'غير محدد'}'),
            Text('رقم العداد: ${customer.meterNumber ?? 'غير محدد'}'),
            if (customer.lastReading > 0)
              Text('آخر قراءة: ${customer.lastReading}'),
            // مؤشر للبيانات المعلقة
            if (customer.pendingSync == 1)
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
          onSelected: (value) => _handleMenuSelection(value, customer),
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: 'add_reading',
              child: Text('إضافة قراءة'),
            ),
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

  void _handleMenuSelection(String value, Customer customer) {
    switch (value) {
      case 'add_reading':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddReadingScreen(customer: customer.toMap()),
          ),
        );
        break;
      case 'view_details':
        _showCustomerDetails(customer);
        break;
      case 'edit':
        _editCustomer(customer);
        break;
      case 'delete':
        _deleteCustomer(customer);
        break;
    }
  }

  void _showCustomerDetails(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل العميل'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الاسم: ${customer.name}'),
              Text('العنوان: ${customer.address ?? 'غير محدد'}'),
              Text('الهاتف: ${customer.phone ?? 'غير محدد'}'),
              Text('رقم العداد: ${customer.meterNumber ?? 'غير محدد'}'),
              Text('آخر قراءة: ${customer.lastReading}'),
              Text('الحالة: ${customer.status}'),
              if (customer.createdAt != null)
                Text('تاريخ الإنشاء: ${customer.createdAt}'),
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

  void _editCustomer(Customer customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة التعديل قريباً')),
    );
  }

  void _deleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العميل'),
        content: Text('هل أنت متأكد من حذف العميل ${customer.name}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final repository = Provider.of<CustomerRepository>(
                context,
                listen: false,
              );

              await repository.deleteCustomer(customer.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف العميل بنجاح')),
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
}
