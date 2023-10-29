// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../annotations.dart';

class OrmGenerator extends GeneratorForAnnotation<entity> {
  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    MetaClass metaClass = generateMetaData(element);
    StringBuffer stringBuffer = StringBuffer();

    generateHead(metaClass, stringBuffer);
    generateToJson(metaClass, stringBuffer);
    generateFromJson(metaClass, stringBuffer);
    generateFooter(metaClass, stringBuffer);

    return stringBuffer.toString();
  }

  void generateHead(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln("");
    stringBuffer.writeln(
        "// JSON class for " + metaClass.className + " serving basic methods for serialize and deserialize " + metaClass.className + ".");
    stringBuffer.writeln("");
    stringBuffer.writeln("class " + metaClass.className + "Json extends JsonAble<" + metaClass.className + "> {");
    stringBuffer.writeln("");
  }

  void generateToJson(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln("Map<String, dynamic> toJson (" + metaClass.className + " " + metaClass.instanceName + ") {");
    stringBuffer.writeln("Map<String, dynamic> map = Map();");
    stringBuffer.write("map['type'] = '" + metaClass.className +  "';");
    metaClass.listFields.forEach((metaField) {
      stringBuffer.writeln("if(" + metaClass.instanceName + "." + metaField.fieldName + " != null) {");
      String content;
      if(metaField.jsonType.listTypeName != null) {
        content = metaClass.instanceName + "." + metaField.fieldName + '.map((e) => ' + metaField.jsonType.listTypeName! + "Json().toJson(e)).toList()";
      } else {
        content = metaField.jsonType.convertToJsonPre + metaClass.instanceName + "." + metaField.fieldName + metaField.jsonType.convertToJsonPost;
        if(metaField.jsonType.referenceClassName != null) {
          content = metaField.jsonType.referenceClassName! + "Json().toJson(" + content + ")";
        }
      }

      stringBuffer.write("map[\"" + metaField.jsonName + "\"] = " + content +  ";");
      stringBuffer.writeln("}");
    });
    stringBuffer.writeln("return map;");
    stringBuffer.writeln("}");
    stringBuffer.writeln("");
  }

  //map["listMatchInformations"] = combinedUpdateData.listMatchInformations.map((e) => MatchInformationJson().toJson(e));

  void generateFromJson(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln(metaClass.className + " fromJson(Map<String, dynamic> map) {");
    stringBuffer.writeln(metaClass.className + " " + metaClass.instanceName + " = " + metaClass.className + "();");
    metaClass.listFields.forEach((metaField) {
      stringBuffer.writeln("if (map[\"" + metaField.jsonName + "\"] != null) {");
      String content;
      if(metaField.jsonType.listTypeName != null) {
        content = 'List<' + metaField.jsonType.listTypeName! + '>.from(map[\"' + metaField.jsonName + "\"].map((data) => " + metaField.jsonType.listTypeName! + "Json().fromJson(data)).toList())";
      } else {
        content = metaField.jsonType.convertToObjectPre + "map[\"" + metaField.jsonName + "\"]" + metaField.jsonType.convertToObjectPost;
        if(metaField.jsonType.referenceClassName != null) {
          content = metaField.jsonType.referenceClassName! + "Json().fromJson(" + content + ")";
        }
      }
      stringBuffer.write(metaClass.instanceName + "." + metaField.fieldName + " = " + content + ";");
      stringBuffer.writeln("}");
    });
    stringBuffer.writeln("return " + metaClass.instanceName + ";");
    stringBuffer.writeln("}");
    stringBuffer.writeln("");
  }

  // combinedUpdateData.listMatchInformations = List<MatchInformation>.from(map["listMatchInformations"].map((data) => MatchInformationJson().fromJson(data)).toList());

  void generateFooter(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln("}");
  }

  // Helper Methods

  MetaClass generateMetaData(Element element) {
    MetaClass metaClass = MetaClass(className: element.displayName,
        instanceName: element.displayName.substring(0, 1).toLowerCase() + element.displayName.substring(1),
        jsonName: element.displayName, listFields: getFieldsWithSuper(element as ClassElement));
    return metaClass;
  }

  List<MetaField> getFieldsWithSuper(ClassElement clazz) {
    List<MetaField> listFields = [];
    if (clazz.supertype != null && clazz.supertype.toString() != 'Object') {
      listFields.addAll(getFieldsWithSuper(clazz.supertype!.element as ClassElement));
    }
    clazz.fields.forEach((field) {
      MetaField metaField = MetaField(fieldName: field.displayName,
          fieldType: field.type.toString(), jsonName: field.displayName, jsonType: getJsonTypeForDartType(field));
      field.metadata.forEach((element) {
        //print(element.toString());
      });
      if(metaField.fieldName != 'hashCode' && metaField.fieldName != 'runtimeType') {
        listFields.add(metaField);
      }

    });
    return listFields;
  }

  JsonType getJsonTypeForDartType(FieldElement field) {
    print(field.type.toString());
    if(field.type.toString().startsWith("List<")) {
      //print("List detected! -> " + field.type.toString().substring(field.type.toString().indexOf("<") + 1, field.type.toString().indexOf(">") - 1));
      return JsonType(listTypeName: field.type.toString().substring(field.type.toString().indexOf("<") + 1, field.type.toString().indexOf(">") - 1));
    }
    if (field.type.toString() == "int?") {
      return JsonType();
    } else if (field.type.toString() == "double?") {
      return JsonType();
    } else if (field.type.toString() == "String?") {
      return JsonType();
    } else if (field.type.toString() == "bool?") {
      return JsonType(convertToJsonPost: "! ? \"true\" : \"false\"");
    } else if (field.type.toString() == "DateTime?") {
      bool isTime = false;
      bool isDate = false;
      field.metadata.forEach((element) {
        if(element.toString() == '@onlyTime? onlyTime()') isTime = true;
        if(element.toString() == '@onlyDate? onlyDate()') isDate = true;
      });
      if(isTime) {
        return JsonType(convertToJsonPost: "!.toIso8601String().substring(11,22)", convertToObjectPre: "DateTime.parse(\"1970-01-01T\" + ", convertToObjectPost: ')');
      } else if (isDate) {
        return JsonType(convertToJsonPost: "!.toIso8601String().substring(0,10)", convertToObjectPre: 'DateTime.parse(',convertToObjectPost: "+ \"T00:00:00.000\")");
      } else {
        return JsonType(convertToObjectPre: 'DateTime.parse(', convertToObjectPost: ')', convertToJsonPost: '!.toIso8601String()');
      }
    } else if (field.type.toString() == "Duration?") {
      return JsonType(convertToJsonPost: "!.inMilliseconds", convertToObjectPre: "Duration(milliseconds:(", convertToObjectPost: "))");
    }
    if(field.type.toString().contains("<")) {
      return JsonType(referenceClassName: field.type.toString().substring(0,field.type.toString().indexOf("<")));
    } else {
      return JsonType(referenceClassName: field.type.toString().substring(0,field.type.toString().length - 1));
    }
  }
}

class MetaClass {
  String className;
  String instanceName;
  String jsonName;
  List<MetaField> listFields;
  MetaClass({required this.className, required this.instanceName, required this.jsonName, required this.listFields});
}

class MetaField {
  String fieldName;
  String fieldType;
  String jsonName;
  JsonType jsonType;
  MetaField({required this.fieldName, required this.fieldType, required this.jsonName, required this.jsonType});
}

class JsonType {
  JsonType(
      {this.createExtension = "",
        this.convertToJsonPre = "",
        this.convertToJsonPost = "",
        this.convertToObjectPre = "",
        this.listTypeName = null,
        this.convertToObjectPost = "",
        this.referenceClassName});

  String? referenceClassName;
  String createExtension;
  String convertToJsonPre;
  String convertToJsonPost;
  String convertToObjectPre;
  String convertToObjectPost;
  String? listTypeName;

}
