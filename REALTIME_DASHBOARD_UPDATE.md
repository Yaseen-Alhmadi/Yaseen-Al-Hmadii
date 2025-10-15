# 📊 تحديث Dashboard - التحديث التلقائي للإحصائيات

## 🎯 الهدف

تحويل Dashboard من عرض بيانات ثابتة إلى **عرض تلقائي فوري (Real-time)** لجميع الإحصائيات:

- ✅ عدد العملاء
- ✅ قراءات اليوم
- ✅ عدد الفواتير المعلقة

---

## 🔄 ما تم تنفيذه

### **1. إنشاء `InvoiceRepository` جديد**

**الملف:** `lib/repositories/invoice_repository.dart`

**المميزات:**

- ✅ Stream للحصول على جميع الفواتير (Real-time)
- ✅ Stream للحصول على فواتير عميل معين
- ✅ Stream للإحصائيات (عدد المعلقة، المدفوعة، المتأخرة، إلخ)
- ✅ دوال لإنشاء وتحديث وحذف الفواتير

**الدوال الرئيسية:**

```dart
// Stream للحصول على جميع الفواتير
Stream<List<Invoice>> getAllInvoicesStream()

// Stream للحصول على إحصائيات الفواتير
Stream<Map<String, dynamic>> getInvoiceStatsStream()
// يُرجع:
// - totalRevenue: إجمالي الإيرادات
// - pendingAmount: المبلغ المعلق
// - pendingCount: عدد الفواتير المعلقة
// - paidCount: عدد الفواتير المدفوعة
// - overdueCount: عدد الفواتير المتأخرة
// - totalCount: إجمالي الفواتير

// إنشاء فاتورة جديدة
Future<String> createInvoice(Map<String, dynamic> invoiceData)

// تحديث حالة الفاتورة
Future<void> updateInvoiceStatus(String invoiceId, String status, {String? paymentMethod})
```

---

### **2. تحديث `ReadingRepository`**

**الملف:** `lib/repositories/reading_repository.dart`

**الإضافات:**

```dart
// Stream للحصول على عدد قراءات اليوم (Real-time)
Stream<int> getTodayReadingsCountStream()

// Stream للحصول على جميع القراءات (Real-time)
Stream<List<Reading>> getAllReadingsStream()
```

**كيف يعمل `getTodayReadingsCountStream()`:**

1. يحسب تاريخ بداية اليوم (00:00:00)
2. يستعلم من Firestore عن القراءات التي `readingDate >= startOfDay`
3. يُرجع عدد القراءات فوراً
4. يتحدث تلقائياً عند إضافة قراءة جديدة

```dart
final now = DateTime.now();
final startOfDay = DateTime(now.year, now.month, now.day);
final startTimestamp = Timestamp.fromDate(startOfDay);

await for (final snapshot in _firestore
    .collection('meter_readings')
    .where('userId', isEqualTo: userId)
    .where('readingDate', isGreaterThanOrEqualTo: startTimestamp)
    .snapshots()) {
  yield snapshot.docs.length;
}
```

---

### **3. تحديث `main.dart`**

**الإضافات:**

```dart
import 'repositories/invoice_repository.dart';

// تهيئة InvoiceRepository
final invoiceRepository = InvoiceRepository();

// إضافة إلى Providers
Provider<InvoiceRepository>.value(value: invoiceRepository),
```

---

### **4. تحديث `dashboard_screen.dart`**

**التغييرات الرئيسية:**

#### **أ. إضافة Imports:**

```dart
import '../repositories/reading_repository.dart';
import '../repositories/invoice_repository.dart';
```

#### **ب. تحديث `_buildQuickStats()`:**

**قبل:**

```dart
Widget _buildQuickStats(CustomerRepository customerRepo) {
  return StreamBuilder<List<Customer>>(
    stream: customerRepo.customersStream,
    builder: (context, snapshot) {
      int customerCount = snapshot.hasData ? snapshot.data!.length : 0;

      return Row(
        children: [
          _buildStatCard('إجمالي العملاء', customerCount.toString(), ...),
          _buildStatCard('قراءات اليوم', '0', ...), // ثابت ❌
          _buildStatCard('فواتير pending', '0', ...), // ثابت ❌
        ],
      );
    },
  );
}
```

**بعد:**

```dart
Widget _buildQuickStats(
  CustomerRepository customerRepo,
  ReadingRepository readingRepo,
  InvoiceRepository invoiceRepo,
) {
  return Row(
    children: [
      // عدد العملاء (Real-time) ✅
      Expanded(
        child: StreamBuilder<List<Customer>>(
          stream: customerRepo.customersStream,
          builder: (context, snapshot) {
            int customerCount = snapshot.hasData ? snapshot.data!.length : 0;
            return _buildStatCard(
              'إجمالي العملاء',
              customerCount.toString(),
              Icons.people,
              Colors.blue,
              isLoading: snapshot.connectionState == ConnectionState.waiting,
            );
          },
        ),
      ),

      // قراءات اليوم (Real-time) ✅
      Expanded(
        child: StreamBuilder<int>(
          stream: readingRepo.getTodayReadingsCountStream(),
          builder: (context, snapshot) {
            int todayCount = snapshot.hasData ? snapshot.data! : 0;
            return _buildStatCard(
              'قراءات اليوم',
              todayCount.toString(),
              Icons.speed,
              Colors.green,
              isLoading: snapshot.connectionState == ConnectionState.waiting,
            );
          },
        ),
      ),

      // فواتير معلقة (Real-time) ✅
      Expanded(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: invoiceRepo.getInvoiceStatsStream(),
          builder: (context, snapshot) {
            int pendingCount = snapshot.hasData
                ? (snapshot.data!['pendingCount'] ?? 0)
                : 0;
            return _buildStatCard(
              'فواتير معلقة',
              pendingCount.toString(),
              Icons.receipt,
              Colors.orange,
              isLoading: snapshot.connectionState == ConnectionState.waiting,
            );
          },
        ),
      ),
    ],
  );
}
```

#### **ج. تحديث `_buildStatCard()`:**

**الإضافات:**

- معامل `isLoading` لعرض مؤشر تحميل أثناء جلب البيانات
- عرض `CircularProgressIndicator` بدلاً من الرقم أثناء التحميل

```dart
Widget _buildStatCard(
  String title,
  String value,
  IconData icon,
  Color color, {
  bool isLoading = false,
}) {
  return Card(
    elevation: 3,
    child: Padding(
      padding: EdgeInsets.all(15),
      child: Column(
        children: [
          Icon(icon, size: 30, color: color),
          SizedBox(height: 8),
          isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
```

---

## 🎨 تجربة المستخدم (UX)

### **1. التحميل الأولي:**

- عرض `CircularProgressIndicator` ملون لكل إحصائية
- يختفي المؤشر بمجرد وصول البيانات

### **2. التحديث التلقائي:**

- عند إضافة عميل جديد → يتحدث عدد العملاء فوراً ✅
- عند إضافة قراءة جديدة → يتحدث عدد قراءات اليوم فوراً ✅
- عند إنشاء فاتورة → يتحدث عدد الفواتير المعلقة فوراً ✅
- عند دفع فاتورة → ينقص عدد الفواتير المعلقة فوراً ✅

### **3. الأداء:**

- استخدام Streams بدلاً من Polling
- لا حاجة لزر "تحديث" يدوي
- استهلاك منخفض للبيانات (فقط التغييرات)

---

## 📊 الإحصائيات المتاحة

### **من `InvoiceRepository.getInvoiceStatsStream()`:**

| الحقل           | الوصف                                 | النوع    |
| --------------- | ------------------------------------- | -------- |
| `totalRevenue`  | إجمالي الإيرادات (الفواتير المدفوعة)  | `double` |
| `pendingAmount` | المبلغ المعلق (الفواتير غير المدفوعة) | `double` |
| `pendingCount`  | عدد الفواتير المعلقة                  | `int`    |
| `paidCount`     | عدد الفواتير المدفوعة                 | `int`    |
| `overdueCount`  | عدد الفواتير المتأخرة                 | `int`    |
| `totalCount`    | إجمالي عدد الفواتير                   | `int`    |

**مثال على الاستخدام:**

```dart
StreamBuilder<Map<String, dynamic>>(
  stream: invoiceRepo.getInvoiceStatsStream(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();

    final stats = snapshot.data!;
    return Column(
      children: [
        Text('إجمالي الإيرادات: ${stats['totalRevenue']} ريال'),
        Text('فواتير معلقة: ${stats['pendingCount']}'),
        Text('فواتير متأخرة: ${stats['overdueCount']}'),
      ],
    );
  },
)
```

---

## 🔍 استكشاف الأخطاء

### **المشكلة 1: "The query requires an index"**

**السبب:** الاستعلامات تجمع بين `where()` و `orderBy()` على حقول مختلفة.

**الحل:** أنشئ Firestore Indexes (راجع `FIRESTORE_INDEXES_SETUP.md`)

**الـ Indexes المطلوبة:**

1. **للفواتير:**

   - Collection: `invoices`
   - Fields: `userId` (ASC) + `issueDate` (DESC)

2. **للقراءات:**

   - Collection: `meter_readings`
   - Fields: `userId` (ASC) + `readingDate` (DESC)

3. **لقراءات اليوم:**
   - Collection: `meter_readings`
   - Fields: `userId` (ASC) + `readingDate` (ASC)

---

### **المشكلة 2: البيانات لا تتحدث**

**الأسباب المحتملة:**

1. **لا يوجد اتصال بالإنترنت:**

   - تحقق من الاتصال
   - Firestore يعمل Offline لكن Streams تحتاج اتصال للتحديث الفوري

2. **الـ Indexes لم تُبنى بعد:**

   - تحقق من Firebase Console → Firestore → Indexes
   - انتظر حتى تصبح الحالة "Enabled"

3. **خطأ في userId:**
   - تحقق من أن المستخدم مسجل دخول
   - راجع الـ logs: `debugPrint` في Repositories

---

### **المشكلة 3: "قراءات اليوم" تعرض 0 دائماً**

**السبب:** حقل `readingDate` غير موجود أو بصيغة خاطئة في Firestore.

**الحل:**

1. تحقق من أن القراءات الجديدة تحتوي على `readingDate` من نوع `Timestamp`
2. تحقق من أن التاريخ صحيح (اليوم الحالي)

**مثال على البيانات الصحيحة:**

```dart
await _firestore.collection('meter_readings').add({
  'userId': userId,
  'customerId': customerId,
  'reading': 150.0,
  'readingDate': Timestamp.now(), // ✅ مهم!
  'createdAt': Timestamp.now(),
});
```

---

## 🧪 الاختبار

### **اختبار 1: عدد العملاء**

1. افتح Dashboard
2. افتح شاشة "إدارة العملاء" في نافذة أخرى
3. أضف عميل جديد
4. **النتيجة المتوقعة:** عدد العملاء في Dashboard يزيد فوراً ✅

---

### **اختبار 2: قراءات اليوم**

1. افتح Dashboard
2. أضف قراءة جديدة لأي عميل
3. **النتيجة المتوقعة:** "قراءات اليوم" يزيد بـ 1 فوراً ✅

---

### **اختبار 3: فواتير معلقة**

1. افتح Dashboard
2. أضف قراءة جديدة (تُنشئ فاتورة تلقائياً)
3. **النتيجة المتوقعة:** "فواتير معلقة" يزيد بـ 1 فوراً ✅
4. افتح شاشة الفواتير وادفع الفاتورة
5. **النتيجة المتوقعة:** "فواتير معلقة" ينقص بـ 1 فوراً ✅

---

## 📈 الأداء

### **قبل التحديث:**

- ❌ بيانات ثابتة (لا تتحدث)
- ❌ يحتاج تحديث يدوي (إعادة فتح الشاشة)
- ❌ لا يعكس الحالة الفعلية

### **بعد التحديث:**

- ✅ تحديث فوري (Real-time)
- ✅ لا حاجة لتحديث يدوي
- ✅ يعكس الحالة الفعلية دائماً
- ✅ استهلاك منخفض للبيانات (فقط التغييرات)

---

## 🎯 الخلاصة

### **ما تم إنجازه:**

1. ✅ إنشاء `InvoiceRepository` مع Streams كاملة
2. ✅ إضافة Streams للقراءات اليومية في `ReadingRepository`
3. ✅ تحديث Dashboard لاستخدام Streams
4. ✅ إضافة مؤشرات تحميل (Loading indicators)
5. ✅ دعم كامل للتحديث التلقائي

### **الفوائد:**

- 🚀 تجربة مستخدم أفضل (UX)
- ⚡ بيانات دائماً محدثة
- 📊 إحصائيات دقيقة في الوقت الفعلي
- 🔄 لا حاجة لتحديث يدوي

### **الملفات المُعدلة:**

| الملف                                      | التغيير                    |
| ------------------------------------------ | -------------------------- |
| `lib/repositories/invoice_repository.dart` | ✅ ملف جديد                |
| `lib/repositories/reading_repository.dart` | ✅ إضافة Streams           |
| `lib/main.dart`                            | ✅ إضافة InvoiceRepository |
| `lib/screens/dashboard_screen.dart`        | ✅ تحديث كامل للإحصائيات   |

---

## 📞 للمساعدة

إذا واجهت أي مشكلة:

1. راجع قسم "استكشاف الأخطاء" أعلاه
2. تحقق من الـ logs في التطبيق
3. تأكد من إنشاء Firestore Indexes (راجع `FIRESTORE_INDEXES_SETUP.md`)

---

**آخر تحديث:** 2024
**الحالة:** ✅ جاهز للاستخدام
