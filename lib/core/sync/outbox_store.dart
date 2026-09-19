import 'package:sqflite/sqflite.dart';

import 'outbox_item.dart';

/// Kho lưu outbox (tách interface để unit test không cần sqflite).
abstract class OutboxStore {
  Future<void> init();
  Future<void> insert(OutboxItem item);
  Future<void> update(OutboxItem item);
  Future<void> delete(String id);
  Future<List<OutboxItem>> all();
  Future<void> clear();
}

/// Bản thật: sqflite, bảng `outbox`.
class SqfliteOutboxStore implements OutboxStore {
  SqfliteOutboxStore({this.databaseName = 'labasset_outbox.db'});

  final String databaseName;
  Database? _db;

  @override
  Future<void> init() async {
    if (_db != null) return;
    final path = '${await getDatabasesPath()}/$databaseName';
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE outbox (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          payload TEXT NOT NULL,
          createdAt INTEGER NOT NULL,
          attempts INTEGER NOT NULL DEFAULT 0,
          lastError TEXT,
          lastAttemptAt INTEGER
        )
      '''),
    );
  }

  Database get _database {
    final db = _db;
    if (db == null) throw StateError('OutboxStore chưa init()');
    return db;
  }

  @override
  Future<void> insert(OutboxItem item) =>
      _database.insert('outbox', item.toRow());

  @override
  Future<void> update(OutboxItem item) => _database.update(
    'outbox',
    item.toRow(),
    where: 'id = ?',
    whereArgs: [item.id],
  );

  @override
  Future<void> delete(String id) =>
      _database.delete('outbox', where: 'id = ?', whereArgs: [id]);

  @override
  Future<List<OutboxItem>> all() async {
    final rows = await _database.query('outbox', orderBy: 'createdAt ASC');
    return rows.map((r) => OutboxItem.fromRow(r)).toList();
  }

  @override
  Future<void> clear() => _database.delete('outbox');
}
