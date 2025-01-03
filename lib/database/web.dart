import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import '../InnerDatabase.dart';

InnerDatabase constructDb(String name, int dbVersion, MigrationStrategy migrationStrategy, {bool logStatements = false, bool useOldPath = false}) {
  throw 'Platform not yet supported (TODO)';
  //return InnerDatabase(WasmDatabase(path: name,sqlite3: ,  logStatements: logStatements), dbVersion, migrationStrategy);
}
