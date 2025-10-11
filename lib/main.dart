import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // تهيئة نظام الإشعارات
    await NotificationService.initialize();

    debugPrint('✅ Firebase initialized successfully');
    runApp(const WaterManagementApp());
  } catch (e, stack) {
    debugPrint('❌ Error initializing Firebase: $e');
    debugPrint(stack.toString());
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('خطأ في تهيئة التطبيق: $e'),
        ),
      ),
    ));
  }
}
