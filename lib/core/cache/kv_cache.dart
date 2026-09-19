import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// Giá trị cache kèm thời điểm ghi.
class CachedValue {
  const CachedValue(this.value, this.updatedAt);

  final Map<String, dynamic> value;
  final DateTime updatedAt;
}

/// Cache khoá–giá trị nhỏ (trang chủ, lịch sử quét…) trên sqflite.
abstract class KvCache {
  Future<void> init();
  Future<void> put(String key, Map<String, dynamic> value);
  Future<CachedValue?> get(String key);
  Future<void> delete(String key);
}

class SqfliteKvCache implements KvCache {
  SqfliteKvCache({this.databaseName = 'labasset_cache.db'});

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
        CREATE TABLE kv (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updatedAt INTEGER NOT NULL
        )
      '''),
    );
  }

  Database get _database {
    final db = _db;
    if (db == null) throw StateError('KvCache chưa init()');
    return db;
  }

  @override
  Future<void> put(String key, Map<String, dynamic> value) =>
      _database.insert('kv', {
        'key': key,
        'value': jsonEncode(value),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<CachedValue?> get(String key) async {
    final rows = await _database.query(
      'kv',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return CachedValue(
      jsonDecode(row['value'] as String) as Map<String, dynamic>,
      DateTime.fromMillisecondsSinceEpoch((row['updatedAt'] as num).toInt()),
    );
  }

  @override
  Future<void> delete(String key) =>
      _database.delete('kv', where: 'key = ?', whereArgs: [key]);
}
