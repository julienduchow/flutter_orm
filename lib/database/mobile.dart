import 'dart:io';
import 'dart:isolate';

import 'package:drift/isolate.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:path_provider/path_provider.dart' as paths;
import 'package:path/path.dart' as p;

import '../InnerDatabase.dart';

Future<DriftIsolate> _createMoorIsolate(String dbName) async {
  // this method is called from the main isolate. Since we can't use
  // getApplicationDocumentsDirectory on a background isolate, we calculate
  // the database path in the foreground isolate and then inform the
  // background isolate about the path.
  final dir = await paths.getApplicationDocumentsDirectory();
  final path = p.join(dir.path, dbName);
  final receivePort = ReceivePort();

  await Isolate.spawn(
    _startBackground,
    _IsolateStartRequest(receivePort.sendPort, path),
  );

  // _startBackground will send the MoorIsolate to this ReceivePort
  return (await receivePort.first as DriftIsolate);
}

void _startBackground(_IsolateStartRequest request) {
  // this is the entry point from the background isolate! Let's create
  // the database from the path we received
  final executor = NativeDatabase(File(request.targetPath));
  //final executor = WebDatabase('db', logStatements: true);
  // we're using MoorIsolate.inCurrent here as this method already runs on a
  // background isolate. If we used MoorIsolate.spawn, a third isolate would be
  // started which is not what we want!
  final moorIsolate = DriftIsolate.inCurrent(
    () => DatabaseConnection.fromExecutor(executor),
  );
  // inform the starting isolate about this, so that it can call .connect()
  request.sendMoorIsolate.send(moorIsolate);
}

// used to bundle the SendPort and the target path, since isolate entry point
// functions can only take one parameter.
class _IsolateStartRequest {
  final SendPort sendMoorIsolate;
  final String targetPath;

  _IsolateStartRequest(this.sendMoorIsolate, this.targetPath);
}

class MyQueryExecutorUser extends QueryExecutorUser {
  int get schemaVersion => 2;
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) {
    return Future(() => null);
  }
}

Future<InnerDatabase> constructDb(String name, int dbVersion, MigrationStrategy migrationStrategy, {bool logStatements = false}) async {
  if (Platform.isIOS || Platform.isAndroid) {
    /*final executor = LazyDatabase(() async {
      final dataDir = await paths.getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dataDir.path, name + '.sqlite'));
      return VmDatabase(dbFile, logStatements: logStatements);
    });*/
    DriftIsolate isolate = await _createMoorIsolate(name);
    DatabaseConnection connection = await isolate.connect();
    await connection.executor.ensureOpen(MyQueryExecutorUser());
    return InnerDatabase(connection.executor, dbVersion, migrationStrategy);
  }
  if (Platform.isMacOS || Platform.isLinux) {
    final file = File(name + '.sqlite');
    return InnerDatabase(NativeDatabase(file, logStatements: logStatements), dbVersion, migrationStrategy);
  }
  // if (Platform.isWindows) {
  //   final file = File('db.sqlite');
  //   return Database(VMDatabase(file, logStatements: logStatements));
  // }
  return InnerDatabase(NativeDatabase.memory(logStatements: logStatements), dbVersion, migrationStrategy);
}
