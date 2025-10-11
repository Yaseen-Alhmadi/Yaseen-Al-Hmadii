import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // أضف هذا الاستيراد
import 'package:intl/intl.dart';
import '../services/reading_service.dart';

class ReadingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('قراءات العدادات'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Provider.of<ReadingService>(context).getAllReadings(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل البيانات'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final readings = snapshot.data ?? [];

          if (readings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.speed, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد قراءات مسجلة بعد'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: readings.length,
            itemBuilder: (context, index) {
              return _buildReadingCard(readings[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildReadingCard(Map<String, dynamic> reading) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.speed, color: Colors.white),
        ),
        title: Text(reading['customerName'] ?? 'عميل'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'الاستهلاك: ${NumberFormat('0.00', 'ar').format(reading['consumption'] ?? 0)} وحدة'),
            Text(
                'المبلغ: ${NumberFormat('0.00', 'ar').format(reading['amount'] ?? 0)} ريال'),
            Text('التاريخ: ${_formatDate(reading['readingDate'])}'),
          ],
        ),
        trailing: Text(
            NumberFormat('0.00', 'ar').format(reading['currentReading'] ?? 0)),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'غير محدد';

    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'غير محدد';
    }

    return DateFormat('dd/MM/yyyy', 'ar').format(dateTime);
  }
}
