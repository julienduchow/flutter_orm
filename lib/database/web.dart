import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/wasm.dart';

import '../InnerDatabase.dart';

Future<InnerDatabase> constructDb(String name, int dbVersion, MigrationStrategy migrationStrategy, {bool logStatements = false, bool useOldPath = false}) async {
 // return InnerDatabase(WasmDatabase(path: name,sqlite3: await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm')),  logStatements: logStatements), dbVersion, migrationStrategy);


  final result = await WasmDatabase.open(
    databaseName: name, // prefer to only use valid identifiers here
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.dart.js'),
  );

  if (result.missingFeatures.isNotEmpty) {
    // Depending how central local persistence is to your app, you may want
    // to show a warning to the user if only unrealiable implemetentations
    // are available.
    print('Using ${result.chosenImplementation} due to missing browser '
        'features: ${result.missingFeatures}');
  }



  return InnerDatabase(result.resolvedExecutor.executor, dbVersion, migrationStrategy);

}
