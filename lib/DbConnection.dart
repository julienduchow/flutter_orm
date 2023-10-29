import 'package:drift/drift.dart';
import 'package:duchow_orm/Database.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/backends.dart';

class DbConnection {

  DbConnection(this.database);

  Database database;

  Future<List<QueryResultRow>> executeQuery(String sqlQuery) async {
    //print(sqlQuery);
    //await compute(que,sqlQuery);
    return await database.executeQuery(sqlQuery);
  }

  Future<void> executeUpdate(String sql) async {
    //print(sql);
    await database.executeUpdate(sql);
    //compute(exe, sql);

  }

  Object getObjectFromCustomType(String sql, String type) {
    return database.getObjectFromCustomType(sql, type);
  }

  String getSqlFromCustomType(Object obj, String type) {
    return database.getSqlFromCustomType(obj, type);
  }

  Future<int> executeForInt(String sqlQuery) async {
    List<QueryResultRow> rs = await database.executeQuery(sqlQuery);
    return rs[0].data.values.first == null ? 0 : rs[0].data.values.first;
  }

  Future<bool> checkIfExists(String sqlQuery) async {
    List<QueryResultRow> rs = await database.executeQuery(sqlQuery);
    return rs.isNotEmpty;
    //return rs[0].data.values.first == null ? 0 : rs[0].data.values.first;
  }

  Future<List<int>> executeForIntList(String sqlQuery) async {
    List<QueryResultRow> rs = await database.executeQuery(sqlQuery);
    List<int> list = [];
    rs.forEach((e) => list.add(e.data.values.first));
    return list;
  }

  Future<List<String>> executeForStringList(String sqlQuery) async {
    List<QueryResultRow> rs = await database.executeQuery(sqlQuery);
    List<String> list = [];
    rs.forEach((e) => list.add(e.data.values.first));
    return list;
  }

}

class DatabaseWithSql {
  DatabaseWithSql(this.database, this.sql);
  Database database;
  String sql;
}

class QEU extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) {
    return Future(() => null);
  }

  @override
  int get schemaVersion => 1;

}

/*Future<int> exe(String d) async {
  //print(sql);
  //await dbWithSql.database.executeUpdate(dbWithSql.sql);
  final database = VmDatabase.memory();
  await database.ensureOpen(QEU());
  await database.runInsert(d, []);
  return 0;
}

Future<List<Map<String, dynamic>>> que(String d) async {
  //print(sql);
  //await dbWithSql.database.executeUpdate(dbWithSql.sql);
  final database = VmDatabase.memory();
  await database.ensureOpen(QEU());
  return await database.runSelect(d, []);
}*/