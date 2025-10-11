import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _taxRateKey = 'tax_rate';
  static const String _waterRateKey = 'water_rate';
  static const String _companyNameKey = 'company_name';
  static const String _companyPhoneKey = 'company_phone';
  static const String _companyAddressKey = 'company_address';
  static const String _invoiceDueDaysKey = 'invoice_due_days';
  static const String _autoBackupKey = 'auto_backup';
  static const String _notificationsKey = 'notifications';

  // الحصول على معدل الضريبة
  static Future<double> getTaxRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_taxRateKey) ?? 0.05; // 5% افتراضي
  }

  // حفظ معدل الضريبة
  static Future<void> setTaxRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_taxRateKey, rate);
  }

  // الحصول على سعر المياه
  static Future<double> getWaterRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_waterRateKey) ?? 0.5; // 0.5 ريال افتراضي
  }

  // حفظ سعر المياه
  static Future<void> setWaterRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_waterRateKey, rate);
  }

  // الحصول على اسم الشركة
  static Future<String> getCompanyName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_companyNameKey) ?? 'شركة إدارة المياه';
  }

  // حفظ اسم الشركة
  static Future<void> setCompanyName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_companyNameKey, name);
  }

  // الحصول على هاتف الشركة
  static Future<String> getCompanyPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_companyPhoneKey) ?? '+966500000000';
  }

  // حفظ هاتف الشركة
  static Future<void> setCompanyPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_companyPhoneKey, phone);
  }

  // الحصول على عنوان الشركة
  static Future<String> getCompanyAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_companyAddressKey) ?? 'المملكة العربية السعودية';
  }

  // حفظ عنوان الشركة
  static Future<void> setCompanyAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_companyAddressKey, address);
  }

  // الحصول على أيام استحقاق الفاتورة
  static Future<int> getInvoiceDueDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_invoiceDueDaysKey) ?? 30; // 30 يوم افتراضي
  }

  // حفظ أيام استحقاق الفاتورة
  static Future<void> setInvoiceDueDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_invoiceDueDaysKey, days);
  }

  // الحصول على إعداد النسخ الاحتياطي التلقائي
  static Future<bool> getAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupKey) ?? true;
  }

  // حفظ إعداد النسخ الاحتياطي التلقائي
  static Future<void> setAutoBackup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);
  }

  // الحصول على إعداد الإشعارات
  static Future<bool> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  // حفظ إعداد الإشعارات
  static Future<void> setNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  // الحصول على جميع الإعدادات
  static Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'taxRate': await getTaxRate(),
      'waterRate': await getWaterRate(),
      'companyName': await getCompanyName(),
      'companyPhone': await getCompanyPhone(),
      'companyAddress': await getCompanyAddress(),
      'invoiceDueDays': await getInvoiceDueDays(),
      'autoBackup': await getAutoBackup(),
      'notifications': await getNotifications(),
    };
  }

  // حفظ جميع الإعدادات
  static Future<void> saveAllSettings(Map<String, dynamic> settings) async {
    await setTaxRate((settings['taxRate'] ?? 0.05) as double);
    await setWaterRate((settings['waterRate'] ?? 0.5) as double);
    await setCompanyName((settings['companyName'] ?? '') as String);
    await setCompanyPhone((settings['companyPhone'] ?? '') as String);
    await setCompanyAddress((settings['companyAddress'] ?? '') as String);
    await setInvoiceDueDays((settings['invoiceDueDays'] ?? 30) as int);
    await setAutoBackup((settings['autoBackup'] ?? true) as bool);
    await setNotifications((settings['notifications'] ?? true) as bool);
  }
}
