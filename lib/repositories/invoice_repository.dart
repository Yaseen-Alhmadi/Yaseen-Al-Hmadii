import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/invoice_model.dart';
import '../services/auth_service.dart';

class InvoiceRepository {
  InvoiceRepository({
    FirebaseFirestore? firestore,
    AuthService? authService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authService = authService ?? AuthService();

  final FirebaseFirestore _firestore;
  final AuthService _authService;

  /// Stream للحصول على جميع الفواتير (Real-time)
  Stream<List<Invoice>> getAllInvoicesStream() async* {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      yield [];
      return;
    }

    await for (final snapshot in _firestore
        .collection('invoices')
        .where('userId', isEqualTo: userId)
        .orderBy('issueDate', descending: true)
        .snapshots()) {
      try {
        final invoices = snapshot.docs
            .map((doc) => Invoice.fromMap(doc.data(), doc.id))
            .toList();
        yield invoices;
      } catch (e) {
        debugPrint('❌ [InvoiceRepo] خطأ في جلب الفواتير: $e');
        yield [];
      }
    }
  }

  /// Stream للحصول على فواتير عميل معين (Real-time)
  Stream<List<Invoice>> getCustomerInvoicesStream(String customerId) async* {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      yield [];
      return;
    }

    await for (final snapshot in _firestore
        .collection('invoices')
        .where('customerId', isEqualTo: customerId)
        .where('userId', isEqualTo: userId)
        .orderBy('issueDate', descending: true)
        .snapshots()) {
      try {
        final invoices = snapshot.docs
            .map((doc) => Invoice.fromMap(doc.data(), doc.id))
            .toList();
        yield invoices;
      } catch (e) {
        debugPrint('❌ [InvoiceRepo] خطأ في جلب فواتير العميل: $e');
        yield [];
      }
    }
  }

  /// Stream للحصول على إحصائيات الفواتير (Real-time)
  Stream<Map<String, dynamic>> getInvoiceStatsStream() async* {
    await for (final invoices in getAllInvoicesStream()) {
      try {
        double totalRevenue = 0;
        double pendingAmount = 0;
        int pendingCount = 0;
        int paidCount = 0;
        int overdueCount = 0;

        for (final invoice in invoices) {
          if (invoice.status == 'paid') {
            totalRevenue += invoice.totalAmount;
            paidCount++;
          } else if (invoice.status == 'pending') {
            pendingAmount += invoice.totalAmount;
            pendingCount++;
            if (invoice.isOverdue) {
              overdueCount++;
            }
          }
        }

        yield {
          'totalRevenue': totalRevenue,
          'pendingAmount': pendingAmount,
          'pendingCount': pendingCount,
          'paidCount': paidCount,
          'overdueCount': overdueCount,
          'totalCount': invoices.length,
        };
      } catch (e) {
        debugPrint('❌ [InvoiceRepo] خطأ في حساب الإحصائيات: $e');
        yield {
          'totalRevenue': 0.0,
          'pendingAmount': 0.0,
          'pendingCount': 0,
          'paidCount': 0,
          'overdueCount': 0,
          'totalCount': 0,
        };
      }
    }
  }

  /// إنشاء فاتورة جديدة
  Future<String> createInvoice(Map<String, dynamic> invoiceData) async {
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('لا يوجد مستخدم مسجل دخول');
      }

      final data = {
        ...invoiceData,
        'userId': userId,
        'createdAt': Timestamp.now(),
      };

      final docRef = await _firestore.collection('invoices').add(data);
      debugPrint('✅ [InvoiceRepo] تم إنشاء فاتورة: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ [InvoiceRepo] خطأ في إنشاء الفاتورة: $e');
      rethrow;
    }
  }

  /// تحديث حالة الفاتورة
  Future<void> updateInvoiceStatus(
    String invoiceId,
    String status, {
    String? paymentMethod,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
      };

      if (status == 'paid') {
        updates['paymentDate'] = Timestamp.now();
        updates['paymentMethod'] = paymentMethod ?? 'نقدي';
      }

      await _firestore.collection('invoices').doc(invoiceId).update(updates);
      debugPrint('✅ [InvoiceRepo] تم تحديث حالة الفاتورة: $invoiceId');
    } catch (e) {
      debugPrint('❌ [InvoiceRepo] خطأ في تحديث الفاتورة: $e');
      rethrow;
    }
  }

  /// حذف فاتورة
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      await _firestore.collection('invoices').doc(invoiceId).delete();
      debugPrint('✅ [InvoiceRepo] تم حذف الفاتورة: $invoiceId');
    } catch (e) {
      debugPrint('❌ [InvoiceRepo] خطأ في حذف الفاتورة: $e');
      rethrow;
    }
  }
}
