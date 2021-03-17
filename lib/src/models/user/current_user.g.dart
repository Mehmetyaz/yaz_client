// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrentUser _$CurrentUserFromJson(Map<String, dynamic> json) {
  $checkKeys(json,
      requiredKeys: const ['user_id', 'user_mail', 'user_first_login']);
  return CurrentUser(
    json['user_first_name'] as String?,
    json['user_last_name'] as String?,
    json['user_id'] as String,
    biography: json['user_biography'] as String? ?? '',
    birthDate: UserModelStatics.dateFromJson(json['birth_date'] as int?),
    isFirstLogin: json['user_first_login'] as bool,
    mail: json['user_mail'] as String,
    createDate: UserModelStatics.dateFromJson(json['create_date'] as int?),
  );
}

Map<String, dynamic> _$CurrentUserToJson(CurrentUser instance) =>
    <String, dynamic>{
      'user_first_name': instance.firstName,
      'user_last_name': instance.lastName,
      'user_id': instance.userID,
      'create_date': UserModelStatics.dateToInt(instance.createDate),
      'user_mail': instance.mail,
      'user_first_login': instance.isFirstLogin,
      'user_biography': instance.biography,
      'birth_date': UserModelStatics.dateToInt(instance.birthDate),
    };
