class StringUtils {

   static String camelToUnderscoreCase(String camelCaseStr) {
     return camelCaseStr.replaceAllMapped(RegExp(r'(?<=[a-z])[A-Z]'), (Match m) => ('_' + m.group(0)!)).toLowerCase();
   }

}