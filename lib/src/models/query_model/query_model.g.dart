// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'query_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Query _$QueryFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['token']);
  return Query(
    json['collection'] as String,
    sorts: (json['sorts'] as Map<String, dynamic>)?.map(
          (k, e) => MapEntry(k, _$enumDecodeNullable(_$SortingEnumMap, e)),
        ) ??
        {},
    equals: json['equals'] as Map<String, dynamic> ?? {},
    filters: json['filters'] as Map<String, dynamic> ?? {},
    update: json['update'] as Map<String, dynamic> ?? {},
    limit: json['limit'] as int ?? 100,
    offset: json['offset'] as int ?? 0,
    token: json['token'] as String,
    queryType: _$enumDecode(_$QueryTypeEnumMap, json['query_type']),
    document: json['document'] as Map<String, dynamic>,
  )..fields = (json['fields'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as bool),
    );
}

Map<String, dynamic> _$QueryToJson(Query instance) => <String, dynamic>{
      'collection': instance.collection,
      'query_type': _$QueryTypeEnumMap[instance.queryType],
      'document': instance.document,
      'fields': instance.fields,
      'token': instance.token,
      'offset': instance.offset,
      'limit': instance.limit,
      'update': instance.update,
      'filters': instance.filters,
      'equals': instance.equals,
      'sorts': instance.sorts?.map((k, e) => MapEntry(k, _$SortingEnumMap[e])),
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

const _$SortingEnumMap = {
  Sorting.ascending: 0,
  Sorting.descending: 1,
};

const _$QueryTypeEnumMap = {
  QueryType.query: 0,
  QueryType.listQuery: 1,
  QueryType.insert: 2,
  QueryType.update: 3,
  QueryType.exists: 4,
  QueryType.streamQuery: 5,
};
