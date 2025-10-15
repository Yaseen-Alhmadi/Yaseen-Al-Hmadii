# 🔧 دليل المطور - نظام المزامنة الفورية

## 📖 نظرة عامة

هذا الدليل يشرح كيفية استخدام نظام المزامنة الفورية في التطبيق، وكيفية تطبيق نفس النمط على جداول أخرى.

---

## 🏗️ البنية المعمارية

### **النمط المُستخدم: Stream Pattern مع SQLite**

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                            │
│              (Dashboard, CustomersScreen)                   │
│                   StreamBuilder<T>                          │
└─────────────────────┬───────────────────────────────────────┘
                      │ يستمع لـ
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    Repository Layer                         │
│                  CustomerRepository                         │
│              Stream<List<Customer>>                         │
└─────────────────────┬───────────────────────────────────────┘
                      │ يقرأ من
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     Data Layer                              │
│                  SQLite (Local DB)                          │
│                   DatabaseHelper                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔑 المكونات الأساسية

### **1. StreamController**

```dart
// في CustomerRepository
final _syncController = StreamController<void>.broadcast();
```

**الغرض:**

- إطلاق إشعارات عند حدوث تغييرات
- `broadcast()` يسمح بعدة مستمعين

**متى يُستخدم:**

- عند إضافة سجل جديد
- عند تحديث سجل موجود
- عند حذف سجل
- عند استقبال تحديثات من Firestore

---

### **2. Stream Generator**

```dart
Stream<List<Customer>> get customersStream async* {
  // 1. إرسال البيانات الأولية
  yield await getCustomers();

  // 2. الاستماع للتحديثات
  await for (final _ in _syncController.stream) {
    yield await getCustomers();
  }
}
```

**كيف يعمل:**

1. عند الاشتراك في الـ Stream، يُرسل البيانات الأولية فوراً
2. ينتظر إشعارات من `_syncController`
3. عند كل إشعار، يُرسل البيانات المحدثة

---

### **3. إطلاق التحديثات**

```dart
Future<void> addCustomer(Customer customer) async {
  // 1. حفظ في SQLite
  await _dbHelper.insert('customers', data);

  // 2. إطلاق إشعار التحديث ← هنا السحر! ✨
  _syncController.add(null);

  // 3. محاولة المزامنة مع Firestore
  await _trySync();
}
```

**القاعدة الذهبية:**

> **كل عملية تُغير البيانات يجب أن تُطلق `_syncController.add(null)`**

---

### **4. StreamBuilder في UI**

```dart
StreamBuilder<List<Customer>>(
  stream: customerRepo.customersStream,
  builder: (context, snapshot) {
    // معالجة الحالات
    if (snapshot.hasError) return ErrorWidget();
    if (snapshot.connectionState == ConnectionState.waiting) return LoadingWidget();

    final customers = snapshot.data ?? [];
    return ListView.builder(...);
  },
)
```

**الفوائد:**

- ✅ تحديث تلقائي عند أي تغيير
- ✅ لا حاجة لـ `setState()`
- ✅ لا حاجة لـ `_loadData()` يدوياً

---

## 🎯 تطبيق النمط على جداول أخرى

### **مثال: ReadingRepository**

#### **الخطوة 1: إضافة StreamController**

```dart
class ReadingRepository {
  final _syncController = StreamController<void>.broadcast();

  // ... باقي الكود
}
```

---

#### **الخطوة 2: إضافة Stream Generator**

```dart
Stream<List<Reading>> get readingsStream async* {
  yield await getReadings();

  await for (final _ in _syncController.stream) {
    yield await getReadings();
  }
}
```

---

#### **الخطوة 3: إطلاق التحديثات في جميع العمليات**

```dart
Future<void> addReading(Reading reading) async {
  await _dbHelper.insert('readings', data);
  _syncController.add(null); // ← إطلاق التحديث
  await _trySync();
}

Future<void> updateReading(Reading reading) async {
  await _dbHelper.update('readings', data, 'id = ?', [reading.id]);
  _syncController.add(null); // ← إطلاق التحديث
  await _trySync();
}

Future<void> deleteReading(String id) async {
  await _dbHelper.update('readings', {'deleted': 1}, 'id = ?', [id]);
  _syncController.add(null); // ← إطلاق التحديث
  await _trySync();
}
```

---

#### **الخطوة 4: تحديث dispose()**

```dart
void dispose() {
  _firestoreSubscription?.cancel();
  _syncController.close(); // ← إغلاق الـ controller
}
```

---

#### **الخطوة 5: استخدام StreamBuilder في UI**

```dart
// في ReadingsScreen
class ReadingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final readingRepo = Provider.of<ReadingRepository>(context, listen: false);

    return StreamBuilder<List<Reading>>(
      stream: readingRepo.readingsStream,
      builder: (context, snapshot) {
        // معالجة البيانات
      },
    );
  }
}
```

---

## 🔍 نقاط مهمة

### **1. استخدام `broadcast()`**

```dart
// ✅ صحيح
final _syncController = StreamController<void>.broadcast();

// ❌ خطأ - لن يسمح بعدة مستمعين
final _syncController = StreamController<void>();
```

**السبب:**

- `broadcast()` يسمح لعدة شاشات بالاستماع لنفس الـ Stream
- بدونه، سيحدث خطأ عند محاولة الاستماع من شاشة ثانية

---

### **2. إغلاق الـ Controllers**

```dart
void dispose() {
  _syncController.close(); // ← مهم جداً!
}
```

**السبب:**

- منع تسرب الذاكرة (Memory Leaks)
- تحرير الموارد

---

### **3. معالجة الأخطاء**

```dart
StreamBuilder<List<Customer>>(
  stream: customerRepo.customersStream,
  builder: (context, snapshot) {
    // ✅ دائماً تحقق من الأخطاء أولاً
    if (snapshot.hasError) {
      return Center(child: Text('خطأ: ${snapshot.error}'));
    }

    // ✅ ثم تحقق من حالة الاتصال
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }

    // ✅ استخدم قيمة افتراضية
    final data = snapshot.data ?? [];

    return ListView.builder(...);
  },
)
```

---

### **4. تجنب الاستماع المتكرر**

```dart
// ✅ صحيح - listen: false
final repo = Provider.of<CustomerRepository>(context, listen: false);

// ❌ خطأ - سيُعيد بناء الـ Widget عند كل تغيير في Provider
final repo = Provider.of<CustomerRepository>(context);
```

**السبب:**

- `StreamBuilder` يستمع للـ Stream بالفعل
- لا حاجة لإعادة بناء الـ Widget من Provider

---

## 🎨 أمثلة عملية

### **مثال 1: Stream مع فلترة**

```dart
// في Repository
Stream<List<Customer>> getActiveCustomersStream() async* {
  yield await getActiveCustomers();

  await for (final _ in _syncController.stream) {
    yield await getActiveCustomers();
  }
}

Future<List<Customer>> getActiveCustomers() async {
  final rows = await _dbHelper.queryRows(
    'customers',
    'userId = ? AND deleted = ? AND status = ?',
    [userId, 0, 'active'],
  );
  return rows.map((row) => Customer.fromMap(row)).toList();
}
```

---

### **مثال 2: Stream مع ترتيب**

```dart
Stream<List<Customer>> getCustomersSortedByNameStream() async* {
  yield await getCustomersSortedByName();

  await for (final _ in _syncController.stream) {
    yield await getCustomersSortedByName();
  }
}

Future<List<Customer>> getCustomersSortedByName() async {
  final customers = await getCustomers();
  customers.sort((a, b) => a.name.compareTo(b.name));
  return customers;
}
```

---

### **مثال 3: Stream مع عدد السجلات**

```dart
// في Dashboard
StreamBuilder<List<Customer>>(
  stream: customerRepo.customersStream,
  builder: (context, snapshot) {
    final count = snapshot.data?.length ?? 0;

    return Text(
      'إجمالي العملاء: $count',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  },
)
```

---

## 🐛 استكشاف الأخطاء

### **المشكلة: Stream لا يُرسل تحديثات**

**الحل:**

1. تحقق من أن `_syncController.add(null)` يتم استدعاؤه
2. تحقق من أن الـ Stream يستخدم `broadcast()`
3. تحقق من رسائل Debug في Console

```dart
Future<void> addCustomer(Customer customer) async {
  await _dbHelper.insert('customers', data);

  // ✅ أضف رسالة Debug
  debugPrint('🔔 [CustomerRepo] إطلاق تحديث بعد إضافة عميل');
  _syncController.add(null);

  await _trySync();
}
```

---

### **المشكلة: "Bad state: Stream has already been listened to"**

**السبب:**

- الـ Stream ليس `broadcast()`

**الحل:**

```dart
// ✅ أضف broadcast()
final _syncController = StreamController<void>.broadcast();
```

---

### **المشكلة: تسرب ذاكرة (Memory Leak)**

**السبب:**

- عدم إغلاق الـ StreamController

**الحل:**

```dart
void dispose() {
  _syncController.close(); // ← لا تنسى!
}
```

---

## 📊 مقارنة الأنماط

### **FutureBuilder vs StreamBuilder**

| الميزة               | FutureBuilder | StreamBuilder |
| -------------------- | ------------- | ------------- |
| **التحديث التلقائي** | ❌ لا         | ✅ نعم        |
| **الاستخدام**        | بيانات ثابتة  | بيانات متغيرة |
| **الأداء**           | جيد           | ممتاز         |
| **التعقيد**          | بسيط          | متوسط         |
| **Offline**          | ✅ نعم        | ✅ نعم        |
| **Realtime**         | ❌ لا         | ✅ نعم        |

---

## 🎯 أفضل الممارسات

### **1. استخدم Stream للبيانات المتغيرة**

```dart
// ✅ جيد - بيانات تتغير كثيراً
StreamBuilder<List<Customer>>(...)

// ❌ سيء - بيانات ثابتة (مثل الإعدادات)
FutureBuilder<Settings>(...)
```

---

### **2. أغلق الـ Streams دائماً**

```dart
@override
void dispose() {
  _syncController.close();
  _firestoreSubscription?.cancel();
  super.dispose();
}
```

---

### **3. استخدم `listen: false` مع Provider**

```dart
// ✅ صحيح
final repo = Provider.of<CustomerRepository>(context, listen: false);

// ❌ خطأ
final repo = Provider.of<CustomerRepository>(context);
```

---

### **4. أضف رسائل Debug**

```dart
Future<void> addCustomer(Customer customer) async {
  debugPrint('➕ [CustomerRepo] إضافة عميل: ${customer.name}');
  await _dbHelper.insert('customers', data);

  debugPrint('🔔 [CustomerRepo] إطلاق تحديث');
  _syncController.add(null);

  await _trySync();
}
```

---

## 📚 مراجع إضافية

### **الملفات ذات الصلة:**

- `lib/repositories/customer_repository.dart` - التنفيذ الكامل
- `lib/screens/customers_screen.dart` - مثال على الاستخدام
- `lib/screens/dashboard_screen.dart` - مثال آخر
- `REALTIME_SYNC_UPDATE.md` - توثيق شامل
- `TEST_CHECKLIST.md` - سيناريوهات الاختبار

---

## 🎉 الخلاصة

### **النمط المُستخدم:**

1. ✅ `StreamController<void>.broadcast()` لإطلاق الإشعارات
2. ✅ `Stream<List<T>> get dataStream async*` لإرسال البيانات
3. ✅ `_syncController.add(null)` في كل عملية تعديل
4. ✅ `StreamBuilder<List<T>>` في UI
5. ✅ `dispose()` لإغلاق الـ controllers

### **الفوائد:**

- ✅ تحديث تلقائي لجميع الشاشات
- ✅ دعم كامل للعمل Offline
- ✅ أداء ممتاز (قراءة محلية)
- ✅ كود بسيط وسهل الصيانة

---

**آخر تحديث:** 2024  
**الإصدار:** 1.1.0  
**المؤلف:** فريق التطوير
