import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/reading_model.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';

class ReadingRepository {
  ReadingRepository({
    DatabaseHelper? dbHelper,
    FirebaseFirestore? firestore,
    Connectivity? connectivity,
    AuthService? authService,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity ?? Connectivity(),
        _authService = authService ?? AuthService();

  final DatabaseHelper _dbHelper;
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;
  final AuthService _authService;

  final _syncController = StreamController<void>.broadcast();
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;

  Stream<void> get syncStream => _syncController.stream;

  /// الحصول على جميع القراءات من القاعدة المحلية
  Future<List<Reading>> getReadings() async {
    final rows = await _dbHelper.queryRows(
      'readings',
      'deleted = ?',
      [0],
    );
    return rows.map((row) => Reading.fromMap(row)).toList();
  }

  /// الحصول على قراءات عميل معين
  Future<List<Reading>> getReadingsByCustomerId(String customerId) async {
    final rows = await _dbHelper.queryRows(
      'readings',
      'customerId = ? AND deleted = ?',
      [customerId, 0],
    );
    return rows.map((row) => Reading.fromMap(row)).toList();
  }

  /// الحصول على قراءة واحدة بواسطة ID
  Future<Reading?> getReadingById(String id) async {
    final rows = await _dbHelper.queryRows(
      'readings',
      'id = ? AND deleted = ?',
      [id, 0],
    );
    if (rows.isEmpty) return null;
    return Reading.fromMap(rows.first);
  }

  /// إضافة قراءة جديدة
  Future<void> addReading(Reading reading) async {
    final now = DateTime.now().toIso8601String();
    final data = reading.toMap()
      ..addAll({
        'pendingSync': 1,
        'lastModified': now,
        'createdAt': reading.createdAt ?? now,
        'deleted': 0,
      });

    await _dbHelper.insert('readings', data);
    _syncController.add(null);
    await _trySync();
  }

  /// تحديث قراءة موجودة
  Future<void> updateReading(Reading reading) async {
    final now = DateTime.now().toIso8601String();
    final data = reading.toMap()
      ..addAll({
        'pendingSync': 1,
        'lastModified': now,
      });

    await _dbHelper.update(
      'readings',
      data,
      'id = ?',
      [reading.id],
    );
    _syncController.add(null);
    await _trySync();
  }

  /// حذف قراءة (حذف منطقي)
  Future<void> deleteReading(String id) async {
    final now = DateTime.now().toIso8601String();

    await _dbHelper.update(
      'readings',
      {
        'pendingSync': 1,
        'lastModified': now,
        'deleted': 1,
      },
      'id = ?',
      [id],
    );
    _syncController.add(null);
    await _trySync();
  }

  /// محاولة المزامنة إذا كان هناك اتصال
  Future<void> _trySync() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final hasNetwork = connectivityResult != ConnectivityResult.none;

    if (!hasNetwork) return;

    await _pushLocalChanges();
  }

  /// رفع التغييرات المحلية إلى Firestore
  Future<void> _pushLocalChanges() async {
    try {
      final pendingRows = await _dbHelper.queryRows(
        'readings',
        'pendingSync = ?',
        [1],
      );

      for (final row in pendingRows) {
        final reading = Reading.fromMap(row);
        final docRef = _firestore.collection('readings').doc(reading.id);

        if (reading.deleted == 1) {
          await docRef.delete();
        } else {
          await docRef.set(reading.toFirestore(), SetOptions(merge: true));
        }

        await _dbHelper.update(
          'readings',
          {
            ...row,
            'pendingSync': 0,
            'lastSyncedAt': DateTime.now().toIso8601String(),
          },
          'id = ?',
          [reading.id],
        );
      }

      _syncController.add(null);
    } catch (e) {
      debugPrint('خطأ في رفع القراءات: $e');
    }
  }

  /// سحب التغييرات من Firestore
  Future<void> pullRemoteChanges() async {
    try {
      final snapshot = await _firestore.collection('readings').get();

      for (final doc in snapshot.docs) {
        final remote = doc.data();
        remote['id'] = doc.id;

        // تحويل Timestamp إلى String
        remote['createdAt'] = _convertTimestampToString(remote['createdAt']);
        remote['lastModified'] =
            _convertTimestampToString(remote['lastModified']);
        remote['date'] = _convertTimestampToString(remote['date']);

        final localRows = await _dbHelper.queryRows(
          'readings',
          'id = ?',
          [doc.id],
        );

        if (localRows.isEmpty) {
          await _dbHelper.insert('readings', {
            ...remote,
            'pendingSync': 0,
            'lastSyncedAt': DateTime.now().toIso8601String(),
            'deleted': remote['deleted'] ?? 0,
          });
          continue;
        }

        final local = localRows.first;
        final isPending = local['pendingSync'] == 1;

        if (isPending) continue;

        final localModified = local['lastModified'] != null
            ? DateTime.parse(local['lastModified'] as String)
            : DateTime(2000);

        final remoteModified = remote['lastModified'] != null
            ? DateTime.parse(remote['lastModified'] as String)
            : DateTime(2000);

        if (remoteModified.isAfter(localModified)) {
          await _dbHelper.update(
            'readings',
            {
              ...remote,
              'pendingSync': 0,
              'lastSyncedAt': DateTime.now().toIso8601String(),
            },
            'id = ?',
            [doc.id],
          );
        }
      }

      _syncController.add(null);
    } catch (e) {
      print('خطأ في سحب القراءات: $e');
    }
  }

  /// تحويل Timestamp إلى String
  String? _convertTimestampToString(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is String) return value;
    return null;
  }

  /// الاستماع للتغييرات في الوقت الفعلي
  void listenForRemoteUpdates() {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = _firestore
        .collection('readings')
        .snapshots()
        .listen((querySnapshot) async {
      for (final change in querySnapshot.docChanges) {
        final doc = change.doc;
        final data = doc.data();

        if (data == null) continue;

        data['id'] = doc.id;

        // تحويل Timestamp إلى String
        data['createdAt'] = _convertTimestampToString(data['createdAt']);
        data['lastModified'] = _convertTimestampToString(data['lastModified']);
        data['date'] = _convertTimestampToString(data['date']);

        if (change.type == DocumentChangeType.removed) {
          await _dbHelper.update(
            'readings',
            {
              'deleted': 1,
              'lastModified': DateTime.now().toIso8601String(),
              'pendingSync': 0,
            },
            'id = ?',
            [doc.id],
          );
          _syncController.add(null);
          continue;
        }

        final rows = await _dbHelper.queryRows('readings', 'id = ?', [doc.id]);

        if (rows.isEmpty) {
          await _dbHelper.insert('readings', {
            ...data,
            'pendingSync': 0,
            'lastSyncedAt': DateTime.now().toIso8601String(),
            'deleted': data['deleted'] ?? 0,
          });
          _syncController.add(null);
          continue;
        }

        final local = rows.first;
        final isPending = local['pendingSync'] == 1;

        if (isPending) continue;

        final localModified = local['lastModified'] != null
            ? DateTime.parse(local['lastModified'] as String)
            : DateTime(2000);

        final remoteModified = data['lastModified'] != null
            ? DateTime.parse(data['lastModified'] as String)
            : DateTime(2000);

        if (remoteModified.isAfter(localModified)) {
          await _dbHelper.update(
            'readings',
            {
              ...data,
              'pendingSync': 0,
              'lastSyncedAt': DateTime.now().toIso8601String(),
            },
            'id = ?',
            [doc.id],
          );
          _syncController.add(null);
        }
      }
    });
  }

  /// Stream للحصول على قراءات اليوم (Real-time من Firestore)
  Stream<int> getTodayReadingsCountStream() async* {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      yield 0;
      return;
    }

    // تاريخ بداية اليوم (00:00:00)
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startTimestamp = Timestamp.fromDate(startOfDay);

    await for (final snapshot in _firestore
        .collection('meter_readings')
        .where('userId', isEqualTo: userId)
        .where('readingDate', isGreaterThanOrEqualTo: startTimestamp)
        .snapshots()) {
      try {
        yield snapshot.docs.length;
      } catch (e) {
        debugPrint('❌ [ReadingRepo] خطأ في حساب قراءات اليوم: $e');
        yield 0;
      }
    }
  }

  /// Stream للحصول على جميع القراءات (Real-time من Firestore)
  Stream<List<Reading>> getAllReadingsStream() async* {
    final userId = await _authService.getCurrentUserId();
    if (userId == null) {
      yield [];
      return;
    }

    await for (final snapshot in _firestore
        .collection('meter_readings')
        .where('userId', isEqualTo: userId)
        .orderBy('readingDate', descending: true)
        .snapshots()) {
      try {
        final readings = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;

          // تحويل Timestamp إلى String
          data['createdAt'] = _convertTimestampToString(data['createdAt']);
          data['lastModified'] =
              _convertTimestampToString(data['lastModified']);

          // استخدام readingDate كـ date (لأن Model يستخدم date)
          if (data['readingDate'] != null) {
            data['date'] = _convertTimestampToString(data['readingDate']);
          } else if (data['date'] != null) {
            data['date'] = _convertTimestampToString(data['date']);
          }

          return Reading.fromMap(data);
        }).toList();

        yield readings;
      } catch (e) {
        debugPrint('❌ [ReadingRepo] خطأ في جلب القراءات: $e');
        yield [];
      }
    }
  }

  /// إيقاف الاستماع
  void dispose() {
    _firestoreSubscription?.cancel();
    _syncController.close();
  }
}
