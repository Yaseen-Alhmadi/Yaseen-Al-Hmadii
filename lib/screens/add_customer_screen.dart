import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/customer_repository.dart';
import '../models/customer_model.dart';
import '../services/auth_service.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _meterNumberController;
  late final TextEditingController _initialReadingController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _meterNumberController = TextEditingController();
    _initialReadingController = TextEditingController(text: '0.0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _meterNumberController.dispose();
    _initialReadingController.dispose();
    super.dispose();
  }

  void _addCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final customerRepo =
            Provider.of<CustomerRepository>(context, listen: false);
        final authService = Provider.of<AuthService>(context, listen: false);

        // الحصول على معرف المستخدم الحالي
        final userId = await authService.getCurrentUserId();
        if (userId == null) {
          throw Exception('لا يوجد مستخدم مسجل دخول');
        }

        // إنشاء كائن Customer جديد
        final newCustomer = Customer(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          meterNumber: _meterNumberController.text.trim(),
          lastReading: double.parse(_initialReadingController.text),
          lastReadingDate: DateTime.now().toIso8601String(),
          status: 'active',
          createdAt: DateTime.now().toIso8601String(),
          lastModified: DateTime.now().toIso8601String(),
          pendingSync: 1, // سيتم المزامنة مع Firebase
          deleted: 0,
        );

        // إضافة العميل (سيتم حفظه محلياً ومزامنته مع Firebase تلقائياً)
        await customerRepo.addCustomer(newCustomer);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة العميل بنجاح وجاري المزامنة مع Firebase'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إضافة العميل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة عميل جديد'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // حقل الاسم
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم العميل *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال اسم العميل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // حقل العنوان
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال العنوان';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // حقل الهاتف
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال رقم الهاتف';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // حقل رقم العداد
                TextFormField(
                  controller: _meterNumberController,
                  decoration: const InputDecoration(
                    labelText: 'رقم العداد *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.speed),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال رقم العداد';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // حقل القراءة الأولية
                TextFormField(
                  controller: _initialReadingController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'القراءة الأولية',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال القراءة الأولية';
                    }
                    if (double.tryParse(value) == null) {
                      return 'يرجى إدخال رقم صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // زر الإضافة
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _addCustomer,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 55),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'إضافة العميل',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
