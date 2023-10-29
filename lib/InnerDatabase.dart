import 'package:drift/drift.dart';

class InnerDatabase extends GeneratedDatabase {

  int dbVersion;
  MigrationStrategy migrationStrategy;

  InnerDatabase(QueryExecutor e, this.dbVersion, this.migrationStrategy) : super(e);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [];

  @override
  int get schemaVersion => this.dbVersion;

  @override
  MigrationStrategy get migration => migrationStrategy;

}
