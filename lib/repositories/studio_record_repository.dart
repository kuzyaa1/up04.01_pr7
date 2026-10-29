import '../models/studio_record.dart';
import 'api_repository.dart';

class StudioRecordRepository extends ApiRepository<StudioRecord, StudioQuery> {
  StudioRecordRepository(super.dio, this.entity);
  final String entity;
  @override
  String get collectionPath => '/$entity';
  @override
  int get defaultSize => 10;
  @override
  StudioRecord fromJson(Map<String, dynamic> json) => StudioRecord(json);
  @override
  Map<String, dynamic> toRequestBody(StudioRecord record) => record.values;
  @override
  Map<String, dynamic> toParameters(StudioQuery query) => query.parameters;
  @override
  StudioQuery allQuery({bool includeDeleted = false}) => StudioQuery({
        'size': '100',
        if (includeDeleted) 'includeDeleted': 'true',
      });
}
