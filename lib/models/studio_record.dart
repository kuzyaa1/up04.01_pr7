import '../core/json_parsing.dart';

/// Records for subscriptions, additional services and booking payments.
class StudioRecord {
  const StudioRecord(this.values);
  final Map<String, dynamic> values;
  int get id => parseInt(values['id']);
  bool get isDeleted => values['deletedAt'] != null;
  String text(String field) => parseString(values[field]);
  String get title => text('name').isNotEmpty
      ? text('name')
      : text('number').isNotEmpty
          ? text('number')
          : 'Оплата №$id';
}

class StudioQuery {
  const StudioQuery(this.parameters);
  final Map<String, String> parameters;
  factory StudioQuery.fromUri(Uri uri) => StudioQuery(uri.queryParameters);
  int get page => int.tryParse(parameters['page'] ?? '') ?? 1;
  bool get includeDeleted => parameters['includeDeleted'] == 'true';
  StudioQuery change(Map<String, String?> changes) => StudioQuery({
        ...parameters,
        for (final e in changes.entries) e.key: e.value ?? '',
      }..removeWhere((k, v) => v.isEmpty));
  String location(String entity) => Uri(
          path: '/$entity',
          queryParameters: parameters.isEmpty ? null : parameters)
      .toString();
}
