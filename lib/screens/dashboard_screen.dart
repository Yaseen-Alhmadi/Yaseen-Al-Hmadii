import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/customer_service.dart';
import '../services/auth_service.dart';
import 'add_customer_screen.dart';
import 'customers_screen.dart';
import 'invoices_screen.dart';
import 'readings_screen.dart';
import 'reports_screen.dart';
import '../services/settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final customerService = Provider.of<CustomerService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة التحكم - نظام إدارة المياه'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة ترحيب بالمستخدم
            _buildWelcomeCard(user),
            SizedBox(height: 20),

            // إحصائيات سريعة
            _buildQuickStats(customerService),
            SizedBox(height: 30),

            // شبكة الخيارات
            _buildOptionsGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(User? user) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
              radius: 30,
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً بك!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    user?.email ?? 'مستخدم',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'نظام إدارة مشاريع المياه',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(CustomerService customerService) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: customerService.getCustomers(),
      builder: (context, snapshot) {
        int customerCount = snapshot.hasData ? snapshot.data!.length : 0;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'إجمالي العملاء',
                customerCount.toString(),
                Icons.people,
                Colors.blue,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'قراءات اليوم',
                '0',
                Icons.speed,
                Colors.green,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'فواتير pending',
                '0',
                Icons.receipt,
                Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
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

  Widget _buildOptionsGrid(BuildContext context) {
    return Expanded(
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardItem(
            'إدارة العملاء',
            Icons.people,
            Colors.blue,
            () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => CustomersScreen())),
          ),
          _buildDashboardItem(
            'إضافة عميل',
            Icons.person_add,
            Colors.green,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => AddCustomerScreen())),
          ),
          _buildDashboardItem(
            'قراءات العدادات',
            Icons.speed,
            Colors.orange,
            () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => ReadingsScreen())),
          ),
          _buildDashboardItem(
            'الفواتير',
            Icons.receipt,
            Colors.purple,
            () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => InvoicesScreen())),
          ),
          _buildDashboardItem(
            'التقارير',
            Icons.analytics,
            Colors.red,
            () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => ReportsScreen())),
          ),
          _buildDashboardItem(
            'الإعدادات',
            Icons.settings,
            Colors.grey,
            () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => SettingsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
