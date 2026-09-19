import 'package:sqflite/sqflite.dart';

/// Một dòng kiểm kê cục bộ (gộp package + kết quả đếm).
class StocktakeLocalItem {
  StocktakeLocalItem({
    required this.itemId,
    required this.sessionId,
    required this.code,
    required this.name,
    this.equipmentId,
    this.lotId,
    this.supplyId,
    this.location,
    this.lotNo,
    this.bookQty = '1',
    this.countedQty,
    this.countedStatus,
    this.countedLocation,
    this.countedAt,
    this.clientId,
    this.photoFileId,
    this.note,
    this.synced = false,
    this.conflict = false,
    this.keptCountedAt,
  });

  final String itemId;
  final String sessionId;
  final String code;
  final String name;
  final String? equipmentId;
  final String? lotId;
  final String? supplyId;
  final String? location;
  final String? lotNo;
  final String bookQty;
  String? countedQty;
  String? countedStatus;
  String? countedLocation;
  String? countedAt;
  String? clientId;
  String? photoFileId;
  String? note;
  bool synced;
  bool conflict;
  String? keptCountedAt;

  bool get counted => countedAt != null;

  Map<String, Object?> toRow() => {
    'itemId': itemId,
    'sessionId': sessionId,
    'code': code,
    'name': name,
    'equipmentId': equipmentId,
    'lotId': lotId,
    'supplyId': supplyId,
    'location': location,
    'lotNo': lotNo,
    'bookQty': bookQty,
    'countedQty': countedQty,
    'countedStatus': countedStatus,
    'countedLocation': countedLocation,
    'countedAt': countedAt,
    'clientId': clientId,
    'photoFileId': photoFileId,
    'note': note,
    'synced': synced ? 1 : 0,
    'conflict': conflict ? 1 : 0,
    'keptCountedAt': keptCountedAt,
  };

  static StocktakeLocalItem fromRow(Map<String, Object?> r) =>
      StocktakeLocalItem(
        itemId: r['itemId'] as String,
        sessionId: r['sessionId'] as String,
        code: r['code'] as String,
        name: r['name'] as String,
        equipmentId: r['equipmentId'] as String?,
        lotId: r['lotId'] as String?,
        supplyId: r['supplyId'] as String?,
        location: r['location'] as String?,
        lotNo: r['lotNo'] as String?,
        bookQty: r['bookQty'] as String? ?? '1',
        countedQty: r['countedQty'] as String?,
        countedStatus: r['countedStatus'] as String?,
        countedLocation: r['countedLocation'] as String?,
        countedAt: r['countedAt'] as String?,
        clientId: r['clientId'] as String?,
        photoFileId: r['photoFileId'] as String?,
        note: r['note'] as String?,
        synced: (r['synced'] as num?) == 1,
        conflict: (r['conflict'] as num?) == 1,
        keptCountedAt: r['keptCountedAt'] as String?,
      );
}

/// Dòng "phát hiện thêm" ngoài đợt.
class StocktakeLocalExtra {
  StocktakeLocalExtra({
    required this.id,
    required this.sessionId,
    required this.code,
    this.qty = '1',
    this.note,
    this.countedAt,
    this.photoFileId,
    this.synced = false,
  });

  final String id;
  final String sessionId;
  final String code;
  final String qty;
  final String? note;
  final String? countedAt;
  final String? photoFileId;
  bool synced;

  Map<String, Object?> toRow() => {
    'id': id,
    'sessionId': sessionId,
    'code': code,
    'qty': qty,
    'note': note,
    'countedAt': countedAt,
    'photoFileId': photoFileId,
    'synced': synced ? 1 : 0,
  };

  static StocktakeLocalExtra fromRow(Map<String, Object?> r) =>
      StocktakeLocalExtra(
        id: r['id'] as String,
        sessionId: r['sessionId'] as String,
        code: r['code'] as String,
        qty: r['qty'] as String? ?? '1',
        note: r['note'] as String?,
        countedAt: r['countedAt'] as String?,
        photoFileId: r['photoFileId'] as String?,
        synced: (r['synced'] as num?) == 1,
      );
}

/// Meta đợt đã tải cục bộ.
class StocktakeLocalMeta {
  const StocktakeLocalMeta({
    required this.sessionId,
    required this.code,
    required this.name,
    required this.type,
    this.etag,
    required this.downloadedAt,
  });

  final String sessionId;
  final String code;
  final String name;
  final String type;
  final String? etag;
  final DateTime downloadedAt;
}

/// Kho cục bộ kiểm kê (tách interface để test không cần sqflite).
abstract class StocktakeLocalStore {
  Future<void> init();
  Future<void> savePackage({
    required String sessionId,
    required String code,
    required String name,
    required String type,
    String? etag,
    required List<StocktakeLocalItem> items,
  });
  Future<StocktakeLocalMeta?> meta(String sessionId);
  Future<List<StocktakeLocalItem>> items(String sessionId);
  Future<void> upsertCount(StocktakeLocalItem item);
  Future<List<StocktakeLocalExtra>> extras(String sessionId);
  Future<void> addExtra(StocktakeLocalExtra extra);
  Future<int> pendingCount(String sessionId);
  Future<void> markSynced(String sessionId, Set<String> clientIds);
  Future<void> markConflicts(
    String sessionId,
    Map<String, String?> keptAtByClientId,
  );
  Future<void> markExtrasSynced(String sessionId, Set<String> ids);
  Future<List<StocktakeLocalMeta>> downloadedSessions();
  Future<void> deleteSession(String sessionId);
}

class SqfliteStocktakeLocalStore implements StocktakeLocalStore {
  SqfliteStocktakeLocalStore({this.databaseName = 'labasset_stocktake.db'});

  final String databaseName;
  Database? _db;

  @override
  Future<void> init() async {
    if (_db != null) return;
    final path = '${await getDatabasesPath()}/$databaseName';
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE st_meta (
            sessionId TEXT PRIMARY KEY,
            code TEXT NOT NULL,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            etag TEXT,
            downloadedAt INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE st_items (
            itemId TEXT PRIMARY KEY,
            sessionId TEXT NOT NULL,
            code TEXT NOT NULL,
            name TEXT NOT NULL,
            equipmentId TEXT,
            lotId TEXT,
            supplyId TEXT,
            location TEXT,
            lotNo TEXT,
            bookQty TEXT NOT NULL,
            countedQty TEXT,
            countedStatus TEXT,
            countedLocation TEXT,
            countedAt TEXT,
            clientId TEXT,
            photoFileId TEXT,
            note TEXT,
            synced INTEGER NOT NULL DEFAULT 0,
            conflict INTEGER NOT NULL DEFAULT 0,
            keptCountedAt TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX IDX_st_items_session ON st_items (sessionId)',
        );
        await db.execute('''
          CREATE TABLE st_extras (
            id TEXT PRIMARY KEY,
            sessionId TEXT NOT NULL,
            code TEXT NOT NULL,
            qty TEXT NOT NULL,
            note TEXT,
            countedAt TEXT,
            photoFileId TEXT,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Database get _database {
    final db = _db;
    if (db == null) throw StateError('StocktakeLocalStore chưa init()');
    return db;
  }

  @override
  Future<void> savePackage({
    required String sessionId,
    required String code,
    required String name,
    required String type,
    String? etag,
    required List<StocktakeLocalItem> items,
  }) async {
    final db = _database;
    await db.transaction((txn) async {
      await txn.insert('st_meta', {
        'sessionId': sessionId,
        'code': code,
        'name': name,
        'type': type,
        'etag': etag,
        'downloadedAt': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      for (final item in items) {
        // Giữ kết quả đếm cũ nếu có (không ghi đè counted*).
        final existing = await txn.query(
          'st_items',
          where: 'itemId = ?',
          whereArgs: [item.itemId],
          limit: 1,
        );
        if (existing.isEmpty) {
          await txn.insert('st_items', item.toRow());
        } else {
          await txn.update(
            'st_items',
            {
              'code': item.code,
              'name': item.name,
              'bookQty': item.bookQty,
              'location': item.location,
              'lotNo': item.lotNo,
            },
            where: 'itemId = ?',
            whereArgs: [item.itemId],
          );
        }
      }
    });
  }

  @override
  Future<StocktakeLocalMeta?> meta(String sessionId) async {
    final rows = await _database.query(
      'st_meta',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return StocktakeLocalMeta(
      sessionId: r['sessionId'] as String,
      code: r['code'] as String,
      name: r['name'] as String,
      type: r['type'] as String,
      etag: r['etag'] as String?,
      downloadedAt: DateTime.fromMillisecondsSinceEpoch(
        (r['downloadedAt'] as num).toInt(),
      ),
    );
  }

  @override
  Future<List<StocktakeLocalItem>> items(String sessionId) async {
    final rows = await _database.query(
      'st_items',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'code ASC',
    );
    return rows.map(StocktakeLocalItem.fromRow).toList();
  }

  @override
  Future<void> upsertCount(StocktakeLocalItem item) => _database.update(
    'st_items',
    item.toRow(),
    where: 'itemId = ?',
    whereArgs: [item.itemId],
  );

  @override
  Future<List<StocktakeLocalExtra>> extras(String sessionId) async {
    final rows = await _database.query(
      'st_extras',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'countedAt DESC',
    );
    return rows.map(StocktakeLocalExtra.fromRow).toList();
  }

  @override
  Future<void> addExtra(StocktakeLocalExtra extra) =>
      _database.insert('st_extras', extra.toRow());

  @override
  Future<int> pendingCount(String sessionId) async {
    final items = await _database.rawQuery(
      'SELECT COUNT(*) AS n FROM st_items WHERE sessionId = ? AND countedAt IS NOT NULL AND synced = 0 AND conflict = 0',
      [sessionId],
    );
    final extras = await _database.rawQuery(
      'SELECT COUNT(*) AS n FROM st_extras WHERE sessionId = ? AND synced = 0',
      [sessionId],
    );
    return ((items.first['n'] as num?)?.toInt() ?? 0) +
        ((extras.first['n'] as num?)?.toInt() ?? 0);
  }

  @override
  Future<void> markSynced(String sessionId, Set<String> clientIds) async {
    if (clientIds.isEmpty) return;
    final marks = List.filled(clientIds.length, '?').join(',');
    await _database.rawUpdate(
      'UPDATE st_items SET synced = 1 WHERE sessionId = ? AND clientId IN ($marks)',
      [sessionId, ...clientIds],
    );
  }

  @override
  Future<void> markConflicts(
    String sessionId,
    Map<String, String?> keptAtByClientId,
  ) async {
    for (final e in keptAtByClientId.entries) {
      await _database.rawUpdate(
        'UPDATE st_items SET conflict = 1, keptCountedAt = ? WHERE sessionId = ? AND clientId = ?',
        [e.value, sessionId, e.key],
      );
    }
  }

  @override
  Future<void> markExtrasSynced(String sessionId, Set<String> ids) async {
    if (ids.isEmpty) return;
    final marks = List.filled(ids.length, '?').join(',');
    await _database.rawUpdate(
      'UPDATE st_extras SET synced = 1 WHERE sessionId = ? AND id IN ($marks)',
      [sessionId, ...ids],
    );
  }

  @override
  Future<List<StocktakeLocalMeta>> downloadedSessions() async {
    final rows = await _database.query('st_meta', orderBy: 'downloadedAt DESC');
    return rows
        .map(
          (r) => StocktakeLocalMeta(
            sessionId: r['sessionId'] as String,
            code: r['code'] as String,
            name: r['name'] as String,
            type: r['type'] as String,
            etag: r['etag'] as String?,
            downloadedAt: DateTime.fromMillisecondsSinceEpoch(
              (r['downloadedAt'] as num).toInt(),
            ),
          ),
        )
        .toList();
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final db = _database;
    await db.transaction((txn) async {
      await txn.delete(
        'st_items',
        where: 'sessionId = ?',
        whereArgs: [sessionId],
      );
      await txn.delete(
        'st_extras',
        where: 'sessionId = ?',
        whereArgs: [sessionId],
      );
      await txn.delete(
        'st_meta',
        where: 'sessionId = ?',
        whereArgs: [sessionId],
      );
    });
  }
}
