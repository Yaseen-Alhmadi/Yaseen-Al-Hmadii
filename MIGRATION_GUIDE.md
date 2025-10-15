# دليل الترحيل من DatabaseHelper إلى Repository

## 🎯 الهدف

تحويل الشاشات الموجودة من استخدام `DatabaseHelper` مباشرة إلى استخدام `Repository` للاستفادة من نظام المزامنة.

---

## 📋 خطوات الترحيل السريعة

### الخطوة 1: تحديث الاستيرادات

#### قبل:

```dart
import '../services/database_helper.dart';
```

#### بعد:

```dart
import 'package:provider/provider.dart';
import '../repositories/customer_repository.dart';
import '../models/customer_model.dart';
```

---

### الخطوة 2: تحديث قراءة البيانات

#### قبل:

```dart
Future<List<Map<String, dynamic>>> _loadCustomers() async {
  final db = DatabaseHelper.instance;
  return await db.queryAllRows('customers');
}
```

#### بعد:

```dart
Future<List<Customer>> _loadCustomers() async {
  final repo = Provider.of<CustomerRepository>(context, listen: false);
  return await repo.getCustomers();
}
```

---

### الخطوة 3: تحديث إضافة البيانات

#### قبل:

```dart
void _addCustomer() async {
  final db = DatabaseHelper.instance;
  await db.insert('customers', {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    'name': _nameController.text,
    'phone': _phoneController.text,
    'address': _addressController.text,
    'meterNumber': _meterNumberController.text,
    'lastReading': double.parse(_initialReadingController.text),
    'status': 'active',
    'createdAt': DateTime.now().toIso8601String(),
  });
}
```

#### بعد:

```dart
void _addCustomer() async {
  final repo = Provider.of<CustomerRepository>(context, listen: false);

  final customer = Customer(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: _nameController.text,
    phone: _phoneController.text,
    address: _addressController.text,
    meterNumber: _meterNumberController.text,
    lastReading: double.parse(_initialReadingController.text),
    status: 'active',
    createdAt: DateTime.now().toIso8601String(),
  );

  await repo.addCustomer(customer);
}
```

---

### الخطوة 4: تحديث تعديل البيانات

#### قبل:

```dart
void _updateCustomer(Map<String, dynamic> customer) async {
  final db = DatabaseHelper.instance;
  await db.update(
    'customers',
    {
      ...customer,
      'name': _nameController.text,
      'phone': _phoneController.text,
    },
    'id = ?',
    [customer['id']],
  );
}
```

#### بعد:

```dart
void _updateCustomer(Customer customer) async {
  final repo = Provider.of<CustomerRepository>(context, listen: false);

  final updated = customer.copyWith(
    name: _nameController.text,
    phone: _phoneController.text,
  );

  await repo.updateCustomer(updated);
}
```

---

### الخطوة 5: تحديث حذف البيانات

#### قبل:

```dart
void _deleteCustomer(String id) async {
  final db = DatabaseHelper.instance;
  await db.delete('customers', 'id = ?', [id]);
}
```

#### بعد:

```dart
void _deleteCustomer(String id) async {
  final repo = Provider.of<CustomerRepository>(context, listen: false);
  await repo.deleteCustomer(id);
}
```

---

### الخطوة 6: إضافة الاستماع للتحديثات

#### إضافة في initState:

```dart
@override
void initState() {
  super.initState();
  _loadData();
  _listenToSync(); // جديد
}

void _listenToSync() {
  final repo = Provider.of<CustomerRepository>(context, listen: false);
  repo.syncStream.listen((_) {
    _loadData(); // إعادة تحميل عند أي تغيير
  });
}
```

---

## 🔄 أمثلة كاملة للترحيل

### مثال 1: شاشة قائمة العملاء

#### قبل:

```dart
class CustomersScreen extends StatefulWidget {
  @override
  _CustomersScreenState createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late Future<List<Map<String, dynamic>>> _customersFuture;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  void _loadCustomers() {
    final db = DatabaseHelper.instance;
    _customersFuture = db.queryAllRows('customers');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('العملاء')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _customersFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          final customers = snapshot.data!;
          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(customers[index]['name']),
              );
            },
          );
        },
      ),
    );
  }
}
```

#### بعد:

```dart
class CustomersScreen extends StatefulWidget {
  @override
  _CustomersScreenState createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _listenToSync();
  }

  void _loadCustomers() async {
    setState(() => _isLoading = true);

    final repo = Provider.of<CustomerRepository>(context, listen: false);
    final customers = await repo.getCustomers();

    setState(() {
      _customers = customers;
      _isLoading = false;
    });
  }

  void _listenToSync() {
    final repo = Provider.of<CustomerRepository>(context, listen: false);
    repo.syncStream.listen((_) => _loadCustomers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('العملاء')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _customers.length,
              itemBuilder: (context, index) {
                final customer = _customers[index];
                return ListTile(
                  title: Text(customer.name),
                  subtitle: Text(customer.phone ?? ''),
                  // مؤشر للبيانات المعلقة
                  trailing: customer.pendingSync == 1
                      ? Icon(Icons.sync, color: Colors.orange)
                      : null,
                );
              },
            ),
    );
  }
}
```

---

### مثال 2: شاشة إضافة عميل

#### قبل:

```dart
class AddCustomerScreen extends StatefulWidget {
  @override
  _AddCustomerScreenState createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  void _saveCustomer() async {
    final db = DatabaseHelper.instance;

    await db.insert('customers', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _nameController.text,
      'phone': _phoneController.text,
      'status': 'active',
      'createdAt': DateTime.now().toIso8601String(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إضافة عميل')),
      body: Column(
        children: [
          TextField(controller: _nameController),
          TextField(controller: _phoneController),
          ElevatedButton(
            onPressed: _saveCustomer,
            child: Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
```

#### بعد:

```dart
class AddCustomerScreen extends StatefulWidget {
  @override
  _AddCustomerScreenState createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  void _saveCustomer() async {
    final repo = Provider.of<CustomerRepository>(context, listen: false);

    final customer = Customer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      phone: _phoneController.text,
      status: 'active',
      createdAt: DateTime.now().toIso8601String(),
    );

    await repo.addCustomer(customer);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم الحفظ وسيتم المزامنة تلقائياً')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إضافة عميل')),
      body: Column(
        children: [
          TextField(controller: _nameController),
          TextField(controller: _phoneController),
          ElevatedButton(
            onPressed: _saveCustomer,
            child: Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
```

---

## 📊 جدول المقارنة السريع

| العملية          | الطريقة القديمة                               | الطريقة الجديدة                 |
| ---------------- | --------------------------------------------- | ------------------------------- |
| **القراءة**      | `db.queryAllRows('customers')`                | `repo.getCustomers()`           |
| **القراءة بشرط** | `db.queryRows('customers', 'id = ?', [id])`   | `repo.getCustomerById(id)`      |
| **الإضافة**      | `db.insert('customers', map)`                 | `repo.addCustomer(customer)`    |
| **التحديث**      | `db.update('customers', map, 'id = ?', [id])` | `repo.updateCustomer(customer)` |
| **الحذف**        | `db.delete('customers', 'id = ?', [id])`      | `repo.deleteCustomer(id)`       |
| **نوع البيانات** | `Map<String, dynamic>`                        | `Customer` (كائن)               |
| **المزامنة**     | يدوية                                         | تلقائية ✅                      |

---

## ✅ قائمة التحقق للترحيل

عند ترحيل كل شاشة، تأكد من:

- [ ] تحديث الاستيرادات
- [ ] استبدال DatabaseHelper بـ Repository
- [ ] تحويل Map إلى Model
- [ ] إضافة الاستماع للتحديثات (syncStream)
- [ ] إضافة معالجة الأخطاء
- [ ] إضافة مؤشر للبيانات المعلقة (اختياري)
- [ ] اختبار الشاشة بعد التحديث

---

## 🚨 أخطاء شائعة وحلولها

### خطأ 1: Provider not found

```dart
// ❌ خطأ
final repo = Provider.of<CustomerRepository>(context);

// ✅ صحيح
final repo = Provider.of<CustomerRepository>(context, listen: false);
```

### خطأ 2: استخدام context بعد async

```dart
// ❌ خطأ
await repo.addCustomer(customer);
Navigator.pop(context); // قد يسبب مشكلة

// ✅ صحيح
await repo.addCustomer(customer);
if (mounted) {
  Navigator.pop(context);
}
```

### خطأ 3: عدم تحديث الواجهة

```dart
// ❌ خطأ - لا يوجد استماع للتحديثات
void initState() {
  super.initState();
  _loadData();
}

// ✅ صحيح - مع الاستماع
void initState() {
  super.initState();
  _loadData();
  _listenToSync();
}

void _listenToSync() {
  final repo = Provider.of<CustomerRepository>(context, listen: false);
  repo.syncStream.listen((_) => _loadData());
}
```

---

## 🎯 أولويات الترحيل

### المرحلة 1 (فوري):

1. ✅ `customers_screen.dart`
2. ✅ `add_customer_screen.dart`
3. ✅ `readings_screen.dart`
4. ✅ `add_reading_screen.dart`

### المرحلة 2 (قريب):

5. ⏳ `invoices_screen.dart`
6. ⏳ `invoice_details_screen.dart`
7. ⏳ `dashboard_screen.dart` (إحصائيات)

### المرحلة 3 (اختياري):

8. ⏳ `reports_screen.dart`
9. ⏳ أي شاشات أخرى تستخدم DatabaseHelper

---

## 💡 نصائح للترحيل السلس

1. **ابدأ بشاشة واحدة**: لا تحول كل الشاشات دفعة واحدة
2. **اختبر بعد كل تحويل**: تأكد من عمل الشاشة قبل الانتقال للتالية
3. **احتفظ بنسخة احتياطية**: استخدم Git أو انسخ الملفات
4. **استخدم الأمثلة**: راجع `customers_screen_new.dart` كمرجع
5. **اختبر دون اتصال**: تأكد من عمل المزامنة

---

## 📞 الدعم

إذا واجهت مشكلة أثناء الترحيل:

1. راجع الأمثلة في `customers_screen_new.dart`
2. راجع التوثيق في `SYNC_SYSTEM_README.md`
3. تحقق من console للأخطاء
4. تأكد من تهيئة Provider في main.dart

---

**بالتوفيق في الترحيل! 🚀**
