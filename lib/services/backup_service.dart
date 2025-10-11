import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'settings_service.dart';

class BackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إنشاء نسخة احتياطية كاملة
  Future<Map<String, dynamic>> createFullBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // جمع البيانات من جميع المجموعات
      final customers = await _getCollectionData('customers');
      final meterReadings = await _getCollectionData('meter_readings');
      final invoices = await _getCollectionData('invoices');
      final users = await _getCollectionData('users');

      // حفظ إعدادات التطبيق الحالية
      final settings = await SettingsService.getAllSettings();

      final backupData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'date': DateTime.now().toIso8601String(),
        'totalRecords': customers.length +
            meterReadings.length +
            invoices.length +
            users.length,
        'data': {
          'customers': customers,
          'meter_readings': meterReadings,
          'invoices': invoices,
          'users': users,
          'settings': settings,
        },
      };

      // حفظ النسخة الاحتياطية محلياً
      await prefs.setString('backup_${DateTime.now().millisecondsSinceEpoch}',
          json.encode(backupData));

      // حفظ آخر نسخة احتياطية
      await prefs.setString('last_backup', json.encode(backupData));

      return {
        'success': true,
        'message': 'تم إنشاء النسخة الاحتياطية بنجاح',
        'backupData': backupData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في إنشاء النسخة الاحتياطية: $e',
      };
    }
  }

  // استعادة البيانات من نسخة احتياطية
  Future<Map<String, dynamic>> restoreFromBackup(
      Map<String, dynamic> backupData) async {
    try {
      final data = backupData['data'] as Map<String, dynamic>;

      // استعادة العملاء
      await _restoreCollection('customers', data['customers'] as List<dynamic>);

      // استعادة قراءات العدادات
      await _restoreCollection(
          'meter_readings', data['meter_readings'] as List<dynamic>);

      // استعادة الفواتير
      await _restoreCollection('invoices', data['invoices'] as List<dynamic>);

      // استعادة المستخدمين
      await _restoreCollection('users', data['users'] as List<dynamic>);

      // استعادة إعدادات التطبيق
      final settingsData =
          Map<String, dynamic>.from(data['settings'] as Map<String, dynamic>);
      await SettingsService.saveAllSettings(settingsData);

      return {
        'success': true,
        'message': 'تم استعادة البيانات بنجاح',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في استعادة البيانات: $e',
      };
    }
  }

  // جلب قائمة النسخ الاحتياطية المحفوظة
  Future<List<Map<String, dynamic>>> getBackupList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((key) => key.startsWith('backup_')).toList();

      List<Map<String, dynamic>> backups = [];

      for (String key in keys) {
        final backupString = prefs.getString(key);
        if (backupString != null) {
          final backupData = json.decode(backupString) as Map<String, dynamic>;
          backups.add(backupData);
        }
      }

      // ترتيب حسب التاريخ (الأحدث أولاً)
      backups.sort(
          (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

      return backups;
    } catch (e) {
      return [];
    }
  }

  // جلب بيانات مجموعة معينة
  Future<List<Map<String, dynamic>>> _getCollectionData(
      String collectionName) async {
    final querySnapshot = await _firestore.collection(collectionName).get();
    return querySnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }

  // استعادة مجموعة معينة
  Future<void> _restoreCollection(
      String collectionName, List<dynamic> data) async {
    final batch = _firestore.batch();

    for (var item in data) {
      final itemMap = item as Map<String, dynamic>;
      final docId = itemMap['id'] as String? ??
          _firestore.collection(collectionName).doc().id;
      final docRef = _firestore.collection(collectionName).doc(docId);

      // إزالة حقل id قبل الحفظ
      final itemData = Map<String, dynamic>.from(itemMap);
      itemData.remove('id');

      batch.set(docRef, itemData);
    }

    await batch.commit();
  }

  // تصدير البيانات كملف JSON
  Future<String> exportToJson() async {
    final backupData = await createFullBackup();
    return json.encode(backupData['backupData']);
  }

  // استيراد البيانات من ملف JSON
  Future<Map<String, dynamic>> importFromJson(String jsonData) async {
    try {
      final backupData = json.decode(jsonData) as Map<String, dynamic>;
      return await restoreFromBackup(backupData);
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في استيراد البيانات: $e',
      };
    }
  }

  // النسخ الاحتياطي التلقائي (مرة واحدة في الأسبوع)
  Future<void> autoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAutoBackup = prefs.getInt('last_auto_backup') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const oneWeek = 7 * 24 * 60 * 60 * 1000; // أسبوع بالملي ثانية

    if (now - lastAutoBackup > oneWeek) {
      await createFullBackup();
      await prefs.setInt('last_auto_backup', now);
    }
  }
}
