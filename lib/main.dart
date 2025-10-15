import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'repositories/customer_repository.dart';
import 'repositories/reading_repository.dart';
import 'repositories/invoice_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // تهيئة نظام الإشعارات
    await NotificationService.initialize();

    // تهيئة Repositories
    final customerRepository = CustomerRepository();
    final readingRepository = ReadingRepository();
    final invoiceRepository = InvoiceRepository();

    // تهيئة خدمة المزامنة
    final syncService = SyncService(
      customerRepository: customerRepository,
      readingRepository: readingRepository,
    );
    await syncService.initialize();

    debugPrint('✅ Firebase initialized successfully');
    debugPrint('✅ Sync service initialized successfully');

    runApp(
      MultiProvider(
        providers: [
          Provider<CustomerRepository>.value(value: customerRepository),
          Provider<ReadingRepository>.value(value: readingRepository),
          Provider<InvoiceRepository>.value(value: invoiceRepository),
          Provider<SyncService>.value(value: syncService),
        ],
        child: const WaterManagementApp(),
      ),
    );
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
