# دليل البدء السريع - نظام المزامنة

## ✅ ما تم إنجازه

### 1. البنية التحتية

- ✅ تحديث قاعدة البيانات المحلية (SQLite) بحقول المزامنة
- ✅ إضافة حزمة `connectivity_plus` للتحقق من الاتصال
- ✅ إنشاء نماذج البيانات (Customer, Reading)
- ✅ إنشاء Repositories للعملاء والقراءات
- ✅ إنشاء خدمة المزامنة المركزية (SyncService)
- ✅ تحديث main.dart لتهيئة النظام

### 2. الملفات الجديدة

```
lib/
├── models/
│   ├── customer_model.dart          ✅ جديد
│   └── reading_model.dart           ✅ جديد
├── repositories/
│   ├── customer_repository.dart     ✅ جديد
│   └── reading_repository.dart      ✅ جديد
├── services/
│   ├── sync_service.dart            ✅ جديد
│   └── database_helper.dart         ✅ محدث
├── screens/
│   ├── customers_screen_new.dart    ✅ جديد (مثال)
│   └── add_customer_screen_new.dart ✅ جديد (مثال)
└── main.dart                        ✅ محدث
```

---

## 🚀 كيفية الاستخدام

### الخطوة 1: استخدام Repository في الشاشات

#### مثال: قراءة البيانات

```dart
import 'package:provider/provider.dart';
import '../repositories/customer_repository.dart';

class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  List<Customer> customers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenToChanges();
  }

  void _loadData() async {
    final repo = Provider.of<CustomerRepository>(context, listen: false);
    final data = await repo.getCustomers();
    setState(() => customers = data);
  }

  void _listenToChanges() {
    final repo = Provider.of<CustomerRepository>(context, listen: false);
    repo.syncStream.listen((_) {
      _loadData(); // إعادة تحميل عند أي تغيير
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: customers.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(customers[index].name));
      },
    );
  }
}
```

#### مثال: إضافة بيانات

```dart
void _addCustomer() async {
  final repo = Provider.of<CustomerRepository>(context, listen: false);

  final customer = Customer(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: 'أحمد محمد',
    phone: '0123456789',
    address: 'الرياض',
    meterNumber: 'M12345',
    status: 'active',
    createdAt: DateTime.now().toIso8601String(),
  );

  await repo.addCustomer(customer);
  // سيتم الحفظ محلياً والمزامنة تلقائياً!
}
```

#### مثال: تحديث بيانات

```dart
void _updateCustomer(Customer customer) async {
  final repo = Provider.of<CustomerRepository>(context, listen: false);

  final updated = customer.copyWith(
    name: 'أحمد علي',
    phone: '0987654321',
  );

  await repo.updateCustomer(updated);
  // سيتم التحديث محلياً والمزامنة تلقائياً!
}
```

#### مثال: حذف بيانات

```dart
void _deleteCustomer(String customerId) async {
  final repo = Provider.of<CustomerRepository>(context, listen: false);
  await repo.deleteCustomer(customerId);
  // حذف منطقي محلياً وسيتم حذفه من السحابة تلقائياً!
}
```

---

### الخطوة 2: عرض حالة المزامنة

```dart
import '../services/sync_service.dart';

class MyAppBar extends StatefulWidget {
  @override
  State<MyAppBar> createState() => _MyAppBarState();
}

class _MyAppBarState extends State<MyAppBar> {
  SyncStatus _status = SyncStatus.synced;

  @override
  void initState() {
    super.initState();
    final syncService = Provider.of<SyncService>(context, listen: false);
    syncService.syncStatusStream.listen((status) {
      setState(() => _status = status);
    });
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (_status) {
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = Colors.orange;
        break;
      case SyncStatus.synced:
        icon = Icons.cloud_done;
        color = Colors.green;
        break;
      case SyncStatus.offline:
        icon = Icons.cloud_off;
        color = Colors.red;
        break;
      case SyncStatus.error:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return AppBar(
      title: Text('التطبيق'),
      actions: [
        Icon(icon, color: color),
      ],
    );
  }
}
```

---

### الخطوة 3: المزامنة اليدوية

```dart
void _manualSync() async {
  final syncService = Provider.of<SyncService>(context, listen: false);

  try {
    await syncService.manualSync();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تمت المزامنة بنجاح')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('خطأ: $e')),
    );
  }
}
```

---

## 🔄 تحديث الشاشات الموجودة

### خطوات التحويل من DatabaseHelper إلى Repository:

#### قبل (الطريقة القديمة):

```dart
// في الشاشة القديمة
final dbHelper = DatabaseHelper.instance;
final rows = await dbHelper.queryAllRows('customers');
final customers = rows.map((row) => {...}).toList();
```

#### بعد (الطريقة الجديدة):

```dart
// في الشاشة الجديدة
final repo = Provider.of<CustomerRepository>(context, listen: false);
final customers = await repo.getCustomers();
```

### مثال كامل للتحويل:

**قبل:**

```dart
class OldCustomersScreen extends StatefulWidget {
  @override
  _OldCustomersScreenState createState() => _OldCustomersScreenState();
}

class _OldCustomersScreenState extends State<OldCustomersScreen> {
  Future<List<Map<String, dynamic>>> _loadCustomers() async {
    final db = DatabaseHelper.instance;
    return await db.queryAllRows('customers');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadCustomers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final customer = snapshot.data![index];
            return ListTile(title: Text(customer['name']));
          },
        );
      },
    );
  }
}
```

**بعد:**

```dart
class NewCustomersScreen extends StatefulWidget {
  @override
  _NewCustomersScreenState createState() => _NewCustomersScreenState();
}

class _NewCustomersScreenState extends State<NewCustomersScreen> {
  List<Customer> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _listenToSync();
  }

  void _loadCustomers() async {
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
    if (_isLoading) return CircularProgressIndicator();

    return ListView.builder(
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
    );
  }
}
```

---

## 📋 قائمة المهام للتطبيق الكامل

### مهام فورية:

- [ ] تحديث `customers_screen.dart` لاستخدام `CustomerRepository`
- [ ] تحديث `add_customer_screen.dart` لاستخدام `CustomerRepository`
- [ ] تحديث `readings_screen.dart` لاستخدام `ReadingRepository`
- [ ] تحديث `add_reading_screen.dart` لاستخدام `ReadingRepository`

### مهام متوسطة:

- [ ] إنشاء `invoice_model.dart`
- [ ] إنشاء `invoice_repository.dart`
- [ ] إضافة InvoiceRepository إلى SyncService
- [ ] تحديث شاشات الفواتير

### مهام اختيارية:

- [ ] إضافة شاشة إعدادات المزامنة
- [ ] إضافة سجل للأخطاء
- [ ] إضافة إحصائيات المزامنة
- [ ] إضافة خيار "مزامنة الآن" في القائمة

---

## 🧪 اختبار النظام

### اختبار 1: العمل دون اتصال

1. قم بتشغيل التطبيق
2. قطع الاتصال بالإنترنت (وضع الطيران)
3. أضف عميل جديد
4. تحقق من ظهور أيقونة المزامنة المعلقة (🔄)
5. أعد الاتصال بالإنترنت
6. تحقق من اختفاء الأيقونة (تمت المزامنة ✅)

### اختبار 2: المزامنة التلقائية

1. افتح التطبيق على جهازين
2. أضف عميل من الجهاز الأول
3. تحقق من ظهوره تلقائياً في الجهاز الثاني

### اختبار 3: حل التعارضات

1. قطع الاتصال على الجهازين
2. عدّل نفس العميل على الجهازين بقيم مختلفة
3. أعد الاتصال
4. تحقق من أن التعديل الأحدث هو الذي ظهر

---

## ⚠️ ملاحظات مهمة

### 1. قواعد Firestore

تأكد من إعداد قواعد الأمان في Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /customers/{customerId} {
      allow read, write: if request.auth != null;
    }
    match /readings/{readingId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 2. معرفات السجلات

استخدم دائماً معرفات فريدة:

```dart
id: DateTime.now().millisecondsSinceEpoch.toString()
// أو
id: Uuid().v4()
```

### 3. التعامل مع الأخطاء

احرص على معالجة الأخطاء:

```dart
try {
  await repo.addCustomer(customer);
} catch (e) {
  print('خطأ: $e');
  // عرض رسالة للمستخدم
}
```

---

## 🎯 الخطوة التالية

**للبدء الآن:**

1. افتح `lib/screens/customers_screen.dart`
2. استبدل المحتوى بمحتوى `customers_screen_new.dart`
3. افتح `lib/screens/add_customer_screen.dart`
4. استبدل المحتوى بمحتوى `add_customer_screen_new.dart`
5. اختبر التطبيق!

**أو استخدم الملفات الجديدة مباشرة:**

- استخدم `CustomersScreenNew` بدلاً من `CustomersScreen`
- استخدم `AddCustomerScreenNew` بدلاً من `AddCustomerScreen`

---

## 📞 الدعم

إذا واجهت أي مشكلة:

1. تحقق من ملف `SYNC_SYSTEM_README.md` للتفاصيل الكاملة
2. تحقق من console للأخطاء
3. تأكد من تهيئة Firebase بشكل صحيح
4. تأكد من قواعد Firestore

---

## ✨ الميزات الرئيسية

- ✅ **عمل كامل دون اتصال**: جميع العمليات تعمل محلياً
- ✅ **مزامنة تلقائية**: لا حاجة لأي إجراء يدوي
- ✅ **حل تعارضات ذكي**: الأحدث يفوز دائماً
- ✅ **لا فقدان للبيانات**: كل شيء محفوظ محلياً أولاً
- ✅ **مؤشرات واضحة**: معرفة حالة المزامنة في كل وقت
- ✅ **سهولة الاستخدام**: API بسيط وواضح

---

**تم بناء النظام بنجاح! 🎉**
