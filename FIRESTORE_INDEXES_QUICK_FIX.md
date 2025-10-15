# 🚨 حل سريع: خطأ Firestore Indexes

## المشكلة

عند تشغيل التطبيق، تظهر هذه الأخطاء:

```
[Firestore]: Listen for Query(...) failed:
Status{code=FAILED_PRECONDITION, description=The query requires an index...}
```

---

## ✅ الحل السريع (دقيقة واحدة)

### **الخطوة 1: انسخ الروابط من الـ Logs**

عند ظهور الخطأ، ابحث عن رابط يبدأ بـ:

```
https://console.firebase.google.com/v1/r/project/...
```

### **الخطوة 2: افتح الرابط**

- الصق الرابط في المتصفح
- سيفتح Firebase Console مع الـ Index جاهز

### **الخطوة 3: اضغط "Create Index"**

- اضغط الزر الأزرق **Create Index**
- انتظر 1-5 دقائق حتى يكتمل البناء

### **الخطوة 4: أعد تشغيل التطبيق**

```bash
flutter run
```

---

## 📋 الـ Indexes المطلوبة

إذا لم تجد الروابط في الـ logs، أنشئ هذه الـ Indexes يدوياً:

### **1. Index للفواتير:**

- Collection: `invoices`
- Fields:
  - `userId` → Ascending
  - `issueDate` → Descending

### **2. Index للقراءات:**

- Collection: `meter_readings`
- Fields:
  - `userId` → Ascending
  - `readingDate` → Descending

---

## 📚 للمزيد من التفاصيل

اقرأ: `FIRESTORE_INDEXES_SETUP.md` (دليل شامل مع 3 طرق)

---

## ✅ التحقق من النجاح

بعد إنشاء الـ Indexes:

- ✅ لا توجد أخطاء `FAILED_PRECONDITION` في الـ logs
- ✅ البيانات تُحمل بنجاح في شاشات الفواتير والقراءات
