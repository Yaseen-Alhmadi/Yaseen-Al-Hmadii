# نظام المزامنة بين Firebase و SQLite

## نظرة عامة

تم تطبيق نظام مزامنة متكامل بين Cloud Firestore (السحابة) وقاعدة SQLite المحلية لضمان:

- عمل التطبيق بالكامل دون اتصال بالإنترنت
- مزامنة تلقائية عند توفر الاتصال
- حل التعارضات بناءً على آخر تعديل
- عدم فقدان البيانات في أي حالة

## البنية المعمارية

### 1. طبقة قاعدة البيانات (Database Layer)

**الملف:** `lib/services/database_helper.dart`

تم تحديث جداول SQLite لتشمل حقول المزامنة:

- `lastModified`: تاريخ آخر تعديل (ISO 8601)
- `lastSyncedAt`: تاريخ آخر مزامنة ناجحة
- `pendingSync`: علامة للسجلات في انتظار المزامنة (0 أو 1)
- `deleted`: علامة للحذف المنطقي (0 أو 1)

### 2. طبقة النماذج (Models Layer)

**الملفات:**

- `lib/models/customer_model.dart`
- `lib/models/reading_model.dart`

كل نموذج يحتوي على:

- `toMap()`: تحويل إلى Map للحفظ في SQLite
- `toFirestore()`: تحويل إلى Map للحفظ في Firestore (بدون حقول المزامنة المحلية)
- `fromMap()`: إنشاء كائن من Map
- `copyWith()`: نسخ الكائن مع تعديل بعض الحقول

### 3. طبقة المستودعات (Repository Layer)

**الملفات:**

- `lib/repositories/customer_repository.dart`
- `lib/repositories/reading_repository.dart`

كل Repository يوفر:

- **عمليات CRUD محلية**: إضافة، تحديث، حذف، قراءة من SQLite
- **مزامنة تلقائية**: رفع التغييرات المحلية إلى Firestore
- **استماع للتغييرات**: الاشتراك في تحديثات Firestore في الوقت الفعلي
- **حل التعارضات**: مقارنة `lastModified` لتحديد النسخة الأحدث

#### مثال استخدام CustomerRepository:

```dart
// الحصول على جميع العملاء
final customers = await customerRepository.getCustomers();

// إضافة عميل جديد
final customer = Customer(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  name: 'أحمد محمد',
  phone: '0123456789',
  // ... باقي الحقول
);
await customerRepository.addCustomer(customer);

// تحديث عميل
final updatedCustomer = customer.copyWith(name: 'أحمد علي');
await customerRepository.updateCustomer(updatedCustomer);

// حذف عميل (حذف منطقي)
await customerRepository.deleteCustomer(customerId);
```

### 4. خدمة المزامنة المركزية (Sync Service)

**الملف:** `lib/services/sync_service.dart`

المسؤوليات:

- تهيئة جميع Repositories
- مراقبة حالة الاتصال بالإنترنت
- تشغيل المزامنة التلقائية عند استعادة الاتصال
- توفير واجهة للمزامنة اليدوية
- بث حالة المزامنة (syncing, synced, offline, error)

#### حالات المزامنة:

```dart
enum SyncStatus {
  syncing,   // جاري المزامنة
  synced,    // تمت المزامنة
  offline,   // غير متصل
  error,     // خطأ في المزامنة
}
```

## آلية عمل المزامنة

### 1. عند إضافة/تعديل سجل محلياً:

```
1. حفظ السجل في SQLite مع:
   - pendingSync = 1
   - lastModified = DateTime.now()

2. إرسال إشعار عبر syncStream

3. محاولة المزامنة الفورية:
   - التحقق من الاتصال
   - إذا متصل: رفع إلى Firestore
   - تحديث pendingSync = 0
   - تحديث lastSyncedAt
```

### 2. عند استقبال تحديث من Firestore:

```
1. استقبال التغيير عبر snapshots()

2. التحقق من وجود السجل محلياً:
   - إذا غير موجود: إضافة جديدة
   - إذا موجود: مقارنة lastModified

3. حل التعارض:
   - إذا السجل المحلي pendingSync = 1: تجاهل التحديث السحابي
   - إذا السجل السحابي أحدث: تحديث المحلي
   - إذا السجل المحلي أحدث: سيتم رفعه في المزامنة التالية
```

### 3. عند استعادة الاتصال:

```
1. الكشف التلقائي عبر connectivity_plus

2. تشغيل syncAll():
   - سحب التغييرات من Firestore
   - رفع السجلات المعلقة (pendingSync = 1)

3. تحديث حالة المزامنة
```

## التكامل مع التطبيق

### في main.dart:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // تهيئة Repositories
  final customerRepository = CustomerRepository();
  final readingRepository = ReadingRepository();

  // تهيئة خدمة المزامنة
  final syncService = SyncService(
    customerRepository: customerRepository,
    readingRepository: readingRepository,
  );
  await syncService.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<CustomerRepository>.value(value: customerRepository),
        Provider<ReadingRepository>.value(value: readingRepository),
        Provider<SyncService>.value(value: syncService),
      ],
      child: const WaterManagementApp(),
    ),
  );
}
```

### في الشاشات:

```dart
class CustomersScreenNew extends StatefulWidget {
  @override
  State<CustomersScreenNew> createState() => _CustomersScreenNewState();
}

class _CustomersScreenNewState extends State<CustomersScreenNew> {
  @override
  void initState() {
    super.initState();

    // الاستماع لتغييرات البيانات
    final repository = Provider.of<CustomerRepository>(context, listen: false);
    repository.syncStream.listen((_) {
      // إعادة تحميل البيانات
      _loadCustomers();
    });

    // الاستماع لحالة المزامنة
    final syncService = Provider.of<SyncService>(context, listen: false);
    syncService.syncStatusStream.listen((status) {
      setState(() => _syncStatus = status);
    });
  }

  // ... باقي الكود
}
```

## الملفات الجديدة المضافة

### Models:

- ✅ `lib/models/customer_model.dart`
- ✅ `lib/models/reading_model.dart`

### Repositories:

- ✅ `lib/repositories/customer_repository.dart`
- ✅ `lib/repositories/reading_repository.dart`

### Services:

- ✅ `lib/services/sync_service.dart`

### Screens (أمثلة محدثة):

- ✅ `lib/screens/customers_screen_new.dart`
- ✅ `lib/screens/add_customer_screen_new.dart`

## التحديثات المطلوبة

### 1. تحديث قاعدة البيانات:

- ✅ تم تحديث `database_helper.dart` لإضافة حقول المزامنة
- ✅ تم رفع رقم الإصدار إلى 2
- ✅ تم إضافة منطق الترقية في `_upgradeDB()`

### 2. إضافة الحزم المطلوبة:

```yaml
dependencies:
  connectivity_plus: ^5.0.2 # ✅ تمت الإضافة
```

### 3. تشغيل الأوامر:

```bash
flutter pub get
```

## الخطوات التالية للتطبيق الكامل

### 1. تحديث الشاشات الموجودة:

- استبدال `CustomersScreen` بـ `CustomersScreenNew`
- استبدال `AddCustomerScreen` بـ `AddCustomerScreenNew`
- تحديث شاشات القراءات والفواتير بنفس الطريقة

### 2. إضافة Repository للفواتير:

- إنشاء `lib/models/invoice_model.dart`
- إنشاء `lib/repositories/invoice_repository.dart`
- إضافته إلى `SyncService`

### 3. تحسينات اختيارية:

- إضافة مؤشر تقدم للمزامنة
- إضافة سجل للأخطاء
- إضافة إحصائيات المزامنة
- إضافة خيار المزامنة اليدوية في الإعدادات

## اختبار النظام

### سيناريوهات الاختبار:

#### 1. الإضافة دون اتصال:

```
1. قطع الاتصال بالإنترنت
2. إضافة عميل جديد
3. التحقق من حفظه محلياً مع pendingSync = 1
4. إعادة الاتصال
5. التحقق من رفعه إلى Firestore تلقائياً
```

#### 2. التعديل المتزامن:

```
1. تعديل سجل من جهاز A
2. تعديل نفس السجل من جهاز B
3. التحقق من أن الأحدث يفوز
```

#### 3. الحذف:

```
1. حذف سجل محلياً
2. التحقق من deleted = 1
3. التحقق من حذفه من Firestore
```

## الأمان والأداء

### قواعد Firestore الموصى بها:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // السماح بالقراءة والكتابة للمستخدمين المصادق عليهم فقط
    match /customers/{customerId} {
      allow read, write: if request.auth != null;
    }

    match /readings/{readingId} {
      allow read, write: if request.auth != null;
    }

    match /invoices/{invoiceId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### تحسينات الأداء:

- استخدام Batch للعمليات المتعددة
- تحديد حجم البيانات المسحوبة باستخدام `limit()`
- استخدام Indexes في Firestore للاستعلامات المعقدة
- تخزين مؤقت للبيانات المستخدمة بكثرة

## الدعم والصيانة

### تسجيل الأخطاء:

يمكن إضافة Firebase Crashlytics لتتبع الأخطاء:

```dart
try {
  await repository.addCustomer(customer);
} catch (e, stackTrace) {
  FirebaseCrashlytics.instance.recordError(e, stackTrace);
  print('خطأ في إضافة العميل: $e');
}
```

### المراقبة:

- مراقبة عدد السجلات المعلقة
- مراقبة معدل نجاح المزامنة
- مراقبة وقت استجابة Firestore

## الخلاصة

تم بناء نظام مزامنة احترافي يضمن:

- ✅ عمل التطبيق بالكامل دون اتصال
- ✅ مزامنة تلقائية وشفافة
- ✅ حل التعارضات بذكاء
- ✅ عدم فقدان البيانات
- ✅ تجربة مستخدم سلسة
- ✅ قابلية التوسع والصيانة

النظام جاهز للاستخدام ويمكن توسيعه بسهولة لإضافة المزيد من الكيانات والميزات.
