import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:duchow_orm/annotations.dart';
import 'package:duchow_orm/src/StringUtils.dart';
import 'package:source_gen/source_gen.dart';

class OrmGenerator extends GeneratorForAnnotation<entity> {
  const OrmGenerator();

  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    MetaClass metaClass = generateMetaData(element);
    StringBuffer stringBuffer = StringBuffer();

    generateHead(metaClass, stringBuffer);
    generateTableName(metaClass, stringBuffer);
    generateCreateTableSql(metaClass, stringBuffer);
    generateQueryRowToEntity(metaClass, stringBuffer);
    generateQueryById(metaClass, stringBuffer);
    generateQueryAll(metaClass, stringBuffer);
    generateQueryOne(metaClass, stringBuffer);
    generateQueryCount(metaClass, stringBuffer);
    //generateInsert(metaClass, stringBuffer);
    //generateUpdate(metaClass, stringBuffer);
    //generateCustomUpdate(metaClass, stringBuffer);
    //generateDelete(metaClass, stringBuffer);
    generateFooter(metaClass, stringBuffer);

    return stringBuffer.toString();
  }

  void generateHead(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln("");
    stringBuffer.writeln("// Dao class for " +
        metaClass.className +
        " serving basic methods for query, insert, update, delete " +
        metaClass.className +
        " and generating Table structure from it.");
    stringBuffer.writeln("");
    stringBuffer.writeln("class " + metaClass.className + "Dao extends Dao<" + metaClass.className + "> {");
    stringBuffer.writeln("");
    stringBuffer.writeln("DbConnection dbConnection;");
    stringBuffer.writeln("");
    stringBuffer.writeln(metaClass.className + "Dao(this.dbConnection);");
    stringBuffer.writeln("");
  }

  void generateTableName(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln("String getTableName() {");
    stringBuffer.write("return '" + "dbConnection.getTableName(\"" + metaClass.className + "\")" + "';");
    stringBuffer.writeln("}");
    stringBuffer.writeln("");
  }

  void generateCreateTableSql(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln("String getCreateTableSql() {");
    stringBuffer.write("return \"CREATE TABLE IF NOT EXISTS " + "\" + " + "dbConnection.getTableName(\"" + metaClass.className + "\")" + " + \"" + " (\" + ");
    metaClass.listFields.forEach((metaField) {
      stringBuffer.write("dbConnection.getColumnName(\"" + metaClass.className + "\", \"" + metaField.fieldName + "\")" + " + \"" + metaField.columnType.typeName + metaField.columnType.createExtension + "\"");
      stringBuffer.write(metaField == metaClass.listFields.last ? " + \")\";" : " + \", \" + ");
    });
    stringBuffer.writeln("");
    stringBuffer.writeln("}");
    stringBuffer.writeln("");
  }

  void generateQueryRowToEntity(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln(metaClass.className + " queryRowTo(QueryResultRow queryRow) {");
    stringBuffer.writeln(metaClass.className + " " + metaClass.instanceName + " = " + metaClass.className + "();");
    metaClass.listFields.forEach((metaField) {
      stringBuffer.writeln("if(queryRow.data[" + "dbConnection.getColumnName(\"" + metaClass.className + "\", \"" + metaField.fieldName + "\")" + "] != null) {");
      if (!metaField.isCustom) {
        stringBuffer.writeln(metaClass.instanceName +
            "." +
            metaField.fieldName +
            " = " +
            metaField.columnType.convertToObjectPre +
            "queryRow.data[" +
            "dbConnection.getColumnName(\"" + metaClass.className + "\", \"" + metaField.fieldName + "\")" +
            "]" +
            metaField.columnType.convertToObjectPost +
            ";");
      } else {
        stringBuffer.writeln(metaClass.instanceName +
            "." +
            metaField.fieldName +
            " = dbConnection.getObjectFromCustomType(" +
            "queryRow.data[" +
            "dbConnection.getColumnName(\"" + metaClass.className + "\", \"" + metaField.fieldName + "\")" +
            "]" +
            ", '" +
            metaField.fieldType +
            "') as " + metaField.fieldType + ";");
      }
      stringBuffer.writeln("}");
    });
    stringBuffer.writeln("return " + metaClass.instanceName + ";");
    stringBuffer.writeln("}");
  }

  void generateQueryById(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer
        .writeln("Future<QueryResultRow?> queryById(var id, {String join = \"\"}) async {");
    bool idIsStr = metaClass.listFields.singleWhere((element) => element.isId).fieldType == "String";
    stringBuffer.writeln("List<QueryResultRow> l =  await dbConnection.executeQuery(\"SELECT * FROM " + "\" + " +
        "dbConnection.getTableName(\"" + metaClass.className + "\")" + "+ \"" +
        " \" + join + \" WHERE " + "\" +" +
        "dbConnection.getColumnName(\"" + metaClass.className + "\", \"" + metaClass.listFields.firstWhere((element) => element.isId).fieldName + "\")" + " + \""
        " = " +
        (idIsStr ? "'" : "") +
        "\" + id.toString()" +
        (idIsStr ? "+\"'\"" : "") +
        ");");
    stringBuffer.writeln("return l.isEmpty ? null : l.first;");
    stringBuffer.writeln("}");
  }

  void generateQueryAll(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln("Future<List<QueryResultRow>> queryAll({String? where, String? order, int? limit, int? offset, String? join}) async {");
    stringBuffer.writeln("String sqlStr = \"SELECT * FROM " + "\" + " + "dbConnection.getTableName(\"" + metaClass.className + "\")" + ";");
    stringBuffer.writeln("if(join != null) {");
    stringBuffer.writeln("sqlStr += \" \" + join!;");
    stringBuffer.writeln("}");
    stringBuffer.writeln("if(where != null) {");
    stringBuffer.writeln("sqlStr += \" WHERE \" + where!;");
    stringBuffer.writeln("}");
    stringBuffer.writeln("if(order != null) {");
    stringBuffer.writeln("sqlStr += \" ORDER BY \" + order!;");
    stringBuffer.writeln("}");
    stringBuffer.writeln("if(limit != null) {");
    stringBuffer.writeln("if(offset == null) {");
    stringBuffer.writeln("sqlStr += \" LIMIT \" + limit!.toString();");
    stringBuffer.writeln("} else {");
    stringBuffer.writeln("sqlStr += \" LIMIT \" + offset!.toString() + \",\" + limit!.toString();");
    stringBuffer.writeln("}");
    stringBuffer.writeln("}");
    stringBuffer.writeln("sqlStr += \";\";");
    stringBuffer.writeln("return await dbConnection.executeQuery(sqlStr);");
    stringBuffer.writeln("}");
  }

  void generateQueryOne(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln("Future<QueryResultRow?> queryOne(String where, String? join, String? order) async {");
    stringBuffer.writeln("String sqlStr = \"SELECT * FROM " + "\" + " "dbConnection.getTableName(\"" + metaClass.className + "\")" + ";");
    stringBuffer.writeln("if(join != null) {");
    stringBuffer.writeln("sqlStr += \" \" + join!;");
    stringBuffer.writeln("}");
    stringBuffer.writeln("if(where != null) {");
    stringBuffer.writeln("sqlStr += \" WHERE \" + where;");
    stringBuffer.writeln("}");
    stringBuffer.writeln("if(order != null) {");
    stringBuffer.writeln("sqlStr += \" ORDER BY \" + order!;");
    stringBuffer.writeln("}");
    stringBuffer.writeln("sqlStr += \";\";");
    stringBuffer.writeln("List<QueryResultRow> l = await dbConnection.executeQuery(sqlStr);");
    stringBuffer.writeln("return l.isEmpty ? null : l.first;");
    stringBuffer.writeln("}");
  }

  void generateQueryCount(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln("Future<int> queryCount({String? where, String? order, int? limit, int? offset, String? join}) async {");
    stringBuffer.writeln("String sqlStr = \"SELECT COUNT(*) FROM " + "\" + " + "dbConnection.getTableName(\"" + metaClass.className + "\")" + ";");
    stringBuffer.writeln("if(join != null) {");
    stringBuffer.writeln("sqlStr += \" \" + join;");
    stringBuffer.writeln("}");
    stringBuffer.writeln("if(where != null) {");
    stringBuffer.writeln("sqlStr += \" WHERE \" + where;");
    stringBuffer.writeln("}");
    stringBuffer.writeln("if(order != null) {");
    stringBuffer.writeln("sqlStr += \" ORDER BY \" + order;");
    stringBuffer.writeln("}");
    stringBuffer.writeln("if(limit != null) {");
    stringBuffer.writeln("if(offset == null) {");
    stringBuffer.writeln("sqlStr += \" LIMIT \" + limit.toString();");
    stringBuffer.writeln("} else {");
    stringBuffer.writeln("sqlStr += \" LIMIT \" + offset.toString() + \",\" + limit.toString();");
    stringBuffer.writeln("}");
    stringBuffer.writeln("}");
    stringBuffer.writeln("sqlStr += \";\";");
    stringBuffer.writeln("return dbConnection.executeForInt(sqlStr).then((result) {");
    stringBuffer.writeln("return result;");
    stringBuffer.writeln("});");
    stringBuffer.writeln("}");
  }

  void generateInsert(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln("Future<void> insert(" + metaClass.className + " " + metaClass.instanceName + ", Batch? batch) async {");
    stringBuffer.writeln("if(" + metaClass.instanceName + "." + metaClass.listFields.firstWhere((element) => element.isId).fieldName + " == null) {");
    stringBuffer
        .writeln(metaClass.instanceName + "." + metaClass.listFields.firstWhere((element) => element.isId).fieldName + " = dbConnection.createNewId();");
    stringBuffer.writeln("}");
    stringBuffer.writeln("String columnNames = \"\";");
    stringBuffer.writeln("String columnValues = \"\";");
    stringBuffer.writeln("bool hadBefore = false;");
    metaClass.listFields.forEach((metaField) {
      stringBuffer.writeln("if(" + metaClass.instanceName + "." + metaField.fieldName + " != null ) {");
      stringBuffer.writeln("if(hadBefore) columnNames += \", \";");
      stringBuffer.writeln("if(hadBefore) columnValues += \", \";");
      stringBuffer.writeln("hadBefore = true;");
      stringBuffer.writeln("columnNames += \"" + "dbConnection.getColumnName(\"" + metaClass.className + "\", \"" + metaField.fieldName + "\")" + "\";");
      if (!metaField.isCustom) {
        stringBuffer.writeln("columnValues += " +
            metaField.columnType.convertToSqlPre +
            metaClass.instanceName +
            "." +
            metaField.fieldName + "!" +
            metaField.columnType.convertToSqlPost +
            ";");
        stringBuffer.writeln("}");
      } else {
        stringBuffer.writeln("columnValues += " +
            metaField.columnType.convertToSqlPre +
            "dbConnection.getSqlFromCustomType(" +
            metaClass.instanceName +
            "." +
            metaField.fieldName +
            "!, '" +
            metaField.fieldType +
            "')" +
            metaField.columnType.convertToSqlPost +
            ";");
        stringBuffer.writeln("}");
      }
    });
    stringBuffer.writeln("if(batch == null) {");
    stringBuffer.writeln(
        "return await dbConnection.executeUpdate(\"INSERT INTO " + "dbConnection.getTableName(\"" + metaClass.className + "\")" + " (\" +" + "columnNames + \") VALUES (\" + columnValues + \")\");");
    stringBuffer.writeln("} else {");
    stringBuffer.writeln(
        "batch.customStatement(\"INSERT INTO " + "dbConnection.getTableName(\"" + metaClass.className + "\")" + " (\" +" + "columnNames + \") VALUES (\" + columnValues + \")\");");
    stringBuffer.writeln("return Future(() => null);");
    stringBuffer.writeln("}");

    stringBuffer.writeln("}");
    stringBuffer.writeln("");
  }

  void generateUpdate(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln("Future<void> update(" + metaClass.className + " " + metaClass.instanceName + ", Batch? batch) async {");
    stringBuffer.writeln("String columnChanges = \"\";");
    stringBuffer.writeln("bool hadBefore = false;");
    metaClass.listFields.forEach((metaField) {
      stringBuffer.writeln("if(" + metaClass.instanceName + "." + metaField.fieldName + " != null ) {");
      stringBuffer.writeln("if(hadBefore) columnChanges += \", \";");
      stringBuffer.writeln("hadBefore = true;");
      if (!metaField.isCustom) {
        stringBuffer.writeln("columnChanges += \"" +
            "dbConnection.getColumnName(\"" + metaClass.className + "\", \"" + metaField.fieldName + "\")" +
            " = \" + " +
            metaField.columnType.convertToSqlPre +
            metaClass.instanceName +
            "." +
            metaField.fieldName + "!" +
            metaField.columnType.convertToSqlPost +
            ";");
      } else {
        stringBuffer.writeln("columnChanges += \"" +
            "dbConnection.getColumnName(\"" + metaClass.className + "\", \"" + metaField.fieldName + "\")" +
            " = \" + " +
            metaField.columnType.convertToSqlPre +
            "dbConnection.getSqlFromCustomType(" +
            metaClass.instanceName +
            "." +
            metaField.fieldName +
            "!, '" +
            metaField.fieldType +
            "')" +
            metaField.columnType.convertToSqlPost +
            ";");
      }
      stringBuffer.writeln("}");
    });
    bool idIsStr = metaClass.listFields.singleWhere((element) => element.isId).fieldType == "String";

    stringBuffer.writeln("if(batch == null) {");
    stringBuffer.writeln("return await dbConnection.executeUpdate(\"UPDATE " +
        "dbConnection.getTableName(\"" + metaClass.className + "\")" +
        " SET \" +" +
        "columnChanges" +
        " + \" WHERE " +
        "dbConnection.getColumnName(\"" + metaClass.className + "\", \"" + metaClass.listFields.firstWhere((element) => element.isId).fieldName + "\")" +
        " = " +
        (idIsStr ? "'" : "") +
        "\" + " +
        metaClass.instanceName +
        "." +
        metaClass.listFields.firstWhere((element) => element.isId).fieldName +
        ".toString()" +
        (idIsStr ? "+\"'\"" : "") +
        ");");
    stringBuffer.writeln("} else {");
    stringBuffer.writeln("batch.customStatement(\"UPDATE " +
        "dbConnection.getTableName(\"" + metaClass.className + "\")" +
        " SET \" +" +
        "columnChanges" +
        " + \" WHERE " +
        "dbConnection.getColumnName(\"" + metaClass.className + "\", \"" + metaClass.listFields.firstWhere((element) => element.isId).fieldName + "\")" +
        " = " +
        (idIsStr ? "'" : "") +
        "\" + " +
        metaClass.instanceName +
        "." +
        metaClass.listFields.firstWhere((element) => element.isId).fieldName +
        ".toString()" +
        (idIsStr ? "+\"'\"" : "") +
        ");");
    stringBuffer.writeln("return Future(() => null);");
    stringBuffer.writeln("}");

    stringBuffer.writeln("}");
    stringBuffer.writeln("");
  }

  void generateCustomUpdate(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln(
        "Future<void> updateCustom(" + metaClass.className + " " + metaClass.instanceName + ", String where, List<String> ignore, Batch? batch) async {");
    stringBuffer.writeln("String columnChanges = \"\";");
    stringBuffer.writeln("bool hadBefore = false;");
    metaClass.listFields.forEach((metaField) {
      stringBuffer.writeln("if(" + metaClass.instanceName + "." + metaField.fieldName + " != null && !ignore.any((e) => e=='" + metaField.fieldName + "')) {");
      stringBuffer.writeln("if(hadBefore) columnChanges += \", \";");
      stringBuffer.writeln("hadBefore = true;");
      if (!metaField.isCustom) {
        stringBuffer.writeln("columnChanges += \"" +
            "dbConnection.getColumnName(\"" + metaClass.className + "\", \"" + metaField.fieldName + "\")" +
            " = \" + " +
            metaField.columnType.convertToSqlPre +
            metaClass.instanceName +
            "." +
            metaField.fieldName + "!" +
            metaField.columnType.convertToSqlPost +
            ";");
      } else {
        stringBuffer.writeln("columnChanges += \"" +
            "dbConnection.getColumnName(\"" + metaClass.className + "\", \"" + metaField.fieldName + "\")" +
            " = \" + " +
            metaField.columnType.convertToSqlPre +
            "dbConnection.getSqlFromCustomType(" +
            metaClass.instanceName +
            "." +
            metaField.fieldName +
            "!, '" +
            metaField.fieldType +
            "')" +
            metaField.columnType.convertToSqlPost +
            ";");
      }
      stringBuffer.writeln("}");
    });

    stringBuffer.writeln("if(batch == null) {");
    stringBuffer
        .writeln("return await dbConnection.executeUpdate(\"UPDATE " + "dbConnection.getTableName(\"" + metaClass.className + "\")" + " SET \" +" + "columnChanges" + " + \" WHERE \" + where);");
    stringBuffer.writeln("} else {");
    stringBuffer.writeln("batch.customStatement(\"UPDATE " + "dbConnection.getTableName(\"" + metaClass.className + "\")" + " SET \" +" + "columnChanges" + " + \" WHERE \" + where);");
    stringBuffer.writeln("return Future(() => null);");
    stringBuffer.writeln("}");

    stringBuffer.writeln("}");
    stringBuffer.writeln("");
  }

  void generateDelete(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln("Future<void> delete(" + metaClass.className + " " + metaClass.instanceName + ") async {");
    stringBuffer.writeln("return await dbConnection.executeUpdate(\"DELETE FROM " +
        "dbConnection.getTableName(\"" + metaClass.className + "\")" +
        " WHERE " +
        "dbConnection.getColumnName(\"" + metaClass.className + "\", \"" + metaClass.listFields.firstWhere((element) => element.isId).fieldName + "\")" +
        " = \" + " +
        metaClass.instanceName +
        "." +
        metaClass.listFields.firstWhere((element) => element.isId).fieldName +
        ".toString() + \"\");");
    stringBuffer.writeln("}");
    stringBuffer.writeln("");
  }

  void generateFooter(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln("}");
  }

  // Helper Methods

  MetaClass generateMetaData(Element element) {
    MetaClass metaClass = MetaClass(className: element.displayName,
        instanceName: element.displayName.substring(0, 1).toLowerCase() + element.displayName.substring(1),
        listFields: getFieldsWithSuper(element as ClassElement, StringUtils.camelToUnderscoreCase(element.displayName)));
    return metaClass;
  }

  List<MetaField> getFieldsWithSuper(ClassElement clazz, String tableName) {
    List<MetaField> listFields = [];
    if (clazz.supertype != null && clazz.supertype.toString() != 'Object') {
      listFields.addAll(getFieldsWithSuper(clazz.supertype!.element as ClassElement, tableName));
    }
    clazz.fields.forEach((field) {
      MetaField metaField = MetaField(fieldName: field.displayName, fieldType: field.type.toString().substring(0, field.type.toString().length - 1),
      columnType: getSqlTypeForDartType(field.type, field));
      field.metadata.forEach((element) {
        if (element.element.toString() == 'longText longText()') metaField.columnType = ColumnType("TEXT", convertToSqlPre: "\"'\" + ", convertToSqlPost: " + \"'\"");
      });
      metaField.isCustom = metaField.columnType.isCustom;
      field.metadata.forEach((element) {
        ////print(element.element.toString());
        if (element.element.toString() == "id id()" || element.element.toString() == "identity identity()") {
          ////print('IS ID!');
          metaField.isId = true;
          metaField.columnType.createExtension = ""; //""" PRIMARY KEY ON CONFLICT REPLACE";
        }
      });
      bool ignore = false;
      field.metadata.forEach((element) {
        if (element.element.toString().startsWith("noPersist")) {
          ignore = true;
        }
      });
      if (metaField.columnType != null && metaField.fieldName != "hashCode" && metaField.fieldName != "runtimeType" && !ignore) {
        listFields.add(metaField);
      }
    });
    return listFields;
  }

  ColumnType getSqlTypeForDartType(DartType dartType, FieldElement field) {
    //print(dartType.toString());
    if (dartType.toString() == "int?") {
      ////print('Its a INT');
      return ColumnType("INTEGER", convertToSqlPost: ".toString()");
    } else if (dartType.toString() == "double?") {
      ////print('Its a doub');
      return ColumnType("REAL", convertToSqlPost: ".toString()");
    } else if (dartType.toString() == "String?") {
      //print('Its a STR');
      return ColumnType("VARCHAR(255)", convertToSqlPre: "\"'\" + ", convertToSqlPost: " + \"'\"");
    } else if (dartType.toString() == "longText? String?") {
      //print('Its a LSTR');
      return ColumnType("TEXT", convertToSqlPre: "\"'\" + ", convertToSqlPost: " + \"'\"");
    } else if (dartType.toString() == "bool?") {
      return ColumnType("INT", convertToSqlPost: " ? \"1\" : \"0\")", convertToSqlPre: "(", convertToObjectPost: " == 1");
    } else if (dartType.toString() == "DateTime?") {
      ////print('Its a DT');
      return ColumnType("BIGINT",
          convertToSqlPost: ".millisecondsSinceEpoch.toString()", convertToObjectPre: "DateTime.fromMillisecondsSinceEpoch(", convertToObjectPost: ")");
    } else if (dartType.toString() == "Duration?") {
      ////print('Its a DT');
      return ColumnType("BIGINT", convertToSqlPost: ".inMilliseconds.toString()", convertToObjectPre: "Duration(milliseconds:(", convertToObjectPost: "))");
    } else {
      //print('Its nothing');
      return ColumnType("TEXT", convertToSqlPre: "\"'\" + ", convertToSqlPost: " + \"'\"", isCustom: true);
    }
  }
}

class MetaClass {
  String className;
  String instanceName;
  List<MetaField> listFields;
  MetaClass({required this.className, required this.instanceName, required this.listFields});
}

class MetaField {
  String fieldName;
  String fieldType;
  ColumnType columnType;
  bool isId = false;
  bool isCustom = false;
  bool longText = false;
  MetaField({required this.fieldName, required this.fieldType, required this.columnType});
}

class ColumnType {
  ColumnType(this.typeName,
      {this.createExtension = "", this.convertToSqlPre = "", this.convertToSqlPost = "", this.convertToObjectPre = "", this.convertToObjectPost = "", this.isCustom = false});

  String typeName;
  String createExtension;
  String convertToSqlPre;
  String convertToSqlPost;
  String convertToObjectPre;
  String convertToObjectPost;
  bool isCustom = false;
}
