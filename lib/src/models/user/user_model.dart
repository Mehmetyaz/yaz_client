import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

///Dikimall User
@JsonSerializable()
class YazApiUser {
  /// Default
  YazApiUser(this.firstName, this.lastName, this.userID);

  ///
  factory YazApiUser.fromJson(Map<String, dynamic> json) =>
      _$YazApiUserFromJson(json);

  ///
  Map<String, dynamic> toJson() => _$YazApiUserToJson(this);

  ///User First Name
  @JsonKey(name: "user_first_name")
  final String firstName;

  ///User First Name
  @JsonKey(name: "user_last_name")
  final String lastName;

  ///User ID
  @JsonKey(name: 'user_id', required: true)
  final String userID;

  ///User Full Name
  String get name => '$firstName $lastName';

  // ///Profile picture stored picture ID
  // @JsonKey(name: "user_profile_picture_id", defaultValue: "")
  // String profilePicture = '';

  // ///User Types
  // @JsonKey(name: 'user_types', nullable: true)
  // final List<UserType> types;

  @override
  String toString() {
    return '$firstName $lastName';
  }
}
