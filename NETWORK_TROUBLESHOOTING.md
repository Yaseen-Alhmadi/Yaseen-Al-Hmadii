# 🌐 حل مشكلة الاتصال بـ Firebase

## 🚨 **المشكلة:**

```
Unable to resolve host "firestore.googleapis.com"
No address associated with hostname
```

**هذا يعني: الجهاز غير متصل بالإنترنت!** 📡❌

---

## ✅ **الحلول السريعة:**

### **1️⃣ على المحاكي (Android Emulator):**

#### أ) تأكد من اتصال الكمبيوتر بالإنترنت

```bash
# اختبر الاتصال من CMD
ping google.com
```

#### ب) أعد تشغيل المحاكي

```bash
# أغلق المحاكي وأعد تشغيله
flutter run
```

#### ج) إعدادات DNS في المحاكي

1. افتح **Settings** في المحاكي
2. **Network & Internet**
3. **WiFi** → اضغط على الشبكة المتصلة
4. **Advanced** → **IP settings** → **Static**
5. أضف DNS:
   - DNS 1: `8.8.8.8`
   - DNS 2: `8.8.4.4`

#### د) تفعيل الإنترنت في المحاكي

في AVD Manager:

1. افتح **AVD Manager**
2. اضغط على ⚙️ (Edit) للمحاكي
3. **Show Advanced Settings**
4. تحت **Network**:
   - ✅ تأكد من تفعيل **Network**
   - اختر **NAT** أو **Bridged**

---

### **2️⃣ على الجهاز الحقيقي:**

#### أ) فعّل WiFi أو Mobile Data

- Settings → WiFi → تأكد من الاتصال
- أو: Settings → Mobile Data → فعّل البيانات

#### ب) اختبر الاتصال

- افتح متصفح Chrome
- اذهب إلى `google.com`
- إذا لم يفتح → المشكلة في الشبكة

#### ج) أذونات التطبيق

تأكد من إضافة الأذونات في `AndroidManifest.xml`:

```xml
<manifest ...>
    <!-- ✅ أضف هذه الأذونات -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application ...>
        ...
    </application>
</manifest>
```

---

### **3️⃣ اختبر الاتصال من التطبيق:**

#### استخدم شاشة الاختبار المحدثة:

1. شغّل التطبيق
2. افتح شاشة الاختبار
3. اضغط **"فحص الاتصال"**
4. راقب النتيجة:

**✅ إذا رأيت:**

```
✅ متصل عبر WiFi - Firebase متاح ✅
```

→ الاتصال يعمل بشكل صحيح!

**❌ إذا رأيت:**

```
❌ غير متصل بالإنترنت
```

→ اتبع الحلول أعلاه

---

## 🔧 **حلول متقدمة:**

### **1. تنظيف وإعادة البناء:**

```bash
flutter clean
flutter pub get
flutter run
```

### **2. فحص إعدادات Firewall:**

قد يكون Firewall يمنع الاتصال:

- Windows: Settings → Windows Security → Firewall
- أضف استثناء لـ Android Emulator

### **3. استخدام VPN (إذا كان Firebase محظوراً):**

في بعض الدول، قد يكون Firebase محظوراً:

- استخدم VPN موثوق
- أعد تشغيل التطبيق

### **4. تحديث Google Play Services (للمحاكي):**

في المحاكي:

1. افتح **Play Store**
2. ابحث عن **Google Play Services**
3. اضغط **Update**

---

## 📱 **اختبار سريع:**

### **الطريقة 1: من Console**

شغّل التطبيق وراقب:

```
✅ يجب أن ترى:
🚀 [SyncService] تهيئة خدمة المزامنة...
📡 [SyncService] حالة الاتصال: متصل

❌ إذا رأيت:
📡 [SyncService] حالة الاتصال: غير متصل
```

### **الطريقة 2: من شاشة الاختبار**

1. افتح شاشة الاختبار
2. اضغط "فحص الاتصال"
3. انظر للبطاقة الخضراء/الحمراء في الأعلى

---

## 🎯 **السيناريوهات الشائعة:**

### **السيناريو 1: المحاكي لا يتصل**

**الأعراض:**

- التطبيق يعمل
- لكن لا يتصل بـ Firebase

**الحل:**

```bash
# 1. أغلق المحاكي
# 2. أعد تشغيله
flutter run

# 3. إذا لم ينجح، أعد تشغيل الكمبيوتر
```

---

### **السيناريو 2: الجهاز الحقيقي لا يتصل**

**الأعراض:**

- WiFi متصل
- لكن Firebase لا يعمل

**الحل:**

1. تحقق من أذونات التطبيق
2. أعد تثبيت التطبيق
3. تأكد من عدم وجود VPN يمنع الاتصال

---

### **السيناريو 3: الاتصال يعمل ثم يتوقف**

**الأعراض:**

- يعمل لفترة ثم يتوقف

**الحل:**

- قد تكون مشكلة في قواعد Firestore
- تحقق من Firebase Console → Firestore → Rules

```javascript
// ✅ قواعد مؤقتة للاختبار
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true; // ⚠️ للاختبار فقط!
    }
  }
}
```

---

## 📋 **Checklist سريع:**

قبل أن تبدأ الاختبار، تأكد من:

- [ ] الكمبيوتر/الجهاز متصل بالإنترنت
- [ ] المحاكي/الجهاز يمكنه فتح المتصفح
- [ ] أذونات الإنترنت موجودة في `AndroidManifest.xml`
- [ ] Firebase مُعد بشكل صحيح (`google-services.json`)
- [ ] قواعد Firestore تسمح بالقراءة/الكتابة
- [ ] لا يوجد Firewall يمنع الاتصال

---

## 🚀 **بعد حل المشكلة:**

عندما يعمل الاتصال:

1. **اختبر المزامنة:**

   ```
   اضغط "إضافة عميل في Firebase"
   → يجب أن ترى رسائل في Console
   → العداد المحلي يتحدث تلقائياً
   ```

2. **راقب Console:**

   ```
   🔔 [CustomerRepo] تلقي تحديث: 1 تغيير
   ➕ [CustomerRepo] إضافة عميل جديد (realtime): ...
   ```

3. **تحقق من التطابق:**
   ```
   العداد المحلي = العداد السحابي ✅
   ```

---

## 💡 **نصائح مهمة:**

### **للمحاكي:**

- استخدم محاكي حديث (API 30+)
- تأكد من تخصيص RAM كافي (2GB+)
- فعّل Hardware Acceleration

### **للجهاز الحقيقي:**

- استخدم USB Debugging
- تأكد من تثبيت Google Play Services
- فعّل Developer Options

### **للشبكة:**

- استخدم WiFi مستقر (أفضل من Mobile Data للاختبار)
- تجنب الشبكات المحظورة (مثل شبكات الشركات)
- إذا كنت خلف Proxy، قد تحتاج إعدادات إضافية

---

## 📞 **إذا استمرت المشكلة:**

جرب هذا الاختبار البسيط:

```dart
// أضف هذا في main.dart مؤقتاً
void testFirebaseConnection() async {
  try {
    print('🧪 اختبار الاتصال بـ Firebase...');

    final firestore = FirebaseFirestore.instance;
    await firestore.collection('test').limit(1).get();

    print('✅ Firebase يعمل بشكل صحيح!');
  } catch (e) {
    print('❌ خطأ في الاتصال: $e');
  }
}

// في main()
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
await testFirebaseConnection(); // ✅ أضف هذا
```

---

## 🎉 **الخلاصة:**

**المشكلة الأساسية:** عدم وجود اتصال بالإنترنت

**الحل السريع:**

1. تأكد من الاتصال بالإنترنت
2. أعد تشغيل المحاكي/الجهاز
3. استخدم شاشة الاختبار لفحص الاتصال
4. راقب Console للرسائل

**بعد حل المشكلة:**

- المزامنة ستعمل تلقائياً ✅
- ستر ى رسائل واضحة في Console ✅
- البيانات ستتزامن بين Firebase والقاعدة المحلية ✅

---

**الآن جرب الحلول وأخبرني بالنتيجة! 🚀**
