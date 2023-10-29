import 'package:duchow_orm/Database.dart';
import 'package:drift/drift.dart';

abstract class Dao<E> {
  String getTableName();
  E queryRowTo(QueryResultRow queryRow);
  Future<QueryResultRow> queryById(int id, String join);
  Future<QueryResultRow> queryOne(String where, String? join, String? order);
  Future<int> queryCount({String? where, String? order, int? limit, int? offset});
  Future<List<QueryResultRow>> queryAll({String? where, String? order, int? limit, int? offset, String? join});
  Future<void> insert(E entity, Batch batch);
  Future<void> updateCustom(E entity, String where, List<String> ignore, Batch batch);
  Future<void> update(E entity, Batch batch);
  Future<void> delete(E entity);
}
