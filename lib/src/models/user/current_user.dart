import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../statics/statics.dart';
import 'user_model.dart';

part 'current_user.g.dart';

///Current User Class
@JsonSerializable()
class CurrentUser extends YazApiUser {
  ///
  CurrentUser(String? firstName, String? lastName, String? userID,
      {required this.biography,
      required this.birthDate,
      required this.isFirstLogin,
      required this.mail,
      required this.createDate})
      : super(firstName, lastName, userID);

  ///
  @override
  factory CurrentUser.fromJson(Map<String, dynamic> json) =>
      _$CurrentUserFromJson(json);

  ///
  @override
  Map<String, dynamic> toJson() => _$CurrentUserToJson(this);

  ///User Birth Date
  @JsonKey(
      name: "create_date",
      fromJson: UserModelStatics.dateFromJson,
      toJson: UserModelStatics.dateToInt,
      nullable: false)
  final DateTime createDate;

  ///user mail
  @JsonKey(name: 'user_mail', required: true, nullable: false)
  String? mail;

  // ///user address for purchase
  // @JsonKey(name: 'user_address', nullable: true, required: false)
  // UserAddress address;

  ///the session is first for this user
  @JsonKey(name: 'user_first_login', required: true, nullable: false)
  bool? isFirstLogin;

  ///User Age
  int get age => DateTime.now().year - birthDate.year;

  ///User Bio
  @JsonKey(name: 'user_biography', defaultValue: '')
  String biography;

  ///User Birth Date
  @JsonKey(
      name: "birth_date",
      fromJson: UserModelStatics.dateFromJson,
      nullable: false,
      toJson: UserModelStatics.dateToInt)
  final DateTime birthDate;
}
