import 'package:json_annotation/json_annotation.dart';

///
enum Sorting {
  ///
  @JsonValue(0)
  ascending,

  ///
  @JsonValue(1)
  descending
}
