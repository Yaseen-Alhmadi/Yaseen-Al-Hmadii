import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/customer_service.dart';
import 'add_customer_screen.dart';
import 'add_reading_screen.dart';

class CustomersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة العملاء'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // سنضيف البحث لاحقاً
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ميزة البحث قريباً')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Provider.of<CustomerService>(context).getCustomers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل البيانات'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final customers = snapshot.data ?? [];

          if (customers.isEmpty) {
            return Center(
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
          Navigator.push(context, MaterialPageRoute(builder: (_) => AddCustomerScreen()));
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer, BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            customer['name']?.toString().substring(0, 1) ?? '?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          customer['name'] ?? 'بدون اسم',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('العنوان: ${customer['address'] ?? 'غير محدد'}'),
            Text('الهاتف: ${customer['phone'] ?? 'غير محدد'}'),
            Text('رقم العداد: ${customer['meterNumber'] ?? 'غير محدد'}'),
            if (customer['lastReading'] != null)
              Text('آخر قراءة: ${customer['lastReading']}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            _handleMenuSelection(value, customer, context);
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(value: 'add_reading', child: Text('إضافة قراءة')),
            PopupMenuItem(value: 'view_details', child: Text('عرض التفاصيل')),
            PopupMenuItem(value: 'edit', child: Text('تعديل')),
            PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
      ),
    );
  }

  void _handleMenuSelection(String value, Map<String, dynamic> customer, BuildContext context) {
    switch (value) {
      case 'add_reading':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AddReadingScreen(customer: customer)
        ));
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

  void _showCustomerDetails(Map<String, dynamic> customer, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل العميل'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الاسم: ${customer['name']}'),
              Text('العنوان: ${customer['address']}'),
              Text('الهاتف: ${customer['phone']}'),
              Text('رقم العداد: ${customer['meterNumber']}'),
              Text('القراءة الأولية: ${customer['initialReading']}'),
              Text('آخر قراءة: ${customer['lastReading'] ?? 'لا يوجد'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _editCustomer(Map<String, dynamic> customer, BuildContext context) {
    // سنضيف التعديل لاحقاً
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ميزة التعديل قريباً')),
    );
  }

  void _deleteCustomer(Map<String, dynamic> customer, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف العميل'),
        content: Text('هل أنت متأكد من حذف العميل ${customer['name']}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              // سنضيف الحذف لاحقاً
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ميزة الحذف قريباً')),
              );
            },
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}