import 'package:json_annotation/json_annotation.dart';
import 'package:yaz_client/yaz_client.dart';

part 'query_model.g.dart';

///Query Class for Mongo Db Query
@JsonSerializable()
class Query {
  ///Is the same [Query.create]
  Query(this.collection,
      {required this.sorts,
      required this.equals,
      required this.filters,
      required this.update,
      required this.limit,
      required this.offset,
      required this.token,
      required this.queryType,
      this.document});

  ///Create Query
  ///[collection] must not be null
  ///[token] must not be null
  Query.create(this.collection,
      {this.sorts = const <String, Sorting>{},
      this.notEquals = const <String, dynamic>{},
      this.equals = const <String, dynamic>{},
      this.filters = const <String, dynamic>{},
      this.update = const <String, dynamic>{},
      this.fields = const <String, bool>{},
      this.limit = 100,
      this.offset = 0,
      this.document = const <String, dynamic>{}});

  ///From Json
  factory Query.fromJson(Map<String, dynamic> json) => _$QueryFromJson(json);

  ///To Json
  Map<String, dynamic> toJson() => _$QueryToJson(this);

  ///Query Collection
  @JsonKey(
    name: "collection",
  )
  String? collection;

  ///
  @JsonKey(
    name: "query_type",
  )
  QueryType? queryType;

  ///Query one document
  @JsonKey(
    name: 'document',
  )
  Map<String, dynamic>? document;

  @JsonKey(
    name: 'fields',
  )
  Map<String, bool>? fields;

  ///Access token request type
  @JsonKey(name: 'token', required: true, includeIfNull: false)
  String? token;

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
  Map<String, Sorting?> sorts = <String, Sorting>{};

  ///Sort Query
  @JsonKey(name: 'not_equals', defaultValue: <String, Sorting>{})
  Map<String, dynamic> notEquals = <String, dynamic>{};
}

/// Start creating [QueryBuilder]
///
///
/// collection(Which Collection)  // Must start [collection]
///     .where(Document Fields Equal to what?)
///     .sort(In what order)
///     .filter (Which conditions fit)
///     .limit(Max Response Length)
///     .offset(How Many Skip On Start)
///     .fields(Which Fields Are Included?)
///
/// See this functions documents for more information
///
/// example :
//    Oldest (alphabetical between equals) active user age
/// ```
/// var queryBuilder = collection("users")
///       .sort("name" , Sorting.ascending)
///       .sort("age" , Sorting.descending)
///       .where("active"  , isEqualTo: true)
///       .fields(includes: ["age" , "name" , "user_id"] , excludes: ["mail_address"])
/// ```
///
QueryBuilder collection(String collection) => QueryBuilder._create(collection);

/// Start creating [QueryBuilder]
///
///
/// collection(Which Collection)    // Must start [collection]
///     .where(Document Fields Equal to what?)
///     .sort(In what order)
///     .filter (Which conditions fit)
///     .limit(Max Response Length)
///     .offset(How Many Skip On Start)
///     .fields(Which Fields Are Included?)
///
/// See this functions documents for more information
///
/// example :
//    Oldest (alphabetical between equals) active user age
/// ```
/// var queryBuilder = collection("users")
///       .sort("name" , Sorting.ascending)
///       .sort("age" , Sorting.descending)
///       .where("active"  , isEqualTo: true)
///       .fields(includes: ["age" , "name" , "user_id"] , excludes: ["mail_address"])
/// ```
///
class QueryBuilder {
  QueryBuilder._create(this._collection);

  /// [ { "a" : "b" } ,  { "a" : "c" }  , {"a" : "d" , "arg" : { "1" : "2"}}]
  ///
  /// where("a", isEqualTo: "b") => {"a" : "b"}
  /// where("arg.1" , isEqualTo: "2") => {"a" : "d" , "arg" : { "1" : "2"}}
  ///
  /// Only use equalTo or notEqualTo
  QueryBuilder where(String fieldName,
      {dynamic isEqualTo, dynamic isNotEqualTo}) {
    assert(isEqualTo == null || isNotEqualTo == null, "Only use one");
    assert(isNotEqualTo != null || isEqualTo != null, "Use one condition");
    if (isEqualTo != null) {
      _equals[fieldName] = isEqualTo;
    }
    if (isNotEqualTo != null) {
      _notEquals[fieldName] = isNotEqualTo;
    }
    return this;
  }

  /// [ {"name" : "x" , "age" : 15} , {"name" : "y" , "age" : 20} , {"name" : "z" , "age" : 25}]
  ///
  /// filter("age", isGreaterThan: 20) => {"name" : "z" , "age" : 25}
  /// filter("age", isGreaterOrEqualThan: 20) => [{"name" : "y" , "age" : 20} , {"name" : "z" , "age" : 25}]
  ///
  QueryBuilder filter(String fieldName,
      {dynamic isGreaterThan,
      dynamic isGreaterOrEqualThan,
      dynamic isLessThan,
      dynamic isLessOrEqualThan}) {
    var _l = List<bool>.generate(4, (index) {
      if (index == 0) return isGreaterThan != null;
      if (index == 1) return isGreaterOrEqualThan != null;
      if (index == 2) return isLessThan != null;
      if (index == 3) return isLessOrEqualThan != null;
      return false;
    });

    assert(_l.where((element) => element).length == 1, "Only use one");
    assert(
        isGreaterThan != null ||
            isGreaterOrEqualThan != null ||
            isLessThan != null ||
            isLessOrEqualThan != null,
        "Use one condition");

    if (isGreaterThan != null) {
      _filters["gt"] ??= <String, dynamic>{};
      _filters["gt"][fieldName] = isGreaterThan;
    }
    if (isGreaterOrEqualThan != null) {
      _filters["gte"] ??= <String, dynamic>{};
      _filters["gte"][fieldName] = isGreaterOrEqualThan;
    }
    if (isLessThan != null) {
      _filters["lt"] ??= <String, dynamic>{};
      _filters["lt"][fieldName] = isLessThan;
    }
    if (isLessOrEqualThan != null) {
      _filters["lte"] ??= <String, dynamic>{};
      _filters["lte"][fieldName] = isLessOrEqualThan;
    }
    return this;
  }

  /// Document Limit for list query
  QueryBuilder limit(int limit) {
    assert(limit > 0, "Limit must be greater than 0");
    _limit = limit;
    return this;
  }

  /// Document Skip count on start for list query
  QueryBuilder offset(int offset) {
    assert(offset >= 0, "offset must be greater than or equal to 0");
    _offset = offset;
    return this;
  }

  /// [ {"name" : "x" , "age" : 15} , {"name" : "y" , "age" : 20} , {"name" : "z" , "age" : 25}]
  ///
  /// sort("age" , Sorting.ascending)  => (first element) {"name" : "x" , "age" : 15}
  ///
  QueryBuilder sort(String fieldName, Sorting sorting) {
    _sorts[fieldName] = sorting;
    return this;
  }

  ///
  /// Query Response include or exclude document fields
  QueryBuilder fields({List<String>? includes, List<String>? excludes}) {
    if (includes != null && includes.isNotEmpty) {
      for (var f in includes) {
        _fileds[f] = true;
      }
    }

    if (excludes != null && excludes.isNotEmpty) {
      for (var f in excludes) {
        _fileds[f] = false;
      }
    }
    return this;
  }

  ///Query collection
  ///eg users , posts
  String? _collection;

  ///Query filter
  ///
  Map<String, dynamic> _filters = <String, dynamic>{};

  ///Query equals
  /// e.g. {user_name : "mehmedyaz"}   , {name : Mehmet}
  Map<String, dynamic> _equals = <String, dynamic>{};

  ///
  Map<String, dynamic> _notEquals = <String, dynamic>{};

  ///Sorts
  Map<String, Sorting> _sorts = <String, Sorting>{};

  ///
  Map<String, bool> _fileds = <String, bool>{};

  ///Data counts
  int _limit = 100, _offset = 0;

  ///
  Query toQuery(QueryType type, {String? token}) {
    return Query.create(_collection,
        equals: _equals,
        filters: _filters,
        limit: _limit,
        notEquals: _notEquals,
        offset: _offset,
        fields: _fileds,
        sorts: _sorts)
      ..token = token
      ..queryType = type;
  }
}
