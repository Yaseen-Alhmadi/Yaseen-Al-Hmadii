import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/customer_service.dart';
import '../services/reading_service.dart';

class AddReadingScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const AddReadingScreen({Key? key, required this.customer}) : super(key: key);

  @override
  AddReadingScreenState createState() => AddReadingScreenState();
}

class AddReadingScreenState extends State<AddReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _readingController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _readingController = TextEditingController(
      text: widget.customer['lastReading']?.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _readingController.dispose();
    super.dispose();
  }

  Future<void> _submitReading() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        double newReading = double.parse(_readingController.text);
        double previousReading =
            widget.customer['lastReading']?.toDouble() ?? 0.0;

        if (newReading <= previousReading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('القراءة الجديدة يجب أن تكون أكبر من السابقة')),
          );
          return;
        }

        double consumption = newReading - previousReading;

        // حساب التكلفة (افتراضي: 0.5 ريال لكل وحدة)
        double rate = 0.5;
        double amount = consumption * rate;

        // حفظ القراءة
        ReadingService readingService =
            Provider.of<ReadingService>(context, listen: false);
        await readingService.addReading({
          'customerId': widget.customer['id'],
          'customerName': widget.customer['name'],
          'previousReading': previousReading,
          'currentReading': newReading,
          'consumption': consumption,
          'rate': rate,
          'amount': amount,
          'readingDate': DateTime.now(),
          'month': DateTime.now().month,
          'year': DateTime.now().year,
        });

        // تحديث قراءة العميل الأخيرة
        CustomerService customerService =
            Provider.of<CustomerService>(context, listen: false);
        await customerService.updateCustomerReading(
            widget.customer['id'], newReading);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إضافة القراءة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إضافة القراءة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إضافة قراءة - ${widget.customer['name']}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomerInfo(),
                SizedBox(height: 20),
                _buildReadingForm(),
                SizedBox(height: 30),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('معلومات العميل',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('الاسم: ${widget.customer['name']}'),
            Text('رقم العداد: ${widget.customer['meterNumber']}'),
            Text('آخر قراءة: ${widget.customer['lastReading'] ?? 'لا يوجد'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('القراءة الجديدة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TextFormField(
          controller: _readingController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'أدخل القراءة الحالية',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.numbers),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال القراءة';
            }
            if (double.tryParse(value) == null) {
              return 'يرجى إدخال رقم صحيح';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: _submitReading,
              child: Text('حفظ القراءة', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
    );
  }
}
