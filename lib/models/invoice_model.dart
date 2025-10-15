import 'package:cloud_firestore/cloud_firestore.dart';

class Invoice {
  String id;
  String userId;
  String customerId;
  String customerName;
  String meterReadingId;
  double consumption;
  double rate;
  double amount;
  double tax;
  double totalAmount;
  DateTime issueDate;
  DateTime dueDate;
  String status; // pending, paid, overdue
  DateTime? paymentDate;
  String? paymentMethod;
  String? notes;

  Invoice({
    required this.id,
    required this.userId,
    required this.customerId,
    required this.customerName,
    required this.meterReadingId,
    required this.consumption,
    required this.rate,
    required this.amount,
    required this.tax,
    required this.totalAmount,
    required this.issueDate,
    required this.dueDate,
    required this.status,
    this.paymentDate,
    this.paymentMethod,
    this.notes,
  });

  // تحويل من Map إلى Invoice
  factory Invoice.fromMap(Map<String, dynamic> data, String id) {
    return Invoice(
      id: id,
      userId: data['userId'] ?? 'default_user',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      meterReadingId: data['meterReadingId'] ?? '',
      consumption: (data['consumption'] ?? 0).toDouble(),
      rate: (data['rate'] ?? 0).toDouble(),
      amount: (data['amount'] ?? 0).toDouble(),
      tax: (data['tax'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      issueDate: (data['issueDate'] ?? Timestamp.now()).toDate(),
      dueDate: (data['dueDate'] ?? Timestamp.now()).toDate(),
      status: data['status'] ?? 'pending',
      paymentDate: data['paymentDate']?.toDate(),
      paymentMethod: data['paymentMethod'],
      notes: data['notes'],
    );
  }

  // تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'customerId': customerId,
      'customerName': customerName,
      'meterReadingId': meterReadingId,
      'consumption': consumption,
      'rate': rate,
      'amount': amount,
      'tax': tax,
      'totalAmount': totalAmount,
      'issueDate': Timestamp.fromDate(issueDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'paymentDate':
          paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  // حساب الأيام المتبقية للدفع
  int get daysUntilDue {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  // التحقق إذا كانت الفاتورة متأخرة
  bool get isOverdue {
    return status == 'pending' && DateTime.now().isAfter(dueDate);
  }
}
