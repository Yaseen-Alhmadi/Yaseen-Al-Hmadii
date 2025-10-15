import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/customer_repository.dart';
import '../models/customer_model.dart';
import '../services/auth_service.dart';

class AddCustomerScreenNew extends StatefulWidget {
  const AddCustomerScreenNew({Key? key}) : super(key: key);

  @override
  State<AddCustomerScreenNew> createState() => _AddCustomerScreenNewState();
}

class _AddCustomerScreenNewState extends State<AddCustomerScreenNew> {
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
        final repository = Provider.of<CustomerRepository>(
          context,
          listen: false,
        );

        final authService = Provider.of<AuthService>(
          context,
          listen: false,
        );

        // الحصول على userId من المستخدم المسجل حالياً
        final userId = await authService.getCurrentUserId();
        if (userId == null) {
          throw Exception('لا يوجد مستخدم مسجل دخول');
        }

        final customer = Customer(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          meterNumber: _meterNumberController.text.trim(),
          lastReading: double.parse(_initialReadingController.text),
          status: 'active',
          createdAt: DateTime.now().toIso8601String(),
        );

        await repository.addCustomer(customer);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة العميل بنجاح وسيتم مزامنته تلقائياً'),
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
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال اسم العميل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // حقل العنوان
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // حقل الهاتف
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
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
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال رقم العداد';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // حقل القراءة الأولية
                TextFormField(
                  controller: _initialReadingController,
                  decoration: const InputDecoration(
                    labelText: 'القراءة الأولية',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.water_drop),
                    suffixText: 'م³',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال القراءة الأولية';
                    }
                    if (double.tryParse(value) == null) {
                      return 'الرجاء إدخال رقم صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // زر الحفظ
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addCustomer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'حفظ',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // ملاحظة عن المزامنة
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'سيتم حفظ البيانات محلياً ومزامنتها تلقائياً مع السحابة',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
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
