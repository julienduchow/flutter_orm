abstract class FieldConverter<E> {

  String getSqlType();
  String getSqlFromEntity(E entity);
  E getEntityFromSql(String sql);
  String getTypeFor();

}