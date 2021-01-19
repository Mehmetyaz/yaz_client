import 'package:json_annotation/json_annotation.dart';

///Image Size Type;
///   Full : Original Image
///   Mid : resized for 700px
///   Thumb : resized for 200px
/// Just for front-end
enum ImageSize {
  /// Original Size
  @JsonValue(0)
  full,

  /// 700 px
  @JsonValue(1)
  mid,

  /// 200 px
  @JsonValue(2)
  thumb
}
