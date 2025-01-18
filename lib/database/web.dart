import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/wasm.dart';

import '../InnerDatabase.dart';

Future<InnerDatabase> constructDb(String name, int dbVersion, MigrationStrategy migrationStrategy, {bool logStatements = false, bool useOldPath = false}) async {
  return InnerDatabase(WasmDatabase(path: name,sqlite3: await WasmSqlite3.loadFromUrl(Uri.parse('sql-wasm.wasm')),  logStatements: logStatements), dbVersion, migrationStrategy);
}
