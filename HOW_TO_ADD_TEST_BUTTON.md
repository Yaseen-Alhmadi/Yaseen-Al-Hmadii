# 🔘 كيف تضيف زر شاشة الاختبار

## 🎯 الهدف

إضافة زر في التطبيق للوصول السريع إلى شاشة اختبار المزامنة.

---

## 📍 الطريقة 1: في الشاشة الرئيسية (الأسهل)

### ابحث عن `home_screen.dart` أو `main_screen.dart`

أضف هذا الكود:

```dart
import 'package:flutter/material.dart';
import 'screens/test_firebase_sync_screen.dart'; // ✅ أضف هذا

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('نظام إدارة المياه'),
        actions: [
          // ✅ أضف هذا الزر
          IconButton(
            icon: Icon(Icons.bug_report),
            tooltip: 'اختبار المزامنة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TestFirebaseSyncScreen(),
                ),
              );
            },
          ),
        ],
      ),
      // ... باقي الكود
    );
  }
}
```

---

## 📍 الطريقة 2: في Drawer (القائمة الجانبية)

إذا كان لديك Drawer:

```dart
Drawer(
  child: ListView(
    children: [
      // ... العناصر الموجودة

      Divider(), // خط فاصل

      // ✅ أضف هذا
      ListTile(
        leading: Icon(Icons.bug_report, color: Colors.orange),
        title: Text('اختبار المزامنة'),
        subtitle: Text('للمطورين فقط'),
        onTap: () {
          Navigator.pop(context); // أغلق Drawer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TestFirebaseSyncScreen(),
            ),
          );
        },
      ),
    ],
  ),
)
```

---

## 📍 الطريقة 3: FloatingActionButton (زر عائم)

```dart
Scaffold(
  appBar: AppBar(title: Text('الرئيسية')),
  body: Center(child: Text('المحتوى')),

  // ✅ أضف هذا
  floatingActionButton: FloatingActionButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TestFirebaseSyncScreen(),
        ),
      );
    },
    child: Icon(Icons.bug_report),
    tooltip: 'اختبار المزامنة',
    backgroundColor: Colors.orange,
  ),
)
```

---

## 📍 الطريقة 4: مؤقتاً في app.dart (للاختبار السريع)

إذا أردت فتح شاشة الاختبار مباشرة عند بدء التطبيق:

### في `lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'screens/test_firebase_sync_screen.dart'; // ✅ أضف هذا

class WaterManagementApp extends StatelessWidget {
  const WaterManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام إدارة المياه',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // ✅ غيّر هذا مؤقتاً للاختبار
      home: const TestFirebaseSyncScreen(), // للاختبار فقط

      // ✅ بعد الاختبار، أرجعه إلى:
      // home: const HomeScreen(),
    );
  }
}
```

⚠️ **تذكر:** أرجع `home` إلى الشاشة الأصلية بعد الاختبار!

---

## 📍 الطريقة 5: في شاشة الإعدادات

```dart
// في settings_screen.dart أو أي شاشة إعدادات

ListTile(
  leading: Icon(Icons.sync, color: Colors.blue),
  title: Text('اختبار المزامنة'),
  subtitle: Text('فحص مزامنة Firebase'),
  trailing: Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TestFirebaseSyncScreen(),
      ),
    );
  },
)
```

---

## 🎨 تخصيص الزر

### زر ملون:

```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TestFirebaseSyncScreen(),
      ),
    );
  },
  icon: Icon(Icons.bug_report),
  label: Text('اختبار المزامنة'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.orange,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  ),
)
```

### زر نصي:

```dart
TextButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TestFirebaseSyncScreen(),
      ),
    );
  },
  icon: Icon(Icons.bug_report),
  label: Text('اختبار المزامنة'),
)
```

---

## 🔍 كيف تجد الملف المناسب؟

### ابحث عن:

1. **`home_screen.dart`** - الشاشة الرئيسية
2. **`main_screen.dart`** - الشاشة الرئيسية
3. **`dashboard_screen.dart`** - لوحة التحكم
4. **`app.dart`** - تطبيق Flutter الرئيسي

### استخدم البحث في VS Code:

```
Ctrl + Shift + F
ابحث عن: "Scaffold"
```

ستجد جميع الشاشات التي تستخدم `Scaffold`.

---

## ✅ التحقق من نجاح الإضافة

بعد إضافة الزر:

1. ✅ شغّل التطبيق: `flutter run`
2. ✅ ابحث عن الزر/الأيقونة
3. ✅ اضغط عليه
4. ✅ يجب أن تفتح شاشة الاختبار

---

## 🐛 حل المشاكل

### ❌ خطأ: "Undefined name 'TestFirebaseSyncScreen'"

**السبب:** نسيت إضافة import

**الحل:**

```dart
import 'screens/test_firebase_sync_screen.dart';
```

---

### ❌ خطأ: "The method 'push' isn't defined"

**السبب:** نسيت `Navigator`

**الحل:**

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const TestFirebaseSyncScreen()),
);
```

---

### ❌ الزر لا يظهر

**السبب:** أضفته في مكان خاطئ

**الحل:** تأكد من أنه داخل `build` method وداخل `Scaffold`

---

## 💡 نصيحة

**للاختبار السريع:**

استخدم **الطريقة 4** (مؤقتاً في app.dart):

```dart
home: const TestFirebaseSyncScreen(),
```

هذا سيفتح شاشة الاختبار مباشرة عند بدء التطبيق.

**لا تنسى إرجاعه بعد الاختبار!**

---

## 📸 مثال كامل

```dart
// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'test_firebase_sync_screen.dart'; // ✅

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام إدارة المياه'),
        actions: [
          // ✅ زر الاختبار
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'اختبار المزامنة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TestFirebaseSyncScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('مرحباً بك في نظام إدارة المياه'),
            const SizedBox(height: 20),

            // ✅ أو زر في الوسط
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TestFirebaseSyncScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('اختبار المزامنة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

**جاهز! 🎉**

الآن يمكنك الوصول إلى شاشة الاختبار بسهولة!
