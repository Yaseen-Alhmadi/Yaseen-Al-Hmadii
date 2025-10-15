import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../repositories/customer_repository.dart';
import '../repositories/reading_repository.dart';

class SyncService {
  SyncService({
    required this.customerRepository,
    required this.readingRepository,
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  final CustomerRepository customerRepository;
  final ReadingRepository readingRepository;
  final Connectivity _connectivity;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isInitialized = false;
  bool _isSyncing = false;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// تهيئة خدمة المزامنة (بدون مزامنة أولية)
  Future<void> initialize() async {
    if (_isInitialized) return;

    // مراقبة حالة الاتصال
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) async {
        final hasNetwork = result != ConnectivityResult.none;

        if (hasNetwork && !_isSyncing) {
          _syncStatusController.add(SyncStatus.syncing);
          await syncAll();
          _syncStatusController.add(SyncStatus.synced);
        } else if (!hasNetwork) {
          _syncStatusController.add(SyncStatus.offline);
        }
      },
    );

    _isInitialized = true;
  }

  /// بدء المزامنة الفورية (يُستدعى بعد تسجيل الدخول)
  Future<void> startRealtimeSync() async {
    debugPrint('🚀 [SyncService] بدء المزامنة الفورية...');

    // بدء الاستماع للتغييرات في الوقت الفعلي
    customerRepository.listenForRemoteUpdates();
    readingRepository.listenForRemoteUpdates();

    debugPrint('✅ [SyncService] تم تفعيل المزامنة الفورية');
  }

  /// مزامنة جميع البيانات
  Future<void> syncAll() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      // سحب التغييرات من السحابة أولاً
      await Future.wait([
        customerRepository.pullRemoteChanges(),
        readingRepository.pullRemoteChanges(),
      ]);

      // ثم رفع التغييرات المحلية
      await Future.wait([
        _pushPendingCustomers(),
        _pushPendingReadings(),
      ]);

      _syncStatusController.add(SyncStatus.synced);
    } catch (e) {
      _syncStatusController.add(SyncStatus.error);
      debugPrint('خطأ في المزامنة: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// رفع العملاء المعلقين
  Future<void> _pushPendingCustomers() async {
    // يتم التعامل مع هذا داخل CustomerRepository
    // هذه الدالة للتوافق مع الهيكل العام
  }

  /// رفع القراءات المعلقة
  Future<void> _pushPendingReadings() async {
    // يتم التعامل مع هذا داخل ReadingRepository
  }

  /// مزامنة يدوية
  Future<void> manualSync() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final hasNetwork = connectivityResult != ConnectivityResult.none;

    if (!hasNetwork) {
      _syncStatusController.add(SyncStatus.offline);
      throw Exception('لا يوجد اتصال بالإنترنت');
    }

    await syncAll();
  }

  /// التحقق من وجود بيانات معلقة
  Future<bool> hasPendingChanges() async {
    // يمكن تحسين هذا بإضافة دالة في DatabaseHelper
    // للتحقق من وجود سجلات بـ pendingSync = 1
    return false; // مؤقتاً
  }

  /// إيقاف الخدمة
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
    customerRepository.dispose();
    readingRepository.dispose();
  }
}

/// حالات المزامنة
enum SyncStatus {
  syncing, // جاري المزامنة
  synced, // تمت المزامنة
  offline, // غير متصل
  error, // خطأ في المزامنة
}
