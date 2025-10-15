# 🔍 دليل إعداد Firestore Indexes

## 🎯 الهدف

إنشاء **Composite Indexes** في Firestore لتمكين الاستعلامات المعقدة التي تستخدم `where()` + `orderBy()`.

---

## 🚨 المشكلة

عند تشغيل التطبيق، تظهر هذه الأخطاء في الـ logs:

```
[Firestore]: Listen for Query(invoices where userId==... order by -issueDate) failed:
Status{code=FAILED_PRECONDITION, description=The query requires an index...}
```

```
[Firestore]: Listen for Query(meter_readings where userId==... order by -readingDate) failed:
Status{code=FAILED_PRECONDITION, description=The query requires an index...}
```

**السبب:** Firestore يتطلب Indexes مخصصة للاستعلامات التي تجمع بين `where()` و `orderBy()` على حقول مختلفة.

---

## ✅ الحل (3 طرق)

### **الطريقة 1: استخدام الروابط المباشرة (الأسرع) ⚡**

عند ظهور الخطأ في الـ logs، انسخ الرابط المُعطى والصقه في المتصفح:

#### **1. Index للفواتير (Invoices):**

```
https://console.firebase.google.com/v1/r/project/water-management-system-d059c/firestore/indexes?create_composite=...
```

#### **2. Index للقراءات (Meter Readings):**

```
https://console.firebase.google.com/v1/r/project/water-management-system-d059c/firestore/indexes?create_composite=...
```

**الخطوات:**

1. انقر على الرابط
2. سيفتح Firebase Console مع الـ Index جاهز
3. اضغط **Create Index**
4. انتظر حتى يكتمل البناء (1-5 دقائق)

---

### **الطريقة 2: إنشاء يدوي من Firebase Console 🖱️**

#### **الخطوة 1: افتح Firebase Console**

1. اذهب إلى: https://console.firebase.google.com/
2. اختر مشروع: **water-management-system-d059c**
3. من القائمة الجانبية: **Firestore Database** → **Indexes**

#### **الخطوة 2: أضف Index للفواتير**

1. اضغط **Create Index**
2. املأ البيانات:
   - **Collection ID:** `invoices`
   - **Fields:**
     - Field: `userId` → Order: **Ascending**
     - Field: `issueDate` → Order: **Descending**
     - Field: `__name__` → Order: **Descending** (يُضاف تلقائياً)
3. اضغط **Create**

#### **الخطوة 3: أضف Index للقراءات**

1. اضغط **Create Index**
2. املأ البيانات:
   - **Collection ID:** `meter_readings`
   - **Fields:**
     - Field: `userId` → Order: **Ascending**
     - Field: `readingDate` → Order: **Descending**
     - Field: `__name__` → Order: **Descending** (يُضاف تلقائياً)
3. اضغط **Create**

#### **الخطوة 4 (اختياري): أضف Index للعملاء**

1. اضغط **Create Index**
2. املأ البيانات:
   - **Collection ID:** `customers`
   - **Fields:**
     - Field: `userId` → Order: **Ascending**
     - Field: `name` → Order: **Ascending**
3. اضغط **Create**

---

### **الطريقة 3: استخدام Firebase CLI (للمطورين) 💻**

#### **الخطوة 1: تثبيت Firebase CLI**

```bash
npm install -g firebase-tools
```

#### **الخطوة 2: تسجيل الدخول**

```bash
firebase login
```

#### **الخطوة 3: تهيئة المشروع**

```bash
cd c:\Users\lenovo\Desktop\Tetse\tests1\water_management_system
firebase init firestore
```

**اختر:**

- ✅ Use an existing project: **water-management-system-d059c**
- ✅ Firestore Rules: `firestore.rules`
- ✅ Firestore Indexes: `firestore.indexes.json`

#### **الخطوة 4: رفع الـ Indexes**

```bash
firebase deploy --only firestore:indexes
```

**النتيجة:**

```
✔ Deploy complete!
Indexes are being built...
```

#### **الخطوة 5: التحقق من الحالة**

```bash
firebase firestore:indexes
```

---

## 📋 الـ Indexes المطلوبة

### **1. Index للفواتير (invoices)**

| Field       | Order      | الغرض                               |
| ----------- | ---------- | ----------------------------------- |
| `userId`    | Ascending  | فلترة الفواتير حسب المستخدم         |
| `issueDate` | Descending | ترتيب الفواتير من الأحدث إلى الأقدم |
| `__name__`  | Descending | ضمان ترتيب ثابت (يُضاف تلقائياً)    |

**الاستعلام المُستخدم:**

```dart
_firestore
  .collection('invoices')
  .where('userId', isEqualTo: userId)
  .orderBy('issueDate', descending: true)
```

---

### **2. Index للقراءات (meter_readings)**

| Field         | Order      | الغرض                               |
| ------------- | ---------- | ----------------------------------- |
| `userId`      | Ascending  | فلترة القراءات حسب المستخدم         |
| `readingDate` | Descending | ترتيب القراءات من الأحدث إلى الأقدم |
| `__name__`    | Descending | ضمان ترتيب ثابت (يُضاف تلقائياً)    |

**الاستعلام المُستخدم:**

```dart
_firestore
  .collection('meter_readings')
  .where('userId', isEqualTo: userId)
  .orderBy('readingDate', descending: true)
```

---

### **3. Index للعملاء (customers) - اختياري**

| Field    | Order     | الغرض                      |
| -------- | --------- | -------------------------- |
| `userId` | Ascending | فلترة العملاء حسب المستخدم |
| `name`   | Ascending | ترتيب العملاء أبجدياً      |

**الاستعلام المُستخدم:**

```dart
_firestore
  .collection('customers')
  .where('userId', isEqualTo: userId)
  .orderBy('name')
```

---

## ⏱️ مدة بناء الـ Indexes

| عدد السجلات | المدة المتوقعة |
| ----------- | -------------- |
| 0 - 100     | 1-2 دقيقة      |
| 100 - 1000  | 2-5 دقائق      |
| 1000+       | 5-15 دقيقة     |

**ملاحظة:** يمكنك استخدام التطبيق أثناء بناء الـ Indexes، لكن الاستعلامات المُعتمدة عليها لن تعمل حتى يكتمل البناء.

---

## 🧪 التحقق من نجاح الإعداد

### **1. من Firebase Console:**

1. اذهب إلى: **Firestore Database** → **Indexes**
2. تحقق من أن جميع الـ Indexes في حالة **Enabled** (وليس Building)

### **2. من التطبيق:**

1. شغل التطبيق: `flutter run`
2. افتح شاشة **الفواتير** أو **القراءات**
3. تحقق من الـ logs - يجب ألا تظهر أخطاء `FAILED_PRECONDITION`

### **3. من الـ Logs:**

**قبل:**

```
[Firestore]: Listen for Query(...) failed: Status{code=FAILED_PRECONDITION...}
```

**بعد:**

```
✅ لا توجد أخطاء - البيانات تُحمل بنجاح
```

---

## 🔍 استكشاف الأخطاء

### **المشكلة 1: "Index is still building"**

**الحل:** انتظر بضع دقائق حتى يكتمل البناء.

### **المشكلة 2: "Permission denied"**

**الحل:** تأكد من أنك مسجل دخول بحساب له صلاحيات على المشروع.

### **المشكلة 3: "Index already exists"**

**الحل:** الـ Index موجود بالفعل - لا حاجة لإنشائه مرة أخرى.

### **المشكلة 4: الاستعلام لا يزال يفشل بعد إنشاء الـ Index**

**الحل:**

1. تحقق من أن الـ Index في حالة **Enabled**
2. أعد تشغيل التطبيق
3. تحقق من أن الاستعلام يطابق الـ Index تماماً (نفس الحقول ونفس الترتيب)

---

## 📚 ملفات ذات صلة

| الملف                      | الوصف                                |
| -------------------------- | ------------------------------------ |
| `firestore.indexes.json`   | تعريف الـ Indexes (للـ Firebase CLI) |
| `firestore.rules`          | قواعد الأمان (إن وُجدت)              |
| `invoice_service.dart`     | الاستعلامات على جدول الفواتير        |
| `reading_service.dart`     | الاستعلامات على جدول القراءات        |
| `customer_repository.dart` | الاستعلامات على جدول العملاء         |

---

## 🎯 الخلاصة

✅ **ما تم:**

- إنشاء ملف `firestore.indexes.json` يحتوي على جميع الـ Indexes المطلوبة
- توثيق 3 طرق لإنشاء الـ Indexes (روابط مباشرة، يدوي، CLI)
- شرح سبب الحاجة لكل Index

✅ **الخطوة التالية:**

1. اختر إحدى الطرق الثلاث لإنشاء الـ Indexes
2. انتظر حتى يكتمل البناء (1-5 دقائق)
3. أعد تشغيل التطبيق
4. تحقق من اختفاء الأخطاء

✅ **الفائدة:**

- 🚀 استعلامات أسرع (10x-100x)
- ✅ دعم الفلترة والترتيب المعقد
- 📊 تحميل البيانات بكفاءة عالية

---

## 📞 للمساعدة

إذا واجهت أي مشكلة:

1. تحقق من قسم "استكشاف الأخطاء" أعلاه
2. راجع الـ logs في التطبيق
3. تحقق من حالة الـ Indexes في Firebase Console

---

**آخر تحديث:** ${new Date().toISOString().split('T')[0]}
