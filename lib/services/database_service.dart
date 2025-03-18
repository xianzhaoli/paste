import 'dart:ffi';
import 'dart:io';

import 'package:paste/widgets/clipboard_history_view.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/clipboard_item.dart';

class DatabaseService {
  static Database? _database;
  static void Function()? onInsertOrUpdate;
  static List<ClipboardItem> _memoryCache = [];

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    // loadToMemory();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'clipboard_history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE clipboard_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            content TEXT NOT NULL,
            html_content TEXT,
            timestamp TEXT NOT NULL,
            hash TEXT NOT NULL,
            size TEXT,
            CONSTRAINT "unique_key_hash" UNIQUE ("hash" ASC) ON CONFLICT REPLACE
          )
        ''');
        await db.execute('''CREATE INDEX idx_content
            ON "clipboard_items" (
              "content" ASC
            )''');
        await db.execute('''CREATE INDEX idx_timestamp
            ON "clipboard_items" (
              "timestamp" DESC
            )''');
      },
    );
  }

  static Future<void> loadToMemory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clipboard_items',
      orderBy: 'timestamp DESC',
    );
    _memoryCache =
        List.generate(maps.length, (i) => ClipboardItem.fromMap(maps[i]));
  }

  static Future<void> insertOrUpdate(ClipboardItem item) async {
    final db = await database;
    await db.insert('clipboard_items', item.toMap());
    if (onInsertOrUpdate != null) {
      onInsertOrUpdate!();
    }
  }

  static Future<void> updateTimestamp(String hash) async {
    final db = await database;
    await db.update(
      'clipboard_items',
      {'timestamp': DateTime.now().toIso8601String()},
      where: "hash = '$hash'",
    );
  }

  static Future<ClipboardItem> getItemByHash(String hash) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clipboard_items',
      where: "hash = '$hash'",
      orderBy: 'timestamp DESC',
    );
    return ClipboardItem.fromMap(maps.first);
  }

  static Future<List<ClipboardItem>> getHistory(String keyword,String type) async {
    final db = await database;
    final start = DateTime.now().millisecondsSinceEpoch;

    String where = "1 = 1 ";
    if(keyword != null && keyword.trim().isNotEmpty){
      where += "and content like '%$keyword%'";
    }

    if(type != null && type.trim().isNotEmpty){
      where += "and type = '$type'";
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'clipboard_items',
      where: where,
      orderBy: 'timestamp DESC',
    );
    final end = DateTime.now().millisecondsSinceEpoch;
    print('${(end - start)} ms');
    return List.generate(maps.length, (i) => ClipboardItem.fromMap(maps[i]));
  }

  static Future<void> delete(hash) async {
    final db = await database;
    await db.delete('clipboard_items', where: "hash = '$hash'");
  }

  static Future<void> removeByTime(int days) async {
    final db = await database;

    String where = "";
    if (days > -1) {
      DateTime dateTime = DateTime.now().add(Duration(days: days * -1));
      where = "timestamp <= '$dateTime'";
    }

    final List<Map<String, dynamic>> maps =
        await db.query('clipboard_items', where: where);
    await db.delete('clipboard_items', where: where);
    List<ClipboardItem> list =
        List.generate(maps.length, (i) => ClipboardItem.fromMap(maps[i]));
    for (ClipboardItem item in list) {
      if (item.type == 'image') {
        File f = File(item.content);
        if (f.existsSync()) {
          f.delete();
        }
      }
    }
  }
}
