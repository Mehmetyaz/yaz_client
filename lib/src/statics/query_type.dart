import 'package:json_annotation/json_annotation.dart';

///
enum QueryType {
  ///
  @JsonValue(0)
  query,

  ///
  @JsonValue(1)
  listQuery,

  ///
  @JsonValue(2)
  insert,

  ///
  @JsonValue(3)
  update,

  ///
  @JsonValue(4)
  exists,

  ///
  @JsonValue(5)
  streamQuery,

  ///
  @JsonValue(6)
  delete,

  ///
  @JsonValue(7)
  count,
}
