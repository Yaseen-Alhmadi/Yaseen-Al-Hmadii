import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/customer_repository.dart';
import '../models/customer_model.dart';
import 'add_customer_screen.dart';
import 'add_reading_screen.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customerRepo =
        Provider.of<CustomerRepository>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العملاء'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // سنضيف البحث لاحقاً
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ميزة البحث قريباً')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Customer>>(
        stream: customerRepo.customersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('خطأ في تحميل البيانات: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final customers = snapshot.data ?? [];

          if (customers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا يوجد عملاء مسجلين بعد'),
                  SizedBox(height: 8),
                  Text('اضغط على زر + لإضافة عميل جديد'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              return _buildCustomerCard(customers[index], context);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            customer.name.isNotEmpty ? customer.name.substring(0, 1) : '?',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('العنوان: ${customer.address}'),
            Text('الهاتف: ${customer.phone}'),
            Text('رقم العداد: ${customer.meterNumber}'),
            if (customer.lastReading > 0)
              Text('آخر قراءة: ${customer.lastReading}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            _handleMenuSelection(value, customer, context);
          },
          itemBuilder: (BuildContext context) => const [
            PopupMenuItem(value: 'add_reading', child: Text('إضافة قراءة')),
            PopupMenuItem(value: 'view_details', child: Text('عرض التفاصيل')),
            PopupMenuItem(value: 'edit', child: Text('تعديل')),
            PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
      ),
    );
  }

  void _handleMenuSelection(
      String value, Customer customer, BuildContext context) {
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
        _showCustomerDetails(customer, context);
        break;
      case 'edit':
        _editCustomer(customer, context);
        break;
      case 'delete':
        _deleteCustomer(customer, context);
        break;
    }
  }

  void _showCustomerDetails(Customer customer, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل العميل'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الاسم: ${customer.name}'),
              Text('العنوان: ${customer.address}'),
              Text('الهاتف: ${customer.phone}'),
              Text('رقم العداد: ${customer.meterNumber}'),
              Text(
                  'آخر قراءة: ${customer.lastReading > 0 ? customer.lastReading : 'لا يوجد'}'),
              Text('تاريخ آخر قراءة: ${customer.lastReadingDate ?? 'لا يوجد'}'),
              Text('الحالة: ${customer.status}'),
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

  void _editCustomer(Customer customer, BuildContext context) {
    // سنضيف التعديل لاحقاً
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة التعديل قريباً')),
    );
  }

  void _deleteCustomer(Customer customer, BuildContext context) {
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
              final customerRepo =
                  Provider.of<CustomerRepository>(context, listen: false);
              try {
                await customerRepo.deleteCustomer(customer.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف العميل بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل في حذف العميل: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
