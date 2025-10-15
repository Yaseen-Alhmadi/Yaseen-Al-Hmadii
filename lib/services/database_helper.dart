import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('water_management.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, filePath);

    return await openDatabase(
      path,
      version: 3, // تحديث رقم النسخة لإضافة userId
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // جدول العملاء
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        meterNumber TEXT,
        lastReading REAL DEFAULT 0.0,
        lastReadingDate TEXT,
        status TEXT DEFAULT 'active',
        createdAt TEXT,
        lastModified TEXT,
        lastSyncedAt TEXT,
        pendingSync INTEGER DEFAULT 0,
        deleted INTEGER DEFAULT 0
      )
    ''');

    // جدول القراءات
    await db.execute('''
      CREATE TABLE readings (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        customerId TEXT NOT NULL,
        reading REAL NOT NULL,
        date TEXT NOT NULL,
        createdAt TEXT,
        lastModified TEXT,
        lastSyncedAt TEXT,
        pendingSync INTEGER DEFAULT 0,
        deleted INTEGER DEFAULT 0,
        FOREIGN KEY (customerId) REFERENCES customers (id)
      )
    ''');

    // جدول الفواتير
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        customerId TEXT NOT NULL,
        customerName TEXT NOT NULL,
        meterReadingId TEXT,
        consumption REAL NOT NULL,
        rate REAL NOT NULL,
        amount REAL NOT NULL,
        tax REAL DEFAULT 0.0,
        totalAmount REAL NOT NULL,
        issueDate TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        createdAt TEXT,
        lastModified TEXT,
        lastSyncedAt TEXT,
        pendingSync INTEGER DEFAULT 0,
        deleted INTEGER DEFAULT 0,
        FOREIGN KEY (customerId) REFERENCES customers (id)
      )
    ''');

    // إنشاء فهارس لتحسين الأداء
    await db.execute(
        'CREATE INDEX idx_customers_userId ON customers(userId, deleted)');
    await db.execute(
        'CREATE INDEX idx_readings_userId ON readings(userId, deleted)');
    await db.execute(
        'CREATE INDEX idx_invoices_userId ON invoices(userId, deleted)');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // منطق الترقية إذا تغيرت النسخة
    if (oldVersion < 2) {
      // إضافة أعمدة المزامنة للجداول الموجودة
      try {
        await db.execute('ALTER TABLE customers ADD COLUMN lastModified TEXT');
        await db.execute('ALTER TABLE customers ADD COLUMN lastSyncedAt TEXT');
        await db.execute(
            'ALTER TABLE customers ADD COLUMN pendingSync INTEGER DEFAULT 0');
        await db.execute(
            'ALTER TABLE customers ADD COLUMN deleted INTEGER DEFAULT 0');
      } catch (e) {
        // الأعمدة موجودة بالفعل
      }

      try {
        await db.execute('ALTER TABLE readings ADD COLUMN lastModified TEXT');
        await db.execute('ALTER TABLE readings ADD COLUMN lastSyncedAt TEXT');
        await db.execute(
            'ALTER TABLE readings ADD COLUMN pendingSync INTEGER DEFAULT 0');
        await db.execute(
            'ALTER TABLE readings ADD COLUMN deleted INTEGER DEFAULT 0');
      } catch (e) {
        // الأعمدة موجودة بالفعل
      }

      try {
        await db.execute('ALTER TABLE invoices ADD COLUMN lastModified TEXT');
        await db.execute('ALTER TABLE invoices ADD COLUMN lastSyncedAt TEXT');
        await db.execute(
            'ALTER TABLE invoices ADD COLUMN pendingSync INTEGER DEFAULT 0');
        await db.execute(
            'ALTER TABLE invoices ADD COLUMN deleted INTEGER DEFAULT 0');
      } catch (e) {
        // الأعمدة موجودة بالفعل
      }
    }

    // الترقية من النسخة 2 إلى 3: إضافة userId
    if (oldVersion < 3) {
      try {
        // إضافة عمود userId للعملاء
        await db.execute(
            'ALTER TABLE customers ADD COLUMN userId TEXT DEFAULT "default_user"');

        // إضافة عمود userId للقراءات
        await db.execute(
            'ALTER TABLE readings ADD COLUMN userId TEXT DEFAULT "default_user"');

        // إضافة عمود userId للفواتير
        await db.execute(
            'ALTER TABLE invoices ADD COLUMN userId TEXT DEFAULT "default_user"');

        // إنشاء فهارس لتحسين الأداء
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_customers_userId ON customers(userId, deleted)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_readings_userId ON readings(userId, deleted)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_invoices_userId ON invoices(userId, deleted)');
      } catch (e) {
        print('خطأ في ترقية قاعدة البيانات: $e');
      }
    }
  }

  // دوال عامة للعمليات
  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(table, row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    final db = await instance.database;
    return await db.query(table);
  }

  Future<List<Map<String, dynamic>>> queryRows(
      String table, String where, List<dynamic> whereArgs) async {
    final db = await instance.database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<int> update(String table, Map<String, dynamic> row, String where,
      List<dynamic> whereArgs) async {
    final db = await instance.database;
    return await db.update(table, row, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
      String table, String where, List<dynamic> whereArgs) async {
    final db = await instance.database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
