import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'local_notification_service.dart';

/// نوع العملية المحفوظة في الطابور
enum OfflineActionType {
  checkIn,
  checkOut,
  partialCheckout,
  resumeCheckin,
  sendLocation,
  fieldVisitStart,
  fieldVisitEnd,
}

class OfflineQueueService {
  static Database? _db;
  static Timer? _syncTimer;
  static bool _isSyncing = false;

  static const String _table = 'offline_queue';

  // ── فتح/إنشاء قاعدة البيانات المحلية ──────────────────────
  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'motionhr_offline.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action_type TEXT NOT NULL,
            endpoint TEXT NOT NULL,
            method TEXT NOT NULL,
            body TEXT,
            created_at TEXT NOT NULL,
            retry_count INTEGER DEFAULT 0,
            status TEXT DEFAULT 'pending',
            owner TEXT
          )
        ''');
      },
      // نسخة 2: كل عملية محفوظة بقت مربوطة بصاحبها (عشان ماتتبعتش باسم حد تاني يدخل على نفس الموبايل)
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $_table ADD COLUMN owner TEXT');
        }
      },
    );
  }

  static Future<String> _currentOwner() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }

  // ── إضافة عملية للطابور ────────────────────────────────────
  static Future<int> enqueue({
    required OfflineActionType actionType,
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final database = await db;
    final now = DateTime.now();
    // الوقت الحقيقي للعملية بيتبعت معاها (عشان البصمة ماتتسجلش بوقت رجوع النت)
    final fullBody = <String, dynamic>{
      ...?body,
      'client_time': now.toIso8601String(),
      'offline': true,
    };
    final id = await database.insert(_table, {
      'action_type': actionType.name,
      'endpoint': endpoint,
      'method': method.toUpperCase(),
      'body': jsonEncode(fullBody),
      'created_at': now.toIso8601String(),
      'retry_count': 0,
      'status': 'pending',
      'owner': await _currentOwner(),
    });
    return id;
  }

  // ── عدد العمليات المنتظرة ──────────────────────────────────
  static Future<int> getPendingCount() async {
    final database = await db;
    final result = await database.rawQuery(
      "SELECT COUNT(*) as cnt FROM $_table WHERE status = 'pending'",
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ── بدء المزامنة التلقائية ─────────────────────────────────
  static void startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      syncAll();
    });
  }

  // ── إيقاف المزامنة التلقائية ───────────────────────────────
  static void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // ── محاولة مزامنة كل العمليات المعلقة ─────────────────────
  static Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final headers = await ApiClient.buildHeaders(includeContentType: true);
      if (!headers.containsKey('Authorization')) return;

      final database = await db;
      // عمليات المستخدم الحالي بس (والقديمة اللي اتحفظت قبل الربط)
      final owner = await _currentOwner();
      if (owner.isEmpty) return;
      final rows = await database.query(
        _table,
        where: "status = 'pending' AND (owner = ? OR owner IS NULL)",
        whereArgs: [owner],
        orderBy: 'created_at ASC',
        limit: 20,
      );

      for (final row in rows) {
        await _processRow(row, headers, database);
      }
    } catch (_) {
      // مش هنوقف التطبيق لو حصل أي error في المزامنة
    } finally {
      _isSyncing = false;
    }
  }

  static Future<void> _processRow(
    Map<String, dynamic> row,
    Map<String, String> headers,
    Database database,
  ) async {
    final id = row['id'] as int;
    final endpoint = row['endpoint'] as String;
    final method = row['method'] as String;
    final bodyStr = row['body'] as String?;
    final retryCount = (row['retry_count'] as int?) ?? 0;

    // لو تجاوزت 5 محاولات نشيلها
    if (retryCount >= 5) {
      await database.update(
        _table,
        {'status': 'failed'},
        where: 'id = ?',
        whereArgs: [id],
      );
      return;
    }

    try {
      final uri = Uri.parse(endpoint);

      http.Response res;
      if (method == 'POST') {
        res = await http.post(
          uri,
          headers: headers,
          body: bodyStr,
        ).timeout(const Duration(seconds: 15));
      } else if (method == 'PUT') {
        res = await http.put(
          uri,
          headers: headers,
          body: bodyStr,
        ).timeout(const Duration(seconds: 15));
      } else {
        res = await http.get(
          uri,
          headers: headers,
        ).timeout(const Duration(seconds: 15));
      }

      if (res.statusCode >= 200 && res.statusCode < 300) {
        // نجحت — نحذفها من الطابور
        await database.delete(
          _table,
          where: 'id = ?',
          whereArgs: [id],
        );
        // إشعار للموظف بنجاح المزامنة
        final actionType = row['action_type'] as String? ?? '';
        final notifTypes = ['checkIn', 'checkOut', 'partialCheckout', 'resumeCheckin'];
        if (notifTypes.contains(actionType)) {
          try {
            await LocalNotificationService.showSyncSuccess(actionType);
          } catch (_) {}
        }
      } else if (res.statusCode == 401) {
        // الجلسة خلصت — نسيبها معلقة لحد ما يدخل تاني بدل ما نرميها
        await database.update(
          _table,
          {'retry_count': retryCount + 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      } else if (res.statusCode >= 400 && res.statusCode < 500) {
        // السيرفر رفضها — مش هتتصلح بالإعادة، فلازم الموظف يعرف بدل ما تضيع في صمت
        await database.update(
          _table,
          {'status': 'failed'},
          where: 'id = ?',
          whereArgs: [id],
        );
        final actionType = row['action_type'] as String? ?? '';
        String reason = '';
        try {
          final decoded = jsonDecode(res.body);
          if (decoded is Map) {
            reason = (decoded['message'] ?? decoded['error'] ?? '').toString();
          }
        } catch (_) {}
        try {
          await LocalNotificationService.showSyncFailed(actionType, reason);
        } catch (_) {}
      } else {
        // خطأ في السيرفر — نزود عداد المحاولات
        await database.update(
          _table,
          {'retry_count': retryCount + 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (_) {
      // مفيش نت — نزود عداد المحاولات
      await database.update(
        _table,
        {'retry_count': retryCount + 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  // ── مسح الطابور بالكامل (للتيست بس) ──────────────────────
  static Future<void> clearAll() async {
    final database = await db;
    await database.delete(_table);
  }
}
