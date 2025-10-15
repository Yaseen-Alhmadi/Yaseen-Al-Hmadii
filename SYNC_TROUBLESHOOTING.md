# 🔧 دليل استكشاف أخطاء المزامنة

## 📋 المشكلة: لماذا لا تتم المزامنة من Firebase إلى القاعدة المحلية؟

---

## 🔍 الأسباب المحتملة

### 1️⃣ **لا توجد بيانات في Firebase**

- ✅ **الحل:** أضف بيانات تجريبية في Firebase Console أو استخدم شاشة الاختبار

### 2️⃣ **قواعد Firestore الأمنية تمنع القراءة**

- ✅ **الحل:** تحديث قواعد Firestore

### 3️⃣ **لا يوجد اتصال بالإنترنت**

- ✅ **الحل:** تحقق من الاتصال

### 4️⃣ **أخطاء صامتة في الكود**

- ✅ **الحل:** تم إضافة Logging مفصل

### 5️⃣ **SyncService لم يتم تهيئته بشكل صحيح**

- ✅ **الحل:** تحقق من `main.dart`

---

## 🛠️ الحلول المطبقة

### ✅ **1. إضافة Logging مفصل**

تم إضافة رسائل تفصيلية في:

- `CustomerRepository.pullRemoteChanges()`
- `CustomerRepository.listenForRemoteUpdates()`
- `SyncService.initialize()`
- `SyncService.syncAll()`

**الرسائل التي ستراها في Console:**

```
🚀 [SyncService] تهيئة خدمة المزامنة...
👂 [CustomerRepo] بدء الاستماع للتحديثات من Firestore...
📡 [SyncService] حالة الاتصال: متصل
🔄 [SyncService] بدء المزامنة الأولية...
📥 [SyncService] سحب التغييرات من Firestore...
🔄 [CustomerRepo] بدء سحب العملاء من Firestore...
📥 [CustomerRepo] تم جلب 5 عميل من Firestore
➕ [CustomerRepo] إضافة عميل جديد: أحمد محمد (abc123)
✅ [CustomerRepo] اكتملت مزامنة العملاء من Firestore
✅ [SyncService] اكتملت المزامنة بنجاح
```

### ✅ **2. شاشة اختبار Firebase**

تم إنشاء `TestFirebaseSyncScreen` لـ:

- ✅ إضافة بيانات تجريبية في Firebase مباشرة
- ✅ مزامنة يدوية
- ✅ عرض العملاء من Firebase
- ✅ عرض العملاء من القاعدة المحلية
- ✅ مقارنة الأعداد

---

## 🚀 خطوات الاختبار

### **الخطوة 1: افتح شاشة الاختبار**

أضف هذا الكود في أي مكان في تطبيقك:

```dart
import 'screens/test_firebase_sync_screen.dart';

// في أي زر أو قائمة
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const TestFirebaseSyncScreen()),
);
```

### **الخطوة 2: أضف عميل تجريبي**

1. اضغط على زر **"إضافة عميل في Firebase"**
2. راقب Console للرسائل
3. انتظر 2-3 ثواني
4. تحقق من تحديث العداد المحلي

### **الخطوة 3: راقب Console**

يجب أن ترى:

```
🔔 [CustomerRepo] تلقي تحديث: 1 تغيير
➕ [CustomerRepo] إضافة عميل جديد (realtime): عميل تجريبي 14:30:45
```

### **الخطوة 4: إذا لم تعمل المزامنة التلقائية**

اضغط على زر **"مزامنة يدوية"** وراقب الرسائل.

---

## 🔍 تشخيص المشاكل

### ❌ **المشكلة: لا ترى أي رسائل في Console**

**السبب:** SyncService لم يتم تهيئته

**الحل:**

```dart
// تحقق من main.dart
final syncService = SyncService(
  customerRepository: customerRepository,
  readingRepository: readingRepository,
);
await syncService.initialize(); // ✅ مهم جداً
```

---

### ❌ **المشكلة: ترى "تم جلب 0 عميل من Firestore"**

**السبب:** لا توجد بيانات في Firebase

**الحل:**

1. استخدم شاشة الاختبار لإضافة بيانات
2. أو أضف بيانات يدوياً في Firebase Console

---

### ❌ **المشكلة: ترى خطأ "permission-denied"**

**السبب:** قواعد Firestore تمنع القراءة

**الحل:** حدّث قواعد Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // للتطوير فقط - اسمح بكل شيء
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

⚠️ **تحذير:** هذه القواعد للتطوير فقط! غيّرها قبل النشر.

---

### ❌ **المشكلة: ترى "لا يوجد اتصال بالإنترنت"**

**السبب:** الجهاز غير متصل

**الحل:**

1. تحقق من WiFi/Mobile Data
2. جرب فتح متصفح للتأكد
3. أعد تشغيل التطبيق

---

### ❌ **المشكلة: البيانات تُضاف في Firebase لكن لا تظهر محلياً**

**الأسباب المحتملة:**

1. **Realtime Listener لا يعمل:**

   ```
   // يجب أن ترى هذه الرسالة عند بدء التطبيق:
   👂 [CustomerRepo] بدء الاستماع للتحديثات من Firestore...
   ```

2. **خطأ في تحويل البيانات:**

   ```
   // تحقق من أن البيانات في Firebase تحتوي على جميع الحقول المطلوبة
   ```

3. **الاستماع توقف:**
   ```dart
   // تأكد من عدم استدعاء dispose() على Repository
   ```

---

## 📊 فهم آلية المزامنة

### **1. المزامنة الأولية (عند بدء التطبيق)**

```
main.dart
  ↓
SyncService.initialize()
  ↓
listenForRemoteUpdates() ← بدء الاستماع للتحديثات
  ↓
pullRemoteChanges() ← سحب البيانات الموجودة
  ↓
القاعدة المحلية محدثة ✅
```

### **2. المزامنة في الوقت الفعلي**

```
تغيير في Firebase
  ↓
Firestore Snapshot
  ↓
listenForRemoteUpdates()
  ↓
تحديث القاعدة المحلية
  ↓
syncStream.add(null)
  ↓
UI تتحدث تلقائياً ✅
```

### **3. المزامنة من المحلي إلى Firebase**

```
إضافة/تحديث محلي
  ↓
pendingSync = 1
  ↓
_trySync()
  ↓
_pushLocalChanges()
  ↓
Firebase محدث ✅
```

---

## 🎯 نقاط التحقق

### ✅ **قبل الاختبار:**

- [ ] Firebase تم تهيئته في `main.dart`
- [ ] SyncService تم تهيئته وتم استدعاء `initialize()`
- [ ] Repositories تم توفيرها عبر Provider
- [ ] الجهاز متصل بالإنترنت
- [ ] قواعد Firestore تسمح بالقراءة/الكتابة

### ✅ **أثناء الاختبار:**

- [ ] ترى رسائل في Console
- [ ] لا توجد أخطاء حمراء
- [ ] العدادات تتحدث
- [ ] البيانات تظهر في كلا المكانين

### ✅ **بعد الاختبار:**

- [ ] المزامنة التلقائية تعمل
- [ ] التحديثات في الوقت الفعلي تعمل
- [ ] لا توجد تسريبات في الذاكرة
- [ ] الأداء جيد

---

## 🔧 أدوات التشخيص

### **1. فحص قاعدة البيانات المحلية**

```dart
import 'services/database_helper.dart';

final db = await DatabaseHelper.instance.database;
final customers = await db.query('customers');
print('عدد العملاء المحليين: ${customers.length}');
print(customers);
```

### **2. فحص Firebase**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

final snapshot = await FirebaseFirestore.instance
    .collection('customers')
    .get();
print('عدد العملاء في Firebase: ${snapshot.docs.length}');
```

### **3. فحص حالة المزامنة**

```dart
import 'package:provider/provider.dart';
import 'services/sync_service.dart';

final syncService = Provider.of<SyncService>(context, listen: false);
syncService.syncStatusStream.listen((status) {
  print('حالة المزامنة: $status');
});
```

---

## 📞 الدعم

### إذا استمرت المشكلة:

1. **شارك رسائل Console:**

   - انسخ جميع الرسائل من Console
   - ابحث عن رسائل تبدأ بـ `[SyncService]` أو `[CustomerRepo]`

2. **تحقق من Firebase Console:**

   - افتح Firestore Database
   - تحقق من وجود collection اسمه `customers`
   - تحقق من وجود documents بداخله

3. **جرب شاشة الاختبار:**

   - استخدم `TestFirebaseSyncScreen`
   - اضغط جميع الأزرار
   - راقب النتائج

4. **تحقق من قواعد Firestore:**
   - افتح Firebase Console → Firestore → Rules
   - تأكد من السماح بالقراءة والكتابة

---

## 🎉 النتيجة المتوقعة

بعد تطبيق هذه الحلول، يجب أن:

✅ ترى رسائل مفصلة في Console
✅ تعمل المزامنة من Firebase إلى المحلي
✅ تعمل المزامنة من المحلي إلى Firebase
✅ تعمل التحديثات في الوقت الفعلي
✅ تتطابق البيانات في كلا المكانين

---

## 📚 ملفات ذات صلة

- `lib/services/sync_service.dart` - خدمة المزامنة الرئيسية
- `lib/repositories/customer_repository.dart` - مستودع العملاء
- `lib/repositories/reading_repository.dart` - مستودع القراءات
- `lib/screens/test_firebase_sync_screen.dart` - شاشة الاختبار
- `lib/main.dart` - نقطة البداية

---

**آخر تحديث:** ${DateTime.now().toString().split('.')[0]}
