import 'package:duchow_orm/DbConnection.dart';
import 'package:duchow_orm/FieldConverter.dart';
import 'package:duchow_orm/InnerDatabase.dart';
import 'package:duchow_orm/database/shared.dart';
import 'package:drift/drift.dart';

abstract class Database {
  InnerDatabase? innerDatabase;
  int? _version;
  String? _name;
  late bool _useOldPath;

  Database() {
    DbConfig config = getConfig();
    this._version = config._version;
    this._name = config._name;
    this._useOldPath = config.useOldPath;
    //this._isDefault = config._isDefault;
  }

  DbConfig getConfig();

  Future<void> onCreate();

  createNewId();

  Future<void> onUpdate(int from, int to);

  List<FieldConverter> getListConverters();

  Object getObjectFromCustomType(String sql, String type) {
    for (FieldConverter fc in getListConverters()) {
      if (fc.getTypeFor() == type) {
        return fc.getEntityFromSql(sql);
      }
    }
    throw new Exception("Could not find a Converter for type " + type.toString());
  }

  String getSqlFromCustomType(Object obj, String type) {
    //print(type);
    for (FieldConverter fc in getListConverters()) {
      if (fc.getTypeFor() == type) {
        return fc.getSqlFromEntity(obj);
      }
    }
    throw new Exception("Could not find a Converter for type " + type.toString());
  }

  close() {
    if (this.innerDatabase != null) this.innerDatabase!.close();
  }

  String getTableName(String className) {
    if(getConfig().useOldColumnNames) {
      return className;
    } else {
      return camelToUnderscoreCase(className);
    }
  }

  String getColumnName(String className, String fieldName) {
    if(getConfig().useOldColumnNames) {
      return className + "_" + fieldName;
    } else {
      return camelToUnderscoreCase(className) + "_" + camelToUnderscoreCase(fieldName);
    }
  }

  static String camelToUnderscoreCase(String camelCaseStr) {
    return camelCaseStr.replaceAllMapped(RegExp(r'(?<=[a-z])[A-Z]'), (Match m) => ('_' + m.group(0)!)).toLowerCase();
  }

  Future<void> init() async {
    //MoorIsolate isolate = await MoorIsolate.spawn(_backgroundConnection);
    //connection = await isolate.connect();
    //connection.executor.ensureOpen(MyQueryExecutorUser());

    print("Initializing Database...");
    innerDatabase = await constructDb(
        _name!,
        _version!,
        MigrationStrategy(
          onCreate: (Migrator m) async {
            print("Creating Database...");
            await onCreate();
          },
          onUpgrade: (Migrator m, int from, int to) async {
            print("Updating Database from $from to $to...");
            await onUpdate(from, to);
          },
          beforeOpen: (details) async {
            //print("Before Open Database...");
            /* Nothing? */
          },
        ), useOldPath: this._useOldPath);
    // to trigger creation/update process*/
    await onCreate();
    await getConnection().executeQuery("SELECT 1");
  }

  Future<List<QueryResultRow>> executeQuery(String sql) async {
    List<QueryRow> result = await innerDatabase!.customSelect(sql).get();
    List<QueryResultRow> list = [];
    result.forEach((element) {
      list.add(QueryResultRow(element.data));
    });
    return list;
  }

  Future<void> execute(String sql) async {
    await innerDatabase!.customStatement(sql);
  }

  Future<void> tryExecute(String sql) async {
    try {
      await innerDatabase!.customStatement(sql);
    } catch (_) {}
  }

  Future<void> executeUpdate(String sql) async {
    await innerDatabase!.customUpdate(sql);
  }

  Future<void> transaction(Future<void> Function() action) async {
    await innerDatabase!.transaction(action);
  }

  Future<void> tc(Future<void> Function(DbConnection) callback) async {
    await innerDatabase!.transaction(() async => await callback.call(getConnection()));
  }

  Future<void> batch(Future<void> Function(Batch) callback) async {
    await innerDatabase!.batch((b) async => await callback.call(b));
  }

  //await innerDatabase.batch((batch) => batch.customStatement(sql))

  DbConnection getConnection() {
    return DbConnection(this);
  }
}

class DbConfig {
  int _version;

  String _name;
  bool _isDefault;
  bool useOldPath;
  bool useOldColumnNames;

  DbConfig(this._version, this._name, this._isDefault, {this.useOldPath = false, this.useOldColumnNames = false});
}

class QueryResultRow {
  Map<String, dynamic> data;

  QueryResultRow(this.data);
}
