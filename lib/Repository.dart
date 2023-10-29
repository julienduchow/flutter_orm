import 'dart:math';

import 'package:duchow_orm/Dao.dart';
import 'package:duchow_orm/Database.dart';
import 'package:duchow_orm/DbConnection.dart';
import 'package:drift/drift.dart';

abstract class Repository<E> {
  DbConnection dbConnection;

  Repository(this.dbConnection);

  Dao<E> getDaoInstance(DbConnection connection);

  String getDeepJoinStr() {
    return "";
  }

  Future<E> queryById(int id, String join) async {
    QueryResultRow queryRow = await getDaoInstance(dbConnection).queryById(id, join);
    E entity = getDaoInstance(dbConnection).queryRowTo(queryRow);
    return entity;
  }

  Future<E> queryOne(String where, {String? join, String? order}) async {
    QueryResultRow queryRow = await getDaoInstance(dbConnection).queryOne(where, join, order);
    E entity = getDaoInstance(dbConnection).queryRowTo(queryRow);
    return entity;
  }

  Future<List<E>> queryAll(
      {String? where, String? join, String? order, int? limit, int? offset, Future<void> executeOnQueryResultRow(E entity, QueryResultRow qrr)?}) async {
    List<QueryResultRow> listQueryRows = await getDaoInstance(dbConnection).queryAll(where: where, order: order, limit: limit, offset: offset, join: join);
    List<E> list = [];
    await Future.forEach(listQueryRows, (element) async {
      E entity = getDaoInstance(dbConnection).queryRowTo(element);
      list.add(entity);
      if (executeOnQueryResultRow != null) await executeOnQueryResultRow.call(entity, element);
    });
    return list;
  }

  Future<int> queryCount({String? where, String? order, int? limit, int? offset}) async =>
      await getDaoInstance(dbConnection).queryCount(where: where, order: order, limit: limit, offset: offset);

  Future<void> insert(E entity, Batch batch) async => await getDaoInstance(dbConnection).insert(entity, batch);

  Future<void> update(E entity, Batch batch) async => await getDaoInstance(dbConnection).update(entity, batch);

  Future<void> delete(E entity) async => await getDaoInstance(dbConnection).delete(entity);

  String col(String columnName) => getDaoInstance(dbConnection).getTableName() + "_" + camelToUnderscoreCase(columnName);

  static String camelToUnderscoreCase(String camelCaseStr) {
    return camelCaseStr.replaceAllMapped(RegExp(r'(?<=[a-z])[A-Z]'), (Match m) => ('_' + m.group(0)!)).toLowerCase();
  }

  onQueryDeep(E entity, QueryResultRow queryResultRow) async {}

  onInsertDeep(E entity) async {}

  onUpdateDeep(E entity) async {}

  onDeleteDeep(E entity) async {}

  Future<E> queryByIdDeep(int id) async {
    QueryResultRow queryRow = await getDaoInstance(dbConnection).queryById(id, getDeepJoinStr());
    E entity = getDaoInstance(dbConnection).queryRowTo(queryRow);
    if (entity != null) await onQueryDeep(entity, queryRow);
    return entity;
  }

  Future<E> queryOneDeep(String where, {String? join, String? order}) async {
    QueryResultRow queryRow = await getDaoInstance(dbConnection).queryOne(where, join, order);
    E entity = getDaoInstance(dbConnection).queryRowTo(queryRow);
    if (entity != null) await onQueryDeep(entity, queryRow);
    return entity;
  }

  Future<List<E>> queryAllDeep(
      {String? where, String? order, int? limit, int? offset, String? join, Future<void> executeOnQueryResultRow(E entity, QueryResultRow qrr)?}) async {
    List<QueryResultRow> listQueryRows = await getDaoInstance(dbConnection).queryAll(where: where, order: order, limit: limit, offset: offset, join: join);
    List<E> list = [];
    await Future.forEach(listQueryRows, (element) async {
      E entity = getDaoInstance(dbConnection).queryRowTo(element);
      list.add(entity);
      if (executeOnQueryResultRow != null) await executeOnQueryResultRow.call(entity, element);
      await onQueryDeep(list.last, element);
    });
    return list;
  }

  Future<void> insertDeep(E entity, Batch batch) async {
    await getDaoInstance(dbConnection).insert(entity, batch);
    await onInsertDeep(entity);
  }

  Future<void> updateDeep(E entity, Batch batch) async {
    await getDaoInstance(dbConnection).update(entity, batch);
    await onUpdateDeep(entity);
  }

  Future<void> deleteDeep(E entity) async {
    await getDaoInstance(dbConnection).delete(entity);
    await onDeleteDeep(entity);
  }
}
