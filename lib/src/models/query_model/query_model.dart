import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:yaz_client/src/statics/query_type.dart';
import 'package:yaz_client/src/statics/sorting.dart';

part 'query_model.g.dart';

///Query Class for Mongo Db Query
@JsonSerializable()
class Query {
  ///Is the same [Query.create]
  Query(this.collection,
      {@required this.sorts,
      @required this.equals,
      @required this.filters,
      @required this.update,
      @required this.limit,
      @required this.offset,
      @required this.token,
      @required this.queryType,
      this.document});

  ///Create Query
  ///[collection] must not be null
  ///[token] must not be null
  Query.create(this.collection,
      {this.sorts = const <String, Sorting>{},
      this.equals = const <String, dynamic>{},
      this.filters = const <String, dynamic>{},
      this.update = const <String, dynamic>{},
      this.fields = const <String, bool>{},
      this.limit = 100,
      this.offset = 0,
      this.queryType,
      this.document = const <String, dynamic>{}});

  ///From Json
  factory Query.fromJson(Map<String, dynamic> json) => _$QueryFromJson(json);

  ///To Json
  Map<String, dynamic> toJson() => _$QueryToJson(this);

  ///Query Collection
  @JsonKey(name: "collection", nullable: false)
  String collection;

  ///
  @JsonKey(name: "query_type", nullable: false)
  QueryType queryType;

  ///Query one document
  @JsonKey(name: 'document', nullable: true)
  Map<String, dynamic> document;

  @JsonKey(name: 'fields', nullable: true)
  Map<String, bool> fields;

  ///Access token request type
  @JsonKey(name: 'token', required: true, nullable: false, includeIfNull: false)
  String token;

  ///
  @JsonKey(name: 'offset', defaultValue: 0)
  int offset;

  ///
  @JsonKey(name: 'limit', defaultValue: 100)
  int limit;

  ///Update Query
  @JsonKey(name: 'update', defaultValue: <String, dynamic>{})
  Map<String, dynamic> update = <String, dynamic>{};

  ///Filter Query
  @JsonKey(name: 'filters', defaultValue: <String, dynamic>{})
  Map<String, dynamic> filters = <String, dynamic>{};

  ///Equal Query
  @JsonKey(name: 'equals', defaultValue: <String, dynamic>{})
  Map<String, dynamic> equals = <String, dynamic>{};

  ///Sort Query
  @JsonKey(name: 'sorts', defaultValue: <String, Sorting>{})
  Map<String, Sorting> sorts = <String, Sorting>{};
}
