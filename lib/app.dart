import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'models/invoice_model.dart';
import 'screens/add_customer_screen.dart';
import 'screens/add_reading_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/invoice_details_screen.dart';
import 'screens/invoices_screen.dart';
import 'screens/login_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/signup_screen.dart';
import 'services/auth_service.dart';
import 'services/backup_service.dart';
import 'services/customer_service.dart';
import 'services/invoice_service.dart';
import 'services/reading_service.dart';
import 'services/report_service.dart';
import 'services/settings_screen.dart';

class WaterManagementApp extends StatelessWidget {
  const WaterManagementApp({super.key});

  Invoice _createDummyInvoice() {
    return Invoice(
      id: 'temp',
      customerId: 'temp',
      customerName: 'عميل مؤقت',
      meterReadingId: 'temp',
      consumption: 0,
      rate: 0,
      amount: 0,
      tax: 0,
      totalAmount: 0,
      issueDate: DateTime.now(),
      dueDate: DateTime.now(),
      status: 'pending',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<CustomerService>(create: (_) => CustomerService()),
        Provider<ReadingService>(create: (_) => ReadingService()),
        Provider<InvoiceService>(create: (_) => InvoiceService()),
        Provider<ReportService>(create: (_) => ReportService()),
        Provider<BackupService>(create: (_) => BackupService()),
      ],
      child: MaterialApp(
        title: 'نظام إدارة المياه',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          fontFamily: 'Cairo',
          cardTheme: CardTheme(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
        ],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: '/login',
        routes: {
          '/login': (context) => LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/customers': (context) => CustomersScreen(),
          '/add_customer': (context) => const AddCustomerScreen(),
          '/add_reading': (context) => const AddReadingScreen(customer: {}),
          '/invoices': (context) => InvoicesScreen(),
          '/reports': (context) => ReportsScreen(),
          '/settings': (context) => SettingsScreen(),
          '/invoice_details': (context) =>
              InvoiceDetailsScreen(invoice: _createDummyInvoice()),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
