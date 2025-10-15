import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/backup_service.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _settings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    _settings = await SettingsService.getAllSettings();
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      await SettingsService.saveAllSettings(_settings);

      setState(() => _isLoading = false);

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.rightSlide,
        title: 'تم الحفظ',
        desc: 'تم حفظ الإعدادات بنجاح',
        btnOkOnPress: () {},
      ).show();
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);

    final backupService = Provider.of<BackupService>(context, listen: false);
    final result = await backupService.createFullBackup();

    setState(() => _isLoading = false);

    AwesomeDialog(
      context: context,
      dialogType: result['success'] ? DialogType.success : DialogType.error,
      animType: AnimType.rightSlide,
      title: result['success'] ? 'نجاح' : 'خطأ',
      desc: result['message'],
      btnOkOnPress: () {},
    ).show();
  }

  Future<void> _showBackupList() async {
    final backupService = Provider.of<BackupService>(context, listen: false);
    final backups = await backupService.getBackupList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('النسخ الاحتياطية'),
        content: backups.isEmpty
            ? Text('لا توجد نسخ احتياطية')
            : Container(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: backups.length,
                  itemBuilder: (context, index) {
                    final backup = backups[index];
                    final date = DateTime.fromMillisecondsSinceEpoch(
                        backup['timestamp']);
                    return ListTile(
                      leading: Icon(Icons.backup),
                      title: Text('${backup['totalRecords']} سجل'),
                      subtitle: Text('${date.day}/${date.month}/${date.year}'),
                      trailing: IconButton(
                        icon: Icon(Icons.restore),
                        onPressed: () => _restoreBackup(backup),
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreBackup(Map<String, dynamic> backup) async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.rightSlide,
      title: 'تأكيد الاستعادة',
      desc:
          'هل أنت متأكد من استعادة هذه النسخة الاحتياطية؟ سيتم استبدال جميع البيانات الحالية.',
      btnCancelOnPress: () {},
      btnOkText: 'استعادة',
      btnOkOnPress: () async {
        setState(() => _isLoading = true);

        final backupService =
            Provider.of<BackupService>(context, listen: false);
        final result = await backupService.restoreFromBackup(backup);

        setState(() => _isLoading = false);

        AwesomeDialog(
          context: context,
          dialogType: result['success'] ? DialogType.success : DialogType.error,
          animType: AnimType.rightSlide,
          title: result['success'] ? 'نجاح' : 'خطأ',
          desc: result['message'],
          btnOkOnPress: () {},
        ).show();
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإعدادات المتقدمة'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildCompanySettings(),
                    SizedBox(height: 20),
                    _buildFinancialSettings(),
                    SizedBox(height: 20),
                    _buildBackupSettings(),
                    SizedBox(height: 20),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCompanySettings() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إعدادات الشركة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextFormField(
              initialValue: _settings['companyName'],
              decoration: InputDecoration(
                labelText: 'اسم الشركة',
                border: OutlineInputBorder(),
              ),
              onSaved: (value) => _settings['companyName'] = value,
            ),
            SizedBox(height: 12),
            TextFormField(
              initialValue: _settings['companyPhone'],
              decoration: InputDecoration(
                labelText: 'هاتف الشركة',
                border: OutlineInputBorder(),
              ),
              onSaved: (value) => _settings['companyPhone'] = value,
            ),
            SizedBox(height: 12),
            TextFormField(
              initialValue: _settings['companyAddress'],
              decoration: InputDecoration(
                labelText: 'عنوان الشركة',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onSaved: (value) => _settings['companyAddress'] = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSettings() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الإعدادات المالية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextFormField(
              initialValue: (_settings['taxRate'] * 100).toString(),
              decoration: InputDecoration(
                labelText: 'معدل الضريبة (%)',
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return 'يرجى إدخال رقم صحيح';
                }
                return null;
              },
              onSaved: (value) =>
                  _settings['taxRate'] = (double.parse(value!) / 100),
            ),
            SizedBox(height: 12),
            TextFormField(
              initialValue: _settings['waterRate'].toString(),
              decoration: InputDecoration(
                labelText: 'سعر المياه (ريال/وحدة)',
                border: OutlineInputBorder(),
                suffixText: 'ريال',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return 'يرجى إدخال رقم صحيح';
                }
                return null;
              },
              onSaved: (value) => _settings['waterRate'] = double.parse(value!),
            ),
            SizedBox(height: 12),
            TextFormField(
              initialValue: _settings['invoiceDueDays'].toString(),
              decoration: InputDecoration(
                labelText: 'أيام استحقاق الفاتورة',
                border: OutlineInputBorder(),
                suffixText: 'أيام',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || int.tryParse(value) == null) {
                  return 'يرجى إدخال رقم صحيح';
                }
                return null;
              },
              onSaved: (value) =>
                  _settings['invoiceDueDays'] = int.parse(value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSettings() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'النسخ الاحتياطي',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createBackup,
                    icon: Icon(Icons.backup),
                    label: Text('إنشاء نسخة احتياطية'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showBackupList,
                    icon: Icon(Icons.history),
                    label: Text('عرض النسخ السابقة'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            SwitchListTile(
              title: Text('النسخ الاحتياطي التلقائي'),
              subtitle: Text('إنشاء نسخة احتياطية تلقائياً كل أسبوع'),
              value: _settings['autoBackup'] ?? true,
              onChanged: (value) {
                setState(() => _settings['autoBackup'] = value);
              },
            ),
            SwitchListTile(
              title: Text('الإشعارات'),
              subtitle: Text('تفعيل إشعارات التطبيق'),
              value: _settings['notifications'] ?? true,
              onChanged: (value) {
                setState(() => _settings['notifications'] = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('حفظ الإعدادات'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: _loadSettings,
            child: const Text('إعادة تعيين'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }
}
